import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'SignInPage.dart';
import 'household_create.dart';
import 'household_join.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FourthPage extends StatefulWidget {
  @override
  _FourthPageState createState() => _FourthPageState();
}


class _FourthPageState extends State<FourthPage> {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<HouseholdModel> _households = [];

  @override
  void initState() {
    super.initState();
    _fetchHouseholdsForCurrentUser();
  }

  Future<void> _fetchHouseholdsForCurrentUser() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('households')
          .where('roommates', arrayContains: currentUser.email)
          .get();
      setState(() {
        _households = snapshot.docs.map((doc) => HouseholdModel.fromSnapshot(doc)).toList();
      });
    }
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
                future: _readData(),
                builder:( (context, snapshot) {
                  if( snapshot.connectionState == ConnectionState.done){
                    if(snapshot.hasData){
                      UserModel? user = snapshot.data as UserModel;

                      // TODO: find a better way to display user data ... akso add in household info

                      // Display current user email and households
                      return Column(
                        children: [
                          Text(user.email!),
                          SizedBox(height: 20),
                          Text('User Households:'),
                          SizedBox(height: 10,),
                          ListView.builder(
                              shrinkWrap: true,
                              itemCount: _households.length,
                              itemBuilder: (context, index){
                                return ListTile(
                                  title: Text(_households[index].name),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: _households[index].roommates.map((email) => Text(email)).toList(),
                                  ),
                                  trailing: Text("Number of Household Members: ${_households[index].roommates.length}"),
                                );
                              }
                            )
                          
                        ],
                      );

                      //return Center(child: Text( user.email! ) );
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

class HouseholdModel{
  final String name;
  final int max_roommate_count;
  final List<String> roommates;

  HouseholdModel({required this.name, required this.max_roommate_count, required this.roommates});

  factory HouseholdModel.fromSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    List<dynamic> roommates = data['roommates'] != null ? List.from(data['roommates']) : [];
    return HouseholdModel(
      name: data['name'],
      max_roommate_count: data['max_roommate_count'],
      roommates: roommates.cast<String>(),
    );
  }
}