import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel{
  final String? email;
  final String? id;
  final String? currHouse;
  final bool? darkMode;
  final Map? preferences;

  UserModel( this.id, this.email, this.currHouse, this.darkMode, this.preferences );

  static UserModel fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot){
    return UserModel(
      snapshot['id'], 
      snapshot['email'], 
      snapshot['currHouse'],
      snapshot['darkMode'],
      snapshot['slider-prefs']
    );
  }

  String? get _id => id;

  Map<String, dynamic> toJson(){
    return{
      "id": id,
      "email": email,
      "currHouse": currHouse,
      "darkMode": darkMode,
      "slider-prefs": preferences
    };
  }
}

  // displays current user data
  Future<UserModel> readData() async {
    final db = FirebaseFirestore.instance;
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;

    String? currEmail = user!.email;

    final snapshot = await db.collection("users").where("email", isEqualTo: currEmail).get();

    final userData = snapshot.docs.map((e) => UserModel.fromSnapshot(e)).single;
    
    return userData;

  }