import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/household_model.dart';
import 'SignInPage.dart';
import 'account_page.dart';
import 'HomePage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';

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
  TextEditingController _passwordController = TextEditingController();
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: themeProvider.selectedTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: themeProvider.selectedTheme.backgroundColor,
        title: Text('Household Join Form'),
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
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: themeProvider.buttonColor), // Border color when enabled
                  ),
                ),
                dropdownColor: themeProvider.selectedTheme.backgroundColor,
                value: selectedHousehold,
                style: TextStyle(color: themeProvider.inputColor),
                onChanged: (value) {
                  setState(() {
                    selectedHousehold = value;
                  });
                },
                items: _households.map((String household) {
                  return DropdownMenuItem<String>(
                    value: household,
                    child: Text(household, style: TextStyle(color: themeProvider.inputColor),),
                  );
                }).toList(),
                hint: Text('Select Household', style: TextStyle(color: Colors.grey)),
              ),
              TextFormField(
                style: TextStyle(color: themeProvider.inputColor),
                cursorColor: themeProvider.buttonColor,
                controller: _passwordController,
                decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: themeProvider.buttonColor), // Border color when enabled
                  ),
                  floatingLabelStyle: TextStyle(color: themeProvider.buttonColor),
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
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: themeProvider.buttonColor),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Process the data
                      

                      String? name = selectedHousehold;
                      addToObjectArray(name!, _passwordController.text);
                    }
                  },
                  child: Text('Submit', style: TextStyle(color: themeProvider.textColor)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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

          if (existingArray.contains( _currentUser.email)){
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
            existingArray.add(_currentUser.email);
            // Update the document with the modified array
            document.reference.update({'roommates': existingArray}).then((_) {

              // TODO: actually display success upon adding 
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Household joined successfully'),
              ));

              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AccountPage()),
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

  // bool _HouseholdPasswordCheck( String houseName, String password ) {

  // }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}

// EW TODO: do we want to prevent people from joining multiple households??

// EW NOTE: we may want appliances and such to be a subcollection of households