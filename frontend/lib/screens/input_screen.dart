import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../storage/local_storage.dart';
import '../styles.dart';
import '../utils/unit_conversion.dart';
import '../widgets/brand_logo.dart';
import '../widgets/disclaimer.dart';
import '../widgets/health_dashboard_widgets.dart';

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
  final heightFeetCtl = TextEditingController();
  final heightInchesCtl = TextEditingController();
  final weightCtl = TextEditingController();
  final waistCtl = TextEditingController();

  final sysCtl = TextEditingController();
  final diaCtl = TextEditingController();
  final hrCtl = TextEditingController();
  final spo2Ctl = TextEditingController();
  final temperatureCtl = TextEditingController();
  final respiratoryRateCtl = TextEditingController();

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
  final bilirubinDirectCtl = TextEditingController();
  final bilirubinIndirectCtl = TextEditingController();
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
  final bunCtl = TextEditingController();
  final uricAcidCtl = TextEditingController();
  final sodiumCtl = TextEditingController();
  final potassiumCtl = TextEditingController();
  final chlorideCtl = TextEditingController();

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

  String ageUnit = 'years';
  String heightUnit = 'cm';
  String weightUnit = 'kg';
  String waistUnit = 'cm';
  String systolicUnit = 'mmHg';
  String diastolicUnit = 'mmHg';
  String heartRateUnit = 'bpm';
  String spo2Unit = '%';
  String temperatureUnit = '°C';
  String respiratoryRateUnit = 'breaths/min';
  String tgUnit = 'mg/dL';
  String hdlUnit = 'mg/dL';
  String ldlUnit = 'mg/dL';
  String totalCholesterolUnit = 'mg/dL';
  String vldlUnit = 'mg/dL';
  String glucoseUnit = 'mg/dL';
  String ppbsUnit = 'mg/dL';
  String randomSugarUnit = 'mg/dL';
  String hba1cUnit = '%';
  String astUnit = 'U/L';
  String altUnit = 'U/L';
  String ggtUnit = 'U/L';
  String alpUnit = 'U/L';
  String bilirubinUnit = 'mg/dL';
  String bilirubinDirectUnit = 'mg/dL';
  String bilirubinIndirectUnit = 'mg/dL';
  String albuminUnit = 'g/dL';
  String totalProteinUnit = 'g/dL';
  String plateletsUnit = '10⁹/L';
  String wbcUnit = '10⁹/L';
  String neutrophilsUnit = '%';
  String lymphocytesUnit = '%';
  String hemoglobinUnit = 'g/dL';
  String rbcUnit = 'million/µL';
  String esrUnit = 'mm/hr';
  String creatUnit = 'mg/dL';
  String bloodUreaUnit = 'mg/dL';
  String bunUnit = 'mg/dL';
  String uricAcidUnit = 'mg/dL';
  String sodiumUnit = 'mmol/L';
  String potassiumUnit = 'mmol/L';
  String chlorideUnit = 'mmol/L';
  String lipaseUnit = 'U/L';
  String amylaseUnit = 'U/L';
  String afpUnit = 'ng/mL';
  String ca153Unit = 'U/mL';
  String ca2729Unit = 'U/mL';

  bool loading = false;

  final _profileKey = GlobalKey();
  final _lifestyleKey = GlobalKey();
  final _environmentKey = GlobalKey();
  final _reportsKey = GlobalKey();
  String _activeTop = 'basic';

  static const _reportSections = [
    _ReportSection(
      id: 'heart',
      title: 'Heart / Lipid Profile',
      subtitle: 'AIP',
      icon: Icons.favorite_border,
      background: Color(0xFFFFF0F5),
      accent: Color(0xFFD970A0),
    ),
    _ReportSection(
      id: 'diabetes',
      title: 'Diabetes / Metabolic',
      subtitle: 'TyG, metabolic insight',
      icon: Icons.water_drop_outlined,
      background: Color(0xFFFFF7E7),
      accent: Color(0xFFD99D41),
    ),
    _ReportSection(
      id: 'liver',
      title: 'Liver Function Test',
      subtitle: 'APRI, FIB-4, FLI, NAFLD',
      icon: Icons.monitor_heart_outlined,
      background: Color(0xFFECF8EF),
      accent: Color(0xFF65B985),
    ),
    _ReportSection(
      id: 'cbc',
      title: 'CBC / Differential',
      subtitle: 'NLR and liver support',
      icon: Icons.bloodtype_outlined,
      background: Color(0xFFF5F3FA),
      accent: Color(0xFF9C89CD),
    ),
    _ReportSection(
      id: 'kidney',
      title: 'Kidney Function',
      subtitle: 'eGFR',
      icon: Icons.opacity_outlined,
      background: Color(0xFFEAFBFD),
      accent: Color(0xFF49B6C8),
    ),
    _ReportSection(
      id: 'vitals',
      title: 'Vitals',
      subtitle: 'SpO2, BP support',
      icon: Icons.speed_outlined,
      background: Color(0xFFEAF7FF),
      accent: Color(0xFF4BAFE3),
    ),
    _ReportSection(
      id: 'pancreas',
      title: 'Pancreatic Enzymes',
      subtitle: 'LAR',
      icon: Icons.science_outlined,
      background: Color(0xFFFFF0ED),
      accent: Color(0xFFE18170),
    ),
    _ReportSection(
      id: 'cancer',
      title: 'Cancer Awareness',
      subtitle: 'Awareness markers only',
      icon: Icons.health_and_safety_outlined,
      background: Color(0xFFF3F2F8),
      accent: Color(0xFF8B8FC7),
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
      heightFeetCtl,
      heightInchesCtl,
      weightCtl,
      waistCtl,
      sysCtl,
      diaCtl,
      hrCtl,
      spo2Ctl,
      temperatureCtl,
      respiratoryRateCtl,
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
      bilirubinDirectCtl,
      bilirubinIndirectCtl,
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
      bunCtl,
      uricAcidCtl,
      sodiumCtl,
      potassiumCtl,
      chlorideCtl,
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
              'Unable to analyze right now. Please check your input values and try again.'),
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
    final selectedSections = _inferSelectedSections(payload);

    setState(() {
      _selectedSections
        ..clear()
        ..addAll(selectedSections);
      _setText(ageCtl, profile['age']);
      ageUnit = profile['age_unit'] as String? ?? ageUnit;
      heightUnit = profile['height_unit'] as String? ?? heightUnit;
      _setText(heightCtl, profile['height_input'] ?? profile['height_cm']);
      _setText(heightFeetCtl, profile['height_feet']);
      _setText(heightInchesCtl, profile['height_inches']);
      weightUnit = profile['weight_unit'] as String? ?? weightUnit;
      _setText(weightCtl, profile['weight_input'] ?? profile['weight_kg']);
      waistUnit = profile['waist_unit'] as String? ?? waistUnit;
      _setText(waistCtl, profile['waist_input'] ?? profile['waist_cm']);
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
      systolicUnit = vitals['systolic_unit'] as String? ?? systolicUnit;
      _setText(diaCtl, vitals['diastolic']);
      diastolicUnit = vitals['diastolic_unit'] as String? ?? diastolicUnit;
      _setText(hrCtl, vitals['heart_rate']);
      heartRateUnit = vitals['heart_rate_unit'] as String? ?? heartRateUnit;
      _setText(spo2Ctl, vitals['spo2']);
      spo2Unit = vitals['spo2_unit'] as String? ?? spo2Unit;
      temperatureUnit =
          vitals['body_temperature_unit'] as String? ?? temperatureUnit;
      _setText(temperatureCtl,
          vitals['body_temperature_input'] ?? vitals['body_temperature']);
      respiratoryRateUnit =
          vitals['respiratory_rate_unit'] as String? ?? respiratoryRateUnit;
      _setText(respiratoryRateCtl, vitals['respiratory_rate']);
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
      vldlUnit = lipids['vldl_unit'] as String? ?? vldlUnit;

      _setText(fastingCtl, diabetes['fasting_glucose']);
      _setText(hba1cCtl, diabetes['hba1c']);
      _setText(ppbsCtl, diabetes['ppbs']);
      _setText(randomSugarCtl, diabetes['random_blood_sugar']);
      glucoseUnit = diabetes['fasting_glucose_unit'] as String? ?? glucoseUnit;
      hba1cUnit = diabetes['hba1c_unit'] as String? ?? hba1cUnit;
      ppbsUnit = diabetes['ppbs_unit'] as String? ?? ppbsUnit;
      randomSugarUnit =
          diabetes['random_blood_sugar_unit'] as String? ?? randomSugarUnit;

      _setText(astCtl, liver['ast']);
      _setText(altCtl, liver['alt']);
      _setText(ggtCtl, liver['ggt']);
      _setText(alpCtl, liver['alp']);
      _setText(bilirubinCtl, liver['bilirubin']);
      _setText(bilirubinDirectCtl, liver['bilirubin_direct']);
      _setText(bilirubinIndirectCtl, liver['bilirubin_indirect']);
      _setText(albuminCtl, liver['albumin']);
      _setText(totalProteinCtl, liver['total_protein']);
      astUnit = liver['ast_unit'] as String? ?? astUnit;
      altUnit = liver['alt_unit'] as String? ?? altUnit;
      ggtUnit = liver['ggt_unit'] as String? ?? ggtUnit;
      alpUnit = liver['alp_unit'] as String? ?? alpUnit;
      bilirubinUnit = liver['bilirubin_unit'] as String? ?? bilirubinUnit;
      bilirubinDirectUnit =
          liver['bilirubin_direct_unit'] as String? ?? bilirubinDirectUnit;
      bilirubinIndirectUnit =
          liver['bilirubin_indirect_unit'] as String? ?? bilirubinIndirectUnit;
      albuminUnit = liver['albumin_unit'] as String? ?? albuminUnit;
      totalProteinUnit =
          liver['total_protein_unit'] as String? ?? totalProteinUnit;
      _setText(plateletsCtl, cbc['platelets']);
      _setText(wbcCtl, cbc['wbc']);
      _setText(neutCtl, cbc['neutrophils']);
      _setText(lymphCtl, cbc['lymphocytes']);
      _setText(hemoglobinCtl, cbc['hemoglobin']);
      _setText(rbcCtl, cbc['rbc']);
      _setText(esrCtl, cbc['esr']);
      plateletsUnit = cbc['platelets_unit'] as String? ?? plateletsUnit;
      wbcUnit = cbc['wbc_unit'] as String? ?? wbcUnit;
      neutrophilsUnit = cbc['neutrophils_unit'] as String? ?? neutrophilsUnit;
      lymphocytesUnit = cbc['lymphocytes_unit'] as String? ?? lymphocytesUnit;
      hemoglobinUnit = cbc['hemoglobin_unit'] as String? ?? hemoglobinUnit;
      rbcUnit = cbc['rbc_unit'] as String? ?? rbcUnit;
      esrUnit = cbc['esr_unit'] as String? ?? esrUnit;

      _setText(creatCtl, kidney['creatinine']);
      _setText(bloodUreaCtl, kidney['blood_urea']);
      _setText(bunCtl, kidney['bun']);
      _setText(uricAcidCtl, kidney['uric_acid']);
      _setText(sodiumCtl, kidney['sodium']);
      _setText(potassiumCtl, kidney['potassium']);
      _setText(chlorideCtl, kidney['chloride']);
      creatUnit = kidney['creatinine_unit'] as String? ?? creatUnit;
      bloodUreaUnit = kidney['blood_urea_unit'] as String? ?? bloodUreaUnit;
      bunUnit = kidney['bun_unit'] as String? ?? bunUnit;
      uricAcidUnit = kidney['uric_acid_unit'] as String? ?? uricAcidUnit;
      sodiumUnit = kidney['sodium_unit'] as String? ?? sodiumUnit;
      potassiumUnit = kidney['potassium_unit'] as String? ?? potassiumUnit;
      chlorideUnit = kidney['chloride_unit'] as String? ?? chlorideUnit;
      _setText(lipaseCtl, pancreas['lipase']);
      _setText(amylaseCtl, pancreas['amylase']);
      lipaseUnit = pancreas['lipase_unit'] as String? ?? lipaseUnit;
      amylaseUnit = pancreas['amylase_unit'] as String? ?? amylaseUnit;
      _setText(afpCtl, tumor['afp']);
      _setText(ca15Ctl, tumor['ca15_3']);
      _setText(ca27Ctl, tumor['ca27_29']);
      afpUnit = tumor['afp_unit'] as String? ?? afpUnit;
      ca153Unit = tumor['ca15_3_unit'] as String? ?? ca153Unit;
      ca2729Unit = tumor['ca27_29_unit'] as String? ?? ca2729Unit;
    });
  }

  void _setText(TextEditingController controller, dynamic value) {
    if (value != null) controller.text = value.toString();
  }

  Map<String, dynamic> _payload() {
    final heightCm = _heightCm();
    final weightKg = weightToKg(_num(weightCtl), weightUnit);
    final waistCm = waistToCm(_num(waistCtl), waistUnit);
    final neutrophils = _num(neutCtl);
    final lymphocytes = _num(lymphCtl);
    return {
      "selected_report_sections": _selectedSections.toList(),
      "profile": {
        "age": _int(ageCtl),
        "age_unit": ageUnit,
        "sex": sex,
        "height_cm": heightCm,
        "height_unit": heightUnit,
        "height_input": _num(heightCtl),
        "height_feet": _num(heightFeetCtl),
        "height_inches": _num(heightInchesCtl),
        "weight_kg": weightKg,
        "weight_unit": weightUnit,
        "weight_input": _num(weightCtl),
        "waist_cm": waistCm,
        "waist_unit": waistUnit,
        "waist_input": _num(waistCtl),
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
        "systolic": _sectionNum('vitals', sysCtl),
        "systolic_unit": systolicUnit,
        "diastolic": _sectionNum('vitals', diaCtl),
        "diastolic_unit": diastolicUnit,
        "heart_rate": _sectionInt('vitals', hrCtl),
        "heart_rate_unit": heartRateUnit,
        "spo2": _sectionNum('vitals', spo2Ctl),
        "spo2_unit": spo2Unit,
        "body_temperature": _ifSection(
            'vitals', temperatureToC(_num(temperatureCtl), temperatureUnit)),
        "body_temperature_unit": temperatureUnit,
        "body_temperature_input": _sectionNum('vitals', temperatureCtl),
        "respiratory_rate": _sectionInt('vitals', respiratoryRateCtl),
        "respiratory_rate_unit": respiratoryRateUnit,
      },
      "lipid_profile": {
        "triglycerides":
            _ifSection('heart', triglyceridesToMgdl(_num(tgCtl), tgUnit)),
        "triglycerides_unit": "mg/dL",
        "triglycerides_input": _sectionNum('heart', tgCtl),
        "triglycerides_input_unit": tgUnit,
        "hdl": _ifSection('heart', cholesterolToMgdl(_num(hdlCtl), hdlUnit)),
        "hdl_unit": "mg/dL",
        "hdl_input": _sectionNum('heart', hdlCtl),
        "hdl_input_unit": hdlUnit,
        "ldl": _ifSection('heart', cholesterolToMgdl(_num(ldlCtl), ldlUnit)),
        "ldl_unit": "mg/dL",
        "ldl_input": _sectionNum('heart', ldlCtl),
        "ldl_input_unit": ldlUnit,
        "total_cholesterol": _ifSection('heart',
            cholesterolToMgdl(_num(totalCholesterolCtl), totalCholesterolUnit)),
        "total_cholesterol_unit": "mg/dL",
        "total_cholesterol_input": _sectionNum('heart', totalCholesterolCtl),
        "total_cholesterol_input_unit": totalCholesterolUnit,
        "vldl": _ifSection('heart', cholesterolToMgdl(_num(vldlCtl), vldlUnit)),
        "vldl_unit": "mg/dL",
        "vldl_input": _sectionNum('heart', vldlCtl),
        "vldl_input_unit": vldlUnit,
      },
      "diabetes_profile": {
        "fasting_glucose": _ifSection(
            'diabetes', glucoseToMgdl(_num(fastingCtl), glucoseUnit)),
        "fasting_glucose_unit": "mg/dL",
        "fasting_glucose_input": _sectionNum('diabetes', fastingCtl),
        "fasting_glucose_input_unit": glucoseUnit,
        "hba1c": _sectionNum('diabetes', hba1cCtl),
        "hba1c_unit": hba1cUnit,
        "ppbs": _ifSection('diabetes', glucoseToMgdl(_num(ppbsCtl), ppbsUnit)),
        "ppbs_unit": "mg/dL",
        "ppbs_input": _sectionNum('diabetes', ppbsCtl),
        "ppbs_input_unit": ppbsUnit,
        "random_blood_sugar": _ifSection(
            'diabetes', glucoseToMgdl(_num(randomSugarCtl), randomSugarUnit)),
        "random_blood_sugar_unit": "mg/dL",
        "random_blood_sugar_input": _sectionNum('diabetes', randomSugarCtl),
        "random_blood_sugar_input_unit": randomSugarUnit,
      },
      "liver_function": {
        "ast": _sectionNum('liver', astCtl),
        "ast_unit": astUnit,
        "alt": _sectionNum('liver', altCtl),
        "alt_unit": altUnit,
        "ggt": _sectionNum('liver', ggtCtl),
        "ggt_unit": ggtUnit,
        "alp": _sectionNum('liver', alpCtl),
        "alp_unit": alpUnit,
        "bilirubin": _ifSection(
            'liver', bilirubinToMgdl(_num(bilirubinCtl), bilirubinUnit)),
        "bilirubin_unit": "mg/dL",
        "bilirubin_input": _sectionNum('liver', bilirubinCtl),
        "bilirubin_input_unit": bilirubinUnit,
        "bilirubin_direct": _ifSection('liver',
            bilirubinToMgdl(_num(bilirubinDirectCtl), bilirubinDirectUnit)),
        "bilirubin_direct_unit": "mg/dL",
        "bilirubin_indirect": _ifSection('liver',
            bilirubinToMgdl(_num(bilirubinIndirectCtl), bilirubinIndirectUnit)),
        "bilirubin_indirect_unit": "mg/dL",
        "albumin":
            _ifSection('liver', albuminToGdl(_num(albuminCtl), albuminUnit)),
        "albumin_unit": "g/dL",
        "albumin_input": _sectionNum('liver', albuminCtl),
        "albumin_input_unit": albuminUnit,
        "total_protein": _ifSection('liver',
            totalProteinToGdl(_num(totalProteinCtl), totalProteinUnit)),
        "total_protein_unit": "g/dL",
        "total_protein_input": _sectionNum('liver', totalProteinCtl),
        "total_protein_input_unit": totalProteinUnit,
      },
      "cbc": {
        "platelets": _ifSection(
            'cbc', plateletsTo10e9L(_num(plateletsCtl), plateletsUnit)),
        "platelets_unit": "10⁹/L",
        "platelets_input": _sectionNum('cbc', plateletsCtl),
        "platelets_input_unit": plateletsUnit,
        "wbc": _sectionNum('cbc', wbcCtl),
        "wbc_unit": "10⁹/L",
        "wbc_input": _sectionNum('cbc', wbcCtl),
        "wbc_input_unit": "10⁹/L",
        "neutrophils": _ifSection('cbc', neutrophils),
        "neutrophils_unit": "%",
        "lymphocytes": _ifSection('cbc', lymphocytes),
        "lymphocytes_unit": "%",
        "hemoglobin": _sectionNum('cbc', hemoglobinCtl),
        "hemoglobin_unit": "g/dL",
        "rbc": _sectionNum('cbc', rbcCtl),
        "rbc_unit": "million/µL",
        "esr": _sectionNum('cbc', esrCtl),
        "esr_unit": "mm/hr",
      },
      "kidney_function": {
        "creatinine":
            _ifSection('kidney', creatinineToMgdl(_num(creatCtl), creatUnit)),
        "creatinine_unit": "mg/dL",
        "creatinine_input": _sectionNum('kidney', creatCtl),
        "creatinine_input_unit": creatUnit,
        "blood_urea": _ifSection(
            'kidney', bloodUreaToMgdl(_num(bloodUreaCtl), bloodUreaUnit)),
        "blood_urea_unit": "mg/dL",
        "bun": _sectionNum('kidney', bunCtl),
        "bun_unit": bunUnit,
        "uric_acid": _ifSection(
            'kidney', uricAcidToMgdl(_num(uricAcidCtl), uricAcidUnit)),
        "uric_acid_unit": "mg/dL",
        "sodium": _sectionNum('kidney', sodiumCtl),
        "sodium_unit": "mmol/L",
        "potassium": _sectionNum('kidney', potassiumCtl),
        "potassium_unit": "mmol/L",
        "chloride": _sectionNum('kidney', chlorideCtl),
        "chloride_unit": "mmol/L",
      },
      "pancreatic_enzymes": {
        "lipase": _sectionNum('pancreas', lipaseCtl),
        "lipase_unit": lipaseUnit,
        "amylase": _sectionNum('pancreas', amylaseCtl),
        "amylase_unit": amylaseUnit,
      },
      "tumor_markers": {
        "afp": _sectionNum('cancer', afpCtl),
        "afp_unit": afpUnit,
        "ca15_3": _sectionNum('cancer', ca15Ctl),
        "ca15_3_unit": ca153Unit,
        "ca27_29": _sectionNum('cancer', ca27Ctl),
        "ca27_29_unit": ca2729Unit,
      },
    };
  }

  double? _sectionNum(String id, TextEditingController controller) {
    return _selectedSections.contains(id) ? _num(controller) : null;
  }

  int? _sectionInt(String id, TextEditingController controller) {
    return _selectedSections.contains(id) ? _int(controller) : null;
  }

  T? _ifSection<T>(String id, T? value) {
    return _selectedSections.contains(id) ? value : null;
  }

  double? _heightCm() {
    if (heightUnit == 'ft-in') {
      return heightFeetInchesToCm(_num(heightFeetCtl), _num(heightInchesCtl));
    }
    return heightToCm(_num(heightCtl), heightUnit);
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
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              BrandAppBarTitle(title: 'VitalMap'),
              SizedBox(height: 2),
              Text(
                'Organ Health Risk Indicator',
                style: TextStyle(fontSize: 12, color: AppStyles.muted),
              ),
            ],
          ),
          elevation: 0,
          backgroundColor: AppStyles.page,
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopTabs(),
                const SizedBox(height: 8),
                _IntroCard(),
                _stepHeader('Step 1 of 3: General Health Details'),
                Container(key: _profileKey, child: _profileCard()),
                _whyAskCard(),
                Container(key: _lifestyleKey, child: _lifestyleCard()),
                Container(key: null, child: _foodCard()),
                Container(key: _environmentKey, child: _environmentCard()),
                _stepHeader('Step 2 of 3: Optional Report-Based Lab Inputs'),
                const Text(
                  'Choose the report values you have. You do not need to enter all reports. The app will automatically calculate all possible risk indicators.',
                  style: TextStyle(color: AppStyles.muted),
                ),
                const SizedBox(height: 12),
                Container(key: _reportsKey, child: _reportPicker()),
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
                _actionButtons(),
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

  Widget _buildTopTabs() {
    final tabs = [
      ('basic', Icons.person_outline, 'Basic Profile'),
      ('lifestyle', Icons.self_improvement, 'Lifestyle'),
      ('environment', Icons.eco, 'Environment'),
      ('reports', Icons.article_outlined, 'Reports'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((t) {
          final id = t.$1;
          final icon = t.$2;
          final label = t.$3;
          final active = _activeTop == id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() => _activeTop = id);
                Future.delayed(const Duration(milliseconds: 60), () {
                  if (id == 'basic') {
                    Scrollable.ensureVisible(_profileKey.currentContext!,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut);
                  } else if (id == 'lifestyle') {
                    Scrollable.ensureVisible(_lifestyleKey.currentContext!,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut);
                  } else if (id == 'environment') {
                    Scrollable.ensureVisible(
                        _environmentKey.currentContext!,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut);
                  } else if (id == 'reports') {
                    Scrollable.ensureVisible(_reportsKey.currentContext!,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? Colors.white : AppStyles.page,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: active ? AppStyles.primary : AppStyles.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: active ? AppStyles.primary : AppStyles.muted, size: 18),
                    const SizedBox(height: 4),
                    Text(label,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: active ? AppStyles.primary : AppStyles.muted)),
                    const SizedBox(height: 4),
                    Container(
                      height: 3,
                      width: 36,
                      decoration: BoxDecoration(
                        color: active ? AppStyles.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        }).toList(),
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
      title: 'Basic Profile',
      icon: Icons.person_outline,
      background: const Color(0xFFEAF8FF),
      accent: const Color(0xFF55B9DF),
      child: Column(
        children: [
          _twoColumn(
            _unitField(
              ageCtl,
              'Age',
              ageUnit,
              (value) => setState(() => ageUnit = value),
              const ['years'],
              helper: 'Self-reported',
              required: true,
              allowSkip: false,
            ),
            _choice('Sex', sex, const ['Female', 'Male', 'Other'],
                (value) => setState(() => sex = value)),
          ),
          _twoColumn(
            _heightField(),
            _unitField(
              weightCtl,
              'Weight',
              weightUnit,
              (value) => setState(() => weightUnit = value),
              const ['kg', 'lb'],
              helper: 'Self-reported',
              required: true,
              allowSkip: false,
            ),
          ),
          _unitField(
            waistCtl,
            'Waist circumference',
            waistUnit,
            (value) => setState(() => waistUnit = value),
            const ['cm', 'inch'],
            helper: 'Self-reported or measured at waist level',
            required: true,
            allowSkip: false,
          ),
          _readOnlyUnitField(
            'BMI',
            _currentBmi()?.toStringAsFixed(1) ?? '',
            'kg/m²',
            helper: 'Auto-calculated from height and weight.',
          ),
        ],
      ),
    );
  }

  Widget _whyAskCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFEAF8F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppStyles.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F7EE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.verified_user_outlined,
                color: Color(0xFF218A52)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why we ask this?',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 4),
                Text(
                  'These details help calculate important health indicators.',
                  style: TextStyle(color: AppStyles.muted, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double? _currentBmi() {
    final height = _heightCm();
    final weight = weightToKg(_num(weightCtl), weightUnit);
    if (height == null || weight == null || height <= 0) return null;
    return weight / ((height / 100) * (height / 100));
  }

  Set<String> _inferSelectedSections(Map<String, dynamic> payload) {
    final saved = payload['selected_report_sections'];
    if (saved is List) return saved.whereType<String>().toSet();
    final sections = <String>{};
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
    if (_hasSavedValues(vitals, [
      'systolic',
      'diastolic',
      'heart_rate',
      'spo2',
      'body_temperature',
      'respiratory_rate'
    ])) {
      sections.add('vitals');
    }
    if (_hasSavedValues(
        lipids, ['triglycerides', 'hdl', 'ldl', 'total_cholesterol', 'vldl'])) {
      sections.add('heart');
    }
    if (_hasSavedValues(
        diabetes, ['fasting_glucose', 'hba1c', 'ppbs', 'random_blood_sugar'])) {
      sections.add('diabetes');
    }
    if (_hasSavedValues(liver, [
      'ast',
      'alt',
      'ggt',
      'alp',
      'bilirubin',
      'bilirubin_direct',
      'bilirubin_indirect',
      'albumin',
      'total_protein'
    ])) {
      sections.add('liver');
    }
    if (_hasSavedValues(cbc, [
      'platelets',
      'wbc',
      'neutrophils',
      'lymphocytes',
      'hemoglobin',
      'rbc',
      'esr'
    ])) {
      sections.add('cbc');
    }
    if (_hasSavedValues(kidney, [
      'creatinine',
      'blood_urea',
      'bun',
      'uric_acid',
      'sodium',
      'potassium',
      'chloride'
    ])) {
      sections.add('kidney');
    }
    if (_hasSavedValues(pancreas, ['lipase', 'amylase'])) {
      sections.add('pancreas');
    }
    if (_hasSavedValues(tumor, ['afp', 'ca15_3', 'ca27_29'])) {
      sections.add('cancer');
    }
    return sections;
  }

  bool _hasSavedValues(Map<String, dynamic> map, List<String> keys) {
    return keys
        .any((key) => map[key] != null && map[key].toString().isNotEmpty);
  }

  void _toggleSection(String id, bool enabled) {
    setState(() {
      if (enabled) {
        _selectedSections.add(id);
      } else {
        _selectedSections.remove(id);
      }
    });
  }

  void _clearControllers(List<TextEditingController> controllers) {
    setState(() {
      for (final controller in controllers) {
        controller.clear();
      }
    });
  }

  Widget _lifestyleCard() {
    return _SectionCard(
      title: 'Lifestyle',
      icon: Icons.directions_walk,
      background: const Color(0xFFF6EEFF),
      accent: const Color(0xFFA675D6),
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
      title: 'Food Habits',
      icon: Icons.restaurant_outlined,
      background: const Color(0xFFFFF2E8),
      accent: const Color(0xFFE49A52),
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
      background: const Color(0xFFEAF8F6),
      accent: const Color(0xFF48B7AB),
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

  Widget _actionButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final analyzeButton = GradientActionButton(
          onPressed: loading ? null : analyze,
          icon: Icons.arrow_forward,
          loading: loading,
          label: loading ? 'Analyzing...' : 'Save & Continue',
        );
        final saveButton = OutlinedButton.icon(
          onPressed: loading
              ? null
              : () async {
                  await LocalStorage.saveLastPayload(_payload());
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Saved for later.')),
                  );
                },
          icon: const Icon(Icons.bookmark_border),
          label: const Text('Save and Continue Later'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          ),
        );
        if (constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: double.infinity, child: analyzeButton),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: saveButton),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: analyzeButton),
            const SizedBox(width: 12),
            Expanded(child: saveButton),
          ],
        );
      },
    );
  }

  Widget _heartCard() {
    return _SectionCard(
      title: 'Lipid Profile',
      icon: Icons.favorite_border,
      background: const Color(0xFFFFF0F5),
      accent: const Color(0xFFD970A0),
      reportId: 'heart',
      enabled: _selectedSections.contains('heart'),
      onToggle: _toggleSection,
      chip: 'Used for: AIP, TyG, FLI',
      onClear: () => _clearControllers([
        tgCtl,
        hdlCtl,
        ldlCtl,
        totalCholesterolCtl,
        vldlCtl,
      ]),
      child: Column(
        children: [
          _unitField(
              tgCtl,
              'Triglycerides',
              tgUnit,
              (value) => setState(() => tgUnit = value),
              const ['mg/dL', 'mmol/L'],
              helper: 'Found in: Lipid Profile'),
          _unitField(
              hdlCtl,
              'HDL cholesterol',
              hdlUnit,
              (value) => setState(() => hdlUnit = value),
              const ['mg/dL', 'mmol/L'],
              helper: 'Found in: Lipid Profile'),
          _unitField(
              ldlCtl,
              'LDL cholesterol',
              ldlUnit,
              (value) => setState(() => ldlUnit = value),
              const ['mg/dL', 'mmol/L'],
              helper: 'Found in: Lipid Profile'),
          _unitField(
              totalCholesterolCtl,
              'Total cholesterol',
              totalCholesterolUnit,
              (value) => setState(() => totalCholesterolUnit = value),
              const ['mg/dL', 'mmol/L'],
              helper: 'Found in: Lipid Profile'),
          _unitField(
            vldlCtl,
            'VLDL',
            vldlUnit,
            (value) => setState(() => vldlUnit = value),
            const ['mg/dL', 'mmol/L'],
            helper: 'Found in: Lipid Profile',
          ),
        ],
      ),
    );
  }

  Widget _diabetesCard() {
    return _SectionCard(
      title: 'Diabetes / Glucose Profile',
      icon: Icons.water_drop_outlined,
      background: const Color(0xFFFFF7E7),
      accent: const Color(0xFFD99D41),
      reportId: 'diabetes',
      enabled: _selectedSections.contains('diabetes'),
      onToggle: _toggleSection,
      chip: 'Used for: TyG, FLI, NAFLD',
      onClear: () => _clearControllers([
        fastingCtl,
        hba1cCtl,
        ppbsCtl,
        randomSugarCtl,
      ]),
      child: Column(
        children: [
          _unitField(
              fastingCtl,
              'Fasting glucose',
              glucoseUnit,
              (value) => setState(() => glucoseUnit = value),
              const ['mg/dL', 'mmol/L'],
              helper: 'Found in: Diabetes / Glucose Report'),
          _unitField(
            hba1cCtl,
            'HbA1c',
            hba1cUnit,
            (value) => setState(() => hba1cUnit = value),
            const ['%'],
            helper: 'Found in: Diabetes / Glucose Report',
          ),
          _unitField(
              ppbsCtl,
              'PPBS',
              ppbsUnit,
              (value) => setState(() => ppbsUnit = value),
              const ['mg/dL', 'mmol/L'],
              helper: 'Found in: Diabetes / Glucose Report'),
          _unitField(
              randomSugarCtl,
              'Random blood sugar',
              randomSugarUnit,
              (value) => setState(() => randomSugarUnit = value),
              const ['mg/dL', 'mmol/L'],
              helper: 'Found in: Diabetes / Glucose Report'),
        ],
      ),
    );
  }

  Widget _liverCard() {
    return _SectionCard(
      title: 'Liver Function Test',
      icon: Icons.monitor_heart_outlined,
      background: const Color(0xFFECF8EF),
      accent: const Color(0xFF65B985),
      reportId: 'liver',
      enabled: _selectedSections.contains('liver'),
      onToggle: _toggleSection,
      chip: 'Used for: APRI, FIB-4, FLI, NAFLD',
      onClear: () => _clearControllers([
        astCtl,
        altCtl,
        ggtCtl,
        alpCtl,
        bilirubinCtl,
        bilirubinDirectCtl,
        bilirubinIndirectCtl,
        albuminCtl,
        totalProteinCtl,
      ]),
      child: Column(
        children: [
          _twoColumn(
            _unitField(astCtl, 'AST / SGOT', astUnit,
                (value) => setState(() => astUnit = value), const ['U/L'],
                helper: 'Found in: Liver Function Test'),
            _unitField(altCtl, 'ALT / SGPT', altUnit,
                (value) => setState(() => altUnit = value), const ['U/L'],
                helper: 'Found in: Liver Function Test'),
          ),
          _twoColumn(
            _unitField(ggtCtl, 'GGT', ggtUnit,
                (value) => setState(() => ggtUnit = value), const ['U/L'],
                helper: 'Found in: Liver Function Test'),
            _unitField(alpCtl, 'ALP', alpUnit,
                (value) => setState(() => alpUnit = value), const ['U/L'],
                helper: 'Found in: Liver Function Test'),
          ),
          _twoColumn(
            _unitField(
              bilirubinCtl,
              'Bilirubin total',
              bilirubinUnit,
              (value) => setState(() => bilirubinUnit = value),
              const ['mg/dL', 'µmol/L'],
              helper: 'Found in: Liver Function Test',
            ),
            _unitField(
              bilirubinDirectCtl,
              'Bilirubin direct',
              bilirubinDirectUnit,
              (value) => setState(() => bilirubinDirectUnit = value),
              const ['mg/dL', 'µmol/L'],
              helper: 'Found in: Liver Function Test',
            ),
          ),
          _twoColumn(
            _unitField(
              bilirubinIndirectCtl,
              'Bilirubin indirect',
              bilirubinIndirectUnit,
              (value) => setState(() => bilirubinIndirectUnit = value),
              const ['mg/dL', 'µmol/L'],
              helper: 'Found in: Liver Function Test',
            ),
            _unitField(
              albuminCtl,
              'Albumin',
              albuminUnit,
              (value) => setState(() => albuminUnit = value),
              const ['g/dL', 'g/L'],
              helper: 'Found in: Liver Function Test',
            ),
          ),
          _unitField(
            totalProteinCtl,
            'Total protein',
            totalProteinUnit,
            (value) => setState(() => totalProteinUnit = value),
            const ['g/dL', 'g/L'],
            helper: 'Found in: Liver Function Test',
          ),
        ],
      ),
    );
  }

  Widget _cbcCard() {
    return _SectionCard(
      title: 'CBC / Differential Count',
      icon: Icons.bloodtype_outlined,
      background: const Color(0xFFF5F3FA),
      accent: const Color(0xFF9C89CD),
      reportId: 'cbc',
      enabled: _selectedSections.contains('cbc'),
      onToggle: _toggleSection,
      chip: 'Used for: NLR, APRI, FIB-4, NAFLD',
      onClear: () => _clearControllers([
        plateletsCtl,
        wbcCtl,
        neutCtl,
        lymphCtl,
        hemoglobinCtl,
        rbcCtl,
        esrCtl,
      ]),
      child: Column(
        children: [
          _twoColumn(
            _unitField(
              plateletsCtl,
              'Platelets',
              plateletsUnit,
              (value) => setState(() => plateletsUnit = value),
              const ['10⁹/L', 'lakh/µL', 'cells/µL'],
              helper: 'Found in: CBC Report',
            ),
            _unitField(
              wbcCtl,
              'WBC',
              '10⁹/L',
              (_) {},
              const ['10⁹/L'],
              helper: 'Found in: CBC Report',
            ),
          ),
          _twoColumn(
            _unitField(
              neutCtl,
              'Neutrophils',
              '%',
              (_) {},
              const ['%'],
              helper: 'Found in: CBC Differential Count',
            ),
            _unitField(
              lymphCtl,
              'Lymphocytes',
              '%',
              (_) {},
              const ['%'],
              helper: 'Found in: CBC Differential Count',
            ),
          ),
          _twoColumn(
            _unitField(
              hemoglobinCtl,
              'Hemoglobin',
              hemoglobinUnit,
              (value) => setState(() => hemoglobinUnit = value),
              const ['g/dL'],
              helper: 'Found in: CBC Report',
            ),
            _unitField(
              rbcCtl,
              'RBC',
              rbcUnit,
              (value) => setState(() => rbcUnit = value),
              const ['million/µL'],
              helper: 'Found in: CBC Report',
            ),
          ),
          _unitField(
            esrCtl,
            'ESR',
            esrUnit,
            (value) => setState(() => esrUnit = value),
            const ['mm/hr'],
            helper: 'Found in: CBC Report',
          ),
        ],
      ),
    );
  }

  Widget _kidneyCard() {
    return _SectionCard(
      title: 'Kidney Function Test',
      icon: Icons.opacity_outlined,
      background: const Color(0xFFEAFBFD),
      accent: const Color(0xFF49B6C8),
      reportId: 'kidney',
      enabled: _selectedSections.contains('kidney'),
      onToggle: _toggleSection,
      chip: 'Used for: eGFR',
      onClear: () => _clearControllers([
        creatCtl,
        bloodUreaCtl,
        bunCtl,
        uricAcidCtl,
        sodiumCtl,
        potassiumCtl,
        chlorideCtl,
      ]),
      child: Column(
        children: [
          _unitField(
              creatCtl,
              'Creatinine',
              creatUnit,
              (value) => setState(() => creatUnit = value),
              const ['mg/dL', 'µmol/L'],
              helper: 'Found in: Kidney Function Test'),
          _twoColumn(
            _unitField(
              bloodUreaCtl,
              'Blood urea',
              bloodUreaUnit,
              (value) => setState(() => bloodUreaUnit = value),
              const ['mg/dL', 'mmol/L'],
              helper: 'Found in: Kidney Function Test',
            ),
            _unitField(
              bunCtl,
              'Urea nitrogen / BUN',
              bunUnit,
              (value) => setState(() => bunUnit = value),
              const ['mg/dL'],
              helper: 'Found in: Kidney Function Test',
            ),
          ),
          _twoColumn(
            _unitField(
              uricAcidCtl,
              'Uric acid',
              uricAcidUnit,
              (value) => setState(() => uricAcidUnit = value),
              const ['mg/dL', 'µmol/L'],
              helper: 'Found in: Kidney Function Test',
            ),
            _unitField(
              sodiumCtl,
              'Sodium',
              'mmol/L',
              (_) {},
              const ['mmol/L'],
              helper: 'Found in: Kidney Function Test',
            ),
          ),
          _twoColumn(
            _unitField(
              potassiumCtl,
              'Potassium',
              'mmol/L',
              (_) {},
              const ['mmol/L'],
              helper: 'Found in: Kidney Function Test',
            ),
            _unitField(
              chlorideCtl,
              'Chloride',
              'mmol/L',
              (_) {},
              const ['mmol/L'],
              helper: 'Found in: Kidney Function Test',
            ),
          ),
        ],
      ),
    );
  }

  Widget _vitalsCard() {
    return _SectionCard(
      title: 'Vitals',
      icon: Icons.speed_outlined,
      background: const Color(0xFFEAF7FF),
      accent: const Color(0xFF4BAFE3),
      reportId: 'vitals',
      enabled: _selectedSections.contains('vitals'),
      onToggle: _toggleSection,
      chip: 'Used for: BP, SpO₂, pulse support',
      onClear: () => _clearControllers([
        sysCtl,
        diaCtl,
        hrCtl,
        spo2Ctl,
        temperatureCtl,
        respiratoryRateCtl,
      ]),
      child: Column(
        children: [
          _twoColumn(
            _unitField(
              sysCtl,
              'Systolic BP',
              systolicUnit,
              (value) => setState(() => systolicUnit = value),
              const ['mmHg'],
              helper: 'Found in: Vitals',
            ),
            _unitField(
              diaCtl,
              'Diastolic BP',
              diastolicUnit,
              (value) => setState(() => diastolicUnit = value),
              const ['mmHg'],
              helper: 'Found in: Vitals',
            ),
          ),
          _twoColumn(
            _unitField(
              hrCtl,
              'Heart rate',
              heartRateUnit,
              (value) => setState(() => heartRateUnit = value),
              const ['bpm'],
              helper: 'Found in: Vitals',
            ),
            _unitField(
              spo2Ctl,
              'SpO₂',
              spo2Unit,
              (value) => setState(() => spo2Unit = value),
              const ['%'],
              helper: 'Measured using: Pulse oximeter',
            ),
          ),
          _twoColumn(
            _unitField(
              temperatureCtl,
              'Body temperature',
              temperatureUnit,
              (value) => setState(() => temperatureUnit = value),
              const ['°C', '°F'],
              helper: 'Found in: Vitals',
            ),
            _unitField(
              respiratoryRateCtl,
              'Respiratory rate',
              respiratoryRateUnit,
              (value) => setState(() => respiratoryRateUnit = value),
              const ['breaths/min'],
              helper: 'Found in: Vitals',
            ),
          ),
        ],
      ),
    );
  }

  Widget _pancreasCard() {
    return _SectionCard(
      title: 'Pancreatic Enzymes',
      icon: Icons.science_outlined,
      background: const Color(0xFFFFF0ED),
      accent: const Color(0xFFE18170),
      reportId: 'pancreas',
      enabled: _selectedSections.contains('pancreas'),
      onToggle: _toggleSection,
      chip: 'Used for: LAR',
      onClear: () => _clearControllers([lipaseCtl, amylaseCtl]),
      child: _twoColumn(
        _unitField(
          lipaseCtl,
          'Lipase',
          lipaseUnit,
          (value) => setState(() => lipaseUnit = value),
          const ['U/L'],
          helper: 'Found in: Pancreatic Enzymes Report',
        ),
        _unitField(
          amylaseCtl,
          'Amylase',
          amylaseUnit,
          (value) => setState(() => amylaseUnit = value),
          const ['U/L'],
          helper: 'Found in: Pancreatic Enzymes Report',
        ),
      ),
    );
  }

  Widget _cancerCard() {
    return _SectionCard(
      title: 'Cancer Awareness Markers',
      icon: Icons.health_and_safety_outlined,
      background: const Color(0xFFF3F2F8),
      accent: const Color(0xFF8B8FC7),
      reportId: 'cancer',
      enabled: _selectedSections.contains('cancer'),
      onToggle: _toggleSection,
      chip: 'Used for: awareness markers only',
      onClear: () => _clearControllers([afpCtl, ca15Ctl, ca27Ctl]),
      child: Column(
        children: [
          _unitField(
            afpCtl,
            'AFP',
            afpUnit,
            (value) => setState(() => afpUnit = value),
            const ['ng/mL'],
            helper: 'Found in: Tumor Marker Report',
          ),
          _twoColumn(
            _unitField(
              ca15Ctl,
              'CA 15-3',
              ca153Unit,
              (value) => setState(() => ca153Unit = value),
              const ['U/mL'],
              helper: 'Found in: Tumor Marker Report',
            ),
            _unitField(
              ca27Ctl,
              'CA 27.29',
              ca2729Unit,
              (value) => setState(() => ca2729Unit = value),
              const ['U/mL'],
              helper: 'Found in: Tumor Marker Report',
            ),
          ),
        ],
      ),
    );
  }

  Widget _heightField() {
    if (heightUnit == 'ft-in') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _numberField(
                    heightFeetCtl,
                    'Feet',
                    required: true,
                    unitSuffix: 'ft',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _numberField(
                    heightInchesCtl,
                    'Inches',
                    unitSuffix: 'in',
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 112,
                  child: _unitDropdown(
                    heightUnit,
                    const ['cm', 'ft-in'],
                    (value) => setState(() => heightUnit = value),
                  ),
                ),
              ],
            ),
            _fieldHelper('Self-reported', allowSkip: false),
          ],
        ),
      );
    }
    return _unitField(
      heightCtl,
      'Height',
      heightUnit,
      (value) => setState(() => heightUnit = value),
      const ['cm', 'ft-in'],
      helper: 'Self-reported',
      required: true,
      allowSkip: false,
    );
  }

  Widget _numberField(TextEditingController controller, String label,
      {bool required = false, String? unitSuffix}) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        suffixText: unitSuffix,
        suffixIcon: IconButton(
          tooltip: 'Unit help',
          icon: const Icon(Icons.info_outline, size: 18),
          onPressed: _showUnitInfo,
        ),
      ),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (required && text.isEmpty) {
          return 'Please enter a valid number.';
        }
        if (text.isEmpty) return null;
        final parsed = double.tryParse(text);
        if (parsed == null) {
          return 'Please enter a valid number.';
        }
        if (parsed < 0) {
          return 'This value seems unusually low. Please check the unit.';
        }
        if (parsed > 1000000) {
          return 'This value seems unusually high. Please check the unit.';
        }
        return null;
      },
    );
  }

  Widget _unitField(
    TextEditingController controller,
    String label,
    String unit,
    ValueChanged<String> onUnitChanged,
    List<String> units, {
    String? helper,
    bool required = false,
    bool allowSkip = true,
  }) {
    final hasAlternativeUnits = units.length > 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _numberField(controller, label, required: required),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 120,
                child: hasAlternativeUnits
                    ? _unitDropdown(unit, units, onUnitChanged)
                    : _fixedUnitLabel(units.first),
              ),
            ],
          ),
          _fieldHelper(helper, allowSkip: allowSkip, controller: controller),
        ],
      ),
    );
  }

  Widget _readOnlyUnitField(
    String label,
    String value,
    String unit, {
    String? helper,
  }) {
    final text = value.isEmpty ? 'Auto' : value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: ValueKey('$label-$text'),
                  initialValue: text,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: label,
                    suffixText: unit,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(width: 120, child: _fixedUnitLabel('Read-only')),
            ],
          ),
          _fieldHelper(helper, allowSkip: false),
        ],
      ),
    );
  }

  Widget _fixedUnitLabel(String unit) {
    return Container(
      height: 56,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FCFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppStyles.border),
      ),
      child: Text(
        unit,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppStyles.primary,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _unitDropdown(
    String unit,
    List<String> units,
    ValueChanged<String> onUnitChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: unit,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Unit'),
      items: units
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: (value) {
        if (value != null) onUnitChanged(value);
      },
    );
  }

  Widget _fieldHelper(String? helper,
      {bool allowSkip = true, TextEditingController? controller}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 2,
        children: [
          Text(
            helper ?? 'Select the unit exactly as shown in your report.',
            style: const TextStyle(color: AppStyles.muted, fontSize: 12),
          ),
          if (allowSkip && controller != null)
            TextButton.icon(
              onPressed: () => setState(() => controller.clear()),
              icon: const Icon(Icons.remove_circle_outline, size: 16),
              label: const Text("I don't have this value"),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  void _showUnitInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unit help'),
        content: const Text(
          'Select the unit exactly as shown in your report. The app converts it automatically.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
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
        validator: (choice) => choice == null
            ? 'Please complete the compulsory general health questions.'
            : null,
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
    return const VitalMapHeroCard(
      title: "Let's get to know you",
      subtitle: '',
      description:
          'Accurate details help us provide deeper organ-wise insights.',
      bottom: Column(
        children: [
          Row(
            children: [
              Text(
                'Step 1 of 3',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Spacer(),
              Text(
                '33% Complete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(999)),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: 0.33,
              backgroundColor: Colors.white24,
              color: AppStyles.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.background = Colors.white,
    this.accent = AppStyles.primary,
    String? reportId,
    bool enabled = true,
    void Function(String id, bool enabled)? onToggle,
    this.chip,
    this.onClear,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Color background;
  final Color accent;
  final String? chip;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 5,
            child: ColoredBox(color: accent.withValues(alpha: 0.85)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: accent.withValues(alpha: 0.16)),
                      ),
                      child: Icon(icon, color: accent, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: AppStyles.text),
                          ),
                          if (chip != null) ...[
                            const SizedBox(height: 6),
                            _SectionChip(label: chip!, color: accent),
                          ],
                        ],
                      ),
                    ),
                    if (onClear != null)
                      IconButton(
                        tooltip: 'Clear this section',
                        onPressed: onClear,
                        icon: Icon(Icons.cleaning_services_outlined,
                            color: accent),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionChip extends StatelessWidget {
  const _SectionChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
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
          color: selected ? section.background : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: selected ? section.accent : AppStyles.border),
          boxShadow: [
            BoxShadow(
              color: section.accent.withValues(alpha: selected ? 0.12 : 0.03),
              blurRadius: selected ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(section.icon,
                    color: selected ? section.accent : AppStyles.muted),
                const Spacer(),
                Icon(
                  selected ? Icons.check_circle : Icons.add_circle_outline,
                  color: selected ? section.accent : AppStyles.muted,
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
    required this.background,
    required this.accent,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color background;
  final Color accent;
}
