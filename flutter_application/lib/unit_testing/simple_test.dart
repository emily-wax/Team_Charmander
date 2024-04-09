import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application/SignInPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/unit_testing/household_create_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String? email,
    required String? password,
  }) =>
      super.noSuchMethod(
          Invocation.method(#createUserWithEmailAndPassword, [email, password]),
          returnValue: Future.value(MockUserCredential()));
}

void main() {
  late MockFirebaseAuth mockFirebaseAuth;
  late SignInPageState signInPageState;
  late MockUserCredential mockUserCredential;
  late MockUser mockUser;


  setUpAll(() async {
      mockFirebaseAuth = MockFirebaseAuth();
      signInPageState = SignInPageState(firebaseAuth: mockFirebaseAuth);
      mockUserCredential = MockUserCredential();
      mockUser = MockUser();


      when(mockUserCredential.user).thenReturn(mockUser);
  });

  tearDown(() {});

  test("Create Account", () async {
    when(
      mockFirebaseAuth.createUserWithEmailAndPassword(
        email: 'emily.wax@tamu.edu', password: '123456')
      ).thenAnswer((_) async => mockUserCredential);

      expect(await signInPageState.create_account('emily.wax@tamu.edu', '123456'), 'Success' );
  });

}