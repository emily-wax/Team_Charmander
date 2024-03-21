import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart'; // Import Firebase Functions

class ApplianceDetailsPage extends StatelessWidget {
  final String applianceName;

  const ApplianceDetailsPage({Key? key, required this.applianceName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(applianceName),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Call the Cloud Function to claim the appliance
            print("hey");
            _claimAppliance(applianceName);
          },
          style: ElevatedButton.styleFrom(
            //primary: Colors.green,
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Claim',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _claimAppliance(String applianceName) async {
    try {
      // Create a Cloud Functions instance
      FirebaseFunctions functions = FirebaseFunctions.instance;

      // Call the claim_appliance_handler Cloud Function
      final HttpsCallable callable = functions.httpsCallable('claim_appliance_handler');
      final result = await callable.call(<String, dynamic>{
        'applianceName': applianceName,
      });

      // Log the result from the Cloud Function
      print(result.data);
    } catch (e) {
      print('Error claiming appliance: $e');
    }
  }
}
