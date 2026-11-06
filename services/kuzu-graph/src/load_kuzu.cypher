CREATE NODE TABLE Entity(
    id STRING,
    name STRING,
    category STRING,
    dataset STRING,
    PRIMARY KEY(id)
);

CREATE REL TABLE RELATED_TO(
    FROM Entity TO Entity,
    relationship STRING,
    evidence STRING
);

COPY Entity FROM
'C:/Users/advantix-user-001/Documents/Niraiva-Kuzu-Graph/data/nodes.csv'
(HEADER=true);

COPY RELATED_TO FROM
'C:/Users/advantix-user-001/Documents/Niraiva-Kuzu-Graph/data/relationships.csv'
(HEADER=true);

MATCH (n:Entity)
RETURN count(n) AS NodeCount;

MATCH ()-[r:RELATED_TO]->()
RETURN count(r) AS RelationshipCount;