import 'package:cloud_firestore/cloud_firestore.dart';

class HouseholdModel{
  final String name;
  final int max_roommate_count;
  final List<String> roommates;
  final String password;

  HouseholdModel({required this.name, required this.max_roommate_count, required this.roommates, required this.password});

  factory HouseholdModel.fromSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    List<dynamic> roommates = data['roommates'] != null ? List.from(data['roommates']) : [];
    return HouseholdModel(
      name: data['name'],
      max_roommate_count: data['max_roommate_count'],
      roommates: roommates.cast<String>(),
      password: data['password']
    );
  }
}

Future<bool> doesHouseholdExist(String householdId) async {
  try {
    // Create a reference to the document with the given householdId
    DocumentReference householdRef = FirebaseFirestore.instance.collection('households').doc(householdId);

    // Get the document snapshot
    DocumentSnapshot snapshot = await householdRef.get();

    // Check if the document exists
    return snapshot.exists;
  } catch (error) {
    // Handle any errors that occur during the process
    print('Error checking household existence: $error');
    return false; // Return false if an error occurs
  }
}