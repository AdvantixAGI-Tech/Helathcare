COPY (
    MATCH (n:WorkflowNode)
    WHERE NOT n.id IN [
        'D1_METADATA','D2_METADATA','D3_METADATA','D3_CAVEAT','D1_HISTOLOGY','D3_T','D3_N','D3_M',
        'D1_SYSTEMIC','D1_SURFACE','D1_BLEEDING','D1_RESPIRATORY','D1_DIGESTIVE','D1_URINARY',
        'D3_PHYSICAL','D3_IMAGING','D3_ENDOSCOPY','D3_BIOPSY_EVIDENCE','D3_LAB_EVIDENCE',
        'D3_TX','D3_T0','D3_NX',
        'D3_STAGE0_DESC','D3_STAGE1_DESC','D3_STAGE2_DESC','D3_STAGE3_DESC','D3_STAGE4_DESC',
        'D2_SMOKING_VALUE','D2_ALCOHOL_VALUE','D2_RED_MEAT_VALUE',
        'D2_OBESITY_ESOPHAGEAL','D2_OBESITY_ENDOMETRIAL','D2_OBESITY_GALLBLADDER','D2_ACTIVITY_VALUE',
        'D2_INFLAMMATION','D2_ANTI_INFLAMMATORY','D2_DIET_PATTERNS','D2_MICROBIOME',
        'D2_FOOD_PREPARATION','D2_WELLBEING','D2_CANCER_LINKS'
    ]
    RETURN
        n.id AS id, n.name AS name, n.node_type AS node_type,
        n.section AS section, n.description AS description,
        n.value_text AS value_text, n.unit AS unit, n.dataset AS dataset,
        n.sort_order AS sort_order, n.color AS color, n.shape AS shape
    ORDER BY n.sort_order, n.id
)
TO
'C:/Users/advantix-user-001/Documents/Niraiva-Kuzu-Graph/workflow-output/compact_nodes.csv'
(HEADER=true);

COPY (
    MATCH (source:WorkflowNode)-[edge:WORKFLOW_EDGE]->(target:WorkflowNode)
    WHERE NOT source.id IN [
        'D1_METADATA','D2_METADATA','D3_METADATA','D3_CAVEAT','D1_HISTOLOGY','D3_T','D3_N','D3_M',
        'D1_SYSTEMIC','D1_SURFACE','D1_BLEEDING','D1_RESPIRATORY','D1_DIGESTIVE','D1_URINARY',
        'D3_PHYSICAL','D3_IMAGING','D3_ENDOSCOPY','D3_BIOPSY_EVIDENCE','D3_LAB_EVIDENCE',
        'D3_TX','D3_T0','D3_NX',
        'D3_STAGE0_DESC','D3_STAGE1_DESC','D3_STAGE2_DESC','D3_STAGE3_DESC','D3_STAGE4_DESC',
        'D2_SMOKING_VALUE','D2_ALCOHOL_VALUE','D2_RED_MEAT_VALUE',
        'D2_OBESITY_ESOPHAGEAL','D2_OBESITY_ENDOMETRIAL','D2_OBESITY_GALLBLADDER','D2_ACTIVITY_VALUE',
        'D2_INFLAMMATION','D2_ANTI_INFLAMMATORY','D2_DIET_PATTERNS','D2_MICROBIOME',
        'D2_FOOD_PREPARATION','D2_WELLBEING','D2_CANCER_LINKS'
    ]
    AND NOT target.id IN [
        'D1_METADATA','D2_METADATA','D3_METADATA','D3_CAVEAT','D1_HISTOLOGY','D3_T','D3_N','D3_M',
        'D1_SYSTEMIC','D1_SURFACE','D1_BLEEDING','D1_RESPIRATORY','D1_DIGESTIVE','D1_URINARY',
        'D3_PHYSICAL','D3_IMAGING','D3_ENDOSCOPY','D3_BIOPSY_EVIDENCE','D3_LAB_EVIDENCE',
        'D3_TX','D3_T0','D3_NX',
        'D3_STAGE0_DESC','D3_STAGE1_DESC','D3_STAGE2_DESC','D3_STAGE3_DESC','D3_STAGE4_DESC',
        'D2_SMOKING_VALUE','D2_ALCOHOL_VALUE','D2_RED_MEAT_VALUE',
        'D2_OBESITY_ESOPHAGEAL','D2_OBESITY_ENDOMETRIAL','D2_OBESITY_GALLBLADDER','D2_ACTIVITY_VALUE',
        'D2_INFLAMMATION','D2_ANTI_INFLAMMATORY','D2_DIET_PATTERNS','D2_MICROBIOME',
        'D2_FOOD_PREPARATION','D2_WELLBEING','D2_CANCER_LINKS'
    ]
    AND NOT (
        source.id IN ['STAGE_0','STAGE_1','STAGE_2','STAGE_3','STAGE_4']
        AND target.id = 'FOLLOWUP'
    )
    RETURN
        source.id AS source_id, target.id AS target_id,
        edge.relationship AS relationship, edge.branch_label AS branch_label,
        edge.condition AS condition, edge.evidence AS evidence,
        edge.line_style AS line_style, edge.sort_order AS sort_order
    ORDER BY edge.sort_order, source.id, target.id
)
TO
'C:/Users/advantix-user-001/Documents/Niraiva-Kuzu-Graph/workflow-output/compact_relationships.csv'
(HEADER=true);
