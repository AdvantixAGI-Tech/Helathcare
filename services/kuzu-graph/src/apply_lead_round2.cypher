COPY WorkflowNode FROM
'C:/Users/advantix-user-001/Documents/Niraiva-Kuzu-Graph/workflow-data/lead_round2_nodes.csv'
(HEADER=true);

// Clarify retained nodes without altering the excellent staging caution.
MATCH (n:WorkflowNode) WHERE n.id='TNM_ASSESSMENT'
SET n.name='Clinical TNM Assessment (cTNM)',
    n.description='Pre-treatment clinical assessment of primary tumour regional nodes and distant metastasis using available clinical and diagnostic evidence';

MATCH (n:WorkflowNode) WHERE n.id='PATHOLOGY'
SET n.name='Biopsy Histopathology Assessment',
    n.description='Determine histology tumour classification microscopic features and whether malignancy is confirmed';

MATCH (n:WorkflowNode) WHERE n.id='D1_BREAST'
SET n.name='Breast-Specific Clinical Signs (Where Applicable)',
    n.description='Cancer-specific module: lump or thickening; location; size; skin or shape change; nipple change; discharge; pain; duration; progression';

MATCH (n:WorkflowNode) WHERE n.id='N_ASSESSMENT'
SET n.name='N - Regional Lymph-Node Extent',
    n.description='Cancer-specific regional nodal extent based on location laterality size and/or number where applicable; not node count alone';

MATCH (n:WorkflowNode) WHERE n.id='D3_N'
SET n.description='N describes cancer-specific regional lymph-node involvement using applicable location laterality size and/or number criteria';

MATCH (n:WorkflowNode) WHERE n.id='STAGE_1'
SET n.name='Stage I - Cancer-Specific Early Invasive Disease',
    n.description='Often limited primary extent without distant metastasis; exact TNM and profile criteria vary by cancer type';

MATCH (n:WorkflowNode) WHERE n.id='STAGE_2'
SET n.name='Stage II - Cancer-Specific Intermediate Extent',
    n.description='May reflect greater primary extent and/or limited regional nodal involvement without distant metastasis; exact criteria vary';

MATCH (n:WorkflowNode) WHERE n.id='STAGE_3'
SET n.name='Stage III - Cancer-Specific Locally Advanced or Regional Disease',
    n.description='Often greater local extension and/or regional nodal involvement without distant metastasis; exact criteria vary';

MATCH (n:WorkflowNode) WHERE n.id='D3_PATH_STAGE'
SET n.description='Pathological TNM based on clinical information plus adequate surgical and histopathological findings; available only when applicable';

// Delete relationships whose ordering or meaning is being replaced.
MATCH (a:WorkflowNode)-[r:WORKFLOW_EDGE]->(b:WorkflowNode)
WHERE (a.id='CLINICAL_ASSESSMENT' AND b.id='SUSPICIOUS_DECISION')
   OR (a.id='RECEPTOR_ASSESSMENT' AND b.id='BREAST_PROFILE_CONVERGENCE')
   OR (a.id='LAB_ASSESSMENT' AND b.id='ABNORMALITY_DECISION')
   OR (a.id='IMAGING_ASSESSMENT' AND b.id='ABNORMALITY_DECISION')
   OR (a.id='PATHOLOGY' AND b.id='D1_HISTOLOGY')
   OR (a.id='D1_HISTOLOGY' AND b.id='MALIGNANCY_DECISION')
   OR (a.id='BREAST_DECISION' AND b.id='TNM_ASSESSMENT')
   OR (a.id='RECEPTOR_ASSESSMENT' AND b.id='TNM_ASSESSMENT')
   OR (a.id='TNM_ASSESSMENT' AND b.id='D3_CLINICAL_STAGE')
   OR (a.id='TNM_ASSESSMENT' AND b.id='D3_PATH_STAGE')
   OR (a.id='PATHOLOGY' AND b.id='D3_PATH_STAGE')
   OR (a.id='TNM_ASSESSMENT' AND b.id='ALTERNATIVE_STAGING')
   OR (a.id='TNM_ASSESSMENT' AND b.id='GRADE_PROFILE_PROGNOSIS')
   OR (a.id='D1_HER2' AND b.id='TREATMENT_PLANNING')
   OR (a.id='D1_ER' AND b.id='TREATMENT_PLANNING')
   OR (a.id='D1_PR' AND b.id='TREATMENT_PLANNING')
   OR (a.id='GRADE_PROFILE_PROGNOSIS' AND b.id='TREATMENT_PLANNING')
   OR (a.id IN ['STAGE_0','STAGE_1','STAGE_2','STAGE_3','STAGE_4'] AND b.id='TREATMENT_PLANNING')
   OR (a.id='METASTASIS_DECISION' AND b.id='STAGE_4')
   OR (a.id='D3_M1' AND b.id='STAGE_4')
   OR (a.id='T_ASSESSMENT' AND b.id='D3_T')
   OR (a.id='N_ASSESSMENT' AND b.id='D3_N')
   OR (a.id='M_ASSESSMENT' AND b.id='D3_M')
   OR (a.id='D3_T' AND b.id IN ['D3_TIS','D3_T1_T4'])
   OR (a.id='D3_N' AND b.id IN ['D3_N0','D3_N1_N3'])
   OR (a.id='D3_M' AND b.id IN ['D3_M0','D3_M1'])
   OR (a.id='TREATMENT_PLANNING' AND b.id='FOLLOWUP')
   OR (a.id IN ['LUNG_FEMALE_VALUES','LUNG_MALE_VALUES'] AND b.id='LIFESTYLE_RISK_SUMMARY')
DELETE r;

// Lung model: probability outputs converge into an action decision and visibly re-enter the main pathway.
MATCH (a:WorkflowNode), (b:WorkflowNode)
WHERE a.id IN ['LUNG_FEMALE_VALUES','LUNG_MALE_VALUES'] AND b.id='LUNG_RISK_ACTION_DECISION'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'CONVERGES_TO', branch_label:'Probability result', condition:'', evidence:'Source probability model', line_style:'solid', sort_order:5014}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='LUNG_RISK_ACTION_DECISION' AND b.id='SCREENING'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'BRANCH', branch_label:'Screening or clinical review indicated', condition:'Use applicable guidance and clinical judgement; no universal cutoff assumed', evidence:'Conceptual workflow', line_style:'solid', sort_order:5016}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='LUNG_RISK_ACTION_DECISION' AND b.id='LIFESTYLE_RISK_SUMMARY'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'BRANCH', branch_label:'Continue general risk assessment', condition:'Screening or focused review not indicated', evidence:'Conceptual workflow', line_style:'solid', sort_order:5017}]->(b);

// Clinical findings: make breast signs explicitly cancer-specific and converge before the suspicion decision.
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='CLINICAL_ASSESSMENT' AND b.id='CLINICAL_FINDINGS_CONVERGENCE'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'CONTRIBUTES_TO', branch_label:'General clinical findings', condition:'', evidence:'Clinical workflow', line_style:'solid', sort_order:14}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='D1_BREAST' AND b.id='CLINICAL_FINDINGS_CONVERGENCE'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'CONTRIBUTES_TO', branch_label:'Breast-specific findings where applicable', condition:'', evidence:'Clinical dataset', line_style:'solid', sort_order:141}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='CLINICAL_FINDINGS_CONVERGENCE' AND b.id='SUSPICIOUS_DECISION'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'FLOW', branch_label:'Integrated clinical review', condition:'', evidence:'Clinical workflow', line_style:'solid', sort_order:142}]->(b);

// Laboratory and imaging branches visibly converge, then combine with clinical evidence.
MATCH (a:WorkflowNode), (b:WorkflowNode)
WHERE a.id IN ['D1_CBC','D1_CMP','D1_INFLAMMATION'] AND b.id='LAB_RESULTS_CONVERGENCE'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'CONTRIBUTES_TO', branch_label:'Result and trend', condition:'', evidence:'Clinical dataset', line_style:'solid', sort_order:221}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode)
WHERE a.id IN ['D1_IMAGING_METHOD','D1_LESION','D1_SPREAD'] AND b.id='IMAGING_RESULTS_CONVERGENCE'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'CONTRIBUTES_TO', branch_label:'Imaging evidence', condition:'', evidence:'Clinical dataset', line_style:'solid', sort_order:222}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='LAB_RESULTS_CONVERGENCE' AND b.id='INTEGRATED_DIAGNOSTIC_FINDINGS'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'CONTRIBUTES_TO', branch_label:'Laboratory interpretation', condition:'', evidence:'Clinical workflow', line_style:'solid', sort_order:223}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='IMAGING_RESULTS_CONVERGENCE' AND b.id='INTEGRATED_DIAGNOSTIC_FINDINGS'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'CONTRIBUTES_TO', branch_label:'Imaging interpretation', condition:'', evidence:'Clinical workflow', line_style:'solid', sort_order:224}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='CLINICAL_FINDINGS_CONVERGENCE' AND b.id='INTEGRATED_DIAGNOSTIC_FINDINGS'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'CONTRIBUTES_TO', branch_label:'Clinical context', condition:'', evidence:'Clinical workflow', line_style:'solid', sort_order:225}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='INTEGRATED_DIAGNOSTIC_FINDINGS' AND b.id='ABNORMALITY_DECISION'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'FLOW', branch_label:'Review combined evidence', condition:'', evidence:'Clinical workflow', line_style:'solid', sort_order:226}]->(b);

// Consolidate biopsy pathology and histopathology into one confirmation sequence.
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='PATHOLOGY' AND b.id='MALIGNANCY_DECISION'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'CONFIRMS', branch_label:'Histopathology evidence', condition:'', evidence:'Clinical pathology', line_style:'solid', sort_order:31}]->(b);

// Breast receptor branches converge and join both stage/profile interpretation and treatment evidence.
MATCH (a:WorkflowNode), (b:WorkflowNode)
WHERE a.id IN ['D1_HER2','D1_ER','D1_PR'] AND b.id='BREAST_PROFILE_CONVERGENCE'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'CONTRIBUTES_TO', branch_label:'Biomarker result', condition:'', evidence:'Breast biomarker assessment', line_style:'solid', sort_order:371}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='RECEPTOR_ASSESSMENT' AND b.id='BREAST_PROFILE_CONVERGENCE'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'FLOW', branch_label:'Converge receptor results', condition:'', evidence:'Breast biomarker assessment', line_style:'solid', sort_order:372}]->(b);

// Select the staging system explicitly after cancer classification and biomarker identification.
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='BREAST_DECISION' AND b.id='STAGING_SYSTEM_DECISION'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'BRANCH', branch_label:'No - non-breast pathway', condition:'Breast-specific biomarkers do not apply', evidence:'Conceptual workflow', line_style:'solid', sort_order:373}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='BREAST_PROFILE_CONVERGENCE' AND b.id='STAGING_SYSTEM_DECISION'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'FLOW', branch_label:'Breast profile identified', condition:'', evidence:'Breast-specific workflow', line_style:'solid', sort_order:374}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='STAGING_SYSTEM_DECISION' AND b.id='TNM_ASSESSMENT'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'BRANCH', branch_label:'TNM applies', condition:'Applicable solid-tumour TNM system selected', evidence:'Staging reference', line_style:'solid', sort_order:39}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='STAGING_SYSTEM_DECISION' AND b.id='ALTERNATIVE_STAGING'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'BRANCH', branch_label:'Alternative system applies', condition:'Cancer type uses another applicable system', evidence:'Staging reference', line_style:'solid', sort_order:391}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='ALTERNATIVE_STAGING' AND b.id='STAGE_RESULT_CONVERGENCE'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'RESULT', branch_label:'Cancer-specific stage or extent', condition:'', evidence:'Applicable staging system', line_style:'solid', sort_order:392}]->(b);

// Remove duplicated T/N/M explanation nodes from the visible path by linking categories directly.
MATCH (a:WorkflowNode), (b:WorkflowNode)
WHERE a.id='T_ASSESSMENT' AND b.id IN ['D3_TIS','D3_T1_T4']
CREATE (a)-[:WORKFLOW_EDGE {relationship:'HAS_CATEGORY', branch_label:'T category', condition:'', evidence:'TNM staging reference', line_style:'dashed', sort_order:431}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode)
WHERE a.id='N_ASSESSMENT' AND b.id IN ['D3_N0','D3_N1_N3']
CREATE (a)-[:WORKFLOW_EDGE {relationship:'HAS_CATEGORY', branch_label:'N category', condition:'', evidence:'TNM staging reference', line_style:'dashed', sort_order:432}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode)
WHERE a.id='M_ASSESSMENT' AND b.id IN ['D3_M0','D3_M1']
CREATE (a)-[:WORKFLOW_EDGE {relationship:'HAS_CATEGORY', branch_label:'M category', condition:'', evidence:'TNM staging reference', line_style:'dashed', sort_order:433}]->(b);

// Make M1-to-Stage-IV mapping explicitly conditional on the selected cancer-specific system.
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='METASTASIS_DECISION' AND b.id='M1_STAGE4_APPLICABILITY'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'BRANCH', branch_label:'M1 - distant metastasis', condition:'M1 identified', evidence:'TNM assessment', line_style:'solid', sort_order:46}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='M1_STAGE4_APPLICABILITY' AND b.id='STAGE_4'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'BRANCH', branch_label:'Yes - applicable system defines Stage IV', condition:'Cancer-specific mapping confirmed', evidence:'Applicable staging system', line_style:'solid', sort_order:461}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='M1_STAGE4_APPLICABILITY' AND b.id='CANCER_SPECIFIC_STAGE_RESULT'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'BRANCH', branch_label:'No - use selected system definition', condition:'Direct Stage IV mapping not applicable', evidence:'Applicable staging system', line_style:'solid', sort_order:462}]->(b);

// All stage outputs converge, then combine with grade/histology/biomarkers before planning.
MATCH (a:WorkflowNode), (b:WorkflowNode)
WHERE a.id IN ['STAGE_0','STAGE_1','STAGE_2','STAGE_3','STAGE_4','CANCER_SPECIFIC_STAGE_RESULT'] AND b.id='STAGE_RESULT_CONVERGENCE'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'CONVERGES_TO', branch_label:'Applicable stage result', condition:'', evidence:'Selected staging system', line_style:'solid', sort_order:550}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='STAGE_RESULT_CONVERGENCE' AND b.id='STAGE_PROFILE_INTEGRATION'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'CONTRIBUTES_TO', branch_label:'Stage', condition:'', evidence:'Staging result', line_style:'solid', sort_order:560}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='BREAST_PROFILE_CONVERGENCE' AND b.id='STAGE_PROFILE_INTEGRATION'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'CONTRIBUTES_TO', branch_label:'HER2 / ER / PR where applicable', condition:'Breast-specific profile', evidence:'Breast staging reference', line_style:'solid', sort_order:561}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='PATHOLOGY' AND b.id='GRADE_PROFILE_PROGNOSIS'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'SUPPORTS', branch_label:'Histology and grade/profile evidence', condition:'', evidence:'Pathology and staging reference', line_style:'dashed', sort_order:562}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='GRADE_PROFILE_PROGNOSIS' AND b.id='STAGE_PROFILE_INTEGRATION'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'CONTRIBUTES_TO', branch_label:'Grade and tumour profile', condition:'', evidence:'Staging reference', line_style:'solid', sort_order:563}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='STAGE_PROFILE_INTEGRATION' AND b.id='TREATMENT_PLANNING'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'INFORMS', branch_label:'Integrated stage/profile', condition:'', evidence:'Clinical planning context', line_style:'solid', sort_order:564}]->(b);

// cTNM occurs before planning; pTNM only after applicable surgical pathology becomes available.
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='TNM_ASSESSMENT' AND b.id='D3_CLINICAL_STAGE'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'RECORDS', branch_label:'Pre-treatment cTNM', condition:'', evidence:'Staging reference', line_style:'dashed', sort_order:5041}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='TREATMENT_PLANNING' AND b.id='SURGICAL_PATHOLOGY_DECISION'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'FLOW', branch_label:'After initial treatment decision', condition:'', evidence:'Conceptual workflow', line_style:'solid', sort_order:5350}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='SURGICAL_PATHOLOGY_DECISION' AND b.id='FOLLOWUP'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'BRANCH', branch_label:'No - pTNM not available/applicable', condition:'No adequate surgical specimen', evidence:'Staging reference', line_style:'solid', sort_order:5360}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='SURGICAL_PATHOLOGY_DECISION' AND b.id='SURGICAL_PATHOLOGY'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'BRANCH', branch_label:'Yes - surgical pathology available', condition:'Adequate surgical specimen and pathology', evidence:'Staging reference', line_style:'solid', sort_order:5361}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='SURGICAL_PATHOLOGY' AND b.id='D3_PATH_STAGE'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'SUPPORTS', branch_label:'Derive pTNM where applicable', condition:'', evidence:'Surgical pathology', line_style:'solid', sort_order:5362}]->(b);
MATCH (a:WorkflowNode), (b:WorkflowNode) WHERE a.id='D3_PATH_STAGE' AND b.id='FOLLOWUP'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'FLOW', branch_label:'Record postoperative pathological stage and review plan', condition:'', evidence:'Staging reference', line_style:'solid', sort_order:5363}]->(b);

// Previously isolated lifestyle evidence now contributes to the lifestyle-risk summary.
MATCH (a:WorkflowNode), (b:WorkflowNode)
WHERE a.id IN ['FOOD_EVIDENCE_CAUTION','LIFESTYLE_PATHWAYS'] AND b.id='LIFESTYLE_RISK_SUMMARY'
CREATE (a)-[:WORKFLOW_EDGE {relationship:'CONTRIBUTES_TO', branch_label:'Evidence context and limitations', condition:'', evidence:'Lifestyle source', line_style:'dashed', sort_order:5171}]->(b);

MATCH (n:WorkflowNode) RETURN count(n) AS NodeCount;
MATCH ()-[r:WORKFLOW_EDGE]->() RETURN count(r) AS RelationshipCount;
