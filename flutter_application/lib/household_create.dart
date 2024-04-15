import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_application/household_model.dart';
import 'HomePage.dart';
import 'account_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';


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
  TextEditingController _passwordController = TextEditingController();
  late User _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser!;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: themeProvider.selectedTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: themeProvider.selectedTheme.backgroundColor,
        title: Text('Household Creation Form', style: TextStyle(color: themeProvider.textColor),),
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
                style: TextStyle(color: themeProvider.inputColor),
        
                controller: _nameController,
                decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: themeProvider.buttonColor), // Border color when enabled
                  ),
                  floatingLabelStyle: TextStyle(color: themeProvider.buttonColor),
                  labelText: 'Household Name',
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter the name';
                  }
                  return null;
                },
                cursorColor: themeProvider.buttonColor,
              ),
              TextFormField(
                style: TextStyle(color: themeProvider.inputColor),
                cursorColor: themeProvider.buttonColor,
                controller: _countController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: themeProvider.buttonColor), // Border color when enabled
                  ),
                  floatingLabelStyle: TextStyle(color: themeProvider.buttonColor),
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
                style: TextStyle(color: themeProvider.inputColor),
                cursorColor: themeProvider.buttonColor,
                controller: _passwordController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: themeProvider.buttonColor), // Border color when enabled
                  ),
                  floatingLabelStyle: TextStyle(color: themeProvider.buttonColor),
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
                  style: ElevatedButton.styleFrom(backgroundColor: themeProvider.buttonColor),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Process the data
                      String name = _nameController.text;
                      int count = int.parse(_countController.text);
                      _saveHouseholdToFirebase(name, count, _passwordController.text );
                    }
                  },
                  child: Text('Submit', style: TextStyle(color: themeProvider.textColor),),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveHouseholdToFirebase( String name, int count, String password ) async{

    try{

      if( (await doesHouseholdExist(name)) == false ) {
        DocumentReference householdRef = FirebaseFirestore.instance.collection('households').doc(name);

        await householdRef.set(
          {
          'name': name,
          'password': password,
          'max_roommate_count': count,
          'roommates': [_currentUser.email],
          }
        ).then((_) {
          _nameController.clear();
          _countController.clear();      
          _passwordController.clear();
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

  @override
  void dispose() {
    _nameController.dispose();
    _countController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}