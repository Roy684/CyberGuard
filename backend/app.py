from flask import Flask, request, jsonify
import requests
import firebase_admin
from firebase_admin import credentials, auth
from flask_cors import CORS
import os


app = Flask(__name__)
CORS(app, resources={r"/*": {
    "origins": ["http://localhost:*", "http://192.168.*"], 
    "allow_headers": ["Authorization", "Content-Type"]}})  
# Initialize Firebase Admin SDK
cred_path = os.path.abspath("firebase-admin-sdk.json")
cred = credentials.Certificate(cred_path)
firebase_admin.initialize_app(cred)

FACT_CHECK_API_KEY = "API_KEY"

def check_fact(text):
    url = f"https://factchecktools.googleapis.com/v1alpha1/claims:search?query={text}&key={FACT_CHECK_API_KEY}"
    response = requests.get(url)
    data = response.json()
    return {
        "is_fake": len(data.get("claims", [])) > 0,
        "claims": data.get("claims", [])
    }

@app.route("/check_news", methods=["POST"])
def check_news():
    data = request.json
    text = data.get("text", "")
    id_token = request.headers.get("Authorization")

    if not text:
        return jsonify({"error": "No text provided"}), 400
    
    if not id_token:
        return jsonify({"error": "Missing Firebase token"}), 401

    try:
        decoded_token = auth.verify_id_token(id_token)
        uid = decoded_token["uid"]
    except Exception as e:
        return jsonify({"error": f"Invalid Firebase token: {e}"}), 401

    result = check_fact(text)
    return jsonify({"uid": uid, "result": result})

@app.route('/register', methods=['POST', 'OPTIONS'])
def register():
    if request.method == 'OPTIONS':
        return _build_cors_preflight_response()
    
    try:
        id_token = request.headers.get('Authorization')

        if not id_token:
            return jsonify({'error': 'Missing token'}), 401
        
        # Verify Firebase token
        decoded_token = auth.verify_id_token(id_token)
        uid = decoded_token['uid']
        
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No data provided'}), 400
            
        email = data.get('email')
        password = data.get('password')
        name = data.get('name')
        
        if not all([email, password, name]):
            return jsonify({'error': 'Missing required fields'}), 400

        # Create user in Firebase
        user = auth.create_user(
            email=email,
            password=password,
            display_name=name
        )
        
        return jsonify({
            'message': 'Registration successful',
            'uid': user.uid
        }), 200
        
    except auth.EmailAlreadyExistsError:
        return jsonify({'error': 'Email already in use'}), 400
    except auth.ExpiredIdTokenError:
        return jsonify({'error': 'Expired token'}), 401
    except auth.RevokedIdTokenError:
        return jsonify({'error': 'Revoked token'}), 401
    except auth.CertificateFetchError:
        return jsonify({'error': 'Certificate error'}), 401
    except ValueError as e:
        return jsonify({'error': str(e)}), 400
    except Exception as e:
        return jsonify({'error': 'Registration failed: ' + str(e)}), 400

@app.route('/login', methods=['POST', 'OPTIONS'])
def login():
    if request.method == 'OPTIONS':
        return _build_cors_preflight_response()
    
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No data provided'}), 400
            
        email = data.get('email')
        password = data.get('password')
        
        if not all([email, password]):
            return jsonify({'error': 'Missing email or password'}), 400

        # Verify user with Firebase
        user = auth.get_user_by_email(email)
        # Note: In production, you should verify the password properly
        
        return jsonify({
            'message': 'Login successful',
            'uid': user.uid
        }), 200
        
    except auth.UserNotFoundError:
        return jsonify({'error': 'User not found'}), 401
    except Exception as e:
        return jsonify({'error': 'Login failed: ' + str(e)}), 401
    
@app.route('/protected-route')
def protected():
    id_token = request.headers.get('Authorization')
    if not id_token:
        return jsonify({'error': 'Unauthorized'}), 401
    
    try:
        decoded_token = auth.verify_id_token(id_token)
        uid = decoded_token['uid']
        # Proceed with your logic
    except Exception as e:
        return jsonify({'error': str(e)}), 401
    
    
def _build_cors_preflight_response():
    response = jsonify({"message": "OK"})
    response.headers.add("Access-Control-Allow-Origin", "*")
    response.headers.add("Access-Control-Allow-Methods", "POST, OPTIONS")
    response.headers.add("Access-Control-Allow-Headers", "Content-Type, Authorization")
    return response

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)

 
