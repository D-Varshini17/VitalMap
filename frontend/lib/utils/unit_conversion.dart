double? glucoseToMgdl(double? value, String unit) {
  if (value == null) return null;
  if (_unit(unit).contains('mmol')) return value * 18.0;
  return value;
}

double? triglyceridesToMgdl(double? value, String unit) {
  if (value == null) return null;
  if (_unit(unit).contains('mmol')) return value * 88.57;
  return value;
}

double? cholesterolToMgdl(double? value, String unit) {
  if (value == null) return null;
  if (_unit(unit).contains('mmol')) return value * 38.67;
  return value;
}

double? creatinineToMgdl(double? value, String unit) {
  if (value == null) return null;
  if (_unit(unit).contains('umol') || _unit(unit).contains('µmol')) {
    return value / 88.4;
  }
  return value;
}

double? bilirubinToMgdl(double? value, String unit) {
  if (value == null) return null;
  if (_unit(unit).contains('umol') || _unit(unit).contains('µmol')) {
    return value / 17.1;
  }
  return value;
}

double? albuminToGdl(double? value, String unit) {
  if (value == null) return null;
  if (_unit(unit) == 'g/l') return value / 10.0;
  return value;
}

double? totalProteinToGdl(double? value, String unit) {
  if (value == null) return null;
  if (_unit(unit) == 'g/l') return value / 10.0;
  return value;
}

double? heightToCm(double? value, String unit) {
  if (value == null) return null;
  if (_unit(unit).contains('inch')) return value * 2.54;
  if (_unit(unit).contains('ft')) return value * 30.48;
  return value;
}

double? heightFeetInchesToCm(double? feet, double? inches) {
  if (feet == null && inches == null) return null;
  final totalInches = ((feet ?? 0) * 12) + (inches ?? 0);
  return totalInches * 2.54;
}

double? weightToKg(double? value, String unit) {
  if (value == null) return null;
  if (_unit(unit) == 'lb') return value * 0.453592;
  return value;
}

double? waistToCm(double? value, String unit) {
  if (value == null) return null;
  if (_unit(unit).contains('inch')) return value * 2.54;
  return value;
}

double? temperatureToC(double? value, String unit) {
  if (value == null) return null;
  if (_unit(unit) == '°f' || _unit(unit) == 'f') {
    return (value - 32.0) * 5.0 / 9.0;
  }
  return value;
}

double? plateletsTo10e9L(double? value, String unit) {
  if (value == null) return null;
  final normalized = _unit(unit);
  if (normalized.contains('lakh')) return value * 100.0;
  if (normalized.contains('cells')) return value / 1000.0;
  return value;
}

double? wbcTo10e9L(double? value, String unit) {
  if (value == null) return null;
  if (_unit(unit).contains('cells')) return value / 1000.0;
  return value;
}

double? bloodUreaToMgdl(double? value, String unit) {
  if (value == null) return null;
  if (_unit(unit).contains('mmol')) return value * 6.006;
  return value;
}

double? uricAcidToMgdl(double? value, String unit) {
  if (value == null) return null;
  if (_unit(unit).contains('umol') || _unit(unit).contains('µmol')) {
    return value / 59.48;
  }
  return value;
}

double? electrolyteToMmolL(double? value, String unit) {
  if (value == null) return null;
  return value;
}

double? absoluteCountTo10e9L(double? value, String unit) {
  if (value == null) return null;
  if (_unit(unit).contains('cells')) return value / 1000.0;
  return value;
}

bool isAbsoluteCountUnit(String unit) {
  final normalized = _unit(unit);
  return normalized.contains('10') || normalized.contains('cells');
}

bool isPercentUnit(String unit) => _unit(unit).contains('%');

String _unit(String unit) => unit.trim().toLowerCase();
