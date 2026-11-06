$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$nodes = Import-Csv (Join-Path $root 'workflow-output\compact_nodes.csv')
$rels = Import-Csv (Join-Path $root 'workflow-output\compact_relationships.csv')
$dotPath = Join-Path $root 'workflow-output\niraiva_cancer_patient_workflow_compact.dot'
$dotText = Get-Content $dotPath -Raw
$failures = [System.Collections.Generic.List[string]]::new()

function Require-Node([string]$id) {
    if (-not ($nodes.id -contains $id)) { $failures.Add("Missing visible node: $id") }
}
function Require-Edge([string]$from, [string]$to) {
    if (-not ($rels | Where-Object { $_.source_id -eq $from -and $_.target_id -eq $to })) {
        $failures.Add("Missing edge: $from -> $to")
    }
}
function Forbid-Edge([string]$from, [string]$to) {
    if ($rels | Where-Object { $_.source_id -eq $from -and $_.target_id -eq $to }) {
        $failures.Add("Forbidden edge remains: $from -> $to")
    }
}
function Require-Text([string]$pattern, [string]$label) {
    if ($dotText -notmatch $pattern) { $failures.Add("Missing graph text/value: $label") }
}

$requiredNodes = @(
 'LUNG_RISK_ACTION_DECISION','CLINICAL_FINDINGS_CONVERGENCE','LAB_RESULTS_CONVERGENCE',
 'IMAGING_RESULTS_CONVERGENCE','INTEGRATED_DIAGNOSTIC_FINDINGS','STAGING_SYSTEM_DECISION',
 'BREAST_PROFILE_CONVERGENCE','STAGE_RESULT_CONVERGENCE','STAGE_PROFILE_INTEGRATION',
 'M1_STAGE4_APPLICABILITY','SURGICAL_PATHOLOGY_DECISION','SURGICAL_PATHOLOGY'
)
$requiredNodes | ForEach-Object { Require-Node $_ }

@(
 @('LUNG_FEMALE_VALUES','LUNG_RISK_ACTION_DECISION'),
 @('LUNG_MALE_VALUES','LUNG_RISK_ACTION_DECISION'),
 @('LUNG_RISK_ACTION_DECISION','SCREENING'),
 @('LUNG_RISK_ACTION_DECISION','LIFESTYLE_RISK_SUMMARY'),
 @('D1_BREAST','CLINICAL_FINDINGS_CONVERGENCE'),
 @('CLINICAL_ASSESSMENT','CLINICAL_FINDINGS_CONVERGENCE'),
 @('CLINICAL_FINDINGS_CONVERGENCE','SUSPICIOUS_DECISION'),
 @('D1_CBC','LAB_RESULTS_CONVERGENCE'), @('D1_CMP','LAB_RESULTS_CONVERGENCE'),
 @('D1_INFLAMMATION','LAB_RESULTS_CONVERGENCE'),
 @('D1_IMAGING_METHOD','IMAGING_RESULTS_CONVERGENCE'), @('D1_LESION','IMAGING_RESULTS_CONVERGENCE'),
 @('D1_SPREAD','IMAGING_RESULTS_CONVERGENCE'),
 @('CLINICAL_FINDINGS_CONVERGENCE','INTEGRATED_DIAGNOSTIC_FINDINGS'),
 @('LAB_RESULTS_CONVERGENCE','INTEGRATED_DIAGNOSTIC_FINDINGS'),
 @('IMAGING_RESULTS_CONVERGENCE','INTEGRATED_DIAGNOSTIC_FINDINGS'),
 @('INTEGRATED_DIAGNOSTIC_FINDINGS','ABNORMALITY_DECISION'),
 @('PATHOLOGY','MALIGNANCY_DECISION'),
 @('D1_HER2','BREAST_PROFILE_CONVERGENCE'), @('D1_ER','BREAST_PROFILE_CONVERGENCE'),
 @('D1_PR','BREAST_PROFILE_CONVERGENCE'),
 @('STAGING_SYSTEM_DECISION','TNM_ASSESSMENT'), @('STAGING_SYSTEM_DECISION','ALTERNATIVE_STAGING'),
 @('TNM_ASSESSMENT','D3_CLINICAL_STAGE'),
 @('METASTASIS_DECISION','M1_STAGE4_APPLICABILITY'),
 @('M1_STAGE4_APPLICABILITY','STAGE_4'), @('M1_STAGE4_APPLICABILITY','CANCER_SPECIFIC_STAGE_RESULT'),
 @('BREAST_PROFILE_CONVERGENCE','STAGE_PROFILE_INTEGRATION'),
 @('GRADE_PROFILE_PROGNOSIS','STAGE_PROFILE_INTEGRATION'),
 @('STAGE_RESULT_CONVERGENCE','STAGE_PROFILE_INTEGRATION'),
 @('STAGE_PROFILE_INTEGRATION','TREATMENT_PLANNING'),
 @('TREATMENT_PLANNING','SURGICAL_PATHOLOGY_DECISION'),
 @('SURGICAL_PATHOLOGY_DECISION','SURGICAL_PATHOLOGY'),
 @('SURGICAL_PATHOLOGY','D3_PATH_STAGE'), @('D3_PATH_STAGE','FOLLOWUP'),
 @('ENVIRONMENTAL_EXPOSURES','LIFESTYLE_RISK_SUMMARY'),
 @('FOOD_EVIDENCE_CAUTION','LIFESTYLE_RISK_SUMMARY')
) | ForEach-Object { Require-Edge $_[0] $_[1] }

Forbid-Edge 'PATHOLOGY' 'D3_PATH_STAGE'
Forbid-Edge 'TNM_ASSESSMENT' 'D3_PATH_STAGE'
Forbid-Edge 'METASTASIS_DECISION' 'STAGE_4'

$nText = ($nodes | Where-Object id -eq 'N_ASSESSMENT').description
if ($nText -notmatch 'location' -or $nText -notmatch 'not node count alone') {
    $failures.Add('N assessment explanation is incomplete')
}

$caution = ($nodes | Where-Object id -eq 'STAGING_CAUTION').description
if ($caution -notmatch 'cancer-specific' -or $caution -notmatch 'M1' -or $caution -notmatch 'Stage IV') {
    $failures.Add('Protected cancer-specific staging caution changed or missing')
}

Require-Text '0\.185' 'female smoker probability 0.185'
Require-Text '0\.026' 'female quit-smoker probability 0.026'
Require-Text '0\.004' 'female nonsmoker probability 0.004'
Require-Text '0\.244' 'male smoker probability 0.244'
Require-Text '0\.055' 'male quit-smoker probability 0.055'
Require-Text '80%' 'smoking attribution over 80%'
Require-Text '10.?20' '10-20x smoking risk'
Require-Text '4.?5%' 'alcohol 4-5%'
Require-Text '510' 'red meat 510 g/3-4 servings weekly'

$isolated = $nodes | Where-Object {
    $id = $_.id
    -not ($rels | Where-Object { $_.source_id -eq $id -or $_.target_id -eq $id })
}
if ($isolated) { $failures.Add('Isolated visible nodes: ' + (($isolated.id) -join ', ')) }

if ($failures.Count -gt 0) {
    Write-Host 'AUDIT FAILED' -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" }
    exit 1
}

Write-Host 'AUDIT PASSED' -ForegroundColor Green
Write-Host "Visible nodes: $($nodes.Count)"
Write-Host "Visible relationships: $($rels.Count)"
Write-Host 'All lead round-2 structural checks passed; no visible isolated nodes.'
