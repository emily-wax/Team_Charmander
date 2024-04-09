import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_application/household_model.dart';
import 'HomePage.dart';
import 'account_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HouseholdCreate extends StatelessWidget{
  @override
  

  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Household Creation Form',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HouseholdCreateForm( firestore: FirebaseFirestore.instance, firebaseAuth: FirebaseAuth.instance),
    );

  }
}

class HouseholdCreateForm extends StatefulWidget {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  HouseholdCreateForm({
    required this.firebaseAuth,
    required this.firestore
  });

  @override
  HouseholdCreateFormState createState() => HouseholdCreateFormState();
}


class HouseholdCreateFormState extends State<HouseholdCreateForm> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController countController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  late User _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.firebaseAuth.currentUser!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Household Creation Form'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
            },
          ),
          Tooltip(
            message: 'Account Page',
            child: IconButton(
              icon: const Icon(Icons.account_circle_sharp),
              onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AccountPage()),
                  );
              },
            ),
          )
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Household Name',
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter the name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: countController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
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
                controller: passwordController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
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
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Process the data
                      String name = nameController.text;
                      int count = int.parse(countController.text);
                      saveHouseholdToFirebase(name, count, passwordController.text );
                    }
                  },
                  child: Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void saveHouseholdToFirebase( String name, int count, String password ) async{

    try{

      if( (await doesHouseholdExist(name)) == false ) {
        CollectionReference householdRef = widget.firestore.collection('households');

        await householdRef.doc(name).set(
          {
          'name': name,
          'password': password,
          'max_roommate_count': count,
          'roommates': [_currentUser.email],
          }
        ).then((_) {
          nameController.clear();
          countController.clear();      
          passwordController.clear();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Object submitted successfully'),
          ));

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AccountPage()),
          );
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

Future<bool> doesHouseholdExist(String householdId) async {
  try {
    // Create a reference to the document with the given householdId
    DocumentReference householdRef = widget.firestore.collection('households').doc(householdId);

    // Get the document snapshot
    DocumentSnapshot snapshot = await householdRef.get();

    // Check if the document exists
    return snapshot.exists;
  } catch (error) {
    // Handle any errors that occur during the process
    print('Error checking household existence: $error');
    return false; // Return false if an error occurs
  }
}



  @override
  void dispose() {
    nameController.dispose();
    countController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}