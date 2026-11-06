$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$nodes = Import-Csv (Join-Path $root 'workflow-output\compact_nodes.csv')
$rels = Import-Csv (Join-Path $root 'workflow-output\compact_relationships.csv')
$dotPath = Join-Path $root 'workflow-output\niraiva_cancer_patient_workflow_compact.dot'
$dot = Get-Content $dotPath -Raw
$flatDot = (($dot -replace '\\n',' ') -replace '\s+',' ').Trim()
$fail = [System.Collections.Generic.List[string]]::new()
$ids = @($nodes.id)

function NeedNode([string]$id) {
  if ($id -notin $ids) { $fail.Add("Missing node: $id") }
}
function NeedEdge([string]$from,[string]$to) {
  if (-not ($rels | Where-Object { $_.source_id -eq $from -and $_.target_id -eq $to })) {
    $fail.Add("Missing edge: $from -> $to")
  }
}
function ForbidEdge([string]$from,[string]$to) {
  if ($rels | Where-Object { $_.source_id -eq $from -and $_.target_id -eq $to }) {
    $fail.Add("Forbidden bypass edge: $from -> $to")
  }
}

$requiredNodes = @(
 'HEREDITARY_RISK_ASSESSMENT','FAMILY_HISTORY_DETAILS','HEREDITARY_EVAL_DECISION',
 'GENETIC_COUNSELLING','GERMLINE_INTERPRETATION','HEREDITARY_SYNDROMES',
 'HEREDITARY_GENES','PRS_USE_DECISION','PRS_ASSESSMENT','PRS_LIMITATIONS',
 'HEREDITARY_RISK_INTEGRATION','INFECTION_HISTORY','MULTIFACTORIAL_RISK_CONTEXT',
 'INTEGRATED_BASELINE_RISK','MEDICAL_SCREENING_HISTORY','TEMPORAL_HISTORY_ASSESSMENT',
 'RISK_SUSPICION_DIAGNOSIS_CAUTION','LONGITUDINAL_CONTEXT'
)
$requiredNodes | ForEach-Object { NeedNode $_ }

@(
 @('PATIENT_PROFILE','HEREDITARY_RISK_ASSESSMENT'),
 @('HEREDITARY_RISK_ASSESSMENT','FAMILY_HISTORY_DETAILS'),
 @('FAMILY_HISTORY_DETAILS','HEREDITARY_EVAL_DECISION'),
 @('HEREDITARY_EVAL_DECISION','GENETIC_COUNSELLING'),
 @('HEREDITARY_EVAL_DECISION','HEREDITARY_RISK_INTEGRATION'),
 @('GENETIC_COUNSELLING','GERMLINE_INTERPRETATION'),
 @('GERMLINE_INTERPRETATION','HEREDITARY_RISK_INTEGRATION'),
 @('HEREDITARY_RISK_ASSESSMENT','PRS_USE_DECISION'),
 @('PRS_USE_DECISION','PRS_ASSESSMENT'),
 @('PRS_USE_DECISION','HEREDITARY_RISK_INTEGRATION'),
 @('PRS_ASSESSMENT','HEREDITARY_RISK_INTEGRATION'),
 @('HEREDITARY_RISK_INTEGRATION','LIFESTYLE'),
 @('LIFESTYLE_RISK_SUMMARY','INTEGRATED_BASELINE_RISK'),
 @('INFECTION_HISTORY','INTEGRATED_BASELINE_RISK'),
 @('INTEGRATED_BASELINE_RISK','MEDICAL_SCREENING_HISTORY'),
 @('MEDICAL_SCREENING_HISTORY','TEMPORAL_HISTORY_ASSESSMENT'),
 @('TEMPORAL_HISTORY_ASSESSMENT','SYMPTOM_DECISION')
) | ForEach-Object { NeedEdge $_[0] $_[1] }

ForbidEdge 'PATIENT_PROFILE' 'LIFESTYLE'
ForbidEdge 'LIFESTYLE_RISK_SUMMARY' 'SYMPTOM_DECISION'
ForbidEdge 'HEREDITARY_RISK_ASSESSMENT' 'PRS_ASSESSMENT'
ForbidEdge 'HEREDITARY_RISK_ASSESSMENT' 'MALIGNANCY_DECISION'
ForbidEdge 'GERMLINE_INTERPRETATION' 'MALIGNANCY_DECISION'
ForbidEdge 'HEREDITARY_RISK_INTEGRATION' 'TNM_ASSESSMENT'

$missingEndpoints = $rels | Where-Object { $_.source_id -notin $ids -or $_.target_id -notin $ids }
if ($missingEndpoints) { $fail.Add('One or more relationships have missing endpoints') }
$exactDuplicates = $rels | Group-Object source_id,target_id,relationship,branch_label,condition,evidence,line_style | Where-Object Count -gt 1
if ($exactDuplicates) { $fail.Add('Exact duplicate relationship rows exist') }
$isolated = $nodes | Where-Object { $id=$_.id; -not ($rels | Where-Object { $_.source_id -eq $id -or $_.target_id -eq $id }) }
if ($isolated) { $fail.Add('Isolated nodes: ' + (($isolated.id) -join ', ')) }

# Undirected connected-component audit.
$seen = [System.Collections.Generic.HashSet[string]]::new()
$queue = [System.Collections.Generic.Queue[string]]::new()
[void]$seen.Add('INITIAL'); $queue.Enqueue('INITIAL')
while ($queue.Count -gt 0) {
  $x=$queue.Dequeue()
  foreach ($edge in $rels | Where-Object { $_.source_id -eq $x -or $_.target_id -eq $x }) {
    $y = if ($edge.source_id -eq $x) { $edge.target_id } else { $edge.source_id }
    if ($seen.Add($y)) { $queue.Enqueue($y) }
  }
}
if ($seen.Count -ne $nodes.Count) { $fail.Add("Graph is not one connected component: $($seen.Count)/$($nodes.Count)") }

$requiredText = @(
 'biological relationship','maternal or paternal lineage','multiple primary cancers',
 'BRCA1','BRCA2','APC','MLH1','MSH2','MSH6','PMS2','TP53','PALB2','PTEN',
 'Lynch syndrome','familial adenomatous polyposis','Li-Fraumeni syndrome',
 'Polygenic Risk Score','calibration','prospective validation','ancestry',
 'HPV','HBV','HCV','EBV','HTLV-1','HIV-related immunosuppression',
 'pack-years','packs/day','previous cancer','previous biopsy','previous abnormal imaging',
 'new, persistent, previously investigated, recurrent or changing',
 'Risk factors indicate susceptibility','histopathological confirmation'
)
foreach ($text in $requiredText) {
  if ($flatDot -notmatch [regex]::Escape($text)) { $fail.Add("Missing source concept/text: $text") }
}

if ($fail.Count -gt 0) {
  Write-Host 'DATASET 4 INTEGRATION AUDIT FAILED' -ForegroundColor Red
  $fail | ForEach-Object { Write-Host " - $_" }
  exit 1
}
Write-Host 'DATASET 4 INTEGRATION AUDIT PASSED' -ForegroundColor Green
Write-Host "Visible nodes: $($nodes.Count)"
Write-Host "Visible relationships: $($rels.Count)"
Write-Host 'One connected component; no missing endpoints, isolated nodes, exact duplicate rows, or prohibited diagnostic/staging shortcuts.'
