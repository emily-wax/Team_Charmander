from firebase_admin import initialize_app, credentials, firestore
from flask import Flask, request, jsonify

# Initialize Firebase app
# cred = credentials.Certificate('path/to/serviceAccountKey.json')
# initialize_app(cred)


db = firestore.client()

app = Flask(__name__)

@app.route('/claimAppliance', methods=['POST'])
def claim_appliance():
    try:
        # Extract data from the request (e.g., user ID, appliance ID)
        request_data = request.json
        user_id = request_data.get('userId')
        appliance_id = request_data.get('applianceId')

        # Check if the appliance is already claimed
        appliance_ref = db.collection('appliances').document(appliance_id)
        appliance_doc = appliance_ref.get()
        if appliance_doc.exists and 'claimedBy' in appliance_doc.to_dict():
            claimed_by = appliance_doc.to_dict()['claimedBy']
            if claimed_by != user_id:
                # Appliance is already claimed by another user
                return jsonify({'error': 'Appliance is already claimed by another user.'}), 400

        # Update the document in Firestore to mark the appliance as claimed by the user
        appliance_ref.update({
            'claimedBy': user_id,
            'claimedAt': firestore.SERVER_TIMESTAMP
        })

        # Respond with success message
        return jsonify({'message': 'Appliance claimed successfully.'}), 200
    except Exception as e:
        # Respond with error message
        return jsonify({'error': 'Error claiming appliance: ' + str(e)}), 500

if __name__ == '__main__':
    app.run()
