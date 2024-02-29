import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign in anonymously
  Future<UserCredential> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      print("Error signing in anonymously: $e");
      throw Exception("Error signing in anonymously");
    }
  }

  // Check if the user is signed in
  Future<bool> isUserSignedIn() async {
    return _auth.currentUser != null;
  }

  // Get the current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Sign in with email and password
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print("Error signing in with email and password: $e");
      throw Exception("Error signing in with email and password");
    }
  }

  // Sign up with email and password
  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print("Error signing up with email and password: $e");
      throw Exception("Error signing up with email and password");
    }
  }
}
