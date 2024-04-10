import 'package:flutter/material.dart';

// Define your light theme using colorScheme.light()
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Colors.white,
  // accentColor: Colors.lightBlue, // Set the accent color to light blue
  backgroundColor: Colors.white,
  scaffoldBackgroundColor: Colors.white,
  textTheme: TextTheme(
    headline6: TextStyle(
      fontSize: 24,
      color: Colors.black, // Set the headline text color
    ),
    button: TextStyle(
      fontSize: 20,
      color: Colors.black, // Set the button text color
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: MaterialStateProperty.all<Color>(Colors.lightBlue.withOpacity(0.75)), // Set the button background color
    ),
  ),
);

final darkTheme = ThemeData(
  primaryColor: Colors.grey[900],
  // accentColor: Colors.grey[700],
  backgroundColor: Colors.grey[800],
  iconTheme: IconThemeData(color: Colors.white),
  textTheme: TextTheme(
    headline6: TextStyle(
      fontSize: 24,
      color: Colors.white,
    ),
  ),
);