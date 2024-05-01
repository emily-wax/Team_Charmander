/// Account Page
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'preferences_page.dart';
import 'user_model.dart';
import 'SignInPage.dart';
import 'household_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';

ThemeProvider theme = ThemeProvider();

/// StatefulWidget that represents the account page of the application.
class AccountPage extends StatefulWidget {
  @override
  AccountPageState createState() => AccountPageState();
}

/// State class.
class AccountPageState extends State<AccountPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? currUser;
  HouseholdModel? _household;
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _countController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  bool _showJoinButton = true; // boolean to control visibility of Join butto
  String selectedTidy = 'Cleaner';
  String selectedTimeOfDay = 'Early Riser';
  String selectedButton = "";
  double prefSum = 0.0;

  @override
  void initState() {
    super.initState();
    currUser = _auth.currentUser;
    fetchHouseholdsForCurrentUser();
  }


  /// Logs out the current user.
  ///
  /// Navigates to the login screen.
  void logout(BuildContext context) async {
  try {
    await FirebaseAuth.instance.signOut();
    // Navigate to the login screen or any other screen you want after logout
    // For example:
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SignInPage()),
    );
  } catch (e) {
    print('Error logging out: $e');
    // Show a snackbar or an alert dialog to indicate the error to the user
  }
}

  /// Updates the current user's household in firebase.
  ///
  /// [userId] - The ID of the user.
  /// [householdName] - The name of the household to update.
Future<void> updateUserHousehold(String? userId, String householdName) async {

  QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: userId).get();
  List<QueryDocumentSnapshot> documents = querySnapshot.docs;

  if(documents.isNotEmpty) {
    QueryDocumentSnapshot document = documents.first;

    DocumentReference documentReference = document.reference;

    await documentReference.set({'currHouse': householdName}, SetOptions(merge: true));
  } else {
    debugPrint(' not added ');
  }

}
  /// Fetches households for the current user from firebase to update display.
  Future<void> fetchHouseholdsForCurrentUser() async {
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

  /// Saves new household information to Firebase.
  ///
  /// [name] - The name of the household.
  /// [count] - The maximum number of roommates.
  /// [password] - The password for the household.
  void saveHouseholdToFirebase( String name, int count, String password ) async{

    try{

      if( (await doesHouseholdExist(name)) == false ) {
        DocumentReference householdRef = FirebaseFirestore.instance.collection('households').doc(name);

        await householdRef.set(
          {
          'name': name,
          'password': password,
          'max_roommate_count': count,
          'roommates': [currUser!.email],
          }
        ).then((_) {
          _nameController.clear();
          _countController.clear();      
          _passwordController.clear();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Object submitted successfully'),
          ));

          fetchHouseholdsForCurrentUser();
          Navigator.of(context).pop();
        });

      } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Household name already exists. Please enter unique household name.'),
          ));
      }
      // create reference to household
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to submit object: $error'),
        ));
    }
  }

  /// Removes the current user from a household.
  ///
  /// [houseName] - The name of the household.
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

            QuerySnapshot eventsSnapshot = await currHouseRef.collection('events').get();

            for (QueryDocumentSnapshot documentSnapshot in eventsSnapshot.docs) {
              await documentSnapshot.reference.delete();
            }

            await currHouseRef.delete().then((_) {
              setState(() {
                fetchHouseholdsForCurrentUser();
              });
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('You have left the household. It has been deleted.'),
                duration: Duration(seconds: 1, milliseconds: 300),
              ));
            }).catchError((error) {
              print('Failed to update roommates list: $error');
            });

          } else {

            // if there are still roommates left, just delete current user
            document.reference.update({'roommates': existingRoommates}).then((_) {
              setState(() {
                fetchHouseholdsForCurrentUser();
              });
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('You have left the household.'),
                duration: Duration(seconds: 1, milliseconds: 300),
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

  /// Adds the current user to a household.
  ///
  /// [houseName] - The name of the household.
  /// [password] - The password for the household.
  void addToObjectArray( String houseName, String password ){

    FirebaseFirestore.instance.collection('households')
      .where('name', isEqualTo: houseName)
      .get()
      .then( (querySnapshot){
        if(querySnapshot.docs.isNotEmpty){
          // Assuming there's only one document with the given name
          var document = querySnapshot.docs.first;
          // Get the existing array field
          List<dynamic> existingArray = document.data()['roommates'] ?? [];
          // Add the string to the array

          HouseholdModel house = HouseholdModel.fromSnapshot(document);
          // TODO: check if the max roommate count has already been hit

          if (existingArray.contains( currUser?.email)){
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('You are already in this household.'),
            ));            
          } else if (house.password != password) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Incorrect Password.'),
            ));    
          } else if ( existingArray.length >= house.max_roommate_count ){
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('This house has already hit the maximum amount of roommates.'),
            ));   
          } else {
            existingArray.add(currUser?.email);
            // Update the document with the modified array
            document.reference.update({'roommates': existingArray}).then((_) {

              // TODO: actually display success upon adding 
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Household joined successfully'),
              ));

              fetchHouseholdsForCurrentUser();
              Navigator.of(context).pop();

            }).catchError((error) {
              print('Failed to add string to array: $error');
            }); 
          }
        } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('House does not exist.'),
            )); 
          }
      }).catchError((error) {
        print('Error retrieving object: $error');
      });
  }

  /// Builds the form for creating a household.
  Widget _buildHouseholdCreationForm() {
    return Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextFormField(
              style: TextStyle(color: theme.inputColor),
      
              controller: _nameController,
              decoration: InputDecoration(
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.buttonColor), // Border color when enabled
                ),
                floatingLabelStyle: TextStyle(color: theme.buttonColor),
                labelText: 'Household Name',
              ),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter the name';
                }
                return null;
              },
              cursorColor: theme.buttonColor,
            ),
            TextFormField(
              style: TextStyle(color: theme.inputColor),
              cursorColor: theme.buttonColor,
              controller: _countController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.buttonColor), // Border color when enabled
                ),
                floatingLabelStyle: TextStyle(color: theme.buttonColor),
                labelText: 'Maximum Roommate Count',
              ),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter the count';
                }
                return null;
              },
            ),
            TextFormField(
              style: TextStyle(color: theme.inputColor),
              controller: _passwordController,
              decoration: InputDecoration(
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.buttonColor), // Border color when enabled
                ),
                floatingLabelStyle: TextStyle(color: theme.buttonColor),
                labelText: 'Password',
                helperText: 'This is used to control who can join your household',
              ),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter a password for your household';
                }
                return null;
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: theme.buttonColor),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Cancel', style: TextStyle(color: theme.textColor)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: theme.buttonColor),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Process the data
                        String name = _nameController.text;
                        int count = int.parse(_countController.text);
                        _nameController.clear();
                        _countController.clear();
                        saveHouseholdToFirebase(name, count, _passwordController.text);
                        _passwordController.clear();
                      }
                    },
                    child: Text('Submit', style: TextStyle(color: theme.textColor)),
                  ),
                ],
              ),
            ),
          ],
        )
    );
  }

  /// Builds the form for joining a household.
  Widget _buildHouseholdJoinForm() {
    return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                style: TextStyle(color: theme.inputColor),
                cursorColor: theme.buttonColor,
                controller: _nameController,
                decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.buttonColor), // Border color when enabled
                  ),
                  floatingLabelStyle: TextStyle(color: theme.buttonColor),
                  labelText: 'Household Name',
                  labelStyle: TextStyle(color: Colors.grey),
                ),
                validator: (value) {
                  if(value!.isEmpty) {
                    return 'Please enter household name';
                  }
                  return null;
                },
              ),
              TextFormField(
                style: TextStyle(color: theme.inputColor),
                cursorColor: theme.buttonColor,
                controller: _passwordController,
                decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.buttonColor), // Border color when enabled
                  ),
                  floatingLabelStyle: TextStyle(color: theme.buttonColor),
                  labelText: 'Household Password',
                  labelStyle: TextStyle(color: Colors.grey),
                ),
                validator: (value) {
                  if(value!.isEmpty) {
                    return 'Please enter password';
                  }
                  return null;
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: theme.buttonColor),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('Cancel', style: TextStyle(color: theme.textColor)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: theme.buttonColor),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // Process the data

                          String? name = _nameController.text;
                          addToObjectArray(name!, _passwordController.text);

                          _passwordController.clear();
                          _nameController.clear();

                        }
                      },
                      child: Text('Submit', style: TextStyle(color: theme.textColor)),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
  }

  /// Shows the household creation dialog.
  ///
  /// [context] - The build context.
  Future<void> _showHouseholdCreationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            content: 
              SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                  child: _buildHouseholdCreationForm()
                ),
              )
              
          );
        },
    );
  }

  /// Shows the household join dialog.
  ///
  /// [context] - The build context.
  Future<void> _showHouseholdJoinDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            content: 
              SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.25),
                  child: _buildHouseholdJoinForm()
                ),
              )
              
          );
        },
    );
  }

@override
Widget build(BuildContext context) {
  String householdTitle = _household != null
      ? '${_household!.name}'
      : 'Create or Join a House';

  final themeProvider = Provider.of<ThemeProvider>(context);
  theme = themeProvider;

  return Scaffold(
    appBar: AppBar(
      title: Text('Account Page'),
      actions: [
        Tooltip(
          message: 'Log out',
          child: IconButton( 
            icon: const Icon(Icons.logout),
            onPressed:() => logout(context),
          ), 
        )
      ],
    ),
    body: SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Center( // Center the content horizontally
        child: Column(
          children: <Widget>[
            if (_household != null)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  householdTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            FutureBuilder(
              future: readData(),
              builder:(context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                  UserModel? user = snapshot.data as UserModel?;
                  return Column(
                    children: [
                      Text(
                        user!.email!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20.0,
                        ),
                      ),
                      SizedBox(height: 20.0),
                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Adjust each scale:'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      PreferenceSlider(),
                                      SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('Done', style: TextStyle(color: Colors.white)),
                                        style: ElevatedButton.styleFrom(backgroundColor: theme.buttonColor),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: Text('Set Preferences', style: TextStyle(color: Colors.white, fontSize: 16)),
                        style: ElevatedButton.styleFrom(backgroundColor: theme.buttonColor),
                      ),
                      if (_household != null) ...[
                        SizedBox(height: 20.0),
                        Text(
                          'Household Members:',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10.0),
                        Column(
                          children: _household!.roommates
                              .map((email) => Text(email, textAlign: TextAlign.center))
                              .toList(),
                        ),
                        SizedBox(height: 20.0),
                        ElevatedButton(
                          onPressed: () {
                            removeFromHousehold(_household!.name);
                          },
                          child: Text(
                            'Leave House',
                            style: TextStyle(fontSize: 16, color: theme.textColor),
                          ),
                          style: ElevatedButton.styleFrom(backgroundColor: theme.buttonColor),
                        ),
                      ],
                    ],
                  );
                }
                return Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 8, 174, 245)));
              },
            ),
            SizedBox(height: 20),
            Visibility(
              visible: _showJoinButton,
              child: ElevatedButton(
                onPressed: () {
                  _showHouseholdCreationDialog(context); // Call the function to show the dialog
                },
                style: ElevatedButton.styleFrom(backgroundColor: theme.buttonColor),
                child: Text(
                  'Create a Household',
                  style: TextStyle(fontSize: 20, color: theme.textColor),
                ),
              ),
            ),
            SizedBox(height: 20),
            Visibility(
              visible: _showJoinButton,
              child: ElevatedButton(
                onPressed: () {
                  _showHouseholdJoinDialog(context);
                },
                child: Text(
                  'Join a Household',
                  style: TextStyle(fontSize: 20, color: theme.textColor),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: theme.buttonColor),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}



}
