import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

class ThemeProvider extends ChangeNotifier {
  late ThemeData _selectedTheme; // Selected theme
  Color buttonColor = Color.fromARGB(255, 8, 174, 245);
  Color textColor = Colors.white;
  Color inputColor = Colors.black;

  ThemeProvider() {
    _selectedTheme = fetchLightTheme(); // Set default theme
    inputColor = Colors.black;
    _initializeTheme(); // Initialize theme based on user preference
  }

  ThemeData get selectedTheme => _selectedTheme; // Getter for selected theme

  Future<void> _initializeTheme() async {
  try {
    UserModel currUserModel = await readData();
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
