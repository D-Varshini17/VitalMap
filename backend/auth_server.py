from flask import Flask, request, jsonify
from werkzeug.security import generate_password_hash, check_password_hash
import json
from pathlib import Path

app = Flask(__name__)
DATA_FILE = Path(__file__).parent / 'users.json'

def load_db():
    if not DATA_FILE.exists():
        return {}
    try:
        return json.loads(DATA_FILE.read_text())
    except Exception:
        return {}

def save_db(db):
    DATA_FILE.write_text(json.dumps(db))

@app.route('/register', methods=['POST'])
def register():
    data = request.get_json() or {}
    email = (data.get('email') or '').strip().lower()
    password = data.get('password') or ''
    if not email or not password or len(password) < 6:
        return jsonify(success=False, message='Invalid email or password'), 200
    db = load_db()
    if email in db:
        return jsonify(success=False, message='User already exists'), 200
    db[email] = generate_password_hash(password)
    save_db(db)
    return jsonify(success=True, message='Registered successfully'), 200

@app.route('/login', methods=['POST'])
def login():
    data = request.get_json() or {}
    email = (data.get('email') or '').strip().lower()
    password = data.get('password') or ''
    db = load_db()
    pw_hash = db.get(email)
    if pw_hash and check_password_hash(pw_hash, password):
        return jsonify(success=True, message='Login success'), 200
    return jsonify(success=False, message='Invalid credentials'), 200

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5000)
