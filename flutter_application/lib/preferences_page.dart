import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';
// import 'global_variables.dart';

class PreferenceSlider extends StatefulWidget {
  @override
  _PreferenceSliderState createState() => _PreferenceSliderState();
}

class _PreferenceSliderState extends State<PreferenceSlider> {
  double _cleanerValue = 0.5; // Initial value for the slider
  double _organizerValue = 0.5;
  double _outdoorValue = 0.5;
  double _morningValue = 0.5;
  double _eveningValue = 0.5;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // Fetch values from Firestore when the dialog is initialized
    fetchDataFromFirestore();
  }

  // Method to fetch data from Firestore
  void fetchDataFromFirestore() async {
    UserModel currUserModel = await readData();

    // Fetch values from Firestore and update state variables accordingly
    // Example:
    try {
      await _firestore
        .collection('users')
        .doc(currUserModel.id)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        Map<String, dynamic> sliderPrefs = documentSnapshot['slider-prefs'];

        setState(() {
          _cleanerValue = sliderPrefs['cleaner'] ?? 0.5;
          // _cleanerValue = documentSnapshot['cleaner'];
          _organizerValue = sliderPrefs['organizer'] ?? 0.5;
          _outdoorValue = sliderPrefs['outdoor'] ?? 0.5;
          _morningValue = sliderPrefs['morning'] ?? 0.5;
          _eveningValue = sliderPrefs['evening'] ?? 0.5;
        });
      } else {
        debugPrint('Document does not exist on the database');
      }
    });
    } catch (e) {
      debugPrint('Failed to grab preferences: $e');
    }
  }


  // potentially need to do update() instead of set()
  void _savePreferences() async {
    UserModel currUserModel = await readData();
    try {
      await _firestore.collection('users').doc(currUserModel.id).set({
        'slider-prefs': {
          'cleaner': _cleanerValue,
          'organizer': _organizerValue,
          'outdoor': _outdoorValue,
          'morning': _morningValue,
          'evening': _eveningValue,
        }
      }, SetOptions(merge: true));
      // print('Preferences saved successfully!');
    } catch (e) {
      debugPrint('Failed to save preferences: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("I like to clean"),
        Slider(
        value: _cleanerValue,
        onChanged: (newValue) {
          setState(() {
            _cleanerValue = newValue; // Update the value here
          });
          _savePreferences(); // Save the updated value
        },
        min: 0,
        max: 1,
        divisions: 10, // You can adjust the divisions as needed
        label: 'let\'s get it',
        ),
        const Text("I like to organize"),
        Slider(
        value: _organizerValue,
        onChanged: (newValue) {
          setState(() {
            _organizerValue = newValue; // Update the value here
          });
          _savePreferences(); // Save the updated value
        },
        min: 0,
        max: 1,
        divisions: 10, // You can adjust the divisions as needed
        label: 'yes so satisfying',
        ),
        const Text("I don't mind outdoor chores"),
        Slider(
          value: _outdoorValue,
          onChanged: (newValue) {
            setState(() {
              _outdoorValue = newValue; // Update the value here
            });
            _savePreferences(); // Save the updated value
          },
          min: 0,
          max: 1,
          divisions: 10, // You can adjust the divisions as needed
          label: 'yeah i don\'t mind',
        ),
        const Text("I want to do chores in the morning"),
        Slider(
          value: _morningValue,
          onChanged: (newValue) {
            setState(() {
              _morningValue = newValue; // Update the value here
            });
            _savePreferences(); // Save the updated value
          },
          min: 0,
          max: 1,
          divisions: 10, // You can adjust the divisions as needed
          label: 'early bird gets the worm!',
        ),
        const Text("I want to do chores in the evening"),
        Slider(
          value: _eveningValue,
          onChanged: (newValue) {
            setState(() {
              _eveningValue = newValue; // Update the value here
            });
            _savePreferences(); // Save the updated value
          },
          min: 0,
          max: 1,
          divisions: 10, // You can adjust the divisions as needed
          label: 'evening vibes!',
        ),
      ],
    );
  }
}