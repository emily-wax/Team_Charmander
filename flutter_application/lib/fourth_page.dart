import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'SignInPage.dart';
import 'household_create.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FourthPage extends StatelessWidget {
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
                future: _readData(),
                builder:( (context, snapshot) {
                  if( snapshot.connectionState == ConnectionState.done){
                    if(snapshot.hasData){
                      UserModel? user = snapshot.data as UserModel;

                      // TODO: find a better way to display user data

                      return Center(child: Text( user.email! ) );
                    }
                  } 
      
                  return Center(child: CircularProgressIndicator());
                }),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => HouseholdCreate()),);
                }, 
                child: Text(
                  'Create a Household',
                  style: TextStyle(fontSize: 20),
                ),
              )
            ]
          )
        ),
      ),
    );
  }
}

// displays current user data
Future<UserModel> _readData() async {
  final db = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final User? user = auth.currentUser;

  String? currEmail = user!.email;

  final snapshot = await db.collection("users").where("email", isEqualTo: currEmail).get();

  final userData = snapshot.docs.map((e) => UserModel.fromSnapshot(e)).single;
  
  return userData;

}


// This currently gives a list of all users. For households, create a collection of households
// that have a string of user ids as the roommates and a roommate count
// on the account page have an option to "join a household" and be able to join the household by name
// create a household

/* TODO: "create household" and "join household" buttons that link to forms */