# Welcome to Cloud Functions for Firebase for Python!
# To get started, simply uncomment the below code or create your own.
# Deploy with `firebase deploy`

from firebase_functions import https_fn
from firebase_admin import initialize_app, credentials
from claim_appliance import claim_appliance  # Import your claim_appliance function

cred = credentials.Certificate('team-charmander-482-firebase-adminsdk-5qjla-edd1eb5f4a.json')

initialize_app(cred, {'databaseURL': 'https://team-charmander-482-default-rtdb.firebaseio.com'})

# @https_fn.on_request()
# def on_request_example(req: https_fn.Request) -> https_fn.Response:
#     return https_fn.Response("Hello world!")

# Add your claimAppliance function
@https_fn.on_request()
def claim_appliance_handler(req: https_fn.Request) -> https_fn.Response:
    # Implement your claimAppliance function logic here
    response = claim_appliance(req)
    return https_fn.Response(response)

# Export the Firebase Functions instance
# https_fn.export()
