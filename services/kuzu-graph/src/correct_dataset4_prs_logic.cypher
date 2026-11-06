MATCH (a:WorkflowNode)-[r:WORKFLOW_EDGE]->(b:WorkflowNode)
WHERE a.id='HEREDITARY_RISK_ASSESSMENT' AND b.id='PRS_ASSESSMENT'
DELETE r;

COPY WorkflowNode FROM
'C:/Users/advantix-user-001/Documents/Niraiva-Kuzu-Graph/workflow-data/dataset4_prs_decision_node.csv'
(HEADER=true);

COPY WORKFLOW_EDGE FROM
'C:/Users/advantix-user-001/Documents/Niraiva-Kuzu-Graph/workflow-data/dataset4_prs_decision_relationships.csv'
(HEADER=true);
