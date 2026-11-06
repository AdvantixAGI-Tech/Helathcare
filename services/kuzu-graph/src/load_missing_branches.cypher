COPY WorkflowNode FROM
'C:/Users/advantix-user-001/Documents/Niraiva-Kuzu-Graph/workflow-data/missing_branch_nodes.csv'
(HEADER=true);

COPY WORKFLOW_EDGE FROM
'C:/Users/advantix-user-001/Documents/Niraiva-Kuzu-Graph/workflow-data/missing_branch_relationships.csv'
(HEADER=true);

MATCH (n:WorkflowNode) RETURN count(n) AS NodeCount;
MATCH ()-[r:WORKFLOW_EDGE]->() RETURN count(r) AS RelationshipCount;
