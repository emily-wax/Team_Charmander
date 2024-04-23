import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_application/appliances_page.dart';
import 'package:flutter_application/user_model.dart';

class MockFirestoreService extends Mock implements FirestoreService {}

void main() {
  late MockFirestoreService mockFirestoreService;
  late AppliancesPage appliancesPage;
  late AppliancesPageState appliancesPageState;

  setUp(() {
    mockFirestoreService = MockFirestoreService();
    appliancesPage = AppliancesPage(firestoreService: mockFirestoreService);

    // Use createState to access the state of the AppliancesPage instance
    appliancesPageState = appliancesPage.createState();
  });

  test('_addAppliance adds an appliance and clears the controller', () async {
    // Given
    String householdId = 'test_household';
    String applianceName = 'TestAppliance';
    appliancesPageState.currUserModel = UserModel("6mqFosksgFaz4M3RVYv2","jerry.li65@tamu.edu", "Jerry Lane",false,{});

     when(mockFirestoreService.addAppliance('Jerry Lane', applianceName))
        .thenAnswer((_) async => Future.value());

    // When
    try {
      await appliancesPageState.addAppliance(applianceName);
    } catch (e) {
      fail('Unexpected exception: $e');
    }

    // Then
    verify(mockFirestoreService.addAppliance("Jerry Lane", applianceName))
        .called(1);
    expect(appliancesPageState.applianceNameController.text, isEmpty);
  });

  // Add more tests as necessary.
}
