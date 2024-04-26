
/* NOTE: must run file as a whole tests are not standalone. */
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application/appliances_page.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';


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

  testWidgets('AppliancesPage shows loading indicator while fetching user data',
      (WidgetTester tester) async {
    // Build AppliancesPage widget
    await tester.pumpWidget(MaterialApp(home: appliancesPage));

    // Verify CircularProgressIndicator is displayed
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

}