import 'dart:js_interop_unsafe';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'household_create.dart';
import 'household_join.dart';
import 'preferences_page.dart';
import 'user_model.dart';
import 'HomePage.dart';
import 'household_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';

// TODO: add a password for joining the house
// TODO: create a back home button

class AccountPage extends StatefulWidget {
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  HouseholdModel? _household;
  bool _showJoinButton = true; // boolean to control visibility of Join butto
  String selectedTidy = 'Cleaner';
  String selectedTimeOfDay = 'Early Riser';
  String selectedButton = "";
  bool isFirstButtonGreen = false;
  bool isSecondButtonGreen = false;
  final ValueNotifier<bool> isFirstButtonGreenVN = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isSecondButtonGreenVN = ValueNotifier<bool>(false);
  bool isPressed = false;
  double _prefValue = 0.0;
  @override
  void initState() {
    super.initState();
    _fetchHouseholdsForCurrentUser();
  }

Future<void> updateUserHousehold(String? userId, String householdName) async {

  QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: userId).get();
  List<QueryDocumentSnapshot> documents = querySnapshot.docs;

  if(documents.isNotEmpty) {
    QueryDocumentSnapshot document = documents.first;

    DocumentReference documentReference = document.reference;

    await documentReference.set({'currHouse': householdName}, SetOptions(merge: true));
  } else {
    print(' not added ');
  }

}

  Future<void> _fetchHouseholdsForCurrentUser() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('households')
          .where('roommates', arrayContains: currentUser.email)
          .get();
      setState(() {
        if (snapshot.docs.isNotEmpty){
          _household =HouseholdModel.fromSnapshot(snapshot.docs.first);
          updateUserHousehold( currentUser.email, _household!.name);
          _showJoinButton = false;
        } else {
          _household = null;
          updateUserHousehold( currentUser.email, "");
          _showJoinButton = true;
        }
      });
    }
  }

  void removeFromHousehold(String houseName) {
    User? _currentUser = _auth.currentUser;

    FirebaseFirestore.instance
        .collection('households')
        .where('name', isEqualTo: houseName)
        .get()
        .then((querySnapshot) async {
      if (querySnapshot.docs.isNotEmpty) {
        var document = querySnapshot.docs.first;
        List<dynamic> existingRoommates =
            List.from(document.data()['roommates']);
        if (existingRoommates.contains(_currentUser!.email)) {
          existingRoommates.remove(_currentUser.email);

          if(existingRoommates.isEmpty) {

            // delete household if no more roommates exist
            DocumentReference currHouseRef = FirebaseFirestore.instance.collection('households').doc(houseName);

            // TODO: deleting subcollections is hardcoded, put this in it's own function
            QuerySnapshot appliancesSnapshot = await currHouseRef.collection('appliances').get();

            for (QueryDocumentSnapshot documentSnapshot in appliancesSnapshot.docs) {
              await documentSnapshot.reference.delete();
            }

            QuerySnapshot choresSnapshot = await currHouseRef.collection('chores').get();

            for (QueryDocumentSnapshot documentSnapshot in choresSnapshot.docs) {
              await documentSnapshot.reference.delete();
            }

            await currHouseRef.delete().then((_) {
              setState(() {
                _fetchHouseholdsForCurrentUser();
              });
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('You have left the household. It has been deleted.'),
              ));
            }).catchError((error) {
              print('Failed to update roommates list: $error');
            });

          } else {

            // if there are still roommates left, just delete current user
            document.reference.update({'roommates': existingRoommates}).then((_) {
              setState(() {
                _fetchHouseholdsForCurrentUser();
              });
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('You have left the household.'),
              ));
            }).catchError((error) {
              print('Failed to update roommates list: $error');
            });
          }         
        }
      } else {
        print('Household not found.');
      }
    }).catchError((error) {
      print('Error retrieving household: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Account Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
            },
          )
        ],
      ),
      body: Container(
        child: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
              FutureBuilder(
                future: readData(),
                builder:( (context, snapshot) {
                  if( snapshot.connectionState == ConnectionState.done){
                    if(snapshot.hasData){
                      UserModel? user = snapshot.data as UserModel;

                      // TODO: find a better way to display user data ...

                      // Display current user email and households
                      return Column(
                        children: [
                          Text(user.email!),
                          SizedBox(height: 20),
                          // TODO: preferences here
                          ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                  title: Text('Adjust each scale:'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      PreferenceSlider (),
                                      SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('Done', style: TextStyle(color: Colors.white)),
                                        style: ElevatedButton.styleFrom(backgroundColor: themeProvider.buttonColor)
                                      ),
                                    ],
                                  ),
                                );

                                },
                              );
                            },
                            child: Text('Set Preferences', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: themeProvider.buttonColor)
                          ),

                          Text('User Household:'),
                          SizedBox(height: 10,),
                          if (_household != null)
                                ListTile(
                                  title: Text(_household!.name),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: _household!.roommates.map((email) => Text(email)).toList(),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text("Number of Household Members: ${_household!.roommates.length}"),
                                      SizedBox(width: 10),
                                      IconButton(
                                        onPressed: () {
                                          removeFromHousehold(_household!.name);
                                        } , 
                                        icon: Icon(Icons.delete),
                                      )
                                      ],
                                    )
                                )                        
                        ],
                      );
                    }
                  }

                  return Center(child: CircularProgressIndicator());
                }),
              ),
              SizedBox(height: 20),
              Visibility(
                visible: _showJoinButton,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => HouseholdCreate()),
                    );
                  },
                  child: Text(
                    'Create a Household',
                    style: TextStyle(fontSize: 20),
                  ),
                  style: ElevatedButton.styleFrom(backgroundColor: themeProvider.buttonColor)
                ),
              ),
              SizedBox(height: 20),
              Visibility(
                visible: _showJoinButton,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HouseholdJoin()),
                    );
                  },
                  child: Text(
                    'Join a Household',
                    style: TextStyle(fontSize: 20),
                  ),
                  style: ElevatedButton.styleFrom(backgroundColor: themeProvider.buttonColor)
                ),
              ),
            ])),
      ),
    );
  }
}
