import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'household_create.dart';
import 'household_join.dart';
import 'user_model.dart';
import 'household_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

// TODO: add a password for joining the house
// TODO: household auto-deletes when no members are in? 
// TODO: appliances are subcollection now

class FourthPage extends StatefulWidget {
  @override
  _FourthPageState createState() => _FourthPageState();
}


class _FourthPageState extends State<FourthPage> {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  HouseholdModel? _household; // Change _households to a singular object
  bool _showJoinButton = true; // boolean to control visibility of Join button

  @override
  void initState() {
    super.initState();
    _fetchHouseholdsForCurrentUser();
  }

Future<void> updateUserHousehold(String? userId, String householdName) async {
  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'currHouse': householdName});
  } catch (e) {
    print('Error updating user household: $e');
    // Handle error here, such as showing a snackbar or retrying the update
  }
}

  Future<void> _fetchHouseholdsForCurrentUser() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      UserModel currUserModel = await readData() as UserModel;
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('households')
          .where('roommates', arrayContains: currentUser.email)
          .get();
      setState(() {
        if (snapshot.docs.isNotEmpty){
          _household =HouseholdModel.fromSnapshot(snapshot.docs.first);
          updateUserHousehold( currUserModel.id, _household!.name);
          _showJoinButton = false;
        } else {
          _household = null;
          updateUserHousehold( currUserModel.id, "");
          _showJoinButton = true;
        }
      });
    }
  }

void removeFromHousehold(String houseName) {
  User? _currentUser = _auth.currentUser;

  FirebaseFirestore.instance.collection('households')
    .where('name', isEqualTo: houseName)
    .get()
    .then((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        var document = querySnapshot.docs.first;
        List<dynamic> existingRoommates = List.from(document.data()['roommates']);
        if (existingRoommates.contains(_currentUser!.email)) {
          existingRoommates.remove(_currentUser.email);
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
            mainAxisAlignment:  MainAxisAlignment.center,
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
                child: 
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => HouseholdCreate()),);
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
                child:
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => HouseholdJoin()),);
                  }, 
                  child: Text(
                    'Join a Household',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              )
            ]
          )
        ),
      ),
    );
  }
}

