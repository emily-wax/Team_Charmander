import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late CalendarView _calendarView;
  final CalendarController _calendarController = CalendarController();
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _calendarView = CalendarView.day;
    _updateDisplayDate(); // Call the method to set the initial display
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Calendar'),
      ),
      body: SfCalendar(
        view: _calendarView,
        controller: _calendarController,
        dataSource: _getCalendarDataSource(),
        onViewChanged: _onViewChanged,
        timeSlotViewSettings: const TimeSlotViewSettings(
          startHour: 0,
          endHour: 24, // Set the end hour to 24 to show a full day
          timeIntervalHeight: 27.5, // Adjust height to fit the entire day
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: _handleAddEvent,
      ),
    );
  }

  Future<List<DocumentSnapshot>> _fetchHouseholdsForCurrentUser() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('households')
          .where('roommates', arrayContains: currentUser.email)
          .get();
      return snapshot.docs;
    }
    return []; // Return an empty list if the current user is null or no households found
  }

void _handleAddEvent() async {
  // Fetch households for the current user
  List<DocumentSnapshot> households = await _fetchHouseholdsForCurrentUser();

  // Check if households are found
  if (households.isNotEmpty) {
    // Assume the user is part of only one household for simplicity
    DocumentSnapshot householdDoc = households.first;
    String householdId = householdDoc.id;

    // Show dialog to add event
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _eventNameController,
                decoration: const InputDecoration(labelText: 'Event Name'),
              ),
              TextFormField(
                controller: _startTimeController,
                decoration: const InputDecoration(labelText: 'Start Time'),
                keyboardType: TextInputType.datetime,
              ),
              TextFormField(
                controller: _endTimeController,
                decoration: const InputDecoration(labelText: 'End Time'),
                keyboardType: TextInputType.datetime,
              ),
              TextFormField(
                controller: _userController,
                decoration: const InputDecoration(labelText: 'User'),
              ),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(labelText: 'Date'),
                keyboardType: TextInputType.datetime,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Add the event to the household's collection
                FirebaseFirestore.instance
                    .collection('households')
                    .doc(householdId)
                    .collection('events')
                    .add({
                  'name': _eventNameController.text,
                  'startTime': _startTimeController.text,
                  'endTime': _endTimeController.text,
                  'user': _userController.text,
                  'date': _dateController.text,
                  // Add additional event details here
                }).then((_) {
                  // Event added successfully
                  print('Event added to household: $householdId');
                  Navigator.of(context).pop(); // Close the dialog
                }).catchError((error) {
                  // Handle error if event addition fails
                  print('Error adding event: $error');
                });
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  } else {
    // No households found for the current user
    print('No households found for the current user');
    // Show a message or take appropriate action
  }
}


  _DataSource _getCalendarDataSource() {
    List<Appointment> appointments = <Appointment>[];
    return _DataSource(appointments);
  }

  void _onViewChanged(ViewChangedDetails viewChangedDetails) {
    // No need to handle the view change in this method
  }

  void _updateDisplayDate() {
    final now = DateTime.now();
    _calendarController.selectedDate = now;
    _calendarController.view = CalendarView.day;
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _userController.dispose();
    _dateController.dispose();
    super.dispose();
  }
}

class _DataSource extends CalendarDataSource {
  _DataSource(List<Appointment> source) {
    appointments = source;
  }
}
