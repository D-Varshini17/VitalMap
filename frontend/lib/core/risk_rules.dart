class RiskRuleResult {
  const RiskRuleResult(this.level, this.color);

  final String level;
  final String color;
}

const lowConcern = 'Low Concern';
const monitor = 'Monitor';
const attentionNeeded = 'Attention Needed';
const moreDataNeeded = 'More Data Needed';

RiskRuleResult _low() => const RiskRuleResult(lowConcern, 'soft_green');
RiskRuleResult _monitor() => const RiskRuleResult(monitor, 'soft_amber');
RiskRuleResult _attention() =>
    const RiskRuleResult(attentionNeeded, 'soft_coral');
RiskRuleResult _more() => const RiskRuleResult(moreDataNeeded, 'soft_lavender');

RiskRuleResult aipRisk(double? value) {
  if (value == null) return _more();
  if (value <= 0.10) return _low();
  if (value <= 0.24) return _monitor();
  return _attention();
}

RiskRuleResult apriRisk(double? value) {
  if (value == null) return _more();
  if (value <= 0.5) return _low();
  if (value <= 1.5) return _monitor();
  return _attention();
}

RiskRuleResult fib4Risk(double? value) {
  if (value == null) return _more();
  if (value < 1.3) return _low();
  if (value <= 2.67) return _monitor();
  return _attention();
}

RiskRuleResult tygRisk(double? value) {
  if (value == null) return _more();
  if (value <= 4.5) return _low();
  return _attention();
}

RiskRuleResult nlrRisk(double? value) {
  if (value == null) return _more();
  if (value <= 3) return _low();
  if (value <= 9) return _monitor();
  return _attention();
}

RiskRuleResult spo2Risk(double? value) {
  if (value == null) return _more();
  if (value >= 95) return _low();
  if (value >= 90) return _monitor();
  return _attention();
}

RiskRuleResult egfrRisk(double? value) {
  if (value == null) return _more();
  if (value >= 90) return _low();
  if (value >= 60) return _monitor();
  return _attention();
}

RiskRuleResult tumorMarkerRisk(double? value, double cutoff) {
  if (value == null) return _more();
  if (value <= cutoff) return _low();
  return _attention();
}

RiskRuleResult larRisk(double? value) {
  if (value == null) return _more();
  if (value < 3) return _low();
  return _monitor();
}

RiskRuleResult fliRisk(double? value) {
  if (value == null) return _more();
  if (value < 30) return _low();
  if (value <= 60) return _monitor();
  return _attention();
}

RiskRuleResult nafldRisk(double? value) {
  if (value == null) return _more();
  if (value < -1.455) return _low();
  if (value <= 0.676) return _monitor();
  return _attention();
}

RiskRuleResult metabolicRisk({
  double? fasting,
  double? hba1c,
  double? ppbs,
  double? randomBloodSugar,
}) {
  final hasValue =
      [fasting, hba1c, ppbs, randomBloodSugar].any((value) => value != null);
  if (!hasValue) return _more();
  final high = (fasting != null && fasting >= 126) ||
      (hba1c != null && hba1c >= 6.5) ||
      (ppbs != null && ppbs >= 200) ||
      (randomBloodSugar != null && randomBloodSugar >= 200);
  if (high) return _attention();
  final moderate = (fasting != null && fasting >= 100) ||
      (hba1c != null && hba1c >= 5.7) ||
      (ppbs != null && ppbs >= 140) ||
      (randomBloodSugar != null && randomBloodSugar >= 140);
  if (moderate) return _monitor();
  return _low();
}

int severityRank(String? level) {
  final value = (level ?? '').toLowerCase();
  if (value.contains('attention') || value.startsWith('high')) return 3;
  if (value.contains('monitor') || value.startsWith('moderate')) return 2;
  if (value.contains('low') ||
      value.contains('optimal') ||
      value.contains('within awareness threshold')) {
    return 1;
  }
  return 0;
}

String overallRisk(Iterable<String?> levels) {
  final topRank = levels.fold<int>(
    0,
    (top, level) {
      final rank = severityRank(level);
      return rank > top ? rank : top;
    },
  );
  if (topRank >= 3) return attentionNeeded;
  if (topRank == 2) return monitor;
  if (topRank == 1) return lowConcern;
  return moreDataNeeded;
}
