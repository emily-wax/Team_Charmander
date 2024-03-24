import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'SignInPage.dart';
import 'household_create.dart';
import 'household_join.dart';
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
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => HouseholdJoin()),);
                }, 
                child: Text(
                  'Join a Household',
                  style: TextStyle(fontSize: 20),
                ),
              ),
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

/* TODO: "create household" and "join household" buttons that link to forms */