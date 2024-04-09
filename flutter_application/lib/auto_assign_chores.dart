import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_application/household_model.dart';
import 'user_model.dart';
import 'dart:math';

class AutoAssignClass extends StatefulWidget {
  UserModel? currUserModel;

  @override
  _AutoAssignState createState() => _AutoAssignState();

  Future<String> autoAssignChore() {
    return _getUser();
  }

  // eventually, this function will be used to run the Modified Adjusted Winner Allocation Algorithm
  Future<String> _getUser() async {
    // Fetch and save all roommates' emails in the user's household
    UserModel currUserModel = await readData();
    HouseholdModel currHouseModel = HouseholdModel.fromSnapshot(
        await FirebaseFirestore.instance
            .collection('households')
            .doc(currUserModel.currHouse)
            .get());
    List<String> existingRoommates = currHouseModel.roommates;
    // final Map<String, dynamic> sliderPrefs = {};
    // final Map<String, LinkedMap<String, dynamic>> sliderPrefs = {};

    // Fetch the "slider-prefs" of all roommates in the household
    // debugPrint("Existing roommates in _getUser() $existingRoommates");
    // for (String roomieEmail in existingRoommates) {
    //   debugPrint("roomieEmail $roomieEmail");
      // QuerySnapshot userSnapshot = await FirebaseFirestore.instance
      //     .collection('users')
      //     .where('email', isEqualTo: roomieEmail)
      //     .get();



      // QuerySnapshot userSnapshot = await FirebaseFirestore.instance
      //     .collection('users')
      //     .where(roomieEmail)
      //     .get();

      //   if (userSnapshot.docs.isNotEmpty) {
      //     DocumentSnapshot userDoc = userSnapshot.docs.first;
      //     sliderPrefs[roomieEmail] = userDoc['slider-prefs'];
      //   }
      // debugPrint("Slider prefs: $sliderPrefs");


      Map<String, dynamic> sliderPrefs = {};

      // Iterate through each roommate's email address
      for (String email in existingRoommates) {
        // Fetch the user document corresponding to the email address
        debugPrint("email to try to pref is $email");
//         try {
//         DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
//             .collection('users')
//             .doc(email)
//             .get();
//         // Check if the user document exists and has data
//         if (userSnapshot.exists && userSnapshot.data() != null) {
//           // Explicitly cast the data to Map<String, dynamic>
//           Map<String, dynamic> userData =
//               userSnapshot.data() as Map<String, dynamic>;

//           // Extract the 'slider-prefs' attribute from the user document
//           Map<String, dynamic> userPrefs = userData['slider-prefs'];

//           // Add the user's slider preferences to the sliderPrefs map
//           sliderPrefs[email] = userPrefs;
//         } else {
//           debugPrint("User document not found for email: $email");
//         }
//         } catch (e) {
//           debugPrint("Error executing query: $e");
//         }
        
//       }

//       // Print all slider prefs
//       debugPrint("Slider Prefs:");
//       sliderPrefs.forEach((email, prefs) {
//         debugPrint("$email, $prefs");
//       });
//       String algorithmicChoice = await runComplexAlgorithm(sliderPrefs, existingRoommates.length);
//       // more likely than not, this will need to change to Future<String>
//       return algorithmicChoice;
//   }
// }
      try {
        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .get();
        if (userSnapshot.docs.isNotEmpty) {
        DocumentSnapshot userDoc = userSnapshot.docs.first;
        sliderPrefs[email] = userDoc['slider-prefs'];
        }
        // Handle the result...
        debugPrint("Slider prefs: $sliderPrefs");
        // final Map<String, Map<String, double>> finalSliderPrefs = Map.from(sliderPrefs);
        
      } catch (e) {
        debugPrint("Error executing query: $e");
      
      
      }
        // debugPrint("SLIDER PREFS CREATED.");
        // debugPrint(sliderPrefs.keys.toString());
      }

    // PHASE 1: Determine if all roomies are assigned an equal number of chores. If yes, good. If no, assign to whoever has the lowest number of chores.
    String minAssignee = await isEqualNumChores(currUserModel);
    if (minAssignee != "equal"){
      debugPrint("assignee determined within phase 1");
      return minAssignee;
    }

    // PHASE 2: The modified Adjusted Winner Algorithm
    Map<String, String> algorithmicPreferences = await assignPreferences(sliderPrefs, existingRoommates.length);
    debugPrint("FINAL ASSIGNMENT FOR REAL: $algorithmicPreferences");
    // return algorithmicChoice;

    // PHASE 3: Nothing else yielded a result, so just pick someone at random
    Future<String> randomChoice = _getRandomUser(existingRoommates);
    String awaitedRandomChoice = await randomChoice;
    return awaitedRandomChoice;
  }
}

  Future<String> isEqualNumChores(UserModel um) async {
    debugPrint("=========isEqualNumChores()============");
    List<String> assigneeEmails = [];
     try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('households')
          .doc(um.currHouse)
          .collection('chores')
          .get();

      querySnapshot.docs.forEach((doc) {
        var data = doc.data() as Map<String, dynamic>;
          String assignee = data['assignee'] as String;
            assigneeEmails.add(assignee);
      });

    Map<String, int> frequencyMap = {};
    for (String a in assigneeEmails) {
      frequencyMap[a] = (frequencyMap[a] ?? 0) + 1;
    }
    int firstFrequency = frequencyMap.values.first;
    bool isFrequencyEqual = frequencyMap.values.every((frequency) => frequency == firstFrequency);
    String? minFrequencyAssignee;
    if (!isFrequencyEqual) {
      int minFrequency = frequencyMap.values.reduce((value, element) => value < element ? value : element);
      minFrequencyAssignee = frequencyMap.keys.firstWhere((key) => frequencyMap[key] == minFrequency);
      return minFrequencyAssignee;
    }
    } catch (e) {
      debugPrint('Error getting chores: $e');
      // Handle error
    }
    return "equal";
  }

  Future<Map<String, String>> assignPreferences(Map<String, dynamic> sp, int numRoommates) async {
    ///////////////////////////////////////////////////////// Adjusted Winner algorithm here
    //
    // [OPTIONAL] (not in this file): First make sure that preferences page caps the total points assignable to 0.8p where p is the number of preferences.
    //
    // For each preference, determine which roommate wins that preference (naive). Ties are awarded based on who has the lower number of wins at the time of the tie (well, ideally). Result: winningPrefNaive is a map containing the winner of each category and their score.
    debugPrint("=====================runComplexAlgorithm()====================================");
    Map<String, List<dynamic>> winningPrefNaive = {};
    Map<String, String> winningPrefNaiveCategoriesOnly = {};
    Map<String, List<dynamic>> losingPrefNaive = {};
    List<String> roomieEmails = sp.keys.toList();

    // Iterate through each chore category
    sp[roomieEmails.first].forEach((choreCategory1, _) {
      var maxValRoomieEmail = roomieEmails.first;
      var minValRoomieEmail = roomieEmails.first;
      var maxVal = sp[roomieEmails.first][choreCategory1];
      var minVal = sp[roomieEmails.first][choreCategory1];

      // Compare the values for each chore category for all users
      for (var roomieEm in roomieEmails) { // .skip(1)
        var roomieVal = sp[roomieEm][choreCategory1];
        if (roomieVal > maxVal) {
          maxVal = roomieVal;
          maxValRoomieEmail = roomieEm;
        }
        if (roomieVal < minVal) {
          minVal = roomieVal;
          minValRoomieEmail = roomieEm;
        }
        List<dynamic> maxTuple = [maxValRoomieEmail, maxVal];
        winningPrefNaive[choreCategory1] = maxTuple;
        winningPrefNaiveCategoriesOnly[choreCategory1] = maxValRoomieEmail;
        List<dynamic> minTuple = [minValRoomieEmail, minVal];
        losingPrefNaive[choreCategory1] = minTuple;

      }
      // debugPrint($winningPrefNaive);
    });
    // Calculate each roommate's total of winning preferences.
    // Create double variables for each user
    Map<String, double> userVariablesMax = {};
    Map<String, double> userVariablesMin = {};

    // Iterate through winning preferences and increment user variables
    winningPrefNaive.forEach((choreCategory, values) {
      String userEmail = values[0];
      debugPrint("wPN email $userEmail");
      double value = values[1];
      userVariablesMax[userEmail] = (userVariablesMax[userEmail] ?? 0.0) + value;
    });

    debugPrint("winningPrefNaive $winningPrefNaive");
    debugPrint("userVariablesMax $userVariablesMax");
    // Print out the values of user variables
    userVariablesMax.forEach((userEmail, value) {
      debugPrint('User $userEmail: $value');
    });

    losingPrefNaive.forEach((choreCategory, values) {
      String userEmail = values[0];
      debugPrint("LPN email $userEmail");
      double value = values[1];
      userVariablesMin[userEmail] = (userVariablesMin[userEmail] ?? 0.0) + value;
    });

    debugPrint("losingPrefNaive $losingPrefNaive");
    debugPrint("userVariablesMin $userVariablesMin");
    // Print out the values of user variables
    userVariablesMin.forEach((userEmail, value) {
      debugPrint('User $userEmail: $value');
    });

    /// Crown a winningest roommate and losingest roommate
    String winningestRoommate = "";
    double maxValue = double.negativeInfinity;
    userVariablesMax.forEach((key, value) {
      if (value > maxValue) {
        winningestRoommate = key;
        maxValue = value;
      }
    });
    String losingestRoommate = "";
    double minValue = double.infinity;
    userVariablesMin.forEach((key, value) {
      if (value < minValue) {
        losingestRoommate = key;
        minValue = value;
      }
    });
    debugPrint("W $winningestRoommate L $losingestRoommate");
    debugPrint(userVariablesMax.toString());
    debugPrint(userVariablesMin.toString());
    

    /// TODO: Create a ratio for each preference (winningest/losingest)
    Map<String, double> prefRatios = {};
    sp[winningestRoommate].forEach((category, value) {
      double winningestScore = sp[winningestRoommate][category];
      double losingestScore = sp[losingestRoommate][category];
      prefRatios[category] = winningestScore / losingestScore;
    });

    /// TODO: Final step now is to adjust who wins each preference based on the winner-loser ratio. (Real meat of the algo)
    ///
    /// TODO: Check 1: If any roommate did not "win" a preference naively, assign them their highest preference.

   List<String> missingRoomies = List.from(roomieEmails);
   winningPrefNaive.forEach((category, userData) {
   String userEmail = userData.first;
   debugPrint("useremail $userEmail");
   if (missingRoomies.contains(userEmail)) {
     missingRoomies.remove(userEmail);
   }
   });
   debugPrint("missing: $missingRoomies");

   // TODO: For each missing roomie, assign them their highest preference.
  Map<String, double> missingRoomiesPrefs = {};
  Map<String, String> theFinalAssignment = {}; // <email, category>
  List<String> missingRoomiesFake = ['jerry.lisd100@gmail.com'];
  if (missingRoomies.isEmpty){
    // then we are so back
    theFinalAssignment = winningPrefNaiveCategoriesOnly;
    debugPrint("missingRoomies.length == 0 >>> $theFinalAssignment");
  }

  if (missingRoomiesFake.length == 1){
    String missingRoomiesEmail = missingRoomiesFake[0];
    debugPrint(missingRoomiesEmail);
    Map<dynamic, dynamic> roomieValues = sp[missingRoomiesEmail];
    debugPrint(roomieValues.toString());
  
    Map<String, int> emailCountMap = {};
    // Iterate through the categoryEmailMap and count occurrences of each email
    winningPrefNaiveCategoriesOnly.forEach((category, email) {
        emailCountMap.update(email, (value) => value + 1, ifAbsent: () => 1);
      });

    // Find the email address with the maximum count
    String mostFrequentEmail = "";
    int maxCount = 0;

    emailCountMap.forEach((email, count) {
      if (count > maxCount) {
        maxCount = count;
        mostFrequentEmail = email;
      }
    });

    debugPrint('Most frequent email address: $mostFrequentEmail');

    debugPrint("1 missed roomie; his sliderPrefs:");
    debugPrint(roomieValues.toString());

    List<MapEntry<dynamic, dynamic>> sortedRoomieValuesList = roomieValues.entries.toList();

    // Sort the list based on the double values
    sortedRoomieValuesList.sort((a, b) => b.value.compareTo(a.value));

    // Convert the sorted list back into a map
    Map<dynamic, dynamic> sortedRoomieValues = Map.fromEntries(sortedRoomieValuesList);

    sortedRoomieValues.forEach((key, value) {
      debugPrint('$key: $value');
    });

    bool reassigned = false;
    sortedRoomieValues.forEach((key, value) {
      if (reassigned) return;
      String? email = theFinalAssignment[key];
      if (email != null) {
        int count = theFinalAssignment.values.where((e) => e == email).length;
        if (count > 1) {
          theFinalAssignment[key] = missingRoomiesEmail;
          reassigned = true;
        }
      }
    });
    
    if (!reassigned) {
      debugPrint("Somehow, there was no reassignment possible.");
    }

    debugPrint("missingRoomies.length == 1 >>> $theFinalAssignment");
  }
  // for (String roomieEmail in missingRoomies) {
    
  //     // First, check if the key exists in the map
  //     if (sp.containsKey(roomieEmail)) {
  //       debugPrint("F");
  //       // Access the value corresponding to the key
  //       Map<String, double> roomieValues = sp[roomieEmail.toString()];

  //       // Now you have the map containing category and value pairs
  //       // You can access individual values by their category key
  //       roomieValues.forEach((category, value) {
  //         // Here you have access to each category and its value for the current missing roomie
  //         print('Email: $roomieEmail, Category: $category, Value: $value');
  //         // Do whatever processing you need to do with the category and value
  //       });
  //     } else {
  //       // Handle the case where the missing roomie's email is not found in the map
  //       debugPrint('No data found for email: $roomieEmail');
  //     }
  //   }

    /// TODO: Determine the highest pref ratio. This is the one where the winningest preferred it the most and the losingest preferred it the least.
    ///   If r = 2, do nothing.
    ///   If r > 2, award to a middle roommate at random.
    /// 
    /// 
    /// 
    /// 
    /// 
    /// 
    return theFinalAssignment;


    // String result = await _getRandomUser(roomieEmails);

    // // Now you have the result as a String
    // return result;
  }

  Future<String> _getRandomUser(List<String> roommates) async {
    debugPrint("Available roommates $roommates");
    Random random = Random();
    return roommates[random.nextInt(roommates.length)];
  }


class _AutoAssignState extends State<AutoAssignClass> {
  @override
  Widget build(BuildContext context) {
    return const Text("If you're reading this, something's wrong");
  }
}
