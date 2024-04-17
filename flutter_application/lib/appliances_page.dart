import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';

ThemeProvider theme = ThemeProvider();

class AppliancesPage extends StatefulWidget {
  const AppliancesPage({Key? key}) : super(key: key);

  @override
  _AppliancesPageState createState() => _AppliancesPageState();
}

class _AppliancesPageState extends State<AppliancesPage> {
  final TextEditingController _applianceNameController = TextEditingController();
  UserModel? currUserModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Appliances'),
      ),
      body: FutureBuilder<UserModel>(
        future: readData(), // Use getCurrentUser() as the future
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: Color.fromARGB(255, 8, 174, 245),),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            currUserModel = snapshot.data; // Set currUserModel once future completes
            return buildAppliancesPage(); // Build the main content of the page
          }
        },
      ),
    );
  }

  Widget buildAppliancesPage() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    theme = themeProvider;
    return Container(
      padding: EdgeInsets.all(8),
      child: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('households').doc(currUserModel!.currHouse).collection('appliances').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: Color.fromARGB(255, 8, 174, 245),),
                  );
                }
                var appliances = snapshot.data!.docs;
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: appliances.length,
                  itemBuilder: (context, index) {
                    var appliance = appliances[index].data();
                    bool isClaimed = appliance['claimed'] ?? false;
                    String applianceName = appliances[index].id; // Get the document ID as the appliance name
                    return Card(
                      color: Theme.of(context).cardColor,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            backgroundColor: isClaimed ? Theme.of(context).errorColor : Colors.green,
                            radius: 30,
                            child: Icon(
                              isClaimed ? Icons.clear : Icons.check,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            applianceName,
                            style: Theme.of(context).textTheme.headline6,
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center, // Aligns the buttons horizontally to the center
                            children: [
                              isClaimed && appliance['claimedBy'] != currUserModel!.email
                                  ? SizedBox()
                                  : ElevatedButton(
                                      onPressed: () {
                                        if (isClaimed) {
                                          _unclaimAppliance(appliances[index].id);
                                        } else {
                                          _claimAppliance(appliances[index].id);
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: themeProvider.buttonColor),
                                      child: Text(isClaimed ? 'Unclaim' : 'Claim', style: TextStyle(color: themeProvider.textColor)),
                                    ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => _deleteApplianceDialog(context, appliances[index].id),
                              ),
                            ],
                          ),
                        ],
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
    );
  }

  Widget _buildAddApplianceButton() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return GestureDetector(
      onTap: () {
        _addApplianceDialog(context);
      },
      child: Container(
        width: 60,
        height: 60,
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeProvider.buttonColor,
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
            cursorColor: theme.buttonColor,
            controller: _applianceNameController,
            decoration: InputDecoration(
              hintText: 'Enter appliance name',
              focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.buttonColor), // Border color when enabled
                  ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(backgroundColor: theme.buttonColor),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel', style: TextStyle(color: theme.textColor)),
            ),
            TextButton(
              style: TextButton.styleFrom(backgroundColor: theme.buttonColor),
              onPressed: () {
                _addAppliance(_applianceNameController.text);
                Navigator.of(context).pop();
              },
              child: Text('Add', style: TextStyle(color: theme.textColor)),
            ),
          ],
        );
      },
    );
  }

  void _deleteApplianceDialog(BuildContext context, String applianceId) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Delete Appliance'),
        content: Text('Are you sure you want to delete this appliance?'),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(backgroundColor: theme.buttonColor),
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel', style: TextStyle(color: theme.textColor)),
          ),
          TextButton(
            style: TextButton.styleFrom(backgroundColor: theme.buttonColor),
            onPressed: () {
              _deleteAppliance(applianceId);
              Navigator.of(context).pop();
            },
            child: Text('Delete', style: TextStyle(color: theme.textColor)),
          ),
        ],
      );
    },
  );
}


  void _claimAppliance(String applianceId) async {
    // Get the current user's ID
    String? userId = currUserModel!.email;

    // If userId is null, handle the case where the user is not signed in
    if (userId == null) {
      // Handle the case where the user is not signed in
      print('User is not signed in.');
      return;
    }

    // Get the appliance document from Firestore
    DocumentSnapshot applianceSnapshot = await FirebaseFirestore.instance.collection('households').doc(currUserModel!.currHouse).collection('appliances').doc(applianceId).get();

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
    await FirebaseFirestore.instance.collection('households').doc(currUserModel!.currHouse).collection('appliances').doc(applianceId).update({
      'claimed': true,
      'claimedBy': userId, // Use the current user's ID
      'claimedAt': FieldValue.serverTimestamp(), // Update claimedAt with server timestamp
    });
  }

  void _unclaimAppliance(String applianceId) {
    // Clear the claimedBy field when unclaim
    FirebaseFirestore.instance.collection('households').doc(currUserModel!.currHouse).collection('appliances').doc(applianceId).update({
      'claimed': false,
      'claimedBy': null,
      'claimedAt': null, // Clear claimedAt
    });
  }

  // TODO: make sure user is in a household
  void _addAppliance(String applianceName) async {
    // Add a new appliance to Firestore

    FirebaseFirestore.instance.collection('households').doc(currUserModel!.currHouse).collection('appliances').doc(applianceName).set({
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

  void _confirmDeleteAppliance(String applianceId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Appliance'),
          content: Text('Are you sure you want to delete this appliance?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteAppliance(applianceId);
                Navigator.of(context).pop();
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  // TODO: change reference to subcollection
  void _deleteAppliance(String applianceId) {
    // Delete the appliance document from Firestore
    FirebaseFirestore.instance.collection('households').doc(currUserModel!.currHouse).collection('appliances').doc(applianceId).delete().then((_) {
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