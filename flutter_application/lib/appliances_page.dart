import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth

class AppliancesPage extends StatefulWidget {
  const AppliancesPage({Key? key}) : super(key: key);

  @override
  _AppliancesPageState createState() => _AppliancesPageState();
}

class _AppliancesPageState extends State<AppliancesPage> {
  final TextEditingController _applianceNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Appliances'),
      ),
      body: Container(
        color: Colors.lightBlue[100],
        child: Padding(
          padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('appliances').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  var appliances = snapshot.data!.docs;
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: appliances.length,
                    itemBuilder: (context, index) {
                      var appliance = appliances[index].data();
                      bool isClaimed = appliance['claimed'] ?? false;
                      String applianceName = appliances[index].id; // Get the document ID as the appliance name
                      return Padding(
                        padding: const EdgeInsets.all(8.0), // Add padding to create space between the boxes
                        child: Card(
                          color: Colors.lightBlue[50],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                backgroundColor: isClaimed ? Colors.red : Colors.green,
                                radius: 30,
                                child: Icon(
                                  isClaimed ? Icons.clear : Icons.check,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                applianceName,
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 6),
                              isClaimed && appliance['claimedBy'] != FirebaseAuth.instance.currentUser?.uid
                                  ? SizedBox()
                                  : ElevatedButton(
                                      onPressed: () {
                                        if (isClaimed) {
                                          _unclaimAppliance(appliances[index].id);
                                        } else {
                                          _claimAppliance(appliances[index].id);
                                        }
                                      },
                                      child: Text(isClaimed ? 'Unclaim' : 'Claim'),
                                    ),
                            ],
                          ),
                        ),
                      );
                    },

                  );
                },
              ),
            ),
            _buildAddApplianceButton(),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildAddApplianceButton() {
    return GestureDetector(
      onTap: () {
        _addApplianceDialog(context);
      },
      child: Container(
        width: 60,
        height: 60,
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.add,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  void _addApplianceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Appliance'),
          content: TextField(
            controller: _applianceNameController,
            decoration: InputDecoration(
              hintText: 'Enter appliance name',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _addAppliance(_applianceNameController.text);
                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _claimAppliance(String applianceId) async {
  // Get the current user's ID
  String? userId = FirebaseAuth.instance.currentUser?.uid;

  // If userId is null, handle the case where the user is not signed in
  if (userId == null) {
    // Handle the case where the user is not signed in
    print('User is not signed in.');
    return;
  }

  // Get the appliance document from Firestore
  DocumentSnapshot applianceSnapshot = await FirebaseFirestore.instance.collection('appliances').doc(applianceId).get();

  // Get the current claim status and claimed by user ID
  bool isClaimed = applianceSnapshot['claimed'];
  String? claimedBy = applianceSnapshot['claimedBy'];

  // Check if the appliance is already claimed by a different user
  if (isClaimed && claimedBy != userId) {
    // Disable the claim button for other users
    print('Appliance is already claimed by a different user.');
    return;
  }

  // Update the appliance document in Firestore with the current user's ID and claimedAt timestamp
  await FirebaseFirestore.instance.collection('appliances').doc(applianceId).update({
    'claimed': true,
    'claimedBy': userId, // Use the current user's ID
    'claimedAt': FieldValue.serverTimestamp(), // Update claimedAt with server timestamp
  });
}


  void _unclaimAppliance(String applianceId) {
    // Clear the claimedBy field when unclaim
// Clear the claimedBy field when unclaiming the appliance
    FirebaseFirestore.instance.collection('appliances').doc(applianceId).update({
      'claimed': false,
      'claimedBy': null,
      'claimedAt': null, // Clear claimedAt
    });
  }

  void _addAppliance(String applianceName) {
    // Add a new appliance to Firestore
    FirebaseFirestore.instance.collection('appliances').doc(applianceName).set({
      'claimed': false,
      'claimedBy': null,
      'claimedAt': null, // Initialize claimedAt as null
    }).then((_) {
      // Clear the text field after adding the appliance
      _applianceNameController.clear();
    }).catchError((error) {
      // Handle any errors that occur during adding the appliance
      print('Error adding appliance: $error');
    });
  }

  void _deleteAppliance(String applianceId) {
    // Delete the appliance document from Firestore
    FirebaseFirestore.instance.collection('appliances').doc(applianceId).delete().then((_) {
      print('Appliance deleted successfully');
    }).catchError((error) {
      // Handle any errors that occur during deleting the appliance
      print('Error deleting appliance: $error');
    });
  }

  @override
  void dispose() {
    // Dispose the controller when the widget is disposed
    _applianceNameController.dispose();
    super.dispose();
  }
}
