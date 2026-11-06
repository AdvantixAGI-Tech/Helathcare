MATCH ()-[relationship:RELATED_TO]->()
DELETE relationship;

COPY RELATED_TO FROM
'C:/Users/advantix-user-001/Documents/Niraiva-Kuzu-Graph/data/relationships.csv'
(HEADER=true);

MATCH (node:Entity)
RETURN count(node) AS NodeCount;

MATCH ()-[relationship:RELATED_TO]->()
RETURN count(relationship) AS RelationshipCount;