class FormulaDefinition {
  const FormulaDefinition({
    required this.id,
    required this.name,
    required this.formula,
    required this.requiredUnits,
    required this.interpretationNote,
    required this.evidenceSource,
    required this.evidenceTitle,
    required this.evidenceYear,
  });

  final String id;
  final String name;
  final String formula;
  final String requiredUnits;
  final String interpretationNote;
  final String evidenceSource;
  final String evidenceTitle;
  final int evidenceYear;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'formula': formula,
        'required_units': requiredUnits,
        'interpretation_note': interpretationNote,
        'evidence_source': evidenceSource,
        'evidence_title': evidenceTitle,
        'evidence_year': evidenceYear,
      };
}

class FormulaMetadata {
  static const _definitions = <String, FormulaDefinition>{
    'AIP': FormulaDefinition(
      id: 'AIP',
      name: 'Atherogenic Index of Plasma',
      formula: 'log10(TG mmol/L / HDL-C mmol/L)',
      requiredUnits: 'TG and HDL-C normalized to mmol/L',
      interpretationNote:
          'Lipid-related screening indicator, not a cardiovascular disease diagnosis.',
      evidenceSource: 'Dobiasova M, Frohlich J',
      evidenceTitle:
          'The plasma parameter log(TG/HDL-C) as an atherogenic index',
      evidenceYear: 2001,
    ),
    'TyG': FormulaDefinition(
      id: 'TyG',
      name: 'Triglyceride-Glucose Index',
      formula: 'ln((Triglycerides mg/dL x Fasting Glucose mg/dL) / 2)',
      requiredUnits: 'Triglycerides and fasting glucose in mg/dL',
      interpretationNote:
          'Published TyG cutoffs vary across populations and study designs. VitalMap uses these ranges only as screening categories and not as diagnostic thresholds.',
      evidenceSource: 'Guerrero-Romero F et al.',
      evidenceTitle:
          'The product of triglycerides and glucose as a surrogate for insulin resistance',
      evidenceYear: 2010,
    ),
    'APRI': FormulaDefinition(
      id: 'APRI',
      name: 'AST to Platelet Ratio Index',
      formula: '((AST / AST ULN) / Platelets) x 100',
      requiredUnits: 'AST in U/L, AST ULN in U/L, platelets in 10^9/L',
      interpretationNote:
          'Non-invasive fibrosis screening index; it does not diagnose fibrosis or cirrhosis.',
      evidenceSource: 'Wai CT et al.',
      evidenceTitle:
          'A simple noninvasive index can predict both significant fibrosis and cirrhosis',
      evidenceYear: 2003,
    ),
    'FIB-4': FormulaDefinition(
      id: 'FIB-4',
      name: 'Fibrosis-4 Index',
      formula: '(Age x AST) / (Platelets x sqrt(ALT))',
      requiredUnits: 'Age in years, AST and ALT in U/L, platelets in 10^9/L',
      interpretationNote:
          'FIB-4 interpretation can vary according to age, disease context, and clinical guideline.',
      evidenceSource: 'Sterling RK et al.',
      evidenceTitle:
          'Development of a simple noninvasive index to predict significant fibrosis',
      evidenceYear: 2006,
    ),
    'FLI': FormulaDefinition(
      id: 'FLI',
      name: 'Fatty Liver Index',
      formula: 'Logistic equation using BMI, waist, GGT, and triglycerides',
      requiredUnits: 'BMI kg/m2, waist cm, GGT U/L, triglycerides mg/dL',
      interpretationNote:
          'Screening indicator for hepatic steatosis likelihood, not a diagnosis.',
      evidenceSource: 'Bedogni G et al.',
      evidenceTitle:
          'The Fatty Liver Index: a simple and accurate predictor of hepatic steatosis',
      evidenceYear: 2006,
    ),
    'NAFLD Fibrosis Score': FormulaDefinition(
      id: 'NAFLD Fibrosis Score',
      name: 'NAFLD Fibrosis Score',
      formula:
          '-1.675 - 0.037xAge - 0.094xBMI - 1.13xIFG/Diabetes + 0.99xAST/ALT - 0.013xPlatelets + 0.66xAlbumin',
      requiredUnits:
          'Age years, BMI kg/m2, AST/ALT U/L, platelets 10^9/L, albumin g/dL',
      interpretationNote:
          'Indeterminate and attention ranges require clinical context; this score does not diagnose advanced fibrosis.',
      evidenceSource: 'Angulo P et al.',
      evidenceTitle:
          'The NAFLD fibrosis score: a noninvasive system that identifies liver fibrosis',
      evidenceYear: 2007,
    ),
    'eGFR': FormulaDefinition(
      id: 'eGFR',
      name: '2021 CKD-EPI Creatinine Equation',
      formula: '2021 CKD-EPI race-free creatinine equation',
      requiredUnits: 'Age years, sex, creatinine mg/dL',
      interpretationNote:
          'A single eGFR result does not diagnose CKD; persistence and kidney-damage evidence matter.',
      evidenceSource: 'Inker LA et al.',
      evidenceTitle:
          'New creatinine- and cystatin C-based equations to estimate GFR without race',
      evidenceYear: 2021,
    ),
    'NLR': FormulaDefinition(
      id: 'NLR',
      name: 'Neutrophil-to-Lymphocyte Ratio',
      formula: 'Neutrophils / Lymphocytes',
      requiredUnits: 'Both values as percentages or both as absolute counts',
      interpretationNote:
          'CBC-derived inflammatory context indicator; no single universally accepted diagnostic cutoff exists.',
      evidenceSource: 'Zahorec R',
      evidenceTitle: 'Ratio of neutrophil to lymphocyte counts',
      evidenceYear: 2001,
    ),
    'LAR': FormulaDefinition(
      id: 'LAR',
      name: 'Lipase-to-Amylase Ratio - Contextual Pancreatic Enzyme Indicator',
      formula: 'Lipase / Amylase',
      requiredUnits: 'Lipase and amylase in compatible U/L units',
      interpretationNote:
          'Contextual enzyme ratio; no universal disease-prediction cutoff.',
      evidenceSource: 'Context-dependent clinical literature',
      evidenceTitle:
          'Interpret with absolute enzymes, symptoms, and clinical assessment',
      evidenceYear: 2024,
    ),
    'AFP': FormulaDefinition(
      id: 'AFP',
      name: 'AFP Laboratory Marker Awareness',
      formula: 'Direct comparison with configured laboratory awareness range',
      requiredUnits:
          'Use the laboratory-reported AFP unit and reference interval',
      interpretationNote:
          'AFP cannot diagnose cancer by itself and requires clinical context.',
      evidenceSource: 'Laboratory and clinical context required',
      evidenceTitle:
          'Awareness marker interpretation is not a standalone diagnosis',
      evidenceYear: 2024,
    ),
    'CA 15-3': FormulaDefinition(
      id: 'CA 15-3',
      name: 'CA 15-3 Laboratory Marker Awareness',
      formula: 'Direct comparison with configured laboratory awareness range',
      requiredUnits:
          'Use the laboratory-reported CA 15-3 unit and reference interval',
      interpretationNote:
          'CA 15-3 cannot diagnose cancer by itself and requires clinical context.',
      evidenceSource: 'Laboratory and clinical context required',
      evidenceTitle:
          'Awareness marker interpretation is not a standalone diagnosis',
      evidenceYear: 2024,
    ),
    'CA 27.29': FormulaDefinition(
      id: 'CA 27.29',
      name: 'CA 27.29 Laboratory Marker Awareness',
      formula: 'Direct comparison with configured laboratory awareness range',
      requiredUnits:
          'Use the laboratory-reported CA 27.29 unit and reference interval',
      interpretationNote:
          'CA 27.29 cannot diagnose cancer by itself and requires clinical context.',
      evidenceSource: 'Laboratory and clinical context required',
      evidenceTitle:
          'Awareness marker interpretation is not a standalone diagnosis',
      evidenceYear: 2024,
    ),
  };

  static FormulaDefinition? forIndex(String indexName) =>
      _definitions[indexName];
}
