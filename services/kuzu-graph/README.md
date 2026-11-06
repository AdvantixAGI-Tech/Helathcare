# Niraiva Kuzu Knowledge Graph

This service contains the Kuzu-based knowledge graph assets used by Niraiva.

## Contents

- `src/` - graph loading, correction, audit, and export scripts
- `data/` - base graph nodes and relationships
- `workflow-data/` - workflow source datasets
- `database/` - committed Kuzu database snapshots
- `output/` - generated graph exports
- `workflow-output/` - generated workflow exports

## Safety

Real-patient source documents and the local Python virtual environment are intentionally not included. Do not add secrets, credentials, or identifiable patient documents to this directory.

Stop any process writing to the Kuzu database before replacing the committed database snapshots.

## Local requirements

- Python 3
- `pip install -r requirements.txt`
- PowerShell 7 and Graphviz for the workflow rendering scripts

Run `python src/create_graph.py` only when you intentionally want to create a fresh `database/niraiva.kuzu` database.
