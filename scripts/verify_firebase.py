"""Live release checks with disposable synthetic accounts. Never prints tokens."""
import json
import secrets
from pathlib import Path
import httpx

config = json.loads(Path('frontend/android/app/google-services.json').read_text())
key = config['client'][0]['api_key'][0]['current_key']
project = config['project_info']['project_id']
client = httpx.Client(timeout=30)
auth = 'https://identitytoolkit.googleapis.com/v1/accounts:'
base = f'https://firestore.googleapis.com/v1/projects/{project}/databases/(default)/documents/'
accounts = []
documents = []
results = {}

def post(action, payload):
    response = client.post(auth + action, params={'key': key}, json=payload)
    if response.status_code != 200:
        raise RuntimeError(f'{action}: HTTP {response.status_code}: ' + response.json().get('error', {}).get('message', 'request failed'))
    return response.json()

try:
    for _ in range(2):
        email = f'vitalmap-release-{secrets.token_hex(8)}@example.com'
        password = secrets.token_urlsafe(24)
        account = post('signUp', {'email': email, 'password': password, 'returnSecureToken': True})
        accounts.append(account)
        signed = post('signInWithPassword', {'email': email, 'password': password, 'returnSecureToken': True})
        assert signed['localId'] == account['localId']
    results['signup_login'] = True
    account = accounts[0]
    headers = {'Authorization': 'Bearer ' + account['idToken']}
    for suffix in ['', '/health_profile/current', '/lifestyle/current', '/environment/current', '/reports/current', '/screenings/release-check', '/symptoms/release-check', '/lab_scans/release-check']:
        path = 'users/' + account['localId'] + suffix
        response = client.patch(base + path, headers=headers, json={'fields': {'releaseCheck': {'booleanValue': True}}})
        assert response.status_code == 200, f'write {suffix}: HTTP {response.status_code}'
        documents.append((path, headers))
        assert client.get(base + path, headers=headers).status_code == 200
        assert client.get(base + path).status_code in (401, 403)
        other_headers = {'Authorization': 'Bearer ' + accounts[1]['idToken']}
        assert client.get(base + path, headers=other_headers).status_code == 403
    results['own_reads_writes_and_cross_user_denial'] = True
    refreshed = client.post('https://securetoken.googleapis.com/v1/token', params={'key': key}, data={'grant_type': 'refresh_token', 'refresh_token': account['refreshToken']})
    assert refreshed.status_code == 200
    results['session_refresh'] = True
except Exception as error:
    results['error'] = str(error)
finally:
    cleanup = True
    for path, headers in reversed(documents):
        try:
            cleanup &= client.delete(base + path, headers=headers).status_code in (200, 204)
        except Exception:
            cleanup = False
    for account in accounts:
        try:
            post('delete', {'idToken': account['idToken']})
        except Exception:
            cleanup = False
    results['synthetic_data_cleanup'] = cleanup
    Path('artifacts/firebase-verification.json').write_text(json.dumps(results, indent=2))
    print(json.dumps(results))
