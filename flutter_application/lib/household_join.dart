import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'SignInPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class HouseholdJoin extends StatelessWidget{
  @override

  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Household Joining Form',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HouseholdJoinForm(),
    );

  }
}

class HouseholdJoinForm extends StatefulWidget {
  @override
  _HouseholdJoinFormState createState() => _HouseholdJoinFormState();
}

class _HouseholdJoinFormState extends State<HouseholdJoinForm> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  late User _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Household Join Form'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Please enter the name of the household you would like to join.',
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter the name';
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
                      String name = _nameController.text;
                      // TODO: add current user email to the household of that name
                      addToObjectArray(name);
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

  void addToObjectArray( String houseName ){

    // TODO: add a snackbar upon success

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
          existingArray.add(_currentUser.email);
          // Update the document with the modified array
          document.reference.update({'roommates': existingArray}).then((_) {
            print('String added to array successfully');
          }).catchError((error) {
            print('Failed to add string to array: $error');
          });
        } else {
            print('Object with name not found');
          }
      }).catchError((error) {
        print('Error retrieving object: $error');
      });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}