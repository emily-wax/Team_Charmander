import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_model.dart';
import 'household_model.dart';
import 'auto_assign_chores.dart';

class ToDoList extends StatefulWidget {
  const ToDoList({Key? key}) : super(key: key);

  @override
  _ToDoListState createState() => _ToDoListState();
}

class _ToDoListState extends State<ToDoList> {
  TextEditingController titleController = TextEditingController();
  TextEditingController assigneeController = TextEditingController();
  UserModel? currUserModel;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _addChoreToFirestoreDrop(String choreName, String? assignee, Timestamp? deadline, String? timelength) {
    if (autoAssignChecked){
      // debugPrint("Auto Assign checked!");
      AutoAssignClass auto = AutoAssignClass();
      auto.autoAssignChore(choreName).then((String result){
        setState(() {
          assignee = result;
          debugPrint("assignee $assignee");
          FirebaseFirestore.instance.collection('households').doc(currUserModel!.currHouse).collection('chores').add({
            'choreName': choreName,
            'assignee': assignee,
            'isCompleted': false,
            'deadline': deadline,
            'timelength': timelength,
          });
        });
      });      
    }
    else {
      FirebaseFirestore.instance.collection('households').doc(currUserModel!.currHouse).collection('chores').add({
        'choreName': choreName,
        'assignee': assignee,
        'isCompleted': false,
        'deadline': deadline,
        'timelength': timelength
      });
    }
    selectedUser = null;
    selectedDate = null;
    selectedTimelength = null;
    autoAssignChecked = false;

    
  }

  void _updateChoreInFirestore(String choreId, String choreName, String? assignee, Timestamp? deadline, String? timelength) async {
    if (autoAssignChecked) {
      debugPrint("Auto Assign checked!");
      AutoAssignClass auto = AutoAssignClass();
      auto.autoAssignChore(choreName).then((String result) {
        setState(() {
          assignee = result;
          debugPrint("assignee $assignee");
          FirebaseFirestore.instance.collection('households').doc(currUserModel!.currHouse).collection('chores').doc(choreId).update({
          'choreName': choreName,
          'assignee': assignee,
          'deadline': deadline,
          'timelength': timelength,
          });
        });
      });
    }
    else{
      FirebaseFirestore.instance.collection('households').doc(currUserModel!.currHouse).collection('chores').doc(choreId).update({
        'choreName': choreName,
        'assignee': assignee,
        'deadline': deadline,
        'timelength': timelength
      });
    }
  }

  void _deleteChore(String choreId) {
    FirebaseFirestore.instance.collection('households').doc(currUserModel!.currHouse).collection('chores').doc(choreId).delete();
  }

  void _reassignChoreOnClaim(String choreName, String choreId, String assignee, DateTime? deadline, String? newAssigneeUser, String timelength) {
    debugPrint("reassignment in progress");
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
    });
    debugPrint("reassignment done!");
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
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('households')
          .where('roommates', arrayContains: currentUser!.email)
          .get();
      setState(() {
        if(querySnapshot.docs.isNotEmpty){
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
  String? selectedTimelength;
  List<String> _users = [];
  final List<String> _timelengths = ['5m', '10m', '15m', '30m', '60m'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do List'),
      ),

      body: FutureBuilder<UserModel>(
        future: readData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
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
    bool showEveryonesTasks = false;
    return Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('households').doc(currUserModel!.currHouse).collection('chores').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                  var chores = snapshot.data!.docs;
                  List<Widget> choreWidgets = [];
                  Color textColor = Colors.black;
                  

                  for (var c in chores) {
                    var choreData = c.data() as Map<String, dynamic>;
                    var choreId = c.id;
                    var choreName = choreData['choreName'];
                    var assignee = choreData['assignee'];
                    var isCompleted = choreData['isCompleted'];
                    var deadline = choreData['deadline'] != null ? (choreData['deadline'] as Timestamp).toDate() : null;
                    var timelength = choreData['timelength'];

                    if (deadline != null){
                      formattedDate =
                      '${deadline.month.toString().padLeft(2, '0')}-${deadline.day.toString().padLeft(2, '0')}-${deadline.year.toString().substring(2)}';
                    }

                    if (assignee == currUserModel!.email){
                      assigneeMatchesCurrUser = true;
                      textColor = Colors.blue;
                    }
                    else {
                      assigneeMatchesCurrUser = false;
                      textColor = Colors.black;
                    }

                    

                    var choreWidget = ListTile(
                      contentPadding: const EdgeInsets.all(0),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Checkbox(
                            value: isCompleted,
                            onChanged: (value) {
                               FirebaseFirestore.instance.collection('households').doc(currUserModel!.currHouse).collection('chores').doc(choreId).update({'isCompleted': value});
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Task: $choreName',
                                  style: TextStyle(
                                    color: textColor,
                                    decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                                  ),
                                ),
                                Text('Assignee: $assignee',
                                  style: TextStyle(
                                    color: textColor,
                                  )),
                                if (deadline != null) Text('Deadline: $formattedDate',
                                  style: TextStyle(
                                    color: textColor,
                                  )),
                                Text('Estimated time: $timelength',
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
                                icon: const Icon(Icons.shopping_cart_rounded),
                                onPressed: () {
                                  _reassignChoreOnClaim(choreName, choreId, assignee, deadline, currUserModel!.email, timelength);
                                }
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  _editChore(choreName, choreId, assignee, deadline, timelength);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  _deleteChore(choreId);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                    choreWidgets.add(choreWidget);
                  }
                  return ListView(
                    children: choreWidgets,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  assigneeController.clear();
                  titleController.clear();
                  _showAddTaskDialog(context);
                },
                child: const Text('Add Task'),
              ),
            ),
          ],
        );
   
  }

  void _editChore(String choreName, String choreId, String assignee, DateTime? deadline, String timelength) {
    String editedChoreName = choreName;
    String? editedAssignee = assignee;
    String? editedTimelength = timelength;

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
                      initialValue: choreName,
                      decoration: const InputDecoration(labelText: 'Task Name'),
                      onChanged: (value) {
                        editedChoreName = value;
                      },
                    ),
                    DropdownButtonFormField<String>(
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
                          onChanged: (bool? value) {
                            setState(() {
                              autoAssignChecked = value!;
                            });
                          }
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
                          const Text('Select Deadline: '),
                          ElevatedButton(
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
                            child: Text(selectedDate != null
                                ? 'Change Deadline'
                                : 'Set Deadline...'),
                          ),
                          if (selectedDate != null)
                            Text('Deadline: $selectedDate'),
                        ],
                      ),
                      Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: editedTimelength,
                    onChanged: (String? newValue) {
                      setState(() {
                        editedTimelength = newValue;
                      });
                    },
                    items: _timelengths.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    hint: const Text('Select Time Est. (default 15min)'),
                  ),
                ],
              ),
            ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Timestamp? deadline = selectedDate != null
                          ? Timestamp.fromDate(selectedDate!)
                          : null;

                    if (editedTimelength == null) {
                      editedTimelength = '15m';
                    }

                    if (editedChoreName.isNotEmpty) {
                      if (editedAssignee != null || autoAssignChecked) {
                        _updateChoreInFirestore(choreId, editedChoreName, editedAssignee, deadline, editedTimelength);
                        Navigator.of(context).pop();
                      }
                    }


                  },
                  child: const Text('Save'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddTaskDialog(BuildContext context) {
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
                controller: titleController,
                decoration: const InputDecoration(
                  hintText: 'Enter task title',
                ),
              ),
              DropdownButtonFormField<String>(
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
                hint: const Text('Select Assignee'),
              ),
              Row(
                children: [
                  Checkbox(
                    value: autoAssignChecked,
                    onChanged: (bool? value) {
                      setState(() =>
                        autoAssignChecked = value!);
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
                  const Text('Select Deadline: '),
                  ElevatedButton(
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
                    child: Text(selectedDate != null
                        ? 'Change Deadline'
                        : 'Set Deadline...'),
                  ),
                  if (selectedDate != null) Text('Deadline: $selectedDate'),
                ],
              ),
              Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedTimelength,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedTimelength = newValue;
                      });
                    },
                    items: _timelengths.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    hint: const Text('Select Time Est. (default 15min)'),
                  ),
                ],
              ),
          ],
        );
      },
      ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                String choreName = titleController.text.trim();
                Timestamp? deadline = selectedDate != null ? Timestamp.fromDate(selectedDate!) : null;

                if (selectedTimelength == null) {
                  selectedTimelength = '15m';
                }

                if (choreName.isNotEmpty){
                  if (selectedUser != null || autoAssignChecked){
                    _addChoreToFirestoreDrop(choreName, selectedUser, deadline, selectedTimelength);
                    Navigator.of(context).pop();
                  }
                }

                
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showAutoAssignDialog(BuildContext context){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Auto-Assign has 3 phases.'),
          content: StatefulBuilder(
            builder: (context, setState) {
          return RichText(
            text: const TextSpan(
              children: [
                TextSpan(text: '1. Assigns to the roommate with the least chores assigned.\n'),
                TextSpan(text: '2. A modified Adjusted Winner procedure assigns to the "winner" of [chore]\'s category based on their set preferences.\n'),
                TextSpan(text: '3. A fail-safe assigns to a roommate at random.\n\n'),
                TextSpan(text: 'A phase executes if the previous phase does not return a decisive roommate.\n'),
                TextSpan(text: "More information about the Adjusted Winner procedure can be found online.")
              ],
            ),
          );
            },
          ),
        );
  }
    );
      
}
}
                