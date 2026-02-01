#!/usr/bin/env python3
import os
import json
import hashlib
import logging
from flask import Flask, request, jsonify, abort
from functools import wraps
from datetime import datetime

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

def require_api_key(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        api_key = request.headers.get('X-API-Key')
        expected_key = os.getenv('MOMO_API_KEY', '')
        
        if not api_key or api_key != expected_key:
            logger.warning(f"Unauthorized access attempt from {request.remote_addr}")
            abort(401, description='Invalid API Key')
        return f(*args, **kwargs)
    return decorated

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({
        'status': 'healthy',
        'service': 'MoMo Payment Gateway',
        'version': '1.0.0',
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/api/v1/initiate-payment', methods=['POST'])
@require_api_key
def initiate_payment():
    try:
        data = request.get_json()
        
        if not data or 'amount' not in data or 'customer_id' not in data:
            return jsonify({'error': 'Missing required fields: amount and customer_id'}), 400
        
        amount = float(data['amount'])
        if amount <= 0:
            return jsonify({'error': 'Amount must be positive'}), 400
        
        merchant_id = os.getenv('MOMO_MERCHANT_ID', '')
        api_secret = os.getenv('MOMO_API_SECRET', '')
        
        logger.info(f'Payment initiated: ${amount:.2f} for customer {data["customer_id"][:3]}***')
        
        import uuid
        import time
        
        transaction_id = f"MO{str(uuid.uuid4())[:8].upper()}"
        
        signature_data = f"{amount}{data['customer_id']}{merchant_id}{int(time.time())}"
        signature = hashlib.sha256(signature_data.encode()).hexdigest()[:16].upper()
        
        status = "PENDING"
        if amount < 1000:
            status = "COMPLETED"
        
        return jsonify({
            'status': 'success',
            'transaction_id': transaction_id,
            'reference': signature,
            'amount': amount,
            'currency': 'XAF',
            'payment_status': status,
            'message': 'Payment initiated successfully',
            'timestamp': datetime.utcnow().isoformat(),
            'merchant_id': merchant_id[:3] + "***"
        })
        
    except ValueError:
        return jsonify({'error': 'Invalid amount format'}), 400
    except Exception as e:
        logger.error(f"Payment initiation error: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/api/v1/check-status/<transaction_id>', methods=['GET'])
@require_api_key
def check_status(transaction_id):
    return jsonify({
        'transaction_id': transaction_id,
        'status': 'COMPLETED',
        'checked_at': datetime.utcnow().isoformat()
    })

@app.route('/api/v1/config', methods=['GET'])
def get_config():
    return jsonify({
        'service': 'MoMo Payment Gateway',
        'version': '1.0.0',
        'environment': os.getenv('ENVIRONMENT', 'development'),
        'api_url': os.getenv('MOMO_API_URL', 'https://sandbox.momo.example.com'),
        'log_level': os.getenv('LOG_LEVEL', 'info'),
        'max_amount': os.getenv('MAX_AMOUNT', '1000000'),
        'currency': 'XAF',
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/api/v1/validate-secret', methods=['GET'])
@require_api_key
def validate_secret():
    api_key = os.getenv('MOMO_API_KEY', '')
    api_secret = os.getenv('MOMO_API_SECRET', '')
    merchant_id = os.getenv('MOMO_MERCHANT_ID', '')
    
    return jsonify({
        'secrets_loaded': bool(api_key and api_secret and merchant_id),
        'api_key_present': bool(api_key),
        'api_secret_present': bool(api_secret),
        'merchant_id_present': bool(merchant_id),
        'api_key_ends_with': '***' + api_key[-4:] if api_key else 'N/A',
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/api/v1/version', methods=['GET'])
def version():
    return jsonify({
        'name': 'MoMo Payment Gateway API',
        'version': '1.0.0',
        'description': 'Secure payment processing with MoMo',
        'author': 'Ngomse-hub'
    })

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Not found'}), 404

@app.errorhandler(401)
def unauthorized(error):
    return jsonify({'error': 'Unauthorized - Invalid API Key'}), 401

@app.errorhandler(500)
def internal_error(error):
    logger.error(f"Internal server error: {str(error)}")
    return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    port = int(os.getenv('PORT', 8080))
    debug = os.getenv('FLASK_DEBUG', 'false').lower() == 'true'
    app.run(host='0.0.0.0', port=port, debug=debug)
