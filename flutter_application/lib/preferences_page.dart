import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application/theme_provider.dart';
import 'user_model.dart';

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
  bool _darkMode = false;
  Future<UserModel> currUserModel = readData();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Define the _savePreferences method here
  void _savePreferences() async {
    // Save the preferences to Firestore
    UserModel currUserModel = await readData();

    try {
      await _firestore.collection('users').doc(currUserModel.id).set({
        'slider-prefs': {
          'cleaner': _cleanerValue,
          'organizer': _organizerValue,
          'outdoor': _outdoorValue,
          'morning': _morningValue,
          'evening': _eveningValue,
        },
        'darkMode': _darkMode,
      }, SetOptions(merge: true));
      // print('Preferences saved successfully!');
    } catch (e) {
      print('Failed to save preferences: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // stream: FirebaseFirestore.instance.collection('households').doc(currUserModel!.currHouse).collection('appliances').snapshots(),
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
        Row(
        children: [
        const Text('Dark Mode: '),
        Switch(
          value: _darkMode,
          onChanged: (value) {
            setState(() {
              _darkMode = !_darkMode;
            });
            _savePreferences();
            Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            // if (value) {
            //   Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            // } else {
            //   Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            // }
          },
        ),
      ],
      ),
      ],
    );
  }
}
