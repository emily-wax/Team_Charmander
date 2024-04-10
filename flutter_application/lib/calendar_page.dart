import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late CalendarView _calendarView;
  final CalendarController _calendarController = CalendarController();
  final TextEditingController _eventNameController = TextEditingController();

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  final EventDataSource _eventDataSource = EventDataSource([]);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Initialize Firestore

  @override
  void initState() {
    super.initState();
    _calendarView = CalendarView.day;
    _updateDisplayDate();
    _subscribeToEvents(); // Subscribe to events when the widget initializes
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
        dataSource: _eventDataSource,
        timeSlotViewSettings: const TimeSlotViewSettings(
          startHour: 0,
          endHour: 24,
          timeIntervalHeight: 27.5,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: _handleAddEvent,
      ),
    );
  }

  void _handleAddEvent() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String? eventName;

        return AlertDialog(
          title: const Text('Add Event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _eventNameController,
                decoration: const InputDecoration(labelText: 'Event Name'),
                onChanged: (value) => eventName = value,
              ),
              const SizedBox(height: 16.0),
              // Time selection widgets...
            ],
          ),
          actions: [
            // Cancel button...
            ElevatedButton(
              onPressed: () async {
                if (eventName != null && _startTime != null && _endTime != null) {
                  final selectedDate = _calendarController.selectedDate;
                  if (selectedDate != null) {
                    final event = {
                      'eventName': eventName,
                      'startTime': _startTime!.format(context),
                      'endTime': _endTime!.format(context),
                    };

                    await _firestore.collection('events').add(event); // Add event to Firestore
                  }
                }
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _subscribeToEvents() {
    _firestore.collection('events').snapshots().listen((QuerySnapshot snapshot) {
      final List<Appointment> events = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final startTime = DateTime.parse(data['startTime']);
        final endTime = DateTime.parse(data['endTime']);
        return Appointment(
          startTime: startTime,
          endTime: endTime,
          subject: data['eventName'],
          isAllDay: false,
        );
      }).toList();

      setState(() {
        _eventDataSource.appointments = events;
      });
    });
  }

  void _updateDisplayDate() {
    final now = DateTime.now();
    _calendarController.selectedDate = now;
    _calendarController.view = CalendarView.day;
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    super.dispose();
  }
}

class EventDataSource extends CalendarDataSource {
  EventDataSource(List<Appointment> source) {
    appointments = source;
  }
}
