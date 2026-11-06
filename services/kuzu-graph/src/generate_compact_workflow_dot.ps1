$ProjectRoot = Split-Path -Parent $PSScriptRoot

$NodesPath = Join-Path `
    $ProjectRoot `
    "workflow-output\compact_nodes.csv"

$RelationshipsPath = Join-Path `
    $ProjectRoot `
    "workflow-output\compact_relationships.csv"

$DotPath = Join-Path `
    $ProjectRoot `
    "workflow-output\niraiva_cancer_patient_workflow_compact.dot"

$Nodes = Import-Csv $NodesPath
$Relationships = Import-Csv $RelationshipsPath

# PDF-reported numerical values are kept inside existing nodes so the
# presentation graph remains compact. These are source-reported values,
# not universal patient thresholds.
$ReportedValues = @{
    "D2_SMOKING" = ">80% cited lung-cancer attribution; ~10-20x lung-cancer risk"
    "D2_ALCOHOL" = "~4-5% cancer attribution; cited male fractions ~25-50% for several cancers"
    "D2_RED_MEAT" = "Recommended maximum: 18 oz / ~510 g / 3-4 servings per week"
    "D2_OBESITY" = "Esophageal: 29% men, 37% women; endometrial: ~36%; gallbladder: 11% men, 42% women"
    "D2_ACTIVITY" = "Up to ~50% lower colorectal risk; 48% lower among men in one cited study"
}

function Escape-DotText {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ""
    }

    $Text = $Text.Replace("\", "\\")
    $Text = $Text.Replace('"', '\"')
    $Text = $Text.Replace("`r", " ")
    $Text = $Text.Replace("`n", " ")

    return $Text
}

function Wrap-DotText {
    param(
        [string]$Text,
        [int]$Width = 38
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ""
    }

    $Words = $Text -split "\s+"
    $Lines = New-Object System.Collections.Generic.List[string]
    $CurrentLine = ""

    foreach ($Word in $Words) {
        if ([string]::IsNullOrWhiteSpace($CurrentLine)) {
            $CurrentLine = $Word
        }
        elseif (($CurrentLine.Length + $Word.Length + 1) -le $Width) {
            $CurrentLine = "$CurrentLine $Word"
        }
        else {
            $Lines.Add($CurrentLine)
            $CurrentLine = $Word
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($CurrentLine)) {
        $Lines.Add($CurrentLine)
    }

    return ($Lines -join "\n")
}

$DotLines = New-Object System.Collections.Generic.List[string]

$DotLines.Add("digraph NiraivaCancerPatientWorkflow {")
$DotLines.Add('  graph [')
$DotLines.Add('    label="Niraiva Cancer Patient Workflow",')
$DotLines.Add('    labelloc="t",')
$DotLines.Add('    fontsize=26,')
$DotLines.Add('    fontname="Arial",')
$DotLines.Add('    rankdir=TB,')
$DotLines.Add('    splines=ortho,')
$DotLines.Add('    concentrate=false,')
$DotLines.Add('    forcelabels=true,')
$DotLines.Add('    nodesep=0.65,')
$DotLines.Add('    ranksep=1.20,')
$DotLines.Add('    pad=0.4,')
$DotLines.Add('    bgcolor="white",')
$DotLines.Add('    outputorder="edgesfirst",')
$DotLines.Add('    newrank=true')
$DotLines.Add('  ];')

$DotLines.Add('  node [')
$DotLines.Add('    style="filled,rounded",')
$DotLines.Add('    fontname="Arial",')
$DotLines.Add('    fontsize=9,')
$DotLines.Add('    color="#5B7C99",')
$DotLines.Add('    penwidth=1.2,')
$DotLines.Add('    margin="0.12,0.08"')
$DotLines.Add('  ];')

$DotLines.Add('  edge [')
$DotLines.Add('    fontname="Arial",')
$DotLines.Add('    fontsize=8,')
$DotLines.Add('    color="#6B879D",')
$DotLines.Add('    fontcolor="#3F4F5F",')
$DotLines.Add('    arrowsize=0.9,')
$DotLines.Add('    penwidth=1.3,')
$DotLines.Add('    headclip=true,')
$DotLines.Add('    tailclip=true')
$DotLines.Add('  ];')

foreach ($Node in $Nodes) {
    $NodeId = Escape-DotText $Node.id
    $Name = Wrap-DotText (Escape-DotText $Node.name) 34
    $Description = Wrap-DotText (Escape-DotText $Node.description) 42
    $ValueText = Wrap-DotText (Escape-DotText $Node.value_text) 42

    $LabelParts = New-Object System.Collections.Generic.List[string]
    $LabelParts.Add($Name)

    if (-not [string]::IsNullOrWhiteSpace($Description)) {
        $LabelParts.Add($Description)
    }

    if (-not [string]::IsNullOrWhiteSpace($ValueText)) {
        $LabelParts.Add("Value: $ValueText")
    }

    if ($ReportedValues.ContainsKey($Node.id)) {
        $ReportedText = Wrap-DotText (
            Escape-DotText $ReportedValues[$Node.id]
        ) 42
        $LabelParts.Add("Reported value: $ReportedText")
    }

    $Label = $LabelParts -join "\n"

    $FillColor = $Node.color
    if ([string]::IsNullOrWhiteSpace($FillColor)) {
        $FillColor = "#DDEBF7"
    }

    $Shape = $Node.shape
    if ([string]::IsNullOrWhiteSpace($Shape)) {
        $Shape = "box"
    }

    $Style = "filled,rounded"
    $BorderColor = "#5B7C99"
    $PenWidth = "1.2"

    # Reference/detail nodes remain visible for completeness, but a dashed
    # border distinguishes supporting information from executable workflow.
    if ($Node.node_type -match "Detail|Reported Value|Metadata" -or $Shape -eq "note") {
        $Style = "filled,dashed,rounded"
        $BorderColor = "#8A98A6"
        $PenWidth = "1.0"
    }

    if ($Shape -eq "diamond") {
        $Style = "filled"
    }

    if ($Shape -eq "note") {
        $Style = "filled,dashed"
    }

    if ($Shape -eq "circle" -or $Shape -eq "doublecircle") {
        $Style = "filled"
    }

    $DotLines.Add(
        "  `"$NodeId`" [label=`"$Label`", shape=$Shape, fillcolor=`"$FillColor`", color=`"$BorderColor`", penwidth=$PenWidth, style=`"$Style`"];"
    )
}

foreach ($Edge in $Relationships) {
    $SourceId = Escape-DotText $Edge.source_id
    $TargetId = Escape-DotText $Edge.target_id


    $EdgeLabel = ""
    $EdgeKey = "$SourceId->$TargetId"

    switch ($EdgeKey) {
        "SYMPTOM_DECISION->SCREENING"              { $EdgeLabel = "No - Routine screening" }
        "SYMPTOM_DECISION->DIAGNOSTIC_ENCOUNTER"   { $EdgeLabel = "Yes - Symptoms present" }
        "SUSPICIOUS_DECISION->ROUTINE_MONITORING"  { $EdgeLabel = "No - Routine monitoring" }
        "SUSPICIOUS_DECISION->DIAGNOSTIC_WORKUP"   { $EdgeLabel = "Yes - Investigate" }
        "DIAGNOSTIC_WORKUP->LAB_ASSESSMENT"        { $EdgeLabel = "Laboratory tests" }
        "DIAGNOSTIC_WORKUP->IMAGING_ASSESSMENT"    { $EdgeLabel = "Imaging" }
        "ABNORMALITY_DECISION->MONITOR_REASSESS"   { $EdgeLabel = "No - Reassess" }
        "ABNORMALITY_DECISION->BIOPSY"             { $EdgeLabel = "Yes - Biopsy" }
        "MALIGNANCY_DECISION->NON_MALIGNANT_FOLLOWUP" { $EdgeLabel = "No - Non-malignant" }
        "MALIGNANCY_DECISION->CANCER_CLASSIFICATION"  { $EdgeLabel = "Yes - Malignant" }
        "BREAST_DECISION->RECEPTOR_ASSESSMENT"     { $EdgeLabel = "Yes - Breast pathway" }
        "BREAST_DECISION->TNM_ASSESSMENT"          { $EdgeLabel = "No - Other cancer" }
        "TNM_ASSESSMENT->T_ASSESSMENT"             { $EdgeLabel = "T" }
        "TNM_ASSESSMENT->N_ASSESSMENT"             { $EdgeLabel = "N" }
        "TNM_ASSESSMENT->M_ASSESSMENT"             { $EdgeLabel = "M" }
        "METASTASIS_DECISION->STAGE_4"             { $EdgeLabel = "M1 - Metastasis" }
        "METASTASIS_DECISION->INSITU_DECISION"     { $EdgeLabel = "M0 - No metastasis" }
        "INSITU_DECISION->STAGE_0"                 { $EdgeLabel = "Tis - In situ" }
        "INSITU_DECISION->STAGE_GROUP"             { $EdgeLabel = "Not in situ" }
        "STAGE_GROUP->STAGE_1"                     { $EdgeLabel = "Stage I" }
        "STAGE_GROUP->STAGE_2"                     { $EdgeLabel = "Stage II" }
        "STAGE_GROUP->STAGE_3"                     { $EdgeLabel = "Stage III" }
        "PROGRESSION_DECISION->TNM_ASSESSMENT"     { $EdgeLabel = "Yes - Reassess TNM" }
        "PROGRESSION_DECISION->CLINICAL_ASSESSMENT" { $EdgeLabel = "Yes - assess and confirm" }
        "PROGRESSION_DECISION->TERMINAL"           { $EdgeLabel = "No - End workflow" }
        "NON_MALIGNANT_FOLLOWUP->TERMINAL"         { $EdgeLabel = "General care / close pathway" }
        "MONITOR_REASSESS->FOLLOWUP"               { $EdgeLabel = "Return to surveillance" }
        "LUNG_GENDER_DECISION->LUNG_FEMALE_SMOKING" { $EdgeLabel = "Female" }
        "LUNG_GENDER_DECISION->LUNG_MALE_SMOKING"   { $EdgeLabel = "Male" }
        "LUNG_FEMALE_SMOKING->LUNG_QUIT_AGE"        { $EdgeLabel = "Former smoker" }
        "LUNG_MALE_SMOKING->LUNG_MALE_QUIT_AGE"     { $EdgeLabel = "Former smoker" }
        "LUNG_FEMALE_RISK_CALC->LUNG_FEMALE_VALUES" { $EdgeLabel = "Probability result" }
        "LUNG_MALE_RISK_CALC->LUNG_MALE_VALUES"     { $EdgeLabel = "Probability result" }
        "TNM_CONVERGENCE->METASTASIS_DECISION"      { $EdgeLabel = "Integrated T / N / M" }
        "LUNG_FEMALE_VALUES->LUNG_RISK_ACTION_DECISION" { $EdgeLabel = "Female probability result" }
        "LUNG_MALE_VALUES->LUNG_RISK_ACTION_DECISION"   { $EdgeLabel = "Male probability result" }
        "LUNG_RISK_ACTION_DECISION->SCREENING"          { $EdgeLabel = "Review / screening indicated" }
        "LUNG_RISK_ACTION_DECISION->LIFESTYLE_RISK_SUMMARY" { $EdgeLabel = "Continue general risk assessment" }
        "CLINICAL_FINDINGS_CONVERGENCE->SUSPICIOUS_DECISION" { $EdgeLabel = "Integrated clinical findings" }
        "LAB_RESULTS_CONVERGENCE->INTEGRATED_DIAGNOSTIC_FINDINGS" { $EdgeLabel = "Laboratory interpretation" }
        "IMAGING_RESULTS_CONVERGENCE->INTEGRATED_DIAGNOSTIC_FINDINGS" { $EdgeLabel = "Imaging interpretation" }
        "INTEGRATED_DIAGNOSTIC_FINDINGS->ABNORMALITY_DECISION" { $EdgeLabel = "Combined evidence reviewed" }
        "STAGING_SYSTEM_DECISION->TNM_ASSESSMENT"       { $EdgeLabel = "TNM applies" }
        "STAGING_SYSTEM_DECISION->ALTERNATIVE_STAGING"  { $EdgeLabel = "Alternative system applies" }
        "METASTASIS_DECISION->M1_STAGE4_APPLICABILITY"  { $EdgeLabel = "M1 identified" }
        "M1_STAGE4_APPLICABILITY->STAGE_4"               { $EdgeLabel = "Yes - system maps to Stage IV" }
        "M1_STAGE4_APPLICABILITY->CANCER_SPECIFIC_STAGE_RESULT" { $EdgeLabel = "No - use selected system" }
        "STAGE_RESULT_CONVERGENCE->STAGE_PROFILE_INTEGRATION" { $EdgeLabel = "Applicable stage result" }
        "BREAST_PROFILE_CONVERGENCE->STAGE_PROFILE_INTEGRATION" { $EdgeLabel = "HER2 / ER / PR profile" }
        "GRADE_PROFILE_PROGNOSIS->STAGE_PROFILE_INTEGRATION" { $EdgeLabel = "Grade and tumour profile" }
        "STAGE_PROFILE_INTEGRATION->TREATMENT_PLANNING" { $EdgeLabel = "Integrated stage / profile" }
        "TREATMENT_PLANNING->SURGICAL_PATHOLOGY_DECISION" { $EdgeLabel = "After initial treatment decision" }
        "SURGICAL_PATHOLOGY_DECISION->SURGICAL_PATHOLOGY" { $EdgeLabel = "Yes - surgical specimen available" }
        "SURGICAL_PATHOLOGY_DECISION->FOLLOWUP"          { $EdgeLabel = "No - pTNM unavailable / not applicable" }
        "SURGICAL_PATHOLOGY->D3_PATH_STAGE"              { $EdgeLabel = "Derive pTNM where applicable" }
        "D3_PATH_STAGE->FOLLOWUP"                        { $EdgeLabel = "Record postoperative pathological stage" }
    }

    # Preserve the explicit choice labels for the new lung-risk decision tree
    # and the other corrected convergence links.
    if ([string]::IsNullOrWhiteSpace($EdgeLabel) -and
        $Edge.line_style -ne 'dashed' -and
        -not [string]::IsNullOrWhiteSpace($Edge.branch_label)) {
        $EdgeLabel = $Edge.branch_label
    }

    $EdgeLabel = Wrap-DotText (Escape-DotText $EdgeLabel) 24

    $LabelAttribute = "xlabel=`"$EdgeLabel`""
    if ($EdgeKey -eq 'RECEPTOR_ASSESSMENT->BREAST_PROFILE_CONVERGENCE') {
        $LabelAttribute = "headlabel=`"$EdgeLabel`", labeldistance=5.0, labelangle=60"
    }

    $LineStyle = $Edge.line_style

    if ([string]::IsNullOrWhiteSpace($LineStyle)) {
        $LineStyle = "solid"
    }

    $EdgeColor = "#4F6F86"
    $PenWidth = "1.5"
    $ArrowSize = "0.95"

    if ($LineStyle -eq "dashed") {
        $EdgeColor = "#8798A6"
        $PenWidth = "1.0"
        $ArrowSize = "0.70"
    }

    $Constraint = "true"
    # Only secondary evidence rejoin lines are excluded from ranking. The
    # parent-to-detail links remain constrained so notes stay beside their
    # relevant branch instead of forming one extremely wide row.
    if ($LineStyle -eq "dashed" -and $TargetId -in @(
        'LIFESTYLE_RISK_SUMMARY','LUNG_PROBABILITY_MODEL','TREATMENT_PLANNING'
    )) {
        $Constraint = "false"
    }
    if ($EdgeKey -in @(
        'ROUTINE_MONITORING->FOLLOWUP',
        'MONITOR_REASSESS->FOLLOWUP',
        'PROGRESSION_DECISION->CLINICAL_ASSESSMENT',
        'BREAST_PROFILE_CONVERGENCE->STAGE_PROFILE_INTEGRATION'
    )) {
        $Constraint = "false"
    }

    $DotLines.Add(
        "  `"$SourceId`" -> `"$TargetId`" [$LabelAttribute, style=$LineStyle, color=`"$EdgeColor`", fontcolor=`"#33495B`", fontsize=7, penwidth=$PenWidth, arrowsize=$ArrowSize, headclip=true, tailclip=true, constraint=$Constraint];"
    )
}

$DotLines.Add('  subgraph cluster_color_legend {')
$DotLines.Add('    label="Legend - Color and Line Meaning";')
$DotLines.Add('    labelloc="t"; fontsize=12; fontname="Arial Bold";')
$DotLines.Add('    color="#AFC2D1"; bgcolor="#FAFCFD"; style="rounded"; margin=10;')
$DotLines.Add('    "COLOR_LEGEND" [')
$DotLines.Add('      shape=plain,')
$DotLines.Add('      label=<')
$DotLines.Add('        <TABLE BORDER="0" CELLBORDER="0" CELLSPACING="5" CELLPADDING="4">')
$DotLines.Add('          <TR><TD BGCOLOR="#DDEBF7" WIDTH="24"> </TD><TD ALIGN="LEFT">Clinical process</TD><TD BGCOLOR="#9DC3E6" WIDTH="24"> </TD><TD ALIGN="LEFT">Start / end / major state</TD></TR>')
$DotLines.Add('          <TR><TD BGCOLOR="#FFE699"> </TD><TD ALIGN="LEFT">Decision / lifestyle risk</TD><TD BGCOLOR="#E4DFEC"> </TD><TD ALIGN="LEFT">Laboratory / imaging</TD></TR>')
$DotLines.Add('          <TR><TD BGCOLOR="#F4CCCC"> </TD><TD ALIGN="LEFT">Biopsy / pathology</TD><TD BGCOLOR="#F8CBAD"> </TD><TD ALIGN="LEFT">Biomarkers / receptors</TD></TR>')
$DotLines.Add('          <TR><TD BGCOLOR="#E2F0D9"> </TD><TD ALIGN="LEFT">Monitoring / protective</TD><TD BGCOLOR="#C6E0B4"> </TD><TD ALIGN="LEFT">TNM staging</TD></TR>')
$DotLines.Add('          <TR><TD BGCOLOR="#FFD966"> </TD><TD ALIGN="LEFT">Cancer stage group</TD><TD BGCOLOR="#F4B183"> </TD><TD ALIGN="LEFT">Advanced / metastatic</TD></TR>')
$DotLines.Add('          <TR><TD BGCOLOR="#E7E6E6"> </TD><TD ALIGN="LEFT">Reported value / note</TD><TD ALIGN="LEFT"><B>Lines</B></TD><TD ALIGN="LEFT">Solid: workflow; Dashed: detail</TD></TR>')
$DotLines.Add('        </TABLE>')
$DotLines.Add('      >')
$DotLines.Add('    ];')
$DotLines.Add('  }')

$DotLines.Add('  "RIGHT_SPACER" [shape=box, label="", width=8, height=0.01, fixedsize=true, style=invis];')
$DotLines.Add('  { rank=same; "TREATMENT_PLANNING"; "RIGHT_SPACER"; "COLOR_LEGEND"; }')
$DotLines.Add('  "TREATMENT_PLANNING" -> "RIGHT_SPACER" [style=invis, weight=100];')
$DotLines.Add('  "RIGHT_SPACER" -> "COLOR_LEGEND" [style=invis, weight=100];')
$DotLines.Add("}")

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

[System.IO.File]::WriteAllLines(
    $DotPath,
    $DotLines,
    $Utf8NoBom
)

Write-Host "DOT graph created:"
Write-Host $DotPath
Write-Host "Nodes:" $Nodes.Count
Write-Host "Relationships:" $Relationships.Count
