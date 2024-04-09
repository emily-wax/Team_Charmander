import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart'; // Import the AuthService
import 'package:firebase_auth/firebase_auth.dart';
import 'HomePage.dart';
import 'user_model.dart';

class SignInPage extends StatefulWidget {
  SignInPage({super.key});

  final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  SignInPageState createState() => SignInPageState( firebaseAuth: auth );
  
}

class SignInPageState extends State<SignInPage> {
  final FirebaseAuth firebaseAuth;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool isSignUp = false;

  SignInPageState( {
    required this.firebaseAuth
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isSignUp ? 'Sign Up' : 'Sign In'),
        backgroundColor: Colors.white, // White app bar
      ),
      body: Container(
        color: Colors.lightGreen[100], // Soft green background
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isSignUp ? 'Sign Up' : 'Sign In',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue, // Blue color for "Sign In" or "Sign Up" text
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  filled: true,
                  fillColor: Colors.white,
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
                  fillColor: Colors.white,
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
              ElevatedButton(
                onPressed: isLoading ? null : () => _authenticate(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // White button
                ),
                child: Text(isSignUp ? 'Sign Up' : 'Sign In'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  setState(() {
                    isSignUp = !isSignUp;
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue, // Blue color for "already have an account?"
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

  Future<String?> create_account(String email, String password) async {

    try {
      
      await firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);

      return 'Success';
  
    }  on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      rethrow;
    }

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
          create_account(email, password);
          
          // adds user to database when signing up
          _createData(UserModel('0', email, password, ""));

        } else {
          // Sign In
          await firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
        }

        // Navigate to HomePage after signing in/up
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
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
        userModel.password,
        userModel.currHouse,
      ).toJson();

      userCollection.doc(id).set(newUser);
  }
}