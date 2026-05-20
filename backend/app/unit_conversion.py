def glucose_to_mgdl(value, unit="mg/dL"):
    if value is None:
        return None
    if unit.lower() in ["mmol/l", "mmol"]:
        return value * 18.0
    return value


def triglycerides_to_mgdl(value, unit="mg/dL"):
    if value is None:
        return None
    if unit.lower() in ["mmol/l", "mmol"]:
        return value * 88.57
    return value


def cholesterol_to_mgdl(value, unit="mg/dL"):
    if value is None:
        return None
    if unit.lower() in ["mmol/l", "mmol"]:
        return value * 38.67
    return value


def creatinine_to_mgdl(value, unit="mg/dL"):
    if value is None:
        return None
    if unit.lower() in ["umol/l", "µmol/l", "umol"]:
        return value / 88.4
    return value
