COPY WorkflowNode FROM
'C:/Users/advantix-user-001/Documents/Niraiva-Kuzu-Graph/workflow-data/missing_clinical_nodes.csv'
(HEADER=true);

COPY WORKFLOW_EDGE FROM
'C:/Users/advantix-user-001/Documents/Niraiva-Kuzu-Graph/workflow-data/missing_clinical_relationships.csv'
(HEADER=true);
