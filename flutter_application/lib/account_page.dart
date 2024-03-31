import 'dart:js_interop_unsafe';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'household_create.dart';
import 'household_join.dart';
import 'user_model.dart';
import 'HomePage.dart';
import 'household_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

// TODO: add a password for joining the house
// TODO: create a back home button

class FourthPage extends StatefulWidget {
  @override
  _FourthPageState createState() => _FourthPageState();
}

class _FourthPageState extends State<FourthPage> {
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Account Page'),
      ),
      body: Container(
        color: Colors.orange, // Set the background color to orange
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
                                    title: Text('Select 1 From Each Row:'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildChoiceButton(context, 'Cleaner','tidy', 'cleaner'),
                                        const Text("or"),
                                        _buildChoiceButton(context, 'Organizer', 'tidy', 'organizer'),
                                          ],
                                        ),
                                        
                                        SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            _buildChoiceButton(context, 'Early Riser', 'timeOfDay', 'earlyRiser'),
                                            const Text("or"),
                                            _buildChoiceButton(context, 'Night Owl', 'timeOfDay', 'nightOwl'),
                                          ],
                                        ),
                                        SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            _buildChoiceButton(context, 'Chef', 'foodLogistics', 'chef'),
                                            const Text("or"),
                                            _buildChoiceButton(context, 'Dishwasher', 'foodLogistics', 'Dishwasher'),
                                          ],
                                        ),
                                        SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            _buildChoiceButton(context,'Outdoor','location', 'outdoor'),
                                            const Text("or"),
                                            _buildChoiceButton(context, 'Indoor', 'location', 'indoor'),
                                          ],
                                        ),
                                        SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text('Submit'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            child: Text('Set Preferences'),
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
                ),
              ),
              SizedBox(height: 20),
              IconButton(
                onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HomePage()),
                    );
                }, 
                icon: Icon(Icons.home)
                )
            ])),
      ),
    );
  }



  MaterialStateProperty<Color> getColor(Color c1, Color c2){
    final getColor = (Set<MaterialState> states) {
      if (states.contains(MaterialState.pressed)) {
        return c2;
      }
      else {
        return c1;
      }
    };
    return MaterialStateProperty.resolveWith(getColor);
  }

  MaterialStateProperty<BorderSide> getBorder(Color c1, Color c2) {
    final getBorder = (Set<MaterialState> states) {
      if (states.contains(MaterialState.pressed)) {
        return BorderSide(color: c2, width: 2);
      } else {
        return BorderSide(color: c1, width: 2);
      }
    };
    return MaterialStateProperty.resolveWith(getBorder);
  }

  Widget _buildChoiceButton(BuildContext context, String label, String category, String value) {
    return ElevatedButton(
      onPressed: () {
        
        setState(() {
          selectedButton = value; // Update selected button
          _submitChoice(category, value);
        });
      },
      style: ButtonStyle(
        foregroundColor: getColor(Colors.blue, Colors.white),
        backgroundColor: getColor(Colors.white, Colors.green),
        side: getBorder(Colors.white, Colors.black54), // Change button color based on selection
      ),
      child: Text(label),
    );
  }

  void _submitChoice(String category, String value) {
    FirebaseFirestore.instance.collection('users').doc('cxkVM8ZzLo9JzUWoS41B').get().then((DocumentSnapshot snapshot) {
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      Map<String, String> chore_preferences = data['chore-preferences'] != null ? Map<String, String>.from(data['chore-preferences']) : {};

      chore_preferences[category] = value;

      FirebaseFirestore.instance.collection('users').doc('cxkVM8ZzLo9JzUWoS41B').set({
        'chore-preferences': chore_preferences,
      }, SetOptions(merge: true)).then((_) {
        print('Preferences updated successfully!');
      }).catchError((error) {
        print('Failed to update preferences: $error');
      });
    }).catchError((error) {
      print('Error getting document: $error');
    });
  }
}

