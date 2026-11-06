COPY (
    MATCH (n:WorkflowNode)
    RETURN
        n.id AS id,
        n.name AS name,
        n.node_type AS node_type,
        n.section AS section,
        n.description AS description,
        n.value_text AS value_text,
        n.unit AS unit,
        n.dataset AS dataset,
        n.sort_order AS sort_order,
        n.color AS color,
        n.shape AS shape
    ORDER BY n.sort_order, n.id
)
TO
'C:/Users/advantix-user-001/Documents/Niraiva-Kuzu-Graph/workflow-output/kuzu_nodes.csv'
(HEADER=true);

COPY (
    MATCH (source:WorkflowNode)-[edge:WORKFLOW_EDGE]->(target:WorkflowNode)
    RETURN
        source.id AS source_id,
        target.id AS target_id,
        edge.relationship AS relationship,
        edge.branch_label AS branch_label,
        edge.condition AS condition,
        edge.evidence AS evidence,
        edge.line_style AS line_style,
        edge.sort_order AS sort_order
    ORDER BY edge.sort_order, source.id, target.id
)
TO
'C:/Users/advantix-user-001/Documents/Niraiva-Kuzu-Graph/workflow-output/kuzu_relationships.csv'
(HEADER=true);