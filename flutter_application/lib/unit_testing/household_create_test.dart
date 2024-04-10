
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application/household_create.dart'; // Import your file

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockUser extends Mock implements User {}

void main() {
  late HouseholdCreateFormState formState;
  final mockFirebaseAuth = MockFirebaseAuth();
  final mockFirestore = MockFirebaseFirestore();
  final mockUser = MockUser();

  setUp(() {
    final form = HouseholdCreateForm(firebaseAuth: mockFirebaseAuth, firestore: mockFirestore) {
      
    };

    formState = form.createState();
  });

  test('Test saveHouseholdToFirebase', () async {
    
    when(mockFirebaseAuth.currentUser).thenReturn( mockUser ); // Mock currentUser

    final doesHouseholdExistSpy = spy((householdId) => formState.doesHouseholdExist(householdId));

    // Stubbing the spy
    when(doesHouseholdExistSpy(any)).thenAnswer((_) async => false);

    // Using the spy in formState
    formState.doesHouseholdExist = doesHouseholdExistSpy;

    // Mock doesHouseholdExist to return false
    when(formState.doesHouseholdExist('Test Household')).thenAnswer((_) async => false);

    formState.saveHouseholdToFirebase('Test Household', 5, 'password123');

    // Verify that Firestore method was called with correct arguments
    verify(mockFirestore.collection('households').doc('Test Household').set({
      'name': 'Test Household',
      'password': 'password123',
      'max_roommate_count': 5,
      'roommates': [any]
    })).called(1);

    // Verify that the SnackBar was shown
    expect(find.text('Object submitted successfully'), findsOneWidget );
  });
}
