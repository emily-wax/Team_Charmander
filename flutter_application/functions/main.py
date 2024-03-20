# Import the Cloud Functions module
from firebase_functions import https_fn

# Import the Firebase Admin module for initialization
from firebase_admin import initialize_app, credentials

# Initialize the Firebase app (if needed)
cred = credentials.Certificate('team-charmander-482-firebase-adminsdk-5qjla-edd1eb5f4a.json')

initialize_app(cred, {'databaseURL': 'https://team-charmander-482-default-rtdb.firebaseio.com'})

# Import the claim_appliance function
from claim_appliance import claim_appliance

# Define your Cloud Function
@https_fn.on_request()
def claim_appliance_handler(req: https_fn.Request) -> https_fn.Response:
    # Call the claim_appliance function from claim_appliance.py
    return claim_appliance(req)

# Export the Firebase Functions instance
# https_fn.export()
