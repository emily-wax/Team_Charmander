import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth for user authentication
import 'user_model.dart';
import 'package:flutter_application/household_model.dart';
import 'HomePage.dart';
import "theme_provider.dart";
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

  //not for updating the event
  void updateAppointments (QuerySnapshot? snapshot) {

      List<Appointment> appointments = snapshot!.docs.map((doc) {
      Map<String, dynamic> data = (doc.data() as Map<String, dynamic>);
      return Appointment(
        startTime: data['start'].toDate(),
        endTime: data['end'].toDate(),
        subject: data['name'],
      );
    }).toList();

    _eventDataSource.appointments!.addAll(appointments);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    theme = themeProvider;
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
            .doc(currUserModel?.currHouse)
            .collection('events')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || currUserModel == null) {
            return const Center(
              child: CircularProgressIndicator(color: Color.fromARGB(255, 8, 174, 245),),
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
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: _handleAddEvent,
        backgroundColor: themeProvider.buttonColor,
      ),
    );
  }

  Widget buildCalendarPage(QuerySnapshot? snapshot) {
    if (snapshot == null || currUserModel == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color.fromARGB(255, 8, 174, 245),),
      );
    }
    if (snapshot.docs.isEmpty) {
      return const Center(
        child: Text('No events available'),
      );
    }

      List<Appointment> appointments = snapshot!.docs.map((doc) {
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
      view: CalendarView.week,
      dataSource: _eventDataSource,
      onTap: (CalendarTapDetails details) {
        if (details.targetElement == CalendarElement.appointment) {
          // Get the tapped appointment
          Appointment tappedAppointment = details.appointments![0];
          _handleAppointmentTap(tappedAppointment);
        }
      },
    );
  }

void _handleAppointmentTap(Appointment appointment) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      String eventName = appointment.subject ?? '';
      DateTime startDate = appointment.startTime ?? DateTime.now();
      TimeOfDay startTime = TimeOfDay.fromDateTime(startDate);
      DateTime endDate = appointment.endTime ?? DateTime.now();
      TimeOfDay endTime = TimeOfDay.fromDateTime(endDate);

      return AlertDialog(
        title: Text('Update Event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              cursorColor: theme.buttonColor,
              style: TextStyle(color: theme.textColor),
              initialValue: eventName,
              onChanged: (value) => eventName = value,
              decoration: InputDecoration(
                labelText: 'Event Name',
                labelStyle: TextStyle(color: theme.buttonColor),
                focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.buttonColor), // Border color when enabled
                    ),
                ),
            ),
            Text(
              'Note: You can only update/delete events you created.',
              style: TextStyle(color: Colors.grey),
            ),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.buttonColor
                          ),
                          onPressed: () async {
                            final selectedDate = await showDatePicker(
                              context: context,
                              initialDate: startDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (selectedDate != null) {
                              final selectedTime = await showTimePicker(
                                context: context,
                                initialTime: startTime ?? TimeOfDay.now(),
                              );
                              if (selectedTime != null) {
                                setState(() {
                                  startDate = selectedDate;
                                  startTime = selectedTime;
                                });
                              }
                            }
                          },
                          child: Text('Start', style: TextStyle(color: theme.textColor),),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.buttonColor
                          ),
                          onPressed: () async {
                            final selectedDate = await showDatePicker(
                              context: context,
                              initialDate: startDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (selectedDate != null) {
                              final selectedTime = await showTimePicker(
                                context: context,
                                initialTime: startTime?.replacing(hour: startTime!.hour + 1) ??
                                  TimeOfDay.now(),
                              );
                              if (selectedTime != null) {
                                setState(() {
                                  endDate = selectedDate;
                                  endTime = selectedTime;
                                });
                              }
                            }
                          },
                          child: Text('End', style: TextStyle(color: theme.textColor),),
                        ),
                      ],
                    ),
                  ],
              ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: theme.buttonColor
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel', style: TextStyle(color: theme.textColor),),
          ),
         ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: theme.buttonColor,
  ),
  onPressed: () async {
    // Perform update logic here
    UserModel? currentUserModel = await readData();
    if (eventName.isNotEmpty) {
      final updatedEvent = {
        'name': eventName,
        'start': DateTime(startDate.year, startDate.month, startDate.day, startTime.hour, startTime.minute),
        'end': DateTime(endDate.year, endDate.month, endDate.day, endTime.hour, endTime.minute),
        'user': currentUserModel?.email,
      };

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('households')
          .doc(currentUserModel!.currHouse)
          .collection('events')
          .where('name', isEqualTo: appointment.subject)
          .where('user', isEqualTo: currUserModel?.email)
          .get();

      // Iterate over the documents and update each one
      snapshot.docs.forEach((doc) {
        // Get the reference to the document and call .update on it
        doc.reference.update(updatedEvent);
      });

      // Update event in the calendar
      setState(() {
        // Find the index of the updated appointment
        int index = _eventDataSource.appointments!.indexWhere((element) => element == appointment);
        if (index != -1) {
          _eventDataSource.appointments![index].subject = eventName;
          _eventDataSource.appointments![index].startTime = DateTime(startDate.year, startDate.month, startDate.day, startTime.hour, startTime.minute);
          _eventDataSource.appointments![index].endTime = DateTime(endDate.year, endDate.month, endDate.day, endTime.hour, endTime.minute);
        }
      });

      Navigator.of(context).pop(); // Close the dialog
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Event name cannot be empty'),
        ),
      );
    }
  },
  child: Text('Update', style: TextStyle(color: theme.textColor)),
),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
                            backgroundColor: theme.buttonColor
                          ),
            onPressed: () async {
              _showDeleteConfirmationDialog(appointment);
            },
            child: Text('Delete', style: TextStyle(color: theme.textColor)),
          ),
        ],
      );
    },
  );
}

  void _showDeleteConfirmationDialog(Appointment appointment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Event?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${appointment.subject}"?'),
            SizedBox(height: 8),
            Text(
              'Note: You can only delete events you created.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
              backgroundColor: theme.buttonColor
            ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel', style: TextStyle(color: theme.textColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
              backgroundColor: theme.buttonColor
            ),
              onPressed: () async {
                // Delete the event from Firestore
                await _firestore
                    .collection('households')
                    .doc(currUserModel!.currHouse)
                    .collection('events')
                    .where('name', isEqualTo: appointment.subject)
                    .where('user', isEqualTo: currUserModel!.email)
                    .get()
                    .then((snapshot) {
                  snapshot.docs.forEach((doc) {
                    doc.reference.delete();
                  });
                });

                // Remove the event from the calendar
                setState(() {
                  _eventDataSource.appointments!.remove(appointment);
                });

                Navigator.of(context).pop();
              },
              child: Text('Delete', style: TextStyle(color: theme.textColor)),
            ),
          ],
        );
      },
    );
  }

  void _handleAddEvent() async {
  DateTime? selectedStartDate = DateTime.now();
  TimeOfDay? selectedStartTime;
  DateTime? selectedEndDate = DateTime.now();
  TimeOfDay? selectedEndTime;

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
              cursorColor: theme.buttonColor,
              controller: _eventNameController,
              decoration: InputDecoration(
                labelText: 'Event Name',
                labelStyle: TextStyle(color: theme.buttonColor),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.buttonColor), // Border color when enabled
                ),
              ),
              onChanged: (value) => eventName = value,
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.buttonColor,
                      ),
                      onPressed: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedStartDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (selectedDate != null) {
                          final selectedTime = await showTimePicker(
                            context: context,
                            initialTime: selectedStartTime ?? TimeOfDay.now(),
                          );
                          if (selectedTime != null) {
                            setState(() {
                              selectedStartDate = selectedDate;
                              selectedStartTime = selectedTime;
                            });
                          }
                        }
                      },
                      child: Text(
                        'Start',
                        style: TextStyle(color: theme.textColor),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.buttonColor,
                      ),
                      onPressed: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedStartDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (selectedDate != null) {
                          final selectedTime = await showTimePicker(
                            context: context,
                            initialTime: selectedStartTime?.replacing(hour: selectedStartTime!.hour + 1) ?? TimeOfDay.now(),
                          );
                          if (selectedTime != null) {
                            setState(() {
                              selectedEndDate = selectedDate;
                              selectedEndTime = selectedTime;
                            });
                          }
                        }
                      },
                      child: Text(
                        'End',
                        style: TextStyle(color: theme.textColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              'You must enter both a start and end date/time.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          // Cancel button...
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.buttonColor,
            ),
            onPressed: () {
              _eventNameController.clear();
              Navigator.of(context).pop();
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.textColor),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.buttonColor,
            ),
            onPressed: () async {
              // check if name is unique
              QuerySnapshot snapshot = await _firestore
                  .collection('households')
                  .doc(currUserModel!.currHouse)
                  .collection('events')
                  .where('name', isEqualTo: eventName)
                  .get();

              if (snapshot.docs.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Try again with a unique event name.'),
                ));
              } else if (eventName != null &&
                  selectedEndTime != null &&
                  selectedStartTime != null &&
                  selectedEndDate != null &&
                  selectedStartDate != null) {
                UserModel currUserModel = await readData();
                final event = {
                  'name': eventName,
                  'start': DateTime(
                    selectedStartDate!.year,
                    selectedStartDate!.month,
                    selectedStartDate!.day,
                    selectedStartTime!.hour,
                    selectedStartTime!.minute,
                  ),
                  'end': DateTime(
                    selectedEndDate!.year,
                    selectedEndDate!.month,
                    selectedEndDate!.day,
                    selectedEndTime!.hour,
                    selectedEndTime!.minute,
                  ),
                  'user': currUserModel.email, // Placeholder for user name, replace with actual user name
                };

                final startTime = DateTime(
                  selectedStartDate!.year,
                  selectedStartDate!.month,
                  selectedStartDate!.day,
                  selectedStartTime!.hour,
                  selectedStartTime!.minute,
                );

                final endTime = DateTime(
                  selectedEndDate!.year,
                  selectedEndDate!.month,
                  selectedEndDate!.day,
                  selectedEndTime!.hour,
                  selectedEndTime!.minute,
                );

                final appointment = Appointment(
                  endTime: endTime,
                  startTime: startTime,
                  subject: eventName!,
                );

                setState(() {
                  // Add the new appointment to the local list of appointments
                  _eventDataSource.appointments?.add(appointment);
                });

                await _firestore
                    .collection('households')
                    .doc(currUserModel.currHouse) // Use the household ID obtained from Firestore
                    .collection('events')
                    .add(event);

                // Explicitly trigger a rebuild of the widget tree to update the calendar view
                setState(() {});
              }
              _eventNameController.clear();
              Navigator.of(context).pop();
            },
            child: Text(
              'Add',
              style: TextStyle(color: theme.textColor),
            ),
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
