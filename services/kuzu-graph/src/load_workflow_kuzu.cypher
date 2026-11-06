CREATE NODE TABLE WorkflowNode(
    id STRING,
    name STRING,
    node_type STRING,
    section STRING,
    description STRING,
    value_text STRING,
    unit STRING,
    dataset STRING,
    sort_order INT64,
    color STRING,
    shape STRING,
    PRIMARY KEY(id)
);

CREATE REL TABLE WORKFLOW_EDGE(
    FROM WorkflowNode TO WorkflowNode,
    relationship STRING,
    branch_label STRING,
    condition STRING,
    evidence STRING,
    line_style STRING,
    sort_order INT64
);

COPY WorkflowNode FROM
'C:/Users/advantix-user-001/Documents/Niraiva-Kuzu-Graph/workflow-data/combined_nodes.csv'
(HEADER=true);

COPY WORKFLOW_EDGE FROM
'C:/Users/advantix-user-001/Documents/Niraiva-Kuzu-Graph/workflow-data/combined_relationships.csv'
(HEADER=true);

MATCH (n:WorkflowNode)
RETURN count(n) AS NodeCount;

MATCH ()-[r:WORKFLOW_EDGE]->()
RETURN count(r) AS RelationshipCount;