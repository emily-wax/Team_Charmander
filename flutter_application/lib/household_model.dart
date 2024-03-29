import 'package:cloud_firestore/cloud_firestore.dart';

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