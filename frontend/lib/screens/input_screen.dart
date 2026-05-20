import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../storage/local_storage.dart';
import '../styles.dart';
import '../widgets/disclaimer.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key, required this.onAnalysisComplete});

  final ValueChanged<Map<String, dynamic>> onAnalysisComplete;

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _formKey = GlobalKey<FormState>();
  final Set<String> _selectedSections = {};

  final ageCtl = TextEditingController();
  final heightCtl = TextEditingController();
  final weightCtl = TextEditingController();
  final waistCtl = TextEditingController();

  final sysCtl = TextEditingController();
  final diaCtl = TextEditingController();
  final hrCtl = TextEditingController();
  final spo2Ctl = TextEditingController();

  final tgCtl = TextEditingController();
  final hdlCtl = TextEditingController();
  final ldlCtl = TextEditingController();
  final totalCholesterolCtl = TextEditingController();
  final vldlCtl = TextEditingController();

  final fastingCtl = TextEditingController();
  final hba1cCtl = TextEditingController();
  final ppbsCtl = TextEditingController();
  final randomSugarCtl = TextEditingController();

  final astCtl = TextEditingController();
  final altCtl = TextEditingController();
  final ggtCtl = TextEditingController();
  final alpCtl = TextEditingController();
  final bilirubinCtl = TextEditingController();
  final albuminCtl = TextEditingController();
  final totalProteinCtl = TextEditingController();

  final plateletsCtl = TextEditingController();
  final wbcCtl = TextEditingController();
  final neutCtl = TextEditingController();
  final lymphCtl = TextEditingController();
  final hemoglobinCtl = TextEditingController();
  final rbcCtl = TextEditingController();
  final esrCtl = TextEditingController();

  final creatCtl = TextEditingController();
  final bloodUreaCtl = TextEditingController();
  final uricAcidCtl = TextEditingController();
  final sodiumCtl = TextEditingController();
  final potassiumCtl = TextEditingController();

  final lipaseCtl = TextEditingController();
  final amylaseCtl = TextEditingController();

  final afpCtl = TextEditingController();
  final ca15Ctl = TextEditingController();
  final ca27Ctl = TextEditingController();

  String? sex;
  String? smoking;
  String? alcohol;
  String? physicalActivity;
  String? sleepDuration;
  String? stressLevel;
  String? familyHistory;
  String? dietType;
  String? sugarIntake;
  String? saltIntake;
  String? processedFood;
  String? fruitVeg;
  String? sugaryDrinks;
  String? airPollution;
  String? occupationalExposure;
  String? passiveSmoking;
  String? cookingSmoke;
  String? cookingFuelSmoke;
  String? locationType;

  String tgUnit = 'mg/dL';
  String hdlUnit = 'mg/dL';
  String ldlUnit = 'mg/dL';
  String totalCholesterolUnit = 'mg/dL';
  String glucoseUnit = 'mg/dL';
  String ppbsUnit = 'mg/dL';
  String randomSugarUnit = 'mg/dL';
  String creatUnit = 'mg/dL';

  bool loading = false;

  static const _reportSections = [
    _ReportSection(
      id: 'heart',
      title: 'Heart / Lipid Profile',
      subtitle: 'AIP',
      icon: Icons.favorite_border,
    ),
    _ReportSection(
      id: 'diabetes',
      title: 'Diabetes / Metabolic',
      subtitle: 'TyG, metabolic insight',
      icon: Icons.water_drop_outlined,
    ),
    _ReportSection(
      id: 'liver',
      title: 'Liver Function Test',
      subtitle: 'APRI, FIB-4, FLI, NAFLD',
      icon: Icons.monitor_heart_outlined,
    ),
    _ReportSection(
      id: 'cbc',
      title: 'CBC / Differential',
      subtitle: 'NLR and liver support',
      icon: Icons.bloodtype_outlined,
    ),
    _ReportSection(
      id: 'kidney',
      title: 'Kidney Function',
      subtitle: 'eGFR',
      icon: Icons.opacity_outlined,
    ),
    _ReportSection(
      id: 'vitals',
      title: 'Vitals',
      subtitle: 'SpO2, BP support',
      icon: Icons.speed_outlined,
    ),
    _ReportSection(
      id: 'pancreas',
      title: 'Pancreatic Enzymes',
      subtitle: 'LAR',
      icon: Icons.science_outlined,
    ),
    _ReportSection(
      id: 'cancer',
      title: 'Cancer Awareness',
      subtitle: 'Awareness markers only',
      icon: Icons.health_and_safety_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedPayload();
  }

  @override
  void dispose() {
    for (final ctl in [
      ageCtl,
      heightCtl,
      weightCtl,
      waistCtl,
      sysCtl,
      diaCtl,
      hrCtl,
      spo2Ctl,
      tgCtl,
      hdlCtl,
      ldlCtl,
      totalCholesterolCtl,
      vldlCtl,
      fastingCtl,
      hba1cCtl,
      ppbsCtl,
      randomSugarCtl,
      astCtl,
      altCtl,
      ggtCtl,
      alpCtl,
      bilirubinCtl,
      albuminCtl,
      totalProteinCtl,
      plateletsCtl,
      wbcCtl,
      neutCtl,
      lymphCtl,
      hemoglobinCtl,
      rbcCtl,
      esrCtl,
      creatCtl,
      bloodUreaCtl,
      uricAcidCtl,
      sodiumCtl,
      potassiumCtl,
      lipaseCtl,
      amylaseCtl,
      afpCtl,
      ca15Ctl,
      ca27Ctl,
    ]) {
      ctl.dispose();
    }
    super.dispose();
  }

  Future<void> analyze() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please complete the general questions first.')),
      );
      return;
    }

    setState(() => loading = true);
    final payload = _payload();
    await LocalStorage.saveLastPayload(payload);
    final response = await ApiService.analyze(payload);
    if (!mounted) return;
    setState(() => loading = false);

    if (response == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Unable to analyze right now. Please check your connection or try again.'),
        ),
      );
      return;
    }

    await LocalStorage.saveLastResponse(response);
    widget.onAnalysisComplete(response);
  }

  Future<void> _loadSavedPayload() async {
    final payload = await LocalStorage.loadLastPayload();
    if (!mounted || payload == null) return;
    final profile = Map<String, dynamic>.from(payload['profile'] as Map? ?? {});
    final general =
        Map<String, dynamic>.from(payload['general_health'] as Map? ?? {});
    final vitals = Map<String, dynamic>.from(payload['vitals'] as Map? ?? {});
    final lipids =
        Map<String, dynamic>.from(payload['lipid_profile'] as Map? ?? {});
    final diabetes =
        Map<String, dynamic>.from(payload['diabetes_profile'] as Map? ?? {});
    final liver =
        Map<String, dynamic>.from(payload['liver_function'] as Map? ?? {});
    final cbc = Map<String, dynamic>.from(payload['cbc'] as Map? ?? {});
    final kidney =
        Map<String, dynamic>.from(payload['kidney_function'] as Map? ?? {});
    final pancreas =
        Map<String, dynamic>.from(payload['pancreatic_enzymes'] as Map? ?? {});
    final tumor =
        Map<String, dynamic>.from(payload['tumor_markers'] as Map? ?? {});

    setState(() {
      _setText(ageCtl, profile['age']);
      _setText(heightCtl, profile['height_cm']);
      _setText(weightCtl, profile['weight_kg']);
      _setText(waistCtl, profile['waist_cm']);
      sex = profile['sex'] as String?;

      smoking = general['smoking'] as String?;
      alcohol = general['alcohol'] as String?;
      physicalActivity = general['physical_activity'] as String?;
      sleepDuration = general['sleep_duration'] as String?;
      stressLevel = general['stress_level'] as String?;
      familyHistory = general['family_history'] as String?;
      dietType = general['diet_type'] as String?;
      sugarIntake = general['high_sugar_intake'] as String?;
      saltIntake = general['high_salt_intake'] as String?;
      processedFood = general['fried_processed_food'] as String?;
      fruitVeg = general['fruit_veg_intake'] as String?;
      sugaryDrinks = general['sugary_drinks'] as String?;
      airPollution = general['air_pollution'] as String?;
      occupationalExposure = general['occupational_exposure'] as String?;
      passiveSmoking = general['passive_smoking'] as String?;
      cookingSmoke = general['cooking_smoke'] as String?;
      cookingFuelSmoke = general['cooking_fuel_smoke'] as String?;
      locationType = general['location_type'] as String?;

      _setText(sysCtl, vitals['systolic']);
      _setText(diaCtl, vitals['diastolic']);
      _setText(hrCtl, vitals['heart_rate']);
      _setText(spo2Ctl, vitals['spo2']);
      _setText(tgCtl, lipids['triglycerides']);
      _setText(hdlCtl, lipids['hdl']);
      _setText(ldlCtl, lipids['ldl']);
      _setText(totalCholesterolCtl, lipids['total_cholesterol']);
      _setText(vldlCtl, lipids['vldl']);
      tgUnit = lipids['triglycerides_unit'] as String? ?? tgUnit;
      hdlUnit = lipids['hdl_unit'] as String? ?? hdlUnit;
      ldlUnit = lipids['ldl_unit'] as String? ?? ldlUnit;
      totalCholesterolUnit =
          lipids['total_cholesterol_unit'] as String? ?? totalCholesterolUnit;

      _setText(fastingCtl, diabetes['fasting_glucose']);
      _setText(hba1cCtl, diabetes['hba1c']);
      _setText(ppbsCtl, diabetes['ppbs']);
      _setText(randomSugarCtl, diabetes['random_blood_sugar']);
      glucoseUnit = diabetes['fasting_glucose_unit'] as String? ?? glucoseUnit;
      ppbsUnit = diabetes['ppbs_unit'] as String? ?? ppbsUnit;
      randomSugarUnit =
          diabetes['random_blood_sugar_unit'] as String? ?? randomSugarUnit;

      _setText(astCtl, liver['ast']);
      _setText(altCtl, liver['alt']);
      _setText(ggtCtl, liver['ggt']);
      _setText(alpCtl, liver['alp']);
      _setText(bilirubinCtl, liver['bilirubin']);
      _setText(albuminCtl, liver['albumin']);
      _setText(totalProteinCtl, liver['total_protein']);
      _setText(plateletsCtl, cbc['platelets']);
      _setText(wbcCtl, cbc['wbc']);
      _setText(neutCtl, cbc['neutrophils']);
      _setText(lymphCtl, cbc['lymphocytes']);
      _setText(hemoglobinCtl, cbc['hemoglobin']);
      _setText(rbcCtl, cbc['rbc']);
      _setText(esrCtl, cbc['esr']);

      _setText(creatCtl, kidney['creatinine']);
      _setText(bloodUreaCtl, kidney['blood_urea']);
      _setText(uricAcidCtl, kidney['uric_acid']);
      _setText(sodiumCtl, kidney['sodium']);
      _setText(potassiumCtl, kidney['potassium']);
      creatUnit = kidney['creatinine_unit'] as String? ?? creatUnit;
      _setText(lipaseCtl, pancreas['lipase']);
      _setText(amylaseCtl, pancreas['amylase']);
      _setText(afpCtl, tumor['afp']);
      _setText(ca15Ctl, tumor['ca15_3']);
      _setText(ca27Ctl, tumor['ca27_29']);
    });
  }

  void _setText(TextEditingController controller, dynamic value) {
    if (value != null) controller.text = value.toString();
  }

  Map<String, dynamic> _payload() {
    return {
      "profile": {
        "age": _int(ageCtl),
        "sex": sex,
        "height_cm": _num(heightCtl),
        "weight_kg": _num(weightCtl),
        "waist_cm": _num(waistCtl),
      },
      "general_health": {
        "smoking": smoking,
        "alcohol": alcohol,
        "physical_activity": physicalActivity,
        "sleep_duration": sleepDuration,
        "stress_level": stressLevel,
        "family_history": familyHistory,
        "diet_type": dietType,
        "high_sugar_intake": sugarIntake,
        "high_salt_intake": saltIntake,
        "fried_processed_food": processedFood,
        "fruit_veg_intake": fruitVeg,
        "sugary_drinks": sugaryDrinks,
        "air_pollution": airPollution,
        "occupational_exposure": occupationalExposure,
        "passive_smoking": passiveSmoking,
        "cooking_smoke": cookingSmoke,
        "cooking_fuel_smoke": cookingFuelSmoke,
        "location_type": locationType,
      },
      "vitals": {
        "systolic": _num(sysCtl),
        "diastolic": _num(diaCtl),
        "heart_rate": _int(hrCtl),
        "spo2": _num(spo2Ctl),
      },
      "lipid_profile": {
        "triglycerides": _num(tgCtl),
        "triglycerides_unit": tgUnit,
        "hdl": _num(hdlCtl),
        "hdl_unit": hdlUnit,
        "ldl": _num(ldlCtl),
        "ldl_unit": ldlUnit,
        "total_cholesterol": _num(totalCholesterolCtl),
        "total_cholesterol_unit": totalCholesterolUnit,
        "vldl": _num(vldlCtl),
      },
      "diabetes_profile": {
        "fasting_glucose": _num(fastingCtl),
        "fasting_glucose_unit": glucoseUnit,
        "hba1c": _num(hba1cCtl),
        "ppbs": _num(ppbsCtl),
        "ppbs_unit": ppbsUnit,
        "random_blood_sugar": _num(randomSugarCtl),
        "random_blood_sugar_unit": randomSugarUnit,
      },
      "liver_function": {
        "ast": _num(astCtl),
        "alt": _num(altCtl),
        "ggt": _num(ggtCtl),
        "alp": _num(alpCtl),
        "bilirubin": _num(bilirubinCtl),
        "albumin": _num(albuminCtl),
        "total_protein": _num(totalProteinCtl),
      },
      "cbc": {
        "platelets": _num(plateletsCtl),
        "wbc": _num(wbcCtl),
        "neutrophils": _num(neutCtl),
        "lymphocytes": _num(lymphCtl),
        "hemoglobin": _num(hemoglobinCtl),
        "rbc": _num(rbcCtl),
        "esr": _num(esrCtl),
      },
      "kidney_function": {
        "creatinine": _num(creatCtl),
        "creatinine_unit": creatUnit,
        "blood_urea": _num(bloodUreaCtl),
        "uric_acid": _num(uricAcidCtl),
        "sodium": _num(sodiumCtl),
        "potassium": _num(potassiumCtl),
      },
      "pancreatic_enzymes": {
        "lipase": _num(lipaseCtl),
        "amylase": _num(amylaseCtl),
      },
      "tumor_markers": {
        "afp": _num(afpCtl),
        "ca15_3": _num(ca15Ctl),
        "ca27_29": _num(ca27Ctl),
      },
    };
  }

  double? _num(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : double.tryParse(text);
  }

  int? _int(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : int.tryParse(text);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.health_and_safety, color: AppStyles.primary),
              SizedBox(width: 8),
              Text('VitalMap'),
            ],
          ),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IntroCard(),
                _stepHeader('Step 1 of 3: General Health Details'),
                _profileCard(),
                _lifestyleCard(),
                _foodCard(),
                _environmentCard(),
                _stepHeader('Step 2 of 3: Optional Report-Based Lab Inputs'),
                const Text(
                  'Choose the report values you have. You do not need to enter all reports. The app will automatically calculate all possible risk indicators.',
                  style: TextStyle(color: AppStyles.muted),
                ),
                const SizedBox(height: 12),
                _reportPicker(),
                const SizedBox(height: 6),
                if (_selectedSections.contains('heart')) _heartCard(),
                if (_selectedSections.contains('diabetes')) _diabetesCard(),
                if (_selectedSections.contains('liver')) _liverCard(),
                if (_selectedSections.contains('cbc')) _cbcCard(),
                if (_selectedSections.contains('kidney')) _kidneyCard(),
                if (_selectedSections.contains('vitals')) _vitalsCard(),
                if (_selectedSections.contains('pancreas')) _pancreasCard(),
                if (_selectedSections.contains('cancer')) _cancerCard(),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: loading ? null : analyze,
                    icon: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.insights),
                    label: Text(
                        loading ? 'Analyzing...' : 'Analyze Available Values'),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'Step 3 of 3: Review screening insights on the Results tab',
                    style: TextStyle(
                        color: AppStyles.primary, fontWeight: FontWeight.w700),
                  ),
                ),
                const DisclaimerWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppStyles.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
              child:
                  Text(text, style: Theme.of(context).textTheme.titleMedium)),
        ],
      ),
    );
  }

  Widget _profileCard() {
    return _SectionCard(
      title: 'Basic profile',
      icon: Icons.person_outline,
      child: Column(
        children: [
          _twoColumn(
            _numberField(ageCtl, 'Age', required: true),
            _choice('Sex', sex, const ['Female', 'Male', 'Other'],
                (value) => setState(() => sex = value)),
          ),
          _twoColumn(
            _numberField(heightCtl, 'Height (cm)', required: true),
            _numberField(weightCtl, 'Weight (kg)', required: true),
          ),
          _numberField(waistCtl, 'Waist circumference (cm)', required: true),
          if (_currentBmi() != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'BMI: ${_currentBmi()!.toStringAsFixed(1)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: AppStyles.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double? _currentBmi() {
    final height = _num(heightCtl);
    final weight = _num(weightCtl);
    if (height == null || weight == null || height <= 0) return null;
    return weight / ((height / 100) * (height / 100));
  }

  Widget _lifestyleCard() {
    return _SectionCard(
      title: 'Lifestyle',
      icon: Icons.directions_walk,
      child: Column(
        children: [
          _twoColumn(
            _choice('Smoking', smoking, const ['No', 'Former', 'Yes'],
                (value) => setState(() => smoking = value)),
            _choice('Alcohol', alcohol, const ['No', 'Occasional', 'Frequent'],
                (value) => setState(() => alcohol = value)),
          ),
          _twoColumn(
            _choice(
                'Physical activity',
                physicalActivity,
                const ['Low', 'Moderate', 'High'],
                (value) => setState(() => physicalActivity = value)),
            _choice(
                'Sleep duration',
                sleepDuration,
                const ['<5 hrs', '5-7 hrs', '>7 hrs'],
                (value) => setState(() => sleepDuration = value)),
          ),
          _twoColumn(
            _choice(
                'Stress level',
                stressLevel,
                const ['Low', 'Moderate', 'High'],
                (value) => setState(() => stressLevel = value)),
            _choice(
                'Family history',
                familyHistory,
                const [
                  'None',
                  'Diabetes',
                  'Heart disease',
                  'Cancer',
                  'Kidney disease',
                  'Multiple'
                ],
                (value) => setState(() => familyHistory = value)),
          ),
        ],
      ),
    );
  }

  Widget _foodCard() {
    return _SectionCard(
      title: 'Food habits',
      icon: Icons.restaurant_outlined,
      child: Column(
        children: [
          _twoColumn(
            _choice(
                'Diet type',
                dietType,
                const ['Vegetarian', 'Non-vegetarian', 'Mixed'],
                (value) => setState(() => dietType = value)),
            _choice(
                'High sugar intake',
                sugarIntake,
                const ['Low', 'Moderate', 'High'],
                (value) => setState(() => sugarIntake = value)),
          ),
          _twoColumn(
            _choice(
                'High salt intake',
                saltIntake,
                const ['Low', 'Moderate', 'High'],
                (value) => setState(() => saltIntake = value)),
            _choice(
                'Fried / processed food',
                processedFood,
                const ['Rare', 'Sometimes', 'Frequent'],
                (value) => setState(() => processedFood = value)),
          ),
          _twoColumn(
            _choice(
                'Fruit / vegetable intake',
                fruitVeg,
                const ['Low', 'Moderate', 'High'],
                (value) => setState(() => fruitVeg = value)),
            _choice(
                'Sugary drinks',
                sugaryDrinks,
                const ['No', 'Occasionally', 'Frequently'],
                (value) => setState(() => sugaryDrinks = value)),
          ),
        ],
      ),
    );
  }

  Widget _environmentCard() {
    return _SectionCard(
      title: 'Environment',
      icon: Icons.eco_outlined,
      child: Column(
        children: [
          _twoColumn(
            _choice(
                'Air pollution exposure',
                airPollution,
                const ['Low', 'Moderate', 'High'],
                (value) => setState(() => airPollution = value)),
            _choice(
                'Dust / chemical exposure',
                occupationalExposure,
                const ['No', 'Yes'],
                (value) => setState(() => occupationalExposure = value)),
          ),
          _twoColumn(
            _choice('Passive smoking', passiveSmoking, const ['No', 'Yes'],
                (value) => setState(() => passiveSmoking = value)),
            _choice('Cooking smoke', cookingSmoke, const ['No', 'Yes'],
                (value) => setState(() => cookingSmoke = value)),
          ),
          _twoColumn(
            _choice('Cooking fuel smoke', cookingFuelSmoke, const ['No', 'Yes'],
                (value) => setState(() => cookingFuelSmoke = value)),
            _choice('Location type', locationType, const ['Urban', 'Rural'],
                (value) => setState(() => locationType = value)),
          ),
        ],
      ),
    );
  }

  Widget _reportPicker() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth > 620
            ? (constraints.maxWidth - 24) / 3
            : (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final section in _reportSections)
              SizedBox(
                width: cardWidth,
                child: _ReportToggleCard(
                  section: section,
                  selected: _selectedSections.contains(section.id),
                  onTap: () {
                    setState(() {
                      if (_selectedSections.contains(section.id)) {
                        _selectedSections.remove(section.id);
                      } else {
                        _selectedSections.add(section.id);
                      }
                    });
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _heartCard() {
    return _SectionCard(
      title: 'Heart / Lipid Profile',
      icon: Icons.favorite_border,
      child: Column(
        children: [
          _unitField(
              tgCtl,
              'Triglycerides',
              tgUnit,
              (value) => setState(() => tgUnit = value),
              const ['mg/dL', 'mmol/L']),
          _unitField(
              hdlCtl,
              'HDL',
              hdlUnit,
              (value) => setState(() => hdlUnit = value),
              const ['mg/dL', 'mmol/L']),
          _unitField(
              ldlCtl,
              'LDL',
              ldlUnit,
              (value) => setState(() => ldlUnit = value),
              const ['mg/dL', 'mmol/L']),
          _unitField(
              totalCholesterolCtl,
              'Total cholesterol',
              totalCholesterolUnit,
              (value) => setState(() => totalCholesterolUnit = value),
              const ['mg/dL', 'mmol/L']),
          _numberField(vldlCtl, 'VLDL'),
        ],
      ),
    );
  }

  Widget _diabetesCard() {
    return _SectionCard(
      title: 'Diabetes / Metabolic Profile',
      icon: Icons.water_drop_outlined,
      child: Column(
        children: [
          _unitField(
              fastingCtl,
              'Fasting glucose',
              glucoseUnit,
              (value) => setState(() => glucoseUnit = value),
              const ['mg/dL', 'mmol/L']),
          _numberField(hba1cCtl, 'HbA1c (%)'),
          _unitField(
              ppbsCtl,
              'PPBS',
              ppbsUnit,
              (value) => setState(() => ppbsUnit = value),
              const ['mg/dL', 'mmol/L']),
          _unitField(
              randomSugarCtl,
              'Random blood sugar',
              randomSugarUnit,
              (value) => setState(() => randomSugarUnit = value),
              const ['mg/dL', 'mmol/L']),
        ],
      ),
    );
  }

  Widget _liverCard() {
    return _SectionCard(
      title: 'Liver Function Test',
      icon: Icons.monitor_heart_outlined,
      child: Column(
        children: [
          _twoColumn(_numberField(astCtl, 'AST'), _numberField(altCtl, 'ALT')),
          _twoColumn(_numberField(ggtCtl, 'GGT'), _numberField(alpCtl, 'ALP')),
          _twoColumn(_numberField(bilirubinCtl, 'Bilirubin'),
              _numberField(albuminCtl, 'Albumin')),
          _numberField(totalProteinCtl, 'Total protein'),
        ],
      ),
    );
  }

  Widget _cbcCard() {
    return _SectionCard(
      title: 'CBC / Differential Count',
      icon: Icons.bloodtype_outlined,
      child: Column(
        children: [
          _twoColumn(_numberField(plateletsCtl, 'Platelets'),
              _numberField(wbcCtl, 'WBC')),
          _twoColumn(_numberField(neutCtl, 'Neutrophils (%)'),
              _numberField(lymphCtl, 'Lymphocytes (%)')),
          _twoColumn(_numberField(hemoglobinCtl, 'Hemoglobin'),
              _numberField(rbcCtl, 'RBC')),
          _numberField(esrCtl, 'ESR'),
        ],
      ),
    );
  }

  Widget _kidneyCard() {
    return _SectionCard(
      title: 'Kidney Function Test',
      icon: Icons.opacity_outlined,
      child: Column(
        children: [
          _unitField(
              creatCtl,
              'Creatinine',
              creatUnit,
              (value) => setState(() => creatUnit = value),
              const ['mg/dL', 'µmol/L']),
          _twoColumn(_numberField(bloodUreaCtl, 'Blood urea'),
              _numberField(uricAcidCtl, 'Uric acid')),
          _twoColumn(_numberField(sodiumCtl, 'Sodium'),
              _numberField(potassiumCtl, 'Potassium')),
        ],
      ),
    );
  }

  Widget _vitalsCard() {
    return _SectionCard(
      title: 'Vitals',
      icon: Icons.speed_outlined,
      child: Column(
        children: [
          _twoColumn(_numberField(sysCtl, 'Systolic BP'),
              _numberField(diaCtl, 'Diastolic BP')),
          _twoColumn(_numberField(hrCtl, 'Heart rate'),
              _numberField(spo2Ctl, 'SpO2 (%)')),
        ],
      ),
    );
  }

  Widget _pancreasCard() {
    return _SectionCard(
      title: 'Pancreatic Enzymes',
      icon: Icons.science_outlined,
      child: _twoColumn(_numberField(lipaseCtl, 'Lipase'),
          _numberField(amylaseCtl, 'Amylase')),
    );
  }

  Widget _cancerCard() {
    return _SectionCard(
      title: 'Cancer Awareness Markers',
      icon: Icons.health_and_safety_outlined,
      child: Column(
        children: [
          _numberField(afpCtl, 'AFP'),
          _twoColumn(_numberField(ca15Ctl, 'CA 15-3'),
              _numberField(ca27Ctl, 'CA 27.29')),
        ],
      ),
    );
  }

  Widget _numberField(TextEditingController controller, String label,
      {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (required && text.isEmpty) return 'Required';
          if (text.isNotEmpty && double.tryParse(text) == null)
            return 'Enter a valid number';
          return null;
        },
      ),
    );
  }

  Widget _unitField(
    TextEditingController controller,
    String label,
    String unit,
    ValueChanged<String> onUnitChanged,
    List<String> units,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _numberField(controller, label)),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: DropdownButtonFormField<String>(
              initialValue: unit,
              decoration: const InputDecoration(labelText: 'Unit'),
              items: units
                  .map((item) =>
                      DropdownMenuItem(value: item, child: Text(item)))
                  .toList(),
              onChanged: (value) {
                if (value != null) onUnitChanged(value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _choice(
    String label,
    String? value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: options
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
        validator: (choice) => choice == null ? 'Required' : null,
      ),
    );
  }

  Widget _twoColumn(Widget left, Widget right) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(children: [left, right]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 12),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE9FBFF), Color(0xFFFFFFFF), Color(0xFFEAF7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppStyles.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppStyles.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.health_and_safety, color: AppStyles.primary),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Organ health risk indicator',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  SizedBox(height: 6),
                  Text(
                    'Complete the general questions, then add any report values available to generate safe screening insights.',
                    style: TextStyle(color: AppStyles.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard(
      {required this.title, required this.icon, required this.child});

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppStyles.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(title,
                        style: Theme.of(context).textTheme.titleMedium)),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ReportToggleCard extends StatelessWidget {
  const _ReportToggleCard({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final _ReportSection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 126),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAFBFD) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected ? AppStyles.primary : AppStyles.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(section.icon,
                    color: selected ? AppStyles.primary : AppStyles.muted),
                const Spacer(),
                Icon(
                  selected ? Icons.check_circle : Icons.add_circle_outline,
                  color: selected ? AppStyles.primary : AppStyles.muted,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(section.title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppStyles.text)),
            const SizedBox(height: 4),
            Text(section.subtitle,
                style: const TextStyle(fontSize: 12, color: AppStyles.muted)),
          ],
        ),
      ),
    );
  }
}

class _ReportSection {
  const _ReportSection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
}
