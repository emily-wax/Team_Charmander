import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application/theme_provider.dart';
import 'user_model.dart';
// import 'global_variables.dart';



class PreferenceSlider extends StatefulWidget {
  final FirebaseFirestore firestoreInstance;
  final String userEmail;

  const PreferenceSlider({Key? key, required this.firestoreInstance, required this.userEmail}) : super(key: key);

  @override
  _PreferenceSliderState createState() => _PreferenceSliderState();
}

class _PreferenceSliderState extends State<PreferenceSlider> {
  double _cleanerValue = 0.5; // Initial value for the slider
  double _organizerValue = 0.5;
  double _outdoorValue = 0.5;
  double _maintainValue = 0.5;
  double _morningValue = 0.5;
  double _eveningValue = 0.5;
  bool _darkMode = false;
  UserModel? currUserModel;

  ThemeProvider? theme;

  // Define the _savePreferences method here
  @override
  void initState() {
    super.initState();
    // Fetch values from Firestore when the dialog is initialized
    _setUpTheme();
    fetchDataFromFirestore();
    _fetchUserModel();
  }

  void _setUpTheme() {
    theme = ThemeProvider(widget.firestoreInstance, widget.userEmail);
  }

  void _fetchUserModel() async {
    try {
      currUserModel = await readData( widget.userEmail, widget.firestoreInstance );
      setState(() {}); // Trigger a rebuild after getting the user model
    } catch (error) {
      // Handle error here, such as displaying an error message or retrying
      print('Error fetching user data: $error');
    }
  }

  // Method to fetch data from Firestore
  void fetchDataFromFirestore() async {
    UserModel currUserModel = await readData( widget.userEmail, widget.firestoreInstance );

    // Fetch values from Firestore and update state variables accordingly
    // Example:
    try {
      await widget.firestoreInstance
        .collection('users')
        .doc(currUserModel.id)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        Map<String, dynamic> sliderPrefs = documentSnapshot['slider-prefs'];

        setState(() {
          _cleanerValue = sliderPrefs['cleaner'] ?? 0.5;
          _organizerValue = sliderPrefs['organizer'] ?? 0.5;
          _outdoorValue = sliderPrefs['outdoor'] ?? 0.5;
          _maintainValue = sliderPrefs['maintain'] ?? 0.5;
          _morningValue = sliderPrefs['morning'] ?? 0.5;
          _eveningValue = sliderPrefs['evening'] ?? 0.5;
          _darkMode = documentSnapshot['darkMode'] ?? false;
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
    UserModel currUserModel = await readData( widget.userEmail, widget.firestoreInstance);
    try {
      await widget.firestoreInstance.collection('users').doc(currUserModel.id).set({
        'slider-prefs': {
          'cleaner': _cleanerValue,
          'organizer': _organizerValue,
          'outdoor': _outdoorValue,
          'maintain': _maintainValue,
          'morning': _morningValue,
          'evening': _eveningValue,
        },
        'darkMode': _darkMode,
      }, SetOptions(merge: true));
      // print('Preferences saved successfully!');
    } catch (e) {
      debugPrint('Failed to save preferences: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    theme = themeProvider;
    // stream: FirebaseFirestore.instance.collection('households').doc(currUserModel!.currHouse).collection('appliances').snapshots(),
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("I like to clean"),
        Slider(
        
        value: _cleanerValue,
        activeColor: theme?.buttonColor,
        onChanged: (newValue) {
          setState(() {
            _cleanerValue = newValue; // Update the value here
          });
          _savePreferences(); // Save the updated value
        },
        min: 0,
        max: 1,
        divisions: 10, // You can adjust the divisions as needed
        // label: 'let\'s get it',
        ),
        const Text("I like to organize"),
        Slider(
        value: _organizerValue,
        activeColor: theme?.buttonColor,
        onChanged: (newValue) {
          setState(() {
            _organizerValue = newValue; // Update the value here
          });
          _savePreferences(); // Save the updated value
        },
        min: 0,
        max: 1,
        divisions: 10, // You can adjust the divisions as needed
        // label: 'yes so satisfying',
        ),
        const Text("I like to maintain household items"),
        Slider(
          value: _maintainValue,
          activeColor: theme?.buttonColor,
          onChanged: (newValue) {
            setState(() {
              _maintainValue = newValue; // Update the value here
            });
            _savePreferences(); // Save the updated value
          },
          min: 0,
          max: 1,
          divisions: 10, // You can adjust the divisions as needed
          // label: 'yes so satisfying',
        ),
        const Text("I don't mind outdoor chores"),
        Slider(
          value: _outdoorValue,
          activeColor: theme?.buttonColor,
          onChanged: (newValue) {
            setState(() {
              _outdoorValue = newValue; // Update the value here
            });
            _savePreferences(); // Save the updated value
          },
          min: 0,
          max: 1,
          divisions: 10, // You can adjust the divisions as needed
          // label: 'yeah i don\'t mind',
        ),
        const Text("I want to do chores in the morning"),
        Slider(
          value: _morningValue,
          activeColor: theme?.buttonColor,
          onChanged: (newValue) {
            setState(() {
              _morningValue = newValue; // Update the value here
            });
            _savePreferences(); // Save the updated value
          },
          min: 0,
          max: 1,
          divisions: 10, // You can adjust the divisions as needed
          // label: 'early bird gets the worm!',
        ),
        const Text("I want to do chores in the evening"),
        Slider(
          value: _eveningValue,
          activeColor: theme?.buttonColor,
          onChanged: (newValue) {
            setState(() {
              _eveningValue = newValue; // Update the value here
            });
            _savePreferences(); // Save the updated value
          },
          min: 0,
          max: 1,
          divisions: 10, // You can adjust the divisions as needed
          // label: 'evening vibes!',
        ),
        Row(
        children: [
        const Text('Dark Mode: '),
        Switch(
          value: _darkMode,
          activeColor: theme?.buttonColor,
          onChanged: (value) {
            setState(() {
              _darkMode = value;
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
