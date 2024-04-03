import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  List<Appointment> _appointments = [];

  Color neonGreen = Colors.greenAccent; // Assigning neon green color for household events
  Color? _selectedColor;
  bool _isHouseholdEvent = false;

  @override
  void initState() {
    super.initState();
    _calendarView = CalendarView.day;
    _updateDisplayDate();
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
        dataSource: EventDataSource(_appointments),
        onViewChanged: _onViewChanged,
        onTap: (CalendarTapDetails details) {
          // Handle tap on events
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: _handleAddEvent,
      ),
    );
  }

  void _handleAddEvent() async {
    String? eventName;
    Color eventColor = Colors.blue; // Default color

    // Show dialog to add event
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Add Event'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Text field for event name
                  TextFormField(
                    controller: _eventNameController,
                    decoration: const InputDecoration(labelText: 'Event Name'),
                    onChanged: (value) => eventName = value,
                  ),
                  const SizedBox(height: 16.0),
                  // Row to select start and end time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Start time selection
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Start Time'),
                          GestureDetector(
                            onTap: () async {
                              // Show time picker
                              final selectedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                                builder: (context, child) {
                                  return MediaQuery(
                                    data: MediaQuery.of(context).copyWith(
                                      alwaysUse24HourFormat: false,
                                    ),
                                    child: child ?? const SizedBox.shrink(),
                                  );
                                },
                                initialEntryMode: TimePickerEntryMode.input,
                                hourLabelText: 'Hour',
                                minuteLabelText: 'Minute',
                              );
                              if (selectedTime != null) {
                                setState(() {
                                  _startTime = selectedTime;
                                });
                              }
                            },
                            child: Text(
                              _startTime?.format(context) ?? 'Select Start Time',
                              style: const TextStyle(
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // End time selection
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('End Time'),
                          GestureDetector(
                            onTap: () async {
                              // Show time picker
                              final selectedTime = await showTimePicker(
                                context: context,
                                initialTime: _startTime?.replacing(hour: _startTime!.hour + 1) ??
                                    TimeOfDay.now(),
                                builder: (context, child) {
                                  return MediaQuery(
                                    data: MediaQuery.of(context).copyWith(
                                      alwaysUse24HourFormat: false,
                                    ),
                                    child: child ?? const SizedBox.shrink(),
                                  );
                                },
                                initialEntryMode: TimePickerEntryMode.input,
                                hourLabelText: 'Hour',
                                minuteLabelText: 'Minute',
                              );
                              if (selectedTime != null) {
                                setState(() {
                                  _endTime = selectedTime;
                                });
                              }
                            },
                            child: Text(
                              _endTime?.format(context) ?? 'Select End Time',
                              style: const TextStyle(
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  // Checkbox for household event
                  Row(
                    children: [
                      Checkbox(
                        value: _isHouseholdEvent,
                        onChanged: (value) {
                          setState(() {
                            _isHouseholdEvent = value ?? false;
                            if (!_isHouseholdEvent) {
                              _selectedColor = null; // Reset color selection
                            }
                          });
                        },
                      ),
                      const Text('Household Event'),
                    ],
                  ),
                ],
              ),
              actions: [
                // Cancel button
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                // Add button
                ElevatedButton(
                  onPressed: () async {
                    if (eventName != null && _startTime != null && _endTime != null) {
                      // Get the color for the event
                      eventColor = _isHouseholdEvent ? neonGreen : (await _getEventColor() ?? Colors.blue);
                      // Create a new Appointment object
                      final selectedDate = _calendarController.selectedDate;
                      if (selectedDate != null) {
                        final appointment = Appointment(
                          startTime: DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            _startTime!.hour,
                            _startTime!.minute,
                          ),
                          endTime: DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            _endTime!.hour,
                            _endTime!.minute,
                          ),
                          eventName: eventName!,
                          user: FirebaseAuth.instance.currentUser!.displayName!, // Set the user associated with the appointment
                          isAllDay: false,
                          color: eventColor,
                        );

                        // Add the appointment to the list
                        setState(() {
                          _appointments.add(appointment);
                        });

                        // Add event to Firestore
                        await _addEventToFirestore(appointment);
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
      },
    );
  }

  Future<Color?> _getEventColor() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userName = currentUser.displayName;
      try {
        QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('name', isEqualTo: userName)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          Map<String, dynamic> userData = querySnapshot.docs.first.data();
          String? userColor = userData['color'] as String?;
          if (userColor != null) {
            return Color(int.parse(userColor));
          }
        }
      } catch (e) {
        print('Error fetching user color: $e');
      }
    }
    return null;
  }

  void _onViewChanged(ViewChangedDetails viewChangedDetails) {
    // TODO -- if we change the view
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
  List<dynamic>? _appointments;

  EventDataSource(List<dynamic>? source) {
    _appointments = source ?? [];
  }

  @override
  List<dynamic>? get appointments => _appointments;
}

class Appointment {
  final DateTime startTime;
  final DateTime endTime;
  final String eventName; // Event name
  final String user; // User associated with the appointment
  final bool isAllDay;
  final Color color;

  Appointment({
    required this.startTime,
    required this.endTime,
    required this.eventName,
    required this.user,
    this.isAllDay = false,
    this.color = Colors.blue,
  });
}

// Function to add event to Firestore
Future<void> _addEventToFirestore(Appointment appointment) async {
  try {
    // Access the Firestore instance and the 'events' collection
    final firestore = FirebaseFirestore.instance;
    final eventsCollection = firestore.collection('events');

    // Convert appointment data to Firestore compatible format
    Map<String, dynamic> eventData = {
      'start': appointment.startTime,
      'end': appointment.endTime,
      'eventName': appointment.eventName,
      'user': appointment.user, // User associated with the appointment
      'isAllDay': appointment.isAllDay,
      'color': appointment.color.value,
      // Add any other fields you want to store
    };

    // Add the event data to Firestore
    await eventsCollection.add(eventData);

    print('Event added to Firestore successfully!');
  } catch (e) {
    print('Error adding event to Firestore: $e');
  }
}

void main() {
  runApp(MaterialApp(
    home: CalendarPage(),
  ));
}
