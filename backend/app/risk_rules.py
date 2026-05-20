from math import isnan


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
        return "Low", "green"
    if 90 <= spo2 < 95:
        return "Moderate", "yellow"
    return "High", "red"


def lar_rule(lar):
    if lar is None:
        return "More Data Needed", "grey"
    if lar < 3:
        return "Pattern may suggest non-alcohol related triggers", "green"
    return "Pattern may suggest alcohol-related pattern", "yellow"


def egfr_rule(egfr):
    if egfr is None:
        return "More Data Needed", "grey"
    if egfr >= 90:
        return "Low concern", "green"
    if egfr >= 60:
        return "Moderate monitoring suggested", "yellow"
    return "High attention needed", "red"
