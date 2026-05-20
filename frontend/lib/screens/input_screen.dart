import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../widgets/disclaimer.dart';
import '../storage/local_storage.dart';

class InputScreen extends StatefulWidget {
  @override
  _InputScreenState createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _formKey = GlobalKey<FormState>();

  // Profile
  final ageCtl = TextEditingController();
  String sex = 'Male';
  final heightCtl = TextEditingController();
  final weightCtl = TextEditingController();
  final waistCtl = TextEditingController();

  // Vitals
  final sysCtl = TextEditingController();
  final diaCtl = TextEditingController();
  final hrCtl = TextEditingController();
  final spo2Ctl = TextEditingController();

  // Lipids
  final tgCtl = TextEditingController();
  String tgUnit = 'mg/dL';
  final hdlCtl = TextEditingController();
  String hdlUnit = 'mg/dL';

  // Diabetes
  final fastingCtl = TextEditingController();
  String glucoseUnit = 'mg/dL';
  final hba1cCtl = TextEditingController();

  // Liver
  final astCtl = TextEditingController();
  final altCtl = TextEditingController();
  final ggtCtl = TextEditingController();

  // CBC
  final plateletsCtl = TextEditingController();
  final neutCtl = TextEditingController();
  final lymphCtl = TextEditingController();

  // Kidney
  final creatCtl = TextEditingController();
  String creatUnit = 'mg/dL';

  // Pancreas
  final lipaseCtl = TextEditingController();
  final amylaseCtl = TextEditingController();

  // Tumor
  final afpCtl = TextEditingController();
  final ca15Ctl = TextEditingController();
  final ca27Ctl = TextEditingController();

  bool loading = false;

  void analyze() async {
    setState(() => loading = true);
    final payload = {
      "profile": {
        "age": ageCtl.text.isEmpty ? null : int.tryParse(ageCtl.text),
        "sex": sex,
        "height_cm": heightCtl.text.isEmpty ? null : double.tryParse(heightCtl.text),
        "weight_kg": weightCtl.text.isEmpty ? null : double.tryParse(weightCtl.text),
        "waist_cm": waistCtl.text.isEmpty ? null : double.tryParse(waistCtl.text),
      },
      "vitals": {
        "systolic": sysCtl.text.isEmpty ? null : double.tryParse(sysCtl.text),
        "diastolic": diaCtl.text.isEmpty ? null : double.tryParse(diaCtl.text),
        "heart_rate": hrCtl.text.isEmpty ? null : int.tryParse(hrCtl.text),
        "spo2": spo2Ctl.text.isEmpty ? null : double.tryParse(spo2Ctl.text),
      },
      "lipid_profile": {
        "triglycerides": tgCtl.text.isEmpty ? null : double.tryParse(tgCtl.text),
        "triglycerides_unit": tgUnit,
        "hdl": hdlCtl.text.isEmpty ? null : double.tryParse(hdlCtl.text),
        "hdl_unit": hdlUnit,
      },
      "diabetes_profile": {
        "fasting_glucose": fastingCtl.text.isEmpty ? null : double.tryParse(fastingCtl.text),
        "fasting_glucose_unit": glucoseUnit,
        "hba1c": hba1cCtl.text.isEmpty ? null : double.tryParse(hba1cCtl.text),
      },
      "liver_function": {
        "ast": astCtl.text.isEmpty ? null : double.tryParse(astCtl.text),
        "alt": altCtl.text.isEmpty ? null : double.tryParse(altCtl.text),
        "ggt": ggtCtl.text.isEmpty ? null : double.tryParse(ggtCtl.text),
      },
      "cbc": {
        "platelets": plateletsCtl.text.isEmpty ? null : double.tryParse(plateletsCtl.text),
        "neutrophils": neutCtl.text.isEmpty ? null : double.tryParse(neutCtl.text),
        "lymphocytes": lymphCtl.text.isEmpty ? null : double.tryParse(lymphCtl.text),
      },
      "kidney_function": {
        "creatinine": creatCtl.text.isEmpty ? null : double.tryParse(creatCtl.text),
        "creatinine_unit": creatUnit,
      },
      "pancreatic_enzymes": {
        "lipase": lipaseCtl.text.isEmpty ? null : double.tryParse(lipaseCtl.text),
        "amylase": amylaseCtl.text.isEmpty ? null : double.tryParse(amylaseCtl.text),
      },
      "tumor_markers": {
        "afp": afpCtl.text.isEmpty ? null : double.tryParse(afpCtl.text),
        "ca15_3": ca15Ctl.text.isEmpty ? null : double.tryParse(ca15Ctl.text),
        "ca27_29": ca27Ctl.text.isEmpty ? null : double.tryParse(ca27Ctl.text),
      },
    };
    // persist last payload
    await LocalStorage.saveLastPayload(payload);

    final resp = await ApiService.analyze(payload);
    setState(() => loading = false);
    if (resp == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unable to analyze right now. Please check your connection or try again.')));
      return;
    }
    // store response and navigate to results
    await LocalStorage.saveLastResponse(resp);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ResultsScreen.fromResponse(resp)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Row(children: [
            Image.asset('assets/logo.png', width: 36, height: 36, errorBuilder: (c, e, s) => SizedBox(width: 36, height: 36)),
            SizedBox(width: 8),
            Text('Input')
          ]),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Profile Details', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Row(children: [
                          Expanded(child: TextFormField(controller: ageCtl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Age'))),
                          SizedBox(width: 8),
                          DropdownButton<String>(value: sex, items: ['Male', 'Female', 'Other'].map((s) => DropdownMenuItem(child: Text(s), value: s)).toList(), onChanged: (v) => setState(() => sex = v!)),
                        ]),
                        TextFormField(controller: heightCtl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Height (cm)')),
                        TextFormField(controller: weightCtl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Weight (kg)')),
                        TextFormField(controller: waistCtl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Waist circumference (cm)')),
                        SizedBox(height: 6),
                        Text('BMI is calculated automatically from height and weight.'),
                      ],
                    ),
                  ),
                ),

                // Vitals
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Vitals', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextFormField(controller: sysCtl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Systolic BP')),
                      TextFormField(controller: diaCtl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Diastolic BP')),
                      TextFormField(controller: hrCtl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Heart rate')),
                      TextFormField(controller: spo2Ctl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'SpO2 (%)')),
                    ]),
                  ),
                ),

                // Lipid Profile
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Lipid Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                      Row(children: [
                        Expanded(child: TextFormField(controller: tgCtl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Triglycerides'))),
                        SizedBox(width: 8),
                        DropdownButton<String>(value: tgUnit, items: ['mg/dL', 'mmol/L'].map((s) => DropdownMenuItem(child: Text(s), value: s)).toList(), onChanged: (v) => setState(() => tgUnit = v!)),
                      ]),
                      Row(children: [
                        Expanded(child: TextFormField(controller: hdlCtl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'HDL'))),
                        SizedBox(width: 8),
                        DropdownButton<String>(value: hdlUnit, items: ['mg/dL', 'mmol/L'].map((s) => DropdownMenuItem(child: Text(s), value: s)).toList(), onChanged: (v) => setState(() => hdlUnit = v!)),
                      ]),
                    ]),
                  ),
                ),

                // Diabetes
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Diabetes / Glucose Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                      Row(children: [
                        Expanded(child: TextFormField(controller: fastingCtl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Fasting glucose'))),
                        SizedBox(width: 8),
                        DropdownButton<String>(value: glucoseUnit, items: ['mg/dL', 'mmol/L'].map((s) => DropdownMenuItem(child: Text(s), value: s)).toList(), onChanged: (v) => setState(() => glucoseUnit = v!)),
                      ]),
                      TextFormField(controller: hba1cCtl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'HbA1c')),
                    ]),
                  ),
                ),

                // Liver
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Liver Function Test', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextFormField(controller: astCtl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'AST')),
                      TextFormField(controller: altCtl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'ALT')),
                      TextFormField(controller: ggtCtl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'GGT')),
                    ]),
                  ),
                ),

                // CBC
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('CBC / Differential Count', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextFormField(controller: plateletsCtl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Platelets (10^9/L)')),
                      TextFormField(controller: neutCtl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Neutrophils (%)')),
                      TextFormField(controller: lymphCtl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Lymphocytes (%)')),
                    ]),
                  ),
                ),

                // Kidney
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Kidney Function Test', style: TextStyle(fontWeight: FontWeight.bold)),
                      Row(children: [
                        Expanded(child: TextFormField(controller: creatCtl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Creatinine'))),
                        SizedBox(width: 8),
                        DropdownButton<String>(value: creatUnit, items: ['mg/dL', 'µmol/L'].map((s) => DropdownMenuItem(child: Text(s), value: s)).toList(), onChanged: (v) => setState(() => creatUnit = v!)),
                      ]),
                    ]),
                  ),
                ),

                // Pancreas
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Pancreatic Enzymes', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextFormField(controller: lipaseCtl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Lipase')),
                      TextFormField(controller: amylaseCtl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Amylase')),
                    ]),
                  ),
                ),

                // Tumor markers
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Tumor Markers', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextFormField(controller: afpCtl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'AFP')),
                      TextFormField(controller: ca15Ctl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'CA 15-3')),
                      TextFormField(controller: ca27Ctl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'CA 27.29')),
                    ]),
                  ),
                ),

                SizedBox(height: 12),
                ElevatedButton(onPressed: loading ? null : analyze, child: loading ? CircularProgressIndicator() : Text('Analyze Available Values')),
                SizedBox(height: 12),
                DisclaimerWidget(),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
