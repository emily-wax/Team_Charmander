import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late CalendarView _calendarView;
  final CalendarController _calendarController = CalendarController();
  final TextEditingController _eventNameController = TextEditingController();

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

  void _handleAddEvent() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Event'),
          content: TextFormField(
            controller: _eventNameController,
            decoration: const InputDecoration(labelText: 'Event Name'),
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
                // Add the event to the calendar using the CalendarController
                // For demonstration purposes, let's print the event name to the console
                print('Event added: ${_eventNameController.text}');
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
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
    super.dispose();
  }
}

class _DataSource extends CalendarDataSource {
  _DataSource(List<Appointment> source) {
    appointments = source;
  }
}
