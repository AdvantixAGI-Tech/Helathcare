MATCH (n:WorkflowNode)
WHERE n.id = 'STAGE_0'
SET n.name = 'Stage 0 - In Situ (Where Applicable)',
    n.description = 'Carcinoma in situ without invasion; applicability and definition vary by cancer type';
