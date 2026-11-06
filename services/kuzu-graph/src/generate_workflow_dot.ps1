$ProjectRoot = Split-Path -Parent $PSScriptRoot

$NodesPath = Join-Path `
    $ProjectRoot `
    "workflow-output\kuzu_nodes.csv"

$RelationshipsPath = Join-Path `
    $ProjectRoot `
    "workflow-output\kuzu_relationships.csv"

$DotPath = Join-Path `
    $ProjectRoot `
    "workflow-output\niraiva_cancer_patient_workflow.dot"

$Nodes = Import-Csv $NodesPath
$Relationships = Import-Csv $RelationshipsPath

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
$DotLines.Add('    splines=polyline,')
$DotLines.Add('    nodesep=0.35,')
$DotLines.Add('    ranksep=0.65,')
$DotLines.Add('    pad=0.4,')
$DotLines.Add('    bgcolor="white",')
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
$DotLines.Add('    arrowsize=0.7,')
$DotLines.Add('    penwidth=1.1')
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

    if ($Shape -eq "diamond") {
        $Style = "filled"
    }

    if ($Shape -eq "note") {
        $Style = "filled"
    }

    if ($Shape -eq "circle" -or $Shape -eq "doublecircle") {
        $Style = "filled"
    }

    $DotLines.Add(
        "  `"$NodeId`" [label=`"$Label`", shape=$Shape, fillcolor=`"$FillColor`", style=`"$Style`"];"
    )
}

foreach ($Edge in $Relationships) {
    $SourceId = Escape-DotText $Edge.source_id
    $TargetId = Escape-DotText $Edge.target_id

    $EdgeLabel = $Edge.branch_label

    if ([string]::IsNullOrWhiteSpace($EdgeLabel)) {
        $EdgeLabel = $Edge.relationship
    }

    if (-not [string]::IsNullOrWhiteSpace($Edge.condition)) {
        $EdgeLabel = "$EdgeLabel | $($Edge.condition)"
    }

    $EdgeLabel = Wrap-DotText (Escape-DotText $EdgeLabel) 30

    $LineStyle = $Edge.line_style

    if ([string]::IsNullOrWhiteSpace($LineStyle)) {
        $LineStyle = "solid"
    }

    $EdgeColor = "#6B879D"
    $PenWidth = "1.2"

    if ($LineStyle -eq "dashed") {
        $EdgeColor = "#9AA7B2"
        $PenWidth = "0.9"
    }

    $DotLines.Add(
        "  `"$SourceId`" -> `"$TargetId`" [label=`"$EdgeLabel`", style=$LineStyle, color=`"$EdgeColor`", penwidth=$PenWidth];"
    )
}

$DotLines.Add('  subgraph cluster_color_legend {')
$DotLines.Add('    label="Color Description";')
$DotLines.Add('    labelloc="t";')
$DotLines.Add('    fontsize=14;')
$DotLines.Add('    fontname="Arial Bold";')
$DotLines.Add('    color="#B7C9D6";')
$DotLines.Add('    style="rounded";')
$DotLines.Add('    margin=14;')
$DotLines.Add('    rank=sink;')
$DotLines.Add('    "COLOR_LEGEND" [')
$DotLines.Add('      shape=plain,')
$DotLines.Add('      label=<')
$DotLines.Add('        <TABLE BORDER="0" CELLBORDER="1" CELLSPACING="0" CELLPADDING="7">')
$DotLines.Add('          <TR><TD BGCOLOR="#DDEBF7"><B>Blue</B></TD><TD ALIGN="LEFT">Patient and clinical workflow</TD></TR>')
$DotLines.Add('          <TR><TD BGCOLOR="#9DC3E6"><B>Dark Blue</B></TD><TD ALIGN="LEFT">Initial, terminal and major states</TD></TR>')
$DotLines.Add('          <TR><TD BGCOLOR="#FFE699"><B>Yellow</B></TD><TD ALIGN="LEFT">Decision and lifestyle-risk assessment</TD></TR>')
$DotLines.Add('          <TR><TD BGCOLOR="#E4DFEC"><B>Purple</B></TD><TD ALIGN="LEFT">Laboratory and imaging assessment</TD></TR>')
$DotLines.Add('          <TR><TD BGCOLOR="#F4CCCC"><B>Pink</B></TD><TD ALIGN="LEFT">Biopsy and pathology</TD></TR>')
$DotLines.Add('          <TR><TD BGCOLOR="#F8CBAD"><B>Peach</B></TD><TD ALIGN="LEFT">Cancer biomarkers and receptors</TD></TR>')
$DotLines.Add('          <TR><TD BGCOLOR="#E2F0D9"><B>Light Green</B></TD><TD ALIGN="LEFT">Monitoring, follow-up and protective factors</TD></TR>')
$DotLines.Add('          <TR><TD BGCOLOR="#C6E0B4"><B>Green</B></TD><TD ALIGN="LEFT">TNM components and staging information</TD></TR>')
$DotLines.Add('          <TR><TD BGCOLOR="#FFD966"><B>Gold</B></TD><TD ALIGN="LEFT">Cancer stage groups</TD></TR>')
$DotLines.Add('          <TR><TD BGCOLOR="#F4B183"><B>Orange</B></TD><TD ALIGN="LEFT">Advanced cancer and distant metastasis</TD></TR>')
$DotLines.Add('          <TR><TD BGCOLOR="#E7E6E6"><B>Grey</B></TD><TD ALIGN="LEFT">Reported values, metadata and caution notes</TD></TR>')
$DotLines.Add('          <TR><TD><B>Solid arrow</B></TD><TD ALIGN="LEFT">Main patient workflow or decision branch</TD></TR>')
$DotLines.Add('          <TR><TD><B>Dashed arrow</B></TD><TD ALIGN="LEFT">Supporting PDF detail or evidence</TD></TR>')
$DotLines.Add('        </TABLE>')
$DotLines.Add('      >')
$DotLines.Add('    ];')
$DotLines.Add('  }')

$DotLines.Add('  "TERMINAL" -> "COLOR_LEGEND" [style=invis];')
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
