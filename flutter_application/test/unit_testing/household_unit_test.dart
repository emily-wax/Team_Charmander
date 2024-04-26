/* 
HOW TO GET TEST COVERAGE TO SHOW UP:

aiming for about 90% on each file.

run flutter test --coverage PATH

go to linux environment, 
  - run sudo apt-get install lcov
  - run lcov --list lcov.info   IN COVERAGE FOLDER

*/

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application/account_page.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/theme_provider.dart';
import 'package:provider/provider.dart';

class MockBuildContext extends BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main () {

  late AccountPage accountPage;
  late AccountPageState accountPageState;
  late FirebaseFirestore db;
  String userEmail = 'emily.wax@tamu.edu';
  String userHouse = "House";
  final userPrefs = {'cleaner': 0.5, 'evening': 0.5, 'morning': 0.5, 'organizer': 0.5, 'outdoor': 0.5};
  String houseName;
  int roommateCount;
  String housePassword;

  setUpAll(() async {

    db = FakeFirebaseFirestore();
    
    accountPage = AccountPage(firestoreInstance: db, userEmail: userEmail );
    accountPageState = accountPage.createState();

  });

group('Household Creation', () { 
  testWidgets( 'createHousehold adds a nonexisting household to database', ( WidgetTester tester ) async {

    houseName = 'newhouse';

    // add dummy database data
    await db.collection('users').doc(userEmail).set({
      'email': userEmail,
      'currHouse': '',
      'id': userEmail,
      'darkMode': false,
      'slider-prefs': userPrefs
    });

    // Build our widget and trigger a frame
      // Build our widget and trigger a frame
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => ThemeProvider(db, userEmail), // Provide the mock ThemeProvider
            child: Builder(
              builder: (context) => AccountPage(firestoreInstance: db, userEmail: userEmail),
            ),
          ),
        ),
      );

      // Tap the 'Create Household' button
      await tester.tap(find.text('Create a Household'));
      await tester.pump();

      // Enter text into the TextFields
      await tester.enterText(find.byKey(ValueKey('Household Name')), houseName);
      await tester.enterText(find.byKey(ValueKey('Maximum Roommate Count')), '2');
      await tester.enterText(find.byKey(ValueKey('Password')), 'password');

      // Tap the 'Submit' button
      await tester.tap(find.byKey(Key('submit_button')));
      await tester.pump();
      await tester.pump(Duration(seconds: 1));

      final DocumentSnapshot documentSnapshot =
        await db.collection('households').doc(houseName).get();

      expect(documentSnapshot.exists, true);


  });

  testWidgets( 'createHousehold does not add an existing household to database', ( WidgetTester tester ) async {

    // TODO: change account_page.dart to be pass in friendly all the way through
    houseName = 'ExistingHouse';
    roommateCount = 2;
    housePassword = 'password';


    await db.collection('households').doc(houseName).set({
      'max_roommate_count': roommateCount,
      'name': houseName,
      'password': housePassword,
    });

    // Build our widget and trigger a frame
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => ThemeProvider(db, userEmail), // Provide the mock ThemeProvider
            child: Builder(
              builder: (context) => AccountPage(firestoreInstance: db, userEmail: userEmail),
            ),
          ),
        ),
      );

      // Tap the 'Create Household' button
      await tester.tap(find.text('Create a Household'));
      await tester.pump();

      // Enter text into the TextFields
      await tester.enterText(find.byKey(ValueKey('Household Name')), 'ExistingHouse');
      await tester.enterText(find.byKey(ValueKey('Maximum Roommate Count')), '2');
      await tester.enterText(find.byKey(ValueKey('Password')), 'password');

      // Tap the 'Submit' button
      await tester.tap(find.byKey(Key('submit_button')));
      await tester.pump();
      await tester.pump(Duration(seconds: 1));

      // Verify that the Snackbar displays the correct error message
      // expect(find.byType(SnackBar), findsOneWidget);

      expect(find.byKey(Key('household_duplicate')), findsOneWidget);


   });
  });

  testWidgets('leaveHousehold removes user from household and deletes empty household', (WidgetTester tester) async {

    userEmail = 'test@test.com';
    houseName = 'housetest3';

    await db.collection('users').doc(userEmail).set({
      'email': userEmail,
      'currHouse': houseName,
      'id': userEmail,
      'darkMode': false,
      'slider-prefs': userPrefs
    });
    
    await db.collection('households').doc(houseName).set({
      'max_roommate_count': 2,
      'name': houseName,
      'password': 'password',
      'roommates': [userEmail], // Assuming the current user is a roommate
    });

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => ThemeProvider(db, userEmail), // Provide the mock ThemeProvider
          child: Builder(
            builder: (context) => AccountPage(firestoreInstance: db, userEmail: userEmail),
          ),
        ),
      ),
    );

    await tester.pump(Duration(seconds: 3));

    // Ensure user is in household initially
    expect(find.text(houseName), findsOneWidget);

    await tester.pump(Duration(seconds: 3));

    await tester.tap(find.byKey(ValueKey('Leave House')));
    
    await tester.pump(Duration(seconds: 3));

    // Ensure user is removed from household
    expect(find.text(houseName), findsNothing);

    // Ensure household is deleted
    final DocumentSnapshot documentSnapshot = await db.collection('households').doc(houseName).get();
    expect(documentSnapshot.exists, false);
  });

  testWidgets('joinHousehold successfully adds user to household', (WidgetTester tester) async {

    houseName = 'testhouse3';
    // using user from previous test ... shouldn't  be in a house
    userEmail = 'test@test.com';

    await db.collection('users').doc(userEmail).set({
      'email': userEmail,
      'currHouse': '',
      'id': userEmail,
      'darkMode': false,
      'slider-prefs': userPrefs
    });

    await db.collection('households').doc(houseName).set({
      'max_roommate_count': 2,
      'name': houseName,
      'password': 'password',
      'roommates': []
    });

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => ThemeProvider(db, userEmail), // Provide the mock ThemeProvider
          child: Builder(
            builder: (context) => AccountPage(firestoreInstance: db, userEmail: userEmail),
          ),
        ),
      ),
    );

    await tester.pump(Duration(seconds: 3));

    // Ensure user is not in household initially
    expect(find.text(houseName), findsNothing);

    await tester.pump(Duration(seconds: 3));

    // Tap join household button
    await tester.tap(find.text('Join a Household'));

    await tester.pump(Duration(seconds: 3));

    // Enter household name and password
    await tester.enterText(find.byKey(ValueKey('Household Name')), houseName);
    await tester.enterText(find.byKey(ValueKey('Household Password')), 'password');

    await tester.tap(find.byKey(Key('submit_button')));

    await tester.pump(Duration(seconds: 2));

    // Ensure user is added to household
    DocumentSnapshot userSnapshot = await db.collection('users').doc(userEmail).get();
    String? currentUserHouse = userSnapshot['currHouse'];

    expect(currentUserHouse, houseName);
  });

  testWidgets('cannot join house at capacity', (WidgetTester tester) async {

    houseName = 'testhouse4';
    // using user from previous test ... shouldn't  be in a house
    userEmail = 'test4@test4.com';

    await db.collection('users').doc(userEmail).set({
      'email': userEmail,
      'currHouse': '',
      'id': userEmail,
      'darkMode': false,
      'slider-prefs': userPrefs
    });

    await db.collection('households').doc(houseName).set({
      'max_roommate_count': 2,
      'name': houseName,
      'password': 'password',
      'roommates': ['tester@tamu.edu', 't@gmail.com']
    });

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => ThemeProvider(db, userEmail), // Provide the mock ThemeProvider
          child: Builder(
            builder: (context) => AccountPage(firestoreInstance: db, userEmail: userEmail),
          ),
        ),
      ),
    );

    await tester.pump(Duration(seconds: 3));

    // Ensure user is not in household initially
    expect(find.text(houseName), findsNothing);

    await tester.pump(Duration(seconds: 3));

    // Tap join household button
    await tester.tap(find.text('Join a Household'));

    await tester.pump(Duration(seconds: 3));

    // Enter household name and password
    await tester.enterText(find.byKey(ValueKey('Household Name')), houseName);
    await tester.enterText(find.byKey(ValueKey('Household Password')), 'password');

    await tester.tap(find.byKey(Key('submit_button')));

    await tester.pump(Duration(seconds: 2));

    expect(find.byKey(Key('max_roommates')), findsOneWidget);

  });

}