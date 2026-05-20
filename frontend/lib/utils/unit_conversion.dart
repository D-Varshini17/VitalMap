double? glucoseToMgdl(double? value, String unit) {
  if (value == null) return null;
  if (unit.toLowerCase() == 'mmol/l') return value * 18.0;
  return value;
}

double? triglyceridesToMgdl(double? value, String unit) {
  if (value == null) return null;
  if (unit.toLowerCase() == 'mmol/l') return value * 88.57;
  return value;
}

double? creatinineToMgdl(double? value, String unit) {
  if (value == null) return null;
  if (unit.toLowerCase().contains('umol') ||
      unit.toLowerCase().contains('µmol')) return value / 88.4;
  return value;
}
