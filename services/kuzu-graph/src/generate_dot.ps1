$Project = Split-Path -Parent $PSScriptRoot
$InputCsv = Join-Path $Project "output\kuzu_query_result.csv"
$OutputDot = Join-Path $Project "output\niraiva_kuzu_graph.dot"

$Rows = Import-Csv $InputCsv
$DotLines = [System.Collections.Generic.List[string]]::new()

$DotLines.Add('digraph NiraivaKuzuGraph {')
$DotLines.Add('  graph [label="Niraiva Cancer Knowledge Graph — Queried from Kuzu", labelloc="t", fontsize=22, rankdir=LR, bgcolor="white", overlap=false, splines=true, pad=0.4, nodesep=0.3, ranksep=0.8];')
$DotLines.Add('  node [shape=box, style="rounded,filled", fontname="Arial", fontsize=9, fillcolor="#DDEBF7", color="#365B7D", margin="0.12,0.08"];')
$DotLines.Add('  edge [fontname="Arial", fontsize=7, color="#667788", arrowsize=0.7];')

$NodeMap = @{}

foreach ($Row in $Rows) {
    $NodeMap[$Row.source_id.Trim()] = @{
        Name = $Row.source_name.Trim()
        Category = $Row.source_category.Trim()
    }

    $NodeMap[$Row.target_id.Trim()] = @{
        Name = $Row.target_name.Trim()
        Category = $Row.target_category.Trim()
    }
}

foreach ($NodeId in $NodeMap.Keys) {
    $Node = $NodeMap[$NodeId]

    $Color = switch ($Node.Category) {
        "Dataset"              { "#9DC3E6" }
        "Symptom"              { "#DDEBF7" }
        "Clinical Test"        { "#E4DFEC" }
        "Procedure"            { "#F4CCCC" }
        "Clinical Assessment"  { "#F4CCCC" }
        "Biomarker"            { "#F8CBAD" }
        "Lifestyle Factor"     { "#FFE699" }
        "Environmental Factor" { "#FFE699" }
        "Biological Pathway"   { "#E2F0D9" }
        "Cancer"               { "#F4B183" }
        "Staging System"       { "#A9D18E" }
        "Staging Component"    { "#C6E0B4" }
        "Stage Group"          { "#FFD966" }
        default                { "#D9EAF7" }
    }

    $SafeName = $Node.Name.Replace('"', '\"')
    $SafeId = $NodeId.Replace('"', '\"')

    $DotLines.Add(
        "  `"$SafeId`" [label=`"$SafeName`", fillcolor=`"$Color`"];"
    )
}

foreach ($Row in $Rows) {
    $SourceId = $Row.source_id.Trim().Replace('"', '\"')
    $TargetId = $Row.target_id.Trim().Replace('"', '\"')
    $Relationship = $Row.relationship.Trim().Replace('"', '\"')

    $DotLines.Add(
        "  `"$SourceId`" -> `"$TargetId`" [label=`"$Relationship`"];"
    )
}

$DotLines.Add('}')

$DotText = $DotLines -join [Environment]::NewLine
$Utf8NoBom = [System.Text.UTF8Encoding]::new($false)

[System.IO.File]::WriteAllText(
    $OutputDot,
    $DotText,
    $Utf8NoBom
)

Write-Host "Kuzu query rows used: $($Rows.Count)"
Write-Host "Unique nodes rendered: $($NodeMap.Count)"
Write-Host "DOT file created: $OutputDot"
