from pathlib import Path
import kuzu

project = Path(__file__).resolve().parents[1]
database_path = project / "database" / "niraiva.kuzu"
nodes_csv = project / "data" / "nodes.csv"
relationships_csv = project / "data" / "relationships.csv"

db = kuzu.Database(str(database_path))
conn = kuzu.Connection(db)

conn.execute("""
CREATE NODE TABLE Entity(
    id STRING,
    name STRING,
    category STRING,
    dataset STRING,
    PRIMARY KEY(id)
)
""")

conn.execute("""
CREATE REL TABLE RELATED_TO(
    FROM Entity TO Entity,
    relationship STRING,
    evidence STRING
)
""")

conn.execute(
    f'COPY Entity FROM "{nodes_csv.as_posix()}" (HEADER=true)'
)

conn.execute(
    f'COPY RELATED_TO FROM "{relationships_csv.as_posix()}" (HEADER=true)'
)

node_count = conn.execute(
    "MATCH (n:Entity) RETURN count(n)"
).get_next()[0]

relationship_count = conn.execute(
    "MATCH ()-[r:RELATED_TO]->() RETURN count(r)"
).get_next()[0]

print(f"Kuzu database created: {database_path}")
print(f"Nodes imported: {node_count}")
print(f"Relationships imported: {relationship_count}")