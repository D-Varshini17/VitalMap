"""Exercise actual Ollama with synthetic report data; no patient records."""
import io
import json
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from backend.app.local_health_tools import LocalHealthToolsService
from backend.app.formulas import FormulaEngine
from PIL import Image, ImageDraw, ImageFont
import pymupdf

service = LocalHealthToolsService()
results = {}

def check(name, operation):
    started = time.monotonic()
    try:
        value = operation()
        if name in {'text_pdf', 'jpeg', 'png', 'scanned_pdf'}:
            fields = {item['key']: item for item in value['fields']}
            assert fields.get('fasting_glucose', {}).get('value') == 95, 'Expected fasting glucose 95 was not extracted'
            assert fields.get('hdl', {}).get('value') == 50, 'Expected HDL 50 was not extracted'
            assert all(item['unit'] == 'mg/dL' for item in fields.values()), 'Printed units did not match'
        results[name] = {'ok': True, 'seconds': round(time.monotonic() - started, 1), 'response': value}
    except Exception as error:
        results[name] = {'ok': False, 'error': str(error)}
    Path('artifacts/local-ai-verification.json').write_text(json.dumps(results, indent=2), encoding='utf-8')
    print(name, results[name]['ok'], flush=True)

check('status', service.status)
screening, _, _ = FormulaEngine().analyze({'lipid_profile': {'triglycerides': 100, 'hdl': 50}})
metric = next(item for item in screening if item['index_name'] == 'AIP')
metric['display_name'] = 'Atherogenic Index of Plasma'
check('guidance', lambda: service.metric_guidance({'metric': metric}))
document = pymupdf.open()
page = document.new_page()
page.insert_text((72, 72), 'SYNTHETIC LAB REPORT\nFasting glucose: 95 mg/dL\nHDL cholesterol: 50 mg/dL', fontsize=18)
pdf = document.tobytes()
check('text_pdf', lambda: service.scan_report(filename='synthetic.pdf', content_type='application/pdf', data=pdf))
image = Image.new('RGB', (1100, 500), 'white')
draw = ImageDraw.Draw(image)
font = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 36)
draw.multiline_text((40, 40), 'SYNTHETIC LAB REPORT\nFasting glucose: 95 mg/dL\nHDL cholesterol: 50 mg/dL', fill='black', font=font, spacing=25)
for fmt in ['JPEG', 'PNG']:
    stream = io.BytesIO()
    image.save(stream, format=fmt)
    data = stream.getvalue()
    check(fmt.lower(), lambda: service.scan_report(filename='synthetic.' + fmt.lower(), content_type='image/' + fmt.lower(), data=data))
scanned = pymupdf.open()
scanned.new_page().insert_image(pymupdf.Rect(20, 20, 570, 270), stream=data)
check('scanned_pdf', lambda: service.scan_report(filename='scanned.pdf', content_type='application/pdf', data=scanned.tobytes()))
raise SystemExit(not all(item['ok'] for item in results.values()))
