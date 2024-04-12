import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';

ThemeProvider theme = ThemeProvider();

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
    final themeProvider = Provider.of<ThemeProvider>(context);
    theme = themeProvider;
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
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: _handleAddEvent,
        backgroundColor: themeProvider.buttonColor,
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
            cursorColor: theme.buttonColor,
            controller: _eventNameController,
            decoration: InputDecoration(
              labelText: 'Event Name',focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: theme.buttonColor),    // Border color when enabled
                  ),
                  floatingLabelStyle: TextStyle(color: theme.buttonColor),),
          ),
          
          actions: [
            TextButton(
              style: TextButton.styleFrom(backgroundColor: theme.buttonColor),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel', style: TextStyle(color: theme.textColor),),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: theme.buttonColor),
              onPressed: () {
                // Add the event to the calendar using the CalendarController
                // For demonstration purposes, let's print the event name to the console
                print('Event added: ${_eventNameController.text}');
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Add', style: TextStyle(color: theme.textColor),),
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
