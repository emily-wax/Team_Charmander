
/* NOTE: must run file as a whole tests are not standalone. */
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application/appliances_page.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application/theme_provider.dart';


void main () {

  late AppliancesPage appliancesPage;
  late AppliancesPageState appliancesPageState;
  late FirebaseFirestore db;
  String userEmail = "jerry.li65@tamu.edu";
  String userHouse = "Jerry Lane";
  final userPrefs = {'cleaner': 0.5, 'evening': 0.5, 'morning': 0.5, 'organizer': 0.5, 'outdoor': 0.5};
  String applianceName;

  setUpAll(() async {

    db = FakeFirebaseFirestore();
    
    appliancesPage = AppliancesPage(firestoreInstance: db, userEmail: userEmail );
    appliancesPageState = appliancesPage.createState();

  });

  test( 'addAppliance adds a valid appliance', () async {

    applianceName = 'appliance';

    await db.collection('users').doc(userEmail).set({
      'email': userEmail,
      'currHouse': userHouse,
      'id': userEmail,
      'darkMode': false,
      'slider-prefs': userPrefs
    });

    await appliancesPageState.addAppliance( applianceName , db, userHouse );


    final DocumentSnapshot documentSnapshot =
      await db.collection('households').doc(userHouse)
        .collection('appliances').doc(applianceName).get();

    expect(documentSnapshot.exists, true);

    await appliancesPageState.deleteAppliance( db, applianceName, userHouse );

  });

  test( 'deleteAppliance deletes an appliance successfully', () async {

    applianceName = 'appliance_test';

    await appliancesPageState.addAppliance( applianceName , db, userHouse );

    await appliancesPageState.deleteAppliance( db, applianceName, userHouse );

    final DocumentSnapshot documentSnapshot =
      await db.collection('households').doc(userHouse)
        .collection('appliances').doc(applianceName).get();

    expect(documentSnapshot.exists, false );

  });

  test('claim appliance claims successfully', () async{
    applianceName = 'appliance_test';

    await appliancesPageState.addAppliance( applianceName , db, userHouse );

    await appliancesPageState.claimAppliance(applianceName, db, userHouse, 'user1');

    final DocumentSnapshot documentSnapshot =
      await db.collection('households').doc(userHouse)
        .collection('appliances').doc(applianceName).get();

    expect(documentSnapshot['claimed'], true);

    await appliancesPageState.deleteAppliance( db, applianceName, userHouse );

  });

    test('unclaim appliance unclaims successfully', () async{
    applianceName = 'appliance_test';

    await appliancesPageState.addAppliance( applianceName , db, userHouse );

    await appliancesPageState.claimAppliance(applianceName, db, userHouse, 'user1');

    await appliancesPageState.unclaimAppliance(applianceName, db, userHouse);

    final DocumentSnapshot documentSnapshot =
      await db.collection('households').doc(userHouse)
        .collection('appliances').doc(applianceName).get();

    expect(documentSnapshot['claimed'], false);

    await appliancesPageState.deleteAppliance( db, applianceName, userHouse );

  });

    test('Cannot claim already claimed appliance', () async{
    applianceName = 'appliance_test';

    await appliancesPageState.addAppliance( applianceName , db, userHouse );

    await appliancesPageState.claimAppliance(applianceName, db, userHouse, 'user1');

    await appliancesPageState.claimAppliance(applianceName, db, userHouse, 'user2');

    final DocumentSnapshot documentSnapshot =
      await db.collection('households').doc(userHouse)
        .collection('appliances').doc(applianceName).get();

    expect(documentSnapshot['claimedBy'], 'user1');

    await appliancesPageState.deleteAppliance( db, applianceName, userHouse );

  });  

  testWidgets('AppliancesPage shows loading indicator while fetching user data',
      (WidgetTester tester) async {
    // Build AppliancesPage widget
    await tester.pumpWidget(MaterialApp(home: appliancesPage));

    // Verify CircularProgressIndicator is displayed
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });


    testWidgets('Appliance dialog shows up and works', (WidgetTester tester) async {

    userEmail = 'test@test.com';
    String houseName = 'housetest3';
    String applianceName = 'Appl test';

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
            builder: (context) => AppliancesPage(firestoreInstance: db, userEmail: userEmail),
          ),
        ),
      ),
    );

    // Ensure user is in household initially

    await tester.pump(Duration(seconds: 3));

    await tester.tap(find.byKey(ValueKey('Add appliance')));
    
    await tester.pump(Duration(seconds: 3));

    await tester.enterText(find.byKey(ValueKey('Add name')), applianceName);

    // Ensure user is removed from household

    await tester.tap(find.byKey(ValueKey('Submit')));

    final DocumentSnapshot documentSnapshot =
      await db.collection('households').doc(userHouse)
        .collection('appliances').doc(applianceName).get();

    expect(documentSnapshot.exists, true);

    // Ensure household is deleted
  });

}