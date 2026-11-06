MATCH (source:Entity)-[relation:RELATED_TO]->(target:Entity)
RETURN
    source.id AS source_id,
    source.name AS source_name,
    source.category AS source_category,
    relation.relationship AS relationship,
    relation.evidence AS evidence,
    target.id AS target_id,
    target.name AS target_name,
    target.category AS target_category
LIMIT 200;

COPY (
    MATCH (source:Entity)-[relation:RELATED_TO]->(target:Entity)
    RETURN
        source.id AS source_id,
        source.name AS source_name,
        source.category AS source_category,
        relation.relationship AS relationship,
        relation.evidence AS evidence,
        target.id AS target_id,
        target.name AS target_name,
        target.category AS target_category
)
TO
'C:/Users/advantix-user-001/Documents/Niraiva-Kuzu-Graph/output/kuzu_query_result.csv'
(HEADER=true);