import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth for user authentication
import 'user_model.dart';
import 'package:flutter_application/household_model.dart';
import 'HomePage.dart';

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

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _householdId = ""; // Variable to store the household ID
  UserModel? currUserModel;

  @override
  void initState() {
    super.initState();
    _updateDisplayDate();
    _fetchUserModel();
  }

  void _fetchUserModel() async {

  try {
    currUserModel = await readData();
    setState(() {}); // Trigger a rebuild after getting the user model
  } catch (error) {
    // Handle error here, such as displaying an error message or retrying
    print('Error fetching user data: $error');
  }
  }

  @override
  Widget build(BuildContext context) {
   return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('households')
            .doc(currUserModel!.currHouse)
            .collection('events')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          return buildCalendarPage(snapshot.data);
        },
      ),
      floatingActionButton:  FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: _handleAddEvent,
      ),
    );
  }




Widget buildCalendarPage( QuerySnapshot? snapshot ) {

   if (snapshot == null || snapshot.docs.isEmpty) {
      return const Center(
        child: Text('No events available'),
      );
    }

    List<Appointment> appointments = snapshot.docs.map((doc) {
       Map<String, dynamic> data = (doc.data() as Map<String, dynamic>);
      return Appointment(
        startTime: data['start'].toDate(),
        endTime: data['end'].toDate(),
        subject: data['name'],
      );
    }).toList();

    _eventDataSource.appointments!.clear();
    _eventDataSource.appointments!.addAll(appointments);

    return SfCalendar(
      view: CalendarView.day,
      dataSource: _eventDataSource,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Start Time'),
                      GestureDetector(
                        onTap: () async {
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('End Time'),
                      GestureDetector(
                        onTap: () async {
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
            ],
          ),
          actions: [
            // Cancel button...
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (eventName != null && _startTime != null && _endTime != null) {
                  final selectedDate = _calendarController.selectedDate;
                  if (selectedDate != null) {
                    UserModel currUserModel = await readData();
                    final event = {
                      'name': eventName,
                      'start': DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        _startTime!.hour,
                        _startTime!.minute,
                      ),
                      'end': DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        _endTime!.hour,
                        _endTime!.minute,
                      ),
                      'user': currUserModel.email, // Placeholder for user name, replace with actual user name
                    };

                    final startTime = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        _startTime!.hour,
                        _startTime!.minute,
                      );

                    final endTime = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        _endTime!.hour,
                        _endTime!.minute,
                      );

                      final appointment = Appointment(
                        endTime: endTime,
                        startTime: startTime,
                        subject: eventName!
                      );

                      setState(() {
                        _eventDataSource.appointments?.add(appointment);
                      });

                    await _firestore
                        .collection('households')
                        .doc(currUserModel.currHouse) // Use the household ID obtained from Firestore
                        .collection('events')
                        .add(event);
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
