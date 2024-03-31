import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/household_model.dart';
import 'SignInPage.dart';
import 'fourth_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class HouseholdCreate extends StatelessWidget{
  @override

  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Household Creation Form',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HouseholdCreateForm(),
    );

  }
}

class HouseholdCreateForm extends StatefulWidget {
  @override
  _HouseholdCreateFormState createState() => _HouseholdCreateFormState();
}


class _HouseholdCreateFormState extends State<HouseholdCreateForm> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _countController = TextEditingController();
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
        title: Text('Household Creation Form'),
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
                controller: _countController,
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
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Process the data
                      String name = _nameController.text;
                      int count = int.parse(_countController.text);
                      _saveHouseholdToFirebase(name, count);
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

  void _saveHouseholdToFirebase( String name, int count ) async{

    try{

      if( (await doesHouseholdExist(name)) == false ) {
        DocumentReference householdRef = FirebaseFirestore.instance.collection('households').doc(name);

        await householdRef.set(
          {
          'name': name,
          'max_roommate_count': count,
          'roommates': [_currentUser.email],
          }
        ).then((_) {
          _nameController.clear();
          _countController.clear();      
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Object submitted successfully'),
          ));

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FourthPage()),
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

  @override
  void dispose() {
    _nameController.dispose();
    _countController.dispose();
    super.dispose();
  }
}