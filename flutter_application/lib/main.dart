import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application/account_page.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'HomePage.dart';
import 'SignInPage.dart';
import 'calendar_page.dart'; // Import the CalendarPage
import 'theme_provider.dart';

final FirebaseOptions firebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyC_5CMA0uX6Dw8PLvlJs4Y8hzFU1bayZtg",
  authDomain: "team-charmander-482.firebaseapp.com",
  projectId: "team-charmander-482",
  storageBucket: "team-charmander-482.appspot.com",
  messagingSenderId: "1026902486548",
  appId: "1:1026902486548:web:9a624b1af755490ce60101",
  measurementId: "G-HE791BZ4WF"
);

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseOptions);

  // Create an instance of AuthService to check if the user is signed in
  AuthService authService = AuthService();
  bool isUserSignedIn = await authService.isUserSignedIn();

  runApp(MyApp(
    true,
    isUserSignedIn: isUserSignedIn,
  ));
}

class MyApp extends StatelessWidget {
  final bool isUserSignedIn;

  MyApp(bool bool, {required this.isUserSignedIn});

   @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider.value(value: isUserSignedIn),
      ],
      child: Consumer2<ThemeProvider, bool>(
        builder: (context, themeProvider, isUserSignedIn, _) {
          return MaterialApp(
            title: 'House App',
            theme: themeProvider.selectedTheme,
            // Use the HomePage or SignInPage based on the user's sign-in status
            home: isUserSignedIn ? HomePage() : SignInPage(),
          );
        },
      ),
    );
  }
}