import 'package:flutter/material.dart';
import 'package:flutter_application/SignInPage.dart';
import 'package:flutter_application/user_model.dart';
import 'account_page.dart';
import 'chores_page.dart';
import 'appliances_page.dart';
import 'calendar_page.dart'; // Import the CalendarPage
import 'package:firebase_auth/firebase_auth.dart';
// import 'theme_provider.dart'; // Import your themes file
// import 'package:provider/provider.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'user_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key});
  // final bool _isThemeInitialized = false;
  
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late PageController _pageController;
  int _selectedIndex = 0;
  UserModel? currUserModel;

  @override
  void initState() {
    super.initState();
    _fetchUserModel();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  void _fetchUserModel() async {
    try {
      currUserModel = await readData();
      setState(() {}); // Trigger a rebuild after getting the user model
    } catch (error) {
      // Handle error here, such as displaying an error message or retrying
      print('Error fetching user data: $error');
    }
  }

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
    // final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          AccountPage(),
          const ToDoList(),
          const AppliancesPage(),
          const CalendarPage(),
          
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            
            _fetchUserModel();
            Future.delayed(Duration(seconds: 1), () {
              if( index != 0 && currUserModel?.currHouse == ""){

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Container(
                      height: MediaQuery.of(context).size.height * 0.05, // Adjust the height as needed
                      child: Center(
                        child: Text(
                          'Must join or create a household before switching to this page.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 1, milliseconds: 300)
                  ),
                );
                
              } else {
                _selectedIndex = index;
                _pageController.animateToPage(index,
                    duration: Duration(milliseconds: 300), curve: Curves.ease);
              }
            } );


          });
        },
        // selectedItemColor: Color.fromARGB(255, 12, 212, 22), // Color for selected icon and label
        // unselectedItemColor: Color.fromARGB(255, 12, 212, 22).withOpacity(0.5),
        selectedItemColor: (Colors.lightBlue.withOpacity(0.75)),
        unselectedItemColor: (Colors.lightBlue.withOpacity(0.25)),
        backgroundColor: Colors.blue, // Periwinkle blue color // Color for unselected icon and label
        items: [
          BottomNavigationBarItem(
            tooltip: "Account",
            icon: Icon(Icons.account_circle),
            label: 'Account',
          ),
          BottomNavigationBarItem(
            tooltip: "To-Do List",
            icon: Icon(Icons.checklist),
            label: 'Chores', 
          ),
          BottomNavigationBarItem(
            tooltip: "Appliances",
            icon: Icon(Icons.devices),
            label: 'Appliances',
          ),
          BottomNavigationBarItem(
            tooltip: "Calendar",
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ), 
        ],
      ),
      );
    // );
  }
}

