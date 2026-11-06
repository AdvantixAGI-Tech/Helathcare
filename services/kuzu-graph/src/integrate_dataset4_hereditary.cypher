// Remove only the two direct links replaced by the new source-defined sequence.
MATCH (a:WorkflowNode)-[r:WORKFLOW_EDGE]->(b:WorkflowNode)
WHERE (a.id='PATIENT_PROFILE' AND b.id='LIFESTYLE')
   OR (a.id='LIFESTYLE_RISK_SUMMARY' AND b.id='SYMPTOM_DECISION')
DELETE r;

// Extend selected existing risk nodes with fields unique to the new source.
MATCH (n:WorkflowNode) WHERE n.id='D2_SMOKING'
SET n.description='Current and previous smoking; initiation age; duration; quantity; cessation; second-hand exposure; smokeless tobacco; cumulative exposure in pack-years (packs/day × years)';

MATCH (n:WorkflowNode) WHERE n.id='D2_ALCOHOL'
SET n.description='Alcohol type; quantity; frequency; duration; and current versus previous consumption';

MATCH (n:WorkflowNode) WHERE n.id='D2_DIET'
SET n.description='Overall dietary pattern; fruit and vegetables; fibre; processed foods; red meat; and overall nutritional quality';

MATCH (n:WorkflowNode) WHERE n.id='D2_ACTIVITY'
SET n.description='Frequency; duration; intensity; occupational and recreational activity; and sedentary time';

MATCH (n:WorkflowNode) WHERE n.id='ENVIRONMENTAL_EXPOSURES'
SET n.description='Air pollution; occupational chemicals; industrial exposure; dust and fibres; radiation; ultraviolet exposure; workplace conditions; duration and intensity';

MATCH (n:WorkflowNode) WHERE n.id='MEDICAL_SCREENING_HISTORY'
SET n.description='Previous cancer; previous biopsy; previous pathology; previous abnormal imaging; previous screening; previous genetic testing; surgical history; chronic conditions; relevant medications and medical exposures';

COPY WorkflowNode FROM
'C:/Users/advantix-user-001/Documents/Niraiva-Kuzu-Graph/workflow-data/dataset4_hereditary_nodes.csv'
(HEADER=true);

COPY WORKFLOW_EDGE FROM
'C:/Users/advantix-user-001/Documents/Niraiva-Kuzu-Graph/workflow-data/dataset4_hereditary_relationships.csv'
(HEADER=true);
