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
      body: Column(
        children: [
          _buildAddApplianceField(),
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
                return ListView.builder(
                  itemCount: appliances.length,
                  itemBuilder: (context, index) {
                    var appliance = appliances[index].data();
                    bool isClaimed = appliance['claimed'] ?? false;
                    String applianceName = appliances[index].id; // Get the document ID as the appliance name
                    Timestamp? claimedAt = appliance['claimedAt'];
                    String? claimedAtString = claimedAt != null
                        ? 'Claimed at: ${DateTime.fromMillisecondsSinceEpoch(claimedAt.seconds * 1000)}'
                        : null;
                    return ListTile(
                      title: Text(applianceName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isClaimed ? 'Claimed by: ${appliance['claimedBy']}' : 'Available'),
                          if (claimedAtString != null) Text(claimedAtString),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          isClaimed
                              ? TextButton(
                                  onPressed: () => _unclaimAppliance(appliances[index].id),
                                  child: Text('Unclaim'),
                                )
                              : TextButton(
                                  onPressed: () => _claimAppliance(appliances[index].id),
                                  child: Text('Claim'),
                                ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _deleteAppliance(appliances[index].id),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddApplianceField() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _applianceNameController,
              decoration: InputDecoration(
                hintText: 'Enter appliance name',
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _addAppliance(_applianceNameController.text),
          ),
        ],
      ),
    );
  }

  void _claimAppliance(String applianceId) {
    // Get the current user's ID
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    // If userId is null, handle the case where the user is not signed in
    if (userId == null) {
      // Handle the case where the user is not signed in
      print('User is not signed in.');
      return;
    }

    // Update the appliance document in Firestore with the current user's ID and claimedAt timestamp
    FirebaseFirestore.instance.collection('appliances').doc(applianceId).update({
      'claimed': true,
      'claimedBy': userId, // Use the current user's ID
      'claimedAt': FieldValue.serverTimestamp(), // Update claimedAt with server timestamp
    });
  }

  void _unclaimAppliance(String applianceId) {
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
