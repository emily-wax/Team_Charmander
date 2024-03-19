from firebase_admin import db
from firebase_admin import initialize_app, credentials
from flask import Flask, request, jsonify

# Initialize Firebase app
cred = credentials.Certificate('team-charmander-482-firebase-adminsdk-5qjla-edd1eb5f4a.json.json')
initialize_app(cred, {'databaseURL': 'https://team-charmander-482-default-rtdb.firebaseio.com'})

app = Flask(__name__)

@app.route('/claimAppliance', methods=['POST'])
def claim_appliance():
    try:
        # Extract data from the request (e.g., user ID, appliance ID)
        request_data = request.json
        user_id = request_data.get('userId')
        appliance_id = request_data.get('applianceId')

        # Check if the appliance is already claimed
        snapshot = db.reference('/appliances/' + appliance_id).get()
        if snapshot and snapshot.get('claimedBy') and snapshot['claimedBy'] != user_id:
            # Appliance is already claimed by another user
            return jsonify({'error': 'Appliance is already claimed by another user.'}), 400

        # Update the database to mark the appliance as claimed by the user
        db.reference('/appliances/' + appliance_id).update({
            'claimedBy': user_id,
            'claimedAt': db.ServerValue.TIMESTAMP
        })

        # Respond with success message
        return jsonify({'message': 'Appliance claimed successfully.'}), 200
    except Exception as e:
        # Respond with error message
        return jsonify({'error': 'Error claiming appliance: ' + str(e)}), 500

if __name__ == '__main__':
    app.run()
