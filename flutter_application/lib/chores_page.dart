import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_model.dart';
import 'household_model.dart';
import 'auto_assign_chores.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';

ThemeProvider theme = ThemeProvider();

class ChoresPage extends StatefulWidget {
  const ChoresPage({Key? key}) : super(key: key);

  @override
  _ChoresPageState createState() => _ChoresPageState();
}

class _ChoresPageState extends State<ChoresPage> {
  TextEditingController titleController = TextEditingController();
  TextEditingController assigneeController = TextEditingController();
  UserModel? currUserModel;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _addChoreToFirestoreDrop(String choreName, String? assignee,
      Timestamp? deadline, int? timelength) {
    if (autoAssignChecked) {
      AutoAssignClass auto = AutoAssignClass();
      auto.autoAssignChore(choreName).then((String result) {
        setState(() {
          assignee = result;
          FirebaseFirestore.instance
              .collection('households')
              .doc(currUserModel!.currHouse)
              .collection('chores')
              .add({
            'choreName': choreName,
            'assignee': assignee,
            'isCompleted': false,
            'deadline': deadline,
            'timelength': timelength,
            'inCalendar': false,
          });
        });
      });
    } else {
      FirebaseFirestore.instance
          .collection('households')
          .doc(currUserModel!.currHouse)
          .collection('chores')
          .add({
        'choreName': choreName,
        'assignee': assignee,
        'isCompleted': false,
        'deadline': deadline,
        'timelength': timelength,
        'inCalendar': false,
      });
    }
    selectedUser = null;
    selectedDate = null;
    selectedTimelength = null;
    autoAssignChecked = false;
  }

  void _updateChoreInFirestore(String choreId, String choreName,
      String? assignee, Timestamp? deadline, int? timelength) async { //delete calendar event upon updating
    if (autoAssignChecked) {
      debugPrint("Auto Assign checked!");
      AutoAssignClass auto = AutoAssignClass();
      auto.autoAssignChore(choreName).then((String result) {
        setState(() {
          assignee = result;
          debugPrint("assignee $assignee");
          FirebaseFirestore.instance
              .collection('households')
              .doc(currUserModel!.currHouse)
              .collection('chores')
              .doc(choreId)
              .update({
            'choreName': choreName,
            'assignee': assignee,
            'deadline': deadline,
            'timelength': timelength,
            'inCalendar': false,
          });
        });
      });
    } else {
      FirebaseFirestore.instance
          .collection('households')
          .doc(currUserModel!.currHouse)
          .collection('chores')
          .doc(choreId)
          .update({
        'choreName': choreName,
        'assignee': assignee,
        'deadline': deadline,
        'timelength': timelength,
        'inCalendar': false,
      });
    }
    autoAssignChecked = false;
  }

  void _deleteChore(String choreId) {
    FirebaseFirestore.instance
        .collection('households')
        .doc(currUserModel!.currHouse)
        .collection('chores')
        .doc(choreId)
        .delete();
  }

  void _addTocalendar(String choreId) async{                ///////////////here
    DateTime? start;
    DateTime? end;
    DocumentSnapshot choreSnapshot = await FirebaseFirestore.instance   
    .collection('households')
    .doc(currUserModel!.currHouse)
    .collection('chores')
    .doc(choreId)
    .get();

    if (choreSnapshot.exists) {
    var choreData = choreSnapshot.data() as Map<String, dynamic>;

    // Assigning chore fields to variables ... may not need to repeat this
    String choreName = choreData['choreName'] ?? '';
    String? assignee = choreData['assignee'];
    var choreDuration = choreData['timelength'];
    DateTime? deadline = choreData['deadline'] != null
        ? (choreData['deadline'] as Timestamp).toDate()
        : null;

    // Now you have choreName, assignee, deadline, and timelength as variables
    // You can use these variables as needed

    start = DateTime(deadline!.year, deadline.month, deadline.day, 17, 0); // 5pm
    end = start.add(Duration(minutes: choreDuration));   
    DateTime day = DateTime(deadline.year, deadline.month, deadline.day, 0, 0); // midnight the day of the deadline

    start = (await _checkForTimeConflicts(start, end, day, choreDuration )) as DateTime?;
    end = start?.add(Duration(minutes: choreDuration));

    if (start!= null) {

      final event = {
        'name': choreName,
        'start': start,
        'end': end,
        'user': assignee, // Placeholder for user name, replace with actual user name
      };

      FirebaseFirestore.instance
        .collection('households')
        .doc(currUserModel!.currHouse) // Use the household ID obtained from Firestore
        .collection('events')
        .add(event);

      FirebaseFirestore.instance   
      .collection('households')
      .doc(currUserModel!.currHouse)
      .collection('chores')
      .doc(choreId)
      .update({'inCalendar':true});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chore successfully added to calendar.'),
        ),
      );

  
    }

    else{
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chore has too many time conflicts could not add to calendar.'),
        ),
      );
    }



    //TODOOOOO
    //Check for unique name for event (see if event already has that name)
    //adding user prefences 
  
    

    

    // Add your code to use these variables
    // For example, adding to a calendar or any other processing
    }
        

  }

  Future<Object?> _checkForTimeConflicts(DateTime choreStart, DateTime choreEnd, DateTime day, int choreDuration) async {

    QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('households')
      .doc(currUserModel!.currHouse)
      .collection('events')
      .where('start', isGreaterThanOrEqualTo: day)  // Filter events starting from 'day'
      .where('start', isLessThan: day.add(Duration(days: 1)))  // Filter events ending before the next day
      .get();

    List<Map<String, dynamic>> events = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

    for (var event in events){
      DateTime eventStart = (event['start'] as Timestamp).toDate();
      DateTime eventEnd = (event['end'] as Timestamp).toDate();

      // Adjust the time if a conflict is found
      if(eventStart == choreStart || eventEnd == choreEnd || 
        (choreStart.isBefore(eventEnd) && choreEnd.isAfter(eventStart)) ||
        (eventStart.isBefore(choreEnd) && eventEnd.isAfter(choreStart))){

            choreStart = eventEnd.add(Duration(minutes: 10));
            

            if ( choreStart.hour >= 21){
              // reset choreStart to 5pm the day before
              int hourDifference = choreStart.hour - 17;
              choreStart = choreStart.subtract(Duration(hours: hourDifference));

              choreStart = choreStart.subtract(Duration(days: 1));
              choreEnd = choreStart.add(Duration(minutes: choreDuration));
              day = day.subtract(Duration(days: 1));


              if(choreStart.isAfter(DateTime.now())){
                return _checkForTimeConflicts(choreStart, choreEnd, day, choreDuration);
              } else {
                return null;
              }

              
            } else{
              choreEnd = choreStart.add(Duration(minutes: choreDuration));
              return _checkForTimeConflicts(choreStart, choreEnd, day, choreDuration);
            }
            
      }
    }

    return choreStart;
  }

  void _reassignChoreOnClaim(String choreName, String choreId, String assignee,
      DateTime? deadline, String? newAssigneeUser, String timelength) {
    FirebaseFirestore.instance
        .collection('households')
        .doc(currUserModel!.currHouse)
        .collection('chores')
        .doc(choreId)
        .update({
      'choreName': choreName,
      'assignee': newAssigneeUser,
      'deadline': deadline,
      'timelength': timelength,
      'inCalendar': false,
    });
  }

  @override
  void initState() {
    super.initState();
    _loadRoommates();
  }

  Future<void> _loadRoommates() async {
    User? currentUser = _auth.currentUser;
    HouseholdModel currHouse;

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('households')
          .where('roommates', arrayContains: currentUser!.email)
          .get();
      setState(() {
        if (querySnapshot.docs.isNotEmpty) {
          currHouse = HouseholdModel.fromSnapshot(querySnapshot.docs.first);
          _users = currHouse.roommates;
          _users.add('[unassigned]');
        } else {
          debugPrint('error loading roommates');
        }
      });
    } catch (e) {
      debugPrint("Chores Error loading users: $e");
    }
  }

  bool autoAssignChecked = false;
  DateTime? selectedDate;
  String? selectedUser;
  int? selectedTimelength;
  List<String> _users = [];
  final List<int> _timelengths = [5, 15, 30, 60];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    theme = themeProvider;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chores'),
      ),
      body: FutureBuilder<UserModel>(
        future: readData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(255, 8, 174, 245),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            currUserModel = snapshot.data;
            return buildChoresPage();
          }
        },
      ),
    );
  }

  Widget buildChoresPage() {
    String formattedDate = "";
    bool assigneeMatchesCurrUser = false;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('households')
          .doc(currUserModel!.currHouse)
          .collection('chores')
          .orderBy('isCompleted', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Column(
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    "Press the + to add a chore!",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                    bottom: 20.0), // Adjust the padding as needed
                child: FloatingActionButton(
                  onPressed: () {
                    assigneeController.clear();
                    titleController.clear();
                    _showAddTaskDialog(context);
                  },
                  child: Icon(Icons.add, color: Colors.white),
                  backgroundColor: theme.buttonColor, // Customize as needed
            ),
          ),
          ],
        );
      }

      var chores = snapshot.data!.docs;
      List<Widget> choreWidgets = [];
      Color textColor = Colors.grey;

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(8),
                itemCount: chores.length,
                itemBuilder: (context, index) {
                  var choreData = chores[index].data() as Map<String, dynamic>;
                  var choreId = chores[index].id;
                  var choreName = choreData['choreName'];
                  var assignee = choreData['assignee'];
                  var isCompleted = choreData['isCompleted'];
                  var deadline = choreData['deadline'] != null
                      ? (choreData['deadline'] as Timestamp).toDate()
                      : null;
                  var timelength = choreData['timelength'];
                  var inCalendar = choreData['inCalendar'];

                if (deadline != null) {
                  formattedDate =
                      '${deadline.month.toString().padLeft(2, '0')}-${deadline.day.toString().padLeft(2, '0')}-${deadline.year.toString().substring(2)}';
                }

                if (assignee == currUserModel!.email) {
                  assigneeMatchesCurrUser = true;
                  textColor = Colors.blue;
                } else {
                  assigneeMatchesCurrUser = false;
                  textColor = Colors.grey;
                }

                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Row(
                      children: [
                        Checkbox(
                          value: isCompleted,
                          activeColor: theme.buttonColor,
                          onChanged: assigneeMatchesCurrUser ? (value) {
                            FirebaseFirestore.instance
                                .collection('households')
                                .doc(currUserModel!.currHouse)
                                .collection('chores')
                                .doc(choreId)
                                .update({'isCompleted': value});
                          } : null
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$choreName',
                                style: TextStyle(
                                  decoration: isCompleted
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18
                                ),
                              ),
                              Text('Do: $assignee',
                                style: TextStyle(
                                  color: textColor,
                                )),
                              if (deadline != null)
                                Text('Due: $formattedDate',
                                    style: TextStyle(
                                      color: textColor,
                                    )),
                              if (timelength != null)
                                Text('Time: ${timelength}m',
                                    style: TextStyle(
                                      color: textColor,
                                    ))
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              if (!assigneeMatchesCurrUser)
                                IconButton(
                                  icon: const Icon(Icons.transfer_within_a_station),
                                  onPressed: () {
                                    _reassignChoreOnClaim(
                                        choreName,
                                        choreId,
                                        assignee,
                                        deadline,
                                        currUserModel!.email,
                                        timelength);
                                  },
                                ),
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () {
                                  _showEditChoreDialog(choreName, choreId, assignee,    /////////////here
                                      deadline, timelength);
                                },
                              ),
                            if(!assigneeMatchesCurrUser)
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () {
                                    _deleteChore(choreId);
                                  },
                                ),
                              Visibility(
                                visible: !inCalendar && (deadline != null),
                                child:
                                IconButton(
                                icon: Icon(Icons.calendar_month),
                                onPressed: () async {
                                  if(assignee == currUserModel!.email){
                                      QuerySnapshot snapshot = await FirebaseFirestore.instance
                                      .collection('households')
                                      .doc(currUserModel!.currHouse)
                                      .collection('events')
                                      .where('name', isEqualTo: choreName)
                                      .get();

                                    if( snapshot.docs.isNotEmpty){
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Text('Try again with a unique event name.'),
                                      ));
                                    } else{
                                      _addTocalendar(choreId);
                                    }
                                    


                                  } else if (deadline == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: Text('This event does not have a deadline and cannot be added to the calendar.'),
                                    ));
                                  }else{
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: Text('This event is not assigned to you.'),
                                    ));
                                  }
                                },
                              ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
            padding: const EdgeInsets.only(bottom: 20.0), // Adjust the padding as needed
            child: FloatingActionButton(
              onPressed: () {
                assigneeController.clear();
                titleController.clear();
                _showAddTaskDialog(context);
              },
              child: Icon(Icons.add, color: Colors.white),
              backgroundColor: theme.buttonColor, // Customize as needed
            ),
          ),
        ],
      );
  },
  );
    }
  




  void _showEditChoreDialog(String choreName, String choreId, String assignee,
      DateTime? deadline, int timelength) {
    String editedChoreName = choreName;
    String? editedAssignee = assignee;
    int? editedTimelength = timelength;
    const customBlue = Color(0xFF3366FF);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, setState) {
            return AlertDialog(
              title: const Text('Edit Chore'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      cursorColor: theme.buttonColor,
                      initialValue: choreName,
                      decoration: InputDecoration(
                        labelText: 'Task Name',
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: theme.buttonColor),

                          // Border color when enabled
                        ),
                        floatingLabelStyle: TextStyle(color: theme.buttonColor),
                      ),
                      onChanged: (value) {
                        editedChoreName = value;
                      },
                    ),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: theme
                                  .buttonColor), // Border color when enabled
                        ),
                      ),
                      value: editedAssignee,
                      onChanged: (value) {
                        setState(() {
                          editedAssignee = value;
                        });
                      },
                      items: _users.map((String user) {
                        return DropdownMenuItem<String>(
                          value: user,
                          child: Text(user),
                        );
                      }).toList(),
                      hint: const Text('Select Assignee'),
                    ),
                    Row(
                      children: [
                        Checkbox(
                            value: autoAssignChecked,
                            activeColor: theme.buttonColor,
                            onChanged: (bool? value) {
                              setState(() {
                                autoAssignChecked = value!;
                              });
                            }),
                        const Text('Auto-assign this task'),
                        IconButton(
                          icon: const Icon(Icons.question_mark),
                          onPressed: () {
                            _showAutoAssignDialog(context);
                          },
                        )
                      ],
                    ),
                    Row(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: theme.buttonColor),
                          onPressed: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2101),
                            );
                            if (pickedDate != null &&
                                pickedDate != deadline) {
                              setState(() {
                                deadline = pickedDate;
                              });
                            }
                          },
                          child: const Text(
                            'Set Deadline...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        Text(deadline != null
                            ? '${deadline!.month.toString().padLeft(2, '0')}/${deadline!.day.toString().padLeft(2, '0')}/${deadline!.year.toString().substring(2)}'
                            : '',
                            style: const TextStyle(color: customBlue)),
                      ],
                    ),
                    Column(
                      children: [
                        DropdownButtonFormField<int>(
                          value: editedTimelength,
                          onChanged: (int? newValue) {
                            setState(() {
                              editedTimelength = newValue;
                            });
                          },
                          items: _timelengths.map((int value) {
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text('$value min.'),
                            );
                          }).toList(),
                          hint: const Text('Select Time Estimate'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: theme.buttonColor),
                  onPressed: () {
                    Timestamp? deadlineReal = deadline != null
                        ? Timestamp.fromDate(deadline!)
                        : null;

                    if (editedTimelength == null) {
                      editedTimelength = 5;
                    }

                    if (editedChoreName.isNotEmpty) {
                      if (editedAssignee != null || autoAssignChecked) {
                        _updateChoreInFirestore(choreId, editedChoreName,
                            editedAssignee, deadlineReal, editedTimelength);
                        Navigator.of(context).pop();
                      }
                    }
                  },
                  child:
                      const Text('Save', style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: theme.buttonColor),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    const customBlue = Color(0xFF3366FF);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Task'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  TextField(
                    cursorColor: theme.buttonColor,
                    decoration: InputDecoration(
                      hintText: 'Enter task title',
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color:
                                theme.buttonColor), // Border color when enabled
                      ),
                      floatingLabelStyle: TextStyle(color: theme.buttonColor),
                    ),
                    controller: titleController,
                  ),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color:
                                theme.buttonColor), // Border color when enabled
                      ),
                    ),
                    value: selectedUser,
                    onChanged: (value) {
                      setState(() {
                        selectedUser = value;
                      });
                    },
                    items: _users.map((String user) {
                      return DropdownMenuItem<String>(
                        value: user,
                        child: Text(user),
                      );
                    }).toList(),
                    hint: Text('Select Assignee',
                        style: TextStyle(color: theme.inputColor)),
                  ),
                  Row(
                    children: [
                      Checkbox(
                        activeColor: theme.buttonColor,
                        value: autoAssignChecked,
                        onChanged: (bool? value) {
                          setState(() => autoAssignChecked = value!);
                        },
                      ),
                      const Text('Auto-assign this task'),
                      IconButton(
                        icon: const Icon(Icons.question_mark),
                        onPressed: () {
                          _showAutoAssignDialog(context);
                        },
                      )
                    ],
                  ),
                  Row(
                    children: [
                      
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: theme.buttonColor),
                        onPressed: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2101),
                          );

                          if (pickedDate != null &&
                              pickedDate != selectedDate) {
                            setState(() {
                              selectedDate = pickedDate;
                            });
                          }
                        },
                        child: const Text(
                          'Set Deadline...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      Text(
                          selectedDate != null
                              ? '${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.year.toString().substring(2)}'
                              : '',
                          style: const TextStyle(color: customBlue)),
                    ],
                  ),
                  Column(
                    children: [
                      DropdownButtonFormField<int>(
                        value: selectedTimelength,
                        onChanged: (int? newValue) {
                          setState(() {
                            selectedTimelength = newValue;
                          });
                        },
                        items: _timelengths.map((int value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text('$value min.'),
                          );
                        }).toList(),
                        hint: const Text('Select Time Estimate'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(backgroundColor: theme.buttonColor),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              style: TextButton.styleFrom(backgroundColor: theme.buttonColor),
              onPressed: () {
                String choreName = titleController.text.trim();
                Timestamp? deadline = selectedDate != null
                    ? Timestamp.fromDate(selectedDate!)
                    : null;

                if (selectedTimelength == null) {
                  selectedTimelength = 5;
                }

                if (choreName.isNotEmpty) {
                  if (selectedUser != null || autoAssignChecked) {
                    _addChoreToFirestoreDrop(
                        choreName, selectedUser, deadline, selectedTimelength);
                    Navigator.of(context).pop();
                  }
                }
              },
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showAutoAssignDialog(BuildContext context) {
    const customBlue = Color(0xFF3366FF); 
    // String hexValue = customBlue.value.toRadixString(16);
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Auto-Assign has 3 phases.',
            style: TextStyle(color: customBlue),
            ),
            content: StatefulBuilder(
              builder: (context, setState) {
                return RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(text: 'A phase executes if the previous phase does not return a decisive roommate.\n\n',
                        style: TextStyle(color: customBlue),
                      ),
                      TextSpan(text: '1. Assignee = roommate with fewest assignments.\n',
                        style: TextStyle(color: customBlue),
                      ),
                      TextSpan(text: '2. Assignee = result of a modified Adjusted Winner procedure (for x roommates and y chore categories).\n',
                        style: TextStyle(color: customBlue),
                      ),
                       TextSpan(text: '3. Assignee = random roommate (fail-safe).\n\n',
                        style: TextStyle(color: customBlue),
                      ),
                      TextSpan(text: "More information about the Adjusted Winner procedure can be found online.",
                        style: TextStyle(color: customBlue),
                      )
                    ],
                  ),
                );
              },
            ),
          );
        });
  }
}
