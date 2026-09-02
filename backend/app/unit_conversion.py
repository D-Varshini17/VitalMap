def _unit(unit: str | None) -> str:
    return (unit or "").strip().lower()


def glucose_to_mgdl(value, unit="mg/dL"):
    if value is None:
        return None
    if "mmol" in _unit(unit):
        return value * 18.0
    return value


def triglycerides_to_mgdl(value, unit="mg/dL"):
    if value is None:
        return None
    if "mmol" in _unit(unit):
        return value * 88.57
    return value


def cholesterol_to_mgdl(value, unit="mg/dL"):
    if value is None:
        return None
    if "mmol" in _unit(unit):
        return value * 38.67
    return value


def creatinine_to_mgdl(value, unit="mg/dL"):
    if value is None:
        return None
    normalized = _unit(unit)
    if "umol" in normalized or "µmol" in normalized:
        return value / 88.4
    return value


def bilirubin_to_mgdl(value, unit="mg/dL"):
    if value is None:
        return None
    normalized = _unit(unit)
    if "umol" in normalized or "µmol" in normalized:
        return value / 17.1
    return value


def albumin_to_gdl(value, unit="g/dL"):
    if value is None:
        return None
    if _unit(unit) == "g/l":
        return value / 10.0
    return value


def total_protein_to_gdl(value, unit="g/dL"):
    if value is None:
        return None
    if _unit(unit) == "g/l":
        return value / 10.0
    return value


def height_to_cm(value=None, unit="cm", feet=None, inches=None):
    if unit == "ft-in":
        if feet is None and inches is None:
            return None
        return (((feet or 0) * 12) + (inches or 0)) * 2.54
    if value is None:
        return None
    if "inch" in _unit(unit):
        return value * 2.54
    if "ft" in _unit(unit):
        return value * 30.48
    return value


def weight_to_kg(value, unit="kg"):
    if value is None:
        return None
    if _unit(unit) == "lb":
        return value * 0.453592
    return value


def waist_to_cm(value, unit="cm"):
    if value is None:
        return None
    if "inch" in _unit(unit):
        return value * 2.54
    return value


def temperature_to_c(value, unit="°C"):
    if value is None:
        return None
    normalized = _unit(unit)
    if normalized in ["°f", "f"]:
        return (value - 32.0) * 5.0 / 9.0
    return value


def platelets_to_10e9_l(value, unit="10⁹/L"):
    if value is None:
        return None
    normalized = _unit(unit)
    if "lakh" in normalized:
        return value * 100.0
    if "cells" in normalized:
        return value / 1000.0
    return value


def wbc_to_10e9_l(value, unit="10⁹/L"):
    if value is None:
        return None
    if "cells" in _unit(unit):
        return value / 1000.0
    return value


def blood_urea_to_mgdl(value, unit="mg/dL"):
    if value is None:
        return None
    if "mmol" in _unit(unit):
        return value * 6.006
    return value


def uric_acid_to_mgdl(value, unit="mg/dL"):
    if value is None:
        return None
    normalized = _unit(unit)
    if "umol" in normalized or "µmol" in normalized:
        return value / 59.48
    return value


def is_percent_unit(unit) -> bool:
    return "%" in _unit(unit)


def is_absolute_count_unit(unit) -> bool:
    normalized = _unit(unit)
    return "10" in normalized or "cells" in normalized


def absolute_count_to_10e9_l(value, unit):
    if value is None:
        return None
    if "cells" in _unit(unit):
        return value / 1000.0
    return value
