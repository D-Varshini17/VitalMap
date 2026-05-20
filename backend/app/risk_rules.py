def aip_risk(aip):
    if aip is None:
        return "More Data Needed", "grey"
    if aip <= 0.10:
        return "Low", "green"
    if aip <= 0.24:
        return "Moderate", "yellow"
    return "High", "red"


def apri_risk(apri):
    if apri is None:
        return "More Data Needed", "grey"
    if apri <= 0.5:
        return "Low", "green"
    if apri <= 1.5:
        return "Moderate", "yellow"
    return "High", "red"


def fib4_risk(fib4):
    if fib4 is None:
        return "More Data Needed", "grey"
    if fib4 < 1.3:
        return "Low", "green"
    if fib4 <= 2.67:
        return "Moderate", "yellow"
    return "High", "red"


def tyg_risk(tyg):
    if tyg is None:
        return "More Data Needed", "grey"
    if tyg <= 4.5:
        return "Low", "green"
    return "High", "red"


def nlr_risk(nlr):
    if nlr is None:
        return "More Data Needed", "grey"
    if nlr <= 3:
        return "Low", "green"
    if nlr <= 9:
        return "Moderate", "yellow"
    return "High", "red"


def spO2_risk(spo2):
    if spo2 is None:
        return "More Data Needed", "grey"
    if spo2 >= 95:
        return "Low concern", "green"
    if 90 <= spo2 < 95:
        return "Moderate monitoring suggested", "yellow"
    return "High attention needed", "red"


def lar_rule(lar):
    if lar is None:
        return "More Data Needed", "grey"
    if lar < 3:
        return "Low", "green"
    return "Moderate", "yellow"


def egfr_rule(egfr):
    if egfr is None:
        return "More Data Needed", "grey"
    if egfr >= 90:
        return "Low concern", "green"
    if egfr >= 60:
        return "Moderate monitoring suggested", "yellow"
    return "High attention needed / clinical review suggested", "red"


def fli_risk(fli):
    if fli is None:
        return "More Data Needed", "grey"
    if fli < 30:
        return "Low", "green"
    if fli <= 60:
        return "Moderate", "yellow"
    return "High", "red"


def nafld_risk(score):
    if score is None:
        return "More Data Needed", "grey"
    if score < -1.455:
        return "Low", "green"
    if score <= 0.676:
        return "Moderate", "yellow"
    return "High", "red"


def metabolic_risk(fasting=None, hba1c=None, ppbs=None, random_blood_sugar=None):
    values = [v for v in [fasting, hba1c, ppbs, random_blood_sugar] if v is not None]
    if not values:
        return "More Data Needed", "grey"
    high = (
        (fasting is not None and fasting >= 126)
        or (hba1c is not None and hba1c >= 6.5)
        or (ppbs is not None and ppbs >= 200)
        or (random_blood_sugar is not None and random_blood_sugar >= 200)
    )
    moderate = (
        (fasting is not None and fasting >= 100)
        or (hba1c is not None and hba1c >= 5.7)
        or (ppbs is not None and ppbs >= 140)
        or (random_blood_sugar is not None and random_blood_sugar >= 140)
    )
    if high:
        return "High", "red"
    if moderate:
        return "Moderate", "yellow"
    return "Low", "green"


def tumor_marker_risk(value, low_cutoff):
    if value is None:
        return "More Data Needed", "grey"
    if value <= low_cutoff:
        return "Low / within awareness threshold", "green"
    return "High awareness indicator; clinical review suggested", "red"
