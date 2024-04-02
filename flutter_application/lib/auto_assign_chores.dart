import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application/household_model.dart';
import 'user_model.dart';
import 'dart:math';

class AutoAssignClass extends StatefulWidget {
  UserModel? currUserModel;


  @override
  _AutoAssignState createState() => _AutoAssignState();

  Future<String> autoAssignChore() {
    debugPrint("in autoAssignChore(), calling _getUser()...");
    return _getUser();
  }

  // eventually, this function will be used to run the Modified Adjusted Winner Allocation Algorithm
  Future<String> _getUser() async {
    // TODO: Fetch and save all roommates' emails in the user's household
    debugPrint("Starting _getUser()...");
    UserModel currUserModel = await readData();
    debugPrint("UserModel created!");

    HouseholdModel currHouseModel = HouseholdModel.fromSnapshot(await FirebaseFirestore.instance.collection('households').doc(currUserModel.currHouse).get());
    debugPrint("HouseholdModel created!");

    List<String> existingRoommates = currHouseModel.roommates; 
    debugPrint("Roommates accessed!");
    debugPrint(existingRoommates.toString());

    // TODO: Fetch and save the "slider-prefs" in the following collection: pKyWYjznujaUilHDVHmM (this is the key of one of the roommates in household "Jerry Residence")


    // TODO: algorithm here

    //return the user
    return "";
  }
}

class _AutoAssignState extends State<AutoAssignClass> {
   @override
  Widget build(BuildContext context) {
    return const Text("Hi");
  }

  


}