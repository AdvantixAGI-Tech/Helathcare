// Add the new decision and convergence nodes once.
COPY WorkflowNode FROM
'C:/Users/advantix-user-001/Documents/Niraiva-Kuzu-Graph/workflow-data/lead_feedback_nodes.csv'
(HEADER=true);

// Correct labels and descriptions on reused nodes.
MATCH (n:WorkflowNode) WHERE n.id = 'LUNG_PROBABILITY_MODEL'
SET n.name = 'Lung Cancer Risk Inputs',
    n.description = 'Use recorded gender smoking status and quit-smoking age when applicable';

MATCH (n:WorkflowNode) WHERE n.id = 'LUNG_QUIT_AGE'
SET n.name = 'Quit-Smoking Age - Female Branch',
    n.description = 'Record cessation age for former smokers or mark it unavailable';

MATCH (n:WorkflowNode) WHERE n.id = 'STAGE_0'
SET n.name = 'Stage 0 - In Situ (Where Applicable)',
    n.description = 'Cancer-specific in situ stage; only where this stage applies';

MATCH (n:WorkflowNode) WHERE n.id = 'NON_MALIGNANT_FOLLOWUP'
SET n.description = 'Non-cancer follow-up or general care when malignancy is not confirmed';

MATCH (n:WorkflowNode) WHERE n.id = 'PROGRESSION_DECISION'
SET n.description = 'A progression concern or new finding returns to clinical assessment and diagnostic confirmation before any restaging';

// Remove the relationships whose direction or clinical meaning was incorrect.
MATCH (a:WorkflowNode)-[r:WORKFLOW_EDGE]->(b:WorkflowNode)
WHERE (a.id = 'LIFESTYLE' AND b.id = 'SYMPTOM_DECISION')
   OR (a.id = 'ABNORMALITY_DECISION' AND b.id = 'MONITOR_REASSESS')
   OR (a.id = 'MONITOR_REASSESS' AND b.id = 'DIAGNOSTIC_WORKUP')
   OR (a.id = 'PATHOLOGY' AND b.id = 'MALIGNANCY_DECISION')
   OR (a.id = 'NON_MALIGNANT_FOLLOWUP' AND b.id = 'FOLLOWUP')
   OR (a.id = 'PROGRESSION_DECISION' AND b.id = 'TNM_ASSESSMENT')
   OR (a.id = 'T_ASSESSMENT' AND b.id = 'STAGE_GROUP')
   OR (a.id = 'N_ASSESSMENT' AND b.id = 'STAGE_GROUP')
   OR (a.id = 'M_ASSESSMENT' AND b.id = 'METASTASIS_DECISION')
   OR (a.id = 'PATHOLOGY' AND b.id = 'D1_HISTOLOGY')
   OR (a.id = 'LUNG_PROBABILITY_MODEL' AND b.id = 'LUNG_FEMALE_VALUES')
   OR (a.id = 'LUNG_PROBABILITY_MODEL' AND b.id = 'LUNG_MALE_VALUES')
   OR (a.id = 'LUNG_PROBABILITY_MODEL' AND b.id = 'LUNG_QUIT_AGE')
DELETE r;

// Lifestyle findings now converge into a summary that visibly informs the pathway.
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='LIFESTYLE' AND b.id='LIFESTYLE_RISK_SUMMARY'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'FLOW', branch_label:'Summarize assessed risks', condition:'', evidence:'Conceptual workflow', line_style:'solid', sort_order:3}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='LIFESTYLE_RISK_SUMMARY' AND b.id='SYMPTOM_DECISION'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'INFORMS', branch_label:'Risk-informed pathway', condition:'', evidence:'Conceptual workflow', line_style:'solid', sort_order:4}]->(b);

MATCH (a:WorkflowNode), (b:WorkflowNode)
WHERE a.id IN ['D2_SMOKING','D2_ALCOHOL','D2_DIET','D2_RED_MEAT','D2_OBESITY','D2_ACTIVITY','D2_UV','ENVIRONMENTAL_EXPOSURES']
  AND b.id='LIFESTYLE_RISK_SUMMARY'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'CONTRIBUTES_TO', branch_label:'Risk/protective context', condition:'', evidence:'Lifestyle evidence', line_style:'dashed', sort_order:5170}]->(b);

// Lung probability model: gender -> smoking status -> quit age if former smoker -> calculation -> result.
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='LUNG_PROBABILITY_MODEL' AND b.id='LUNG_GENDER_DECISION'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'FLOW', branch_label:'Select branch', condition:'', evidence:'Source probability model', line_style:'solid', sort_order:5001}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='LUNG_GENDER_DECISION' AND b.id='LUNG_FEMALE_SMOKING'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'BRANCH', branch_label:'Female', condition:'Gender = female', evidence:'Source probability model', line_style:'solid', sort_order:5002}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='LUNG_GENDER_DECISION' AND b.id='LUNG_MALE_SMOKING'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'BRANCH', branch_label:'Male', condition:'Gender = male', evidence:'Source probability model', line_style:'solid', sort_order:5003}]->(b);

MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='LUNG_FEMALE_SMOKING' AND b.id='LUNG_FEMALE_RISK_CALC'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'BRANCH', branch_label:'Current smoker', condition:'Current smoker', evidence:'Source probability model', line_style:'solid', sort_order:5004}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='LUNG_FEMALE_SMOKING' AND b.id='LUNG_FEMALE_RISK_CALC'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'BRANCH', branch_label:'Never smoker', condition:'Never smoker', evidence:'Source probability model', line_style:'solid', sort_order:5005}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='LUNG_FEMALE_SMOKING' AND b.id='LUNG_QUIT_AGE'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'BRANCH', branch_label:'Former smoker', condition:'Former smoker', evidence:'Source probability model', line_style:'solid', sort_order:5006}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='LUNG_QUIT_AGE' AND b.id='LUNG_FEMALE_RISK_CALC'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'FLOW', branch_label:'Age recorded / unavailable', condition:'', evidence:'Source probability model', line_style:'solid', sort_order:5007}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='LUNG_FEMALE_RISK_CALC' AND b.id='LUNG_FEMALE_VALUES'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'RESULT', branch_label:'Risk result', condition:'', evidence:'Source probability table', line_style:'solid', sort_order:5008}]->(b);

MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='LUNG_MALE_SMOKING' AND b.id='LUNG_MALE_RISK_CALC'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'BRANCH', branch_label:'Current smoker', condition:'Current smoker', evidence:'Source probability model', line_style:'solid', sort_order:5009}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='LUNG_MALE_SMOKING' AND b.id='LUNG_MALE_RISK_CALC'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'BRANCH', branch_label:'Never smoker', condition:'Never smoker; source value unavailable', evidence:'Source probability model', line_style:'solid', sort_order:5010}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='LUNG_MALE_SMOKING' AND b.id='LUNG_MALE_QUIT_AGE'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'BRANCH', branch_label:'Former smoker', condition:'Former smoker', evidence:'Source probability model', line_style:'solid', sort_order:5011}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='LUNG_MALE_QUIT_AGE' AND b.id='LUNG_MALE_RISK_CALC'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'FLOW', branch_label:'Age recorded / unavailable', condition:'', evidence:'Source probability model', line_style:'solid', sort_order:5012}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='LUNG_MALE_RISK_CALC' AND b.id='LUNG_MALE_VALUES'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'RESULT', branch_label:'Risk result', condition:'', evidence:'Source probability table', line_style:'solid', sort_order:5013}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id IN ['LUNG_FEMALE_VALUES','LUNG_MALE_VALUES'] AND b.id='LIFESTYLE_RISK_SUMMARY'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'INFORMS', branch_label:'Lung-risk result', condition:'', evidence:'Source probability table', line_style:'solid', sort_order:5014}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='D2_SMOKING' AND b.id='LUNG_PROBABILITY_MODEL'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'SUPPLIES', branch_label:'Smoking status', condition:'', evidence:'Lifestyle record', line_style:'dashed', sort_order:5015}]->(b);

// Monitoring returns to the existing surveillance cycle; a new finding restarts diagnostic confirmation.
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='ABNORMALITY_DECISION' AND b.id='MONITOR_REASSESS'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'BRANCH', branch_label:'No - monitor', condition:'No suspicious lesion or abnormality', evidence:'Conceptual workflow', line_style:'solid', sort_order:24}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='MONITOR_REASSESS' AND b.id='FOLLOWUP'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'FLOW', branch_label:'Return to surveillance', condition:'', evidence:'Conceptual workflow', line_style:'solid', sort_order:25}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='PROGRESSION_DECISION' AND b.id='CLINICAL_ASSESSMENT'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'REASSESS', branch_label:'Yes - clinical reassessment', condition:'Progression concern or new finding', evidence:'Conceptual workflow', line_style:'solid', sort_order:61}]->(b);

// Histopathology is evidence in the confirmation sequence, not a detached note.
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='PATHOLOGY' AND b.id='D1_HISTOLOGY'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'FLOW', branch_label:'Histopathology review', condition:'', evidence:'Clinical pathology', line_style:'solid', sort_order:31}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='D1_HISTOLOGY' AND b.id='MALIGNANCY_DECISION'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'CONFIRMS', branch_label:'Pathology evidence', condition:'', evidence:'Clinical pathology', line_style:'solid', sort_order:32}]->(b);

// Non-malignant care exits the cancer surveillance/restaging cycle.
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='NON_MALIGNANT_FOLLOWUP' AND b.id='TERMINAL'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'FLOW', branch_label:'General care / close cancer pathway', condition:'Malignancy not confirmed', evidence:'Conceptual workflow', line_style:'solid', sort_order:33}]->(b);

// Biomarkers and grade/profile visibly inform treatment planning.
MATCH (a:WorkflowNode), (b:WorkflowNode)
WHERE a.id IN ['D1_HER2','D1_ER','D1_PR'] AND b.id='TREATMENT_PLANNING'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'INFORMS', branch_label:'Biomarker result', condition:'Where applicable', evidence:'Clinical biomarker assessment', line_style:'dashed', sort_order:5260}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='GRADE_PROFILE_PROGNOSIS' AND b.id='TREATMENT_PLANNING'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'INFORMS', branch_label:'Grade/profile context', condition:'', evidence:'Staging context', line_style:'dashed', sort_order:5261}]->(b);

// T, N and M converge before metastasis and stage-group decisions.
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id IN ['T_ASSESSMENT','N_ASSESSMENT','M_ASSESSMENT'] AND b.id='TNM_CONVERGENCE'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'CONTRIBUTES_TO', branch_label:'Assessed category', condition:'', evidence:'TNM staging', line_style:'solid', sort_order:43}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='TNM_CONVERGENCE' AND b.id='METASTASIS_DECISION'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'FLOW', branch_label:'Integrated T/N/M', condition:'', evidence:'TNM staging', line_style:'solid', sort_order:44}]->(b);

MATCH (n:WorkflowNode) RETURN count(n) AS NodeCount;
MATCH ()-[r:WORKFLOW_EDGE]->() RETURN count(r) AS RelationshipCount;
