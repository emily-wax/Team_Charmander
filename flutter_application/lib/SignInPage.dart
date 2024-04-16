import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/account_page.dart';
import 'auth_service.dart'; // Import the AuthService
import 'HomePage.dart';
import 'user_model.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final AuthService authService = AuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool isSignUp = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isSignUp ? 'Sign Up' : 'Sign In'),
      ),
      body: Container( 
        color: Colors.white,// Soft green background
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                isSignUp ? 'Welcome to RoomiePal!' : 'Sign In to Your Account',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  filled: true,
                  fillColor: Color.fromARGB(221, 235, 231, 231),
                  
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  filled: true,
                  fillColor: Color.fromARGB(221, 235, 231, 231),
                ),
                obscureText: true,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                "Password must be at least 6 characters.",
                textAlign: TextAlign.left
                ),
              ),
              ElevatedButton(
                onPressed: isLoading ? null : () => _authenticate(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 8, 174, 245), // White button
                ),
                child: Text(isSignUp ? 'Sign Up' : 'Sign In', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  setState(() {
                    isSignUp = !isSignUp;
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: Color.fromARGB(255, 8, 174, 245), // Blue color for "already have an account?"
                ),
                child: Text(
                  isSignUp
                      ? 'Already have an account? Sign In'
                      : 'Don\'t have an account? Sign Up',
                ),
              ),
              if (isLoading) const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  void _authenticate() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      String email = emailController.text.trim();
      String password = passwordController.text.trim();

      try {
        if (isSignUp) {
          // Sign Up
          await authService.signUpWithEmailAndPassword(email, password);
          
          // adds user to database when signing up
          _createData(UserModel('0', email, "", false, {'cleaner': 0.5, 'evening': 0.5, 'morning': 0.5, 'organizer': 0.5, 'outdoor': 0.5}));

        } else {
          // Sign In
          await authService.signInWithEmailAndPassword(email, password);
        }

        // Navigate to HomePage after signing in/up
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } catch (e) {
        // Handle sign-in/up errors, e.g., show an error message
        print("Failed to authenticate: $e");

        // Show an error snackbar or dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Authentication failed. Please check your credentials."),
          ),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Creates user data
  void _createData(UserModel userModel) {
      final userCollection = FirebaseFirestore.instance.collection("users");

      String id = userCollection.doc().id;

      final newUser = UserModel(
        id,
        userModel.email, 
        userModel.currHouse,
        userModel.darkMode,
        userModel.preferences
      ).toJson();

      userCollection.doc(id).set(newUser);
  }
}