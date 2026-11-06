MATCH (n:WorkflowNode)
WHERE n.id = 'STAGING_CAUTION'
SET n.description = 'Stage 0 and TNM groupings are cancer-specific; map M1 to Stage IV only where the applicable cancer-specific system defines it';
