import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'SignInPage.dart';
import 'fourth_page.dart';
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
  List<String> _households = []; // List to store available users
  String? selectedHousehold;


  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser!;
    _loadHouseholds();
  }

  Future<void> _loadHouseholds() async {
     try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('households').get();
      setState(() {
        _households = querySnapshot.docs
            .map((doc) => (doc.data() as Map<String, dynamic>)['name'] as String)
            .toList();
      });
    } catch (e) {
      print("Error loading users: $e");
    }
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
              DropdownButtonFormField<String>(
                value: selectedHousehold,
                onChanged: (value) {
                  setState(() {
                    selectedHousehold = value;
                  });
                },
                items: _households.map((String household) {
                  return DropdownMenuItem<String>(
                    value: household,
                    child: Text(household),
                  );
                }).toList(),
                hint: Text('Select Household'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Process the data
                      String? name = selectedHousehold;
                  
                      addToObjectArray(name!);
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

          // TODO: check if the max roommate count has already been hit

          if(existingArray.contains( _currentUser.email)){
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('You are already in this household.'),
            ));            
          } else {
            existingArray.add(_currentUser.email);
            // Update the document with the modified array
            document.reference.update({'roommates': existingArray}).then((_) {

              // TODO: actually display success upon adding 
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Household joined successfully'),
              ));

              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FourthPage()),
              );

            }).catchError((error) {
              print('Failed to add string to array: $error');
            }); 
          }
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

// EW TODO: do we want to prevent people from joining multiple households??

// EW NOTE: we may want appliances and such to be a subcollection of households