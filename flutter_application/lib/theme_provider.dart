import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

class ThemeProvider extends ChangeNotifier {
  late ThemeData _selectedTheme; // Selected theme
  Color buttonColor = Color.fromARGB(255, 3, 127, 180);
  Color textColor = Colors.white;
  Color inputColor = Colors.black;
  final FirebaseFirestore firestoreInstance;
  final String userEmail;

  ThemeProvider(this.firestoreInstance, this.userEmail) {
    _selectedTheme = fetchLightTheme(); // Set default theme
    inputColor = Colors.black;
    initializeTheme(); // Initialize theme based on user preference
  }

  ThemeData get selectedTheme => _selectedTheme; // Getter for selected theme

Future<void> initializeTheme() async {
  try {
    UserModel currUserModel = await readData( userEmail, firestoreInstance );
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
        await _firestore.collection('users').doc(currUserModel.id).get();

    var darkMode = documentSnapshot['darkMode'];
    _selectedTheme = darkMode ?? false ? fetchDarkTheme() : fetchLightTheme();
    if (_selectedTheme == fetchDarkTheme()) {
      inputColor = Colors.white;
    }
  } catch (e) {
    print('Error initializing theme: $e');
    // In case of error, use the default light theme
    _selectedTheme = fetchLightTheme();
  }

  // Only notify listeners if the theme has been successfully initialized
  notifyListeners();
}


  void toggleTheme() {
    _selectedTheme =
        _selectedTheme == fetchLightTheme() ? fetchDarkTheme() : fetchLightTheme();
    if (_selectedTheme == fetchDarkTheme()) {
      inputColor = Colors.white;
    } else {
      inputColor = Colors.black;
    }
    notifyListeners(); // Notify listeners to update UI with the new theme
  }

  // Define your light theme using ThemeData.light()
  ThemeData fetchLightTheme() {
    return ThemeData.light();
  }

  // Define your dark theme using ThemeData.dark()
  ThemeData fetchDarkTheme() {
    return ThemeData.dark();
  }
}
