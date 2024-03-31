import 'package:flutter/material.dart';
import 'package:flutter_application/SignInPage.dart';
import 'account_page.dart';
import 'chores_page.dart';
import 'appliances_page.dart';
import 'calendar_page.dart'; // Import the CalendarPage
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key});

  void _logout( BuildContext context ) async {
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
          IconButton( 
            icon: Icon(Icons.logout),
            onPressed:() => _logout(context),
          ), 
        ],
      ),
      body: Container(
        color: Colors.yellow[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.house,
                size: 100,
                color: Colors.green,
              ),
              const SizedBox(height: 20),
              Text(
                'Welcome to Your House!',
                style: TextStyle(
                  fontSize: 24,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Chores()),
                  );
                },
                child: const Text(
                  'Chores',
                  style: TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AccountPage()),
                  );
                },
                child: const Text(
                  'Account',
                  style: TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AppliancesPage()),
                  );
                },
                child: const Text(
                  'Appliances',
                  style: TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CalendarPage()),
                  );
                },
                child: const Text(
                  'Calendar',
                  style: TextStyle(fontSize: 20),
                ),
              ),             
            ],
          ),
        ),
      ),
    );
  }
}