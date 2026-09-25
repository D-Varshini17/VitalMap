import io
import json
from unittest.mock import patch

import pytest
from PIL import Image
from fastapi.testclient import TestClient

from backend.app.main import app, local_health_tools
from backend.app.local_health_tools import LocalHealthToolsError, LocalHealthToolsService


def test_confidence_and_qualified_numbers_are_not_upgraded():
    service = LocalHealthToolsService()
    assert service._confidence('low') == 'low'
    assert service._confidence(None) == 'low'
    assert service._as_number('<5') is None
    assert service._as_number(float('nan')) is None


@pytest.mark.parametrize('format', ['JPEG', 'PNG', 'WEBP'])
def test_image_optimization(format):
    stream = io.BytesIO()
    Image.new('RGB', (3000, 2200), 'white').save(stream, format=format)
    result = LocalHealthToolsService._optimize_image(stream.getvalue())
    with Image.open(io.BytesIO(result)) as image:
        assert max(image.size) <= 1280
        assert image.format == 'JPEG'


def test_invalid_image_is_useful_error():
    with pytest.raises(LocalHealthToolsError, match='invalid'):
        LocalHealthToolsService._optimize_image(b'not an image')


def test_truncated_model_output_is_not_silently_imported_or_retried():
    service = LocalHealthToolsService()
    payload = {'done_reason': 'length', 'message': {'content': '{"fields":[]}'}}
    with patch.object(service, '_installed_models', return_value=[service.text_model]), \
            patch('urllib.request.urlopen') as request:
        request.return_value.__enter__.return_value.read.return_value = json.dumps(payload).encode()
        with pytest.raises(LocalHealthToolsError, match='size limit'):
            service._chat_json(model=service.text_model, messages=[], num_predict=10)
        assert request.call_count == 1


def test_scanner_multipart_contract_and_service_error():
    with TestClient(app) as client:
        with patch.object(local_health_tools, 'scan_report', return_value={'fields': [], 'review_required': True}) as scan:
            response = client.post('/tools/lab-report/scan', files={'file': ('lab.png', b'image', 'image/png')})
            assert response.status_code == 200
            assert scan.call_args.kwargs['filename'] == 'lab.png'
        with patch.object(local_health_tools, 'scan_report', side_effect=LocalHealthToolsError('Model timeout', 504)):
            response = client.post('/tools/lab-report/scan', files={'file': ('lab.png', b'image', 'image/png')})
            assert response.status_code == 504
            assert response.json()['detail'] == 'Model timeout'
        assert client.post('/tools/lab-report/scan', files={'wrong': ('lab.png', b'image')}).status_code == 422


def test_extraction_schema_is_validated():
    with pytest.raises(LocalHealthToolsError, match='schema'):
        LocalHealthToolsService()._normalize_extraction({'fields': 'invalid'})


def test_pdf_text_and_render_pipeline():
    import pymupdf
    document = pymupdf.open()
    page = document.new_page()
    page.insert_text((72, 72), 'Fasting glucose 95 mg/dL')
    data = document.tobytes()
    document.close()
    assert '95 mg/dL' in LocalHealthToolsService._extract_pdf_text(data)
    assert len(LocalHealthToolsService._render_pdf_pages(data)) == 1


def test_deterministic_endpoints_do_not_call_ollama():
    with TestClient(app) as client, patch.object(local_health_tools, '_chat_json', side_effect=AssertionError('AI must not run')):
        payload = {'profile': {'age': 40, 'sex': 'Male', 'height_cm': 175, 'weight_kg': 75}}
        first = client.post('/analyze', json=payload)
        assert first.status_code == 200
        assert client.post('/predict', json=payload).json() == first.json()


def test_vision_transcription_precedes_field_extraction():
    service = LocalHealthToolsService()
    extracted = {'fields': [{'key': 'fasting_glucose', 'value': 95, 'unit': 'mg/dL', 'confidence': 'high'}]}
    with patch.object(service, '_local_image_text', return_value=None), patch.object(service, '_installed_models', return_value=[service.vision_model]), patch.object(service, '_optimize_image', return_value=b'image'), patch.object(service, '_chat_json', side_effect=[{'text': 'Fasting glucose 95 mg/dL'}, extracted]) as chat:
        result = service.scan_report(filename='lab.png', content_type='image/png', data=b'image')
        assert result['fields'][0]['value'] == 95
        assert chat.call_args_list[0].kwargs['model'] == service.vision_model
        assert chat.call_args_list[1].kwargs['model'] == service.text_model
        assert 'Fasting glucose 95 mg/dL' in chat.call_args_list[1].kwargs['messages'][1]['content']


def test_local_ocr_uses_text_model_and_requires_explicit_review():
    service = LocalHealthToolsService()
    extracted = {'fields': [{'key': 'fasting_glucose', 'value': 95, 'unit': 'mg/dL', 'confidence': 'high'}]}
    with patch.object(service, '_local_image_text', return_value='Fasting glucose 95 mg/dL'), \
            patch.object(service, '_extract_from_text', return_value=extracted) as extract, \
            patch.object(service, '_installed_models', side_effect=AssertionError('Vision must not run')):
        result = service.scan_report(filename='lab.png', content_type='image/png', data=b'image')
        extract.assert_called_once_with('Fasting glucose 95 mg/dL')
        assert result['mode'] == 'local_ocr'
        assert result['fields'][0]['confidence'] == 'medium'
        assert result['review_required'] is True


def test_pdf_page_limit_is_explicit():
    import pymupdf
    with pymupdf.open() as document:
        for _ in range(4):
            document.new_page()
        with pytest.raises(LocalHealthToolsError, match='3 pages'):
            LocalHealthToolsService._extract_pdf_text(document.tobytes())
