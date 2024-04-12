import 'package:flutter/material.dart';
import 'package:flutter_application/SignInPage.dart';
import 'account_page.dart';
import 'chores_page.dart';
import 'appliances_page.dart';
import 'calendar_page.dart'; // Import the CalendarPage
import 'package:firebase_auth/firebase_auth.dart';
import 'theme_provider.dart'; // Import your themes file
import 'package:provider/provider.dart';


class HomePage extends StatelessWidget {
  const HomePage({Key? key});

  void _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigate to the login screen or any other screen you want after logout
      // For example:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignInPage()),
      );
    } catch (e) {
      print('Error logging out: $e');
      // Show a snackbar or an alert dialog to indicate the error to the user
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              print('Home icon pressed!');
            },
          ),
          Tooltip(
            message: 'Log out',
            child: IconButton(
              icon: Icon(Icons.logout),
              onPressed: () => _logout(context),
            ),
          )
        ],
      ),
      body: Container(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.house,
                size: 100,
                color: themeProvider.selectedTheme.iconTheme.color, // Use theme icon color
              ),
              SizedBox(height: 20),
              Text(
                'Welcome to Your House!',
                style: themeProvider.selectedTheme.textTheme.headline6, // Use theme text style
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ToDoList()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.buttonColor, // Use theme background color
                ),
                child: Text(
                  'Chores',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AccountPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.buttonColor// Use theme background color
                ),
                child: Text(
                  'Account',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AppliancesPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.buttonColor, // Use theme background color
                ),
                child: Text(
                  'Appliances',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CalendarPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.buttonColor, // Use theme background color
                ),
                child: Text(
                  'Calendar',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void addTheme() {
  
}
