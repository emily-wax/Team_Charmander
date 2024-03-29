import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// User model: could be put in a different file in the future but for now is here

class UserModel{
  final String? email;
  final String? password;
  final String? id;
  final String? currHouse;

  UserModel( this.id, this.email, this.password, this.currHouse );

  static UserModel fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot){
    return UserModel(
      snapshot['id'], 
      snapshot['email'], 
      snapshot['password'],
      snapshot['currHouse']
    );
  }

  Map<String, dynamic> toJson(){
    return{
      "id": id,
      "email": email,
      "password": password,
      "currHouse": currHouse
    };
  }
}