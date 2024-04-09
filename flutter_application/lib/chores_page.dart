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
  // TextEditingController taskController = TextEditingController();
  TextEditingController titleController = TextEditingController();
  TextEditingController assigneeController = TextEditingController();
  UserModel? currUserModel;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // String autoAssignee = "";

  // add chore to firestore given an assignee that was selected from a dropdown
  void _addChoreToFirestoreDrop(String choreName, String? assignee, Timestamp? deadline) {
    if (autoAssignChecked){
      debugPrint("Auto Assign checked!");
      AutoAssignClass auto = AutoAssignClass();
      auto.autoAssignChore().then((String result){
        setState(() {
          assignee = result;
          debugPrint("assignee $assignee");
          FirebaseFirestore.instance.collection('households').doc(currUserModel!.currHouse).collection('chores').add({
            'choreName': choreName,
            'assignee': assignee,
            'isCompleted': false,
            'deadline': deadline,
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
      });
    }
    
  }

  void _updateChoreInFirestore(String choreId, String choreName, String? assignee, Timestamp? deadline ) async {
    FirebaseFirestore.instance.collection('households').doc(currUserModel!.currHouse).collection('chores').doc(choreId).update({
        'choreName': choreName,
        'assignee': assignee,
        'deadline': deadline,
      });
    }

  void _deleteChore(String choreId) {
    FirebaseFirestore.instance.collection('households').doc(currUserModel!.currHouse).collection('chores').doc(choreId).delete();
  }

  @override
  void initState() {
    super.initState();
    _loadRoommates(); // Load users from Firestore when the dialog is initialized
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
  List<String> _users = []; // List to store available users

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do List'),
      ),
      // body: Container(
      //   padding: const EdgeInsets.all(8),
      //   color: Colors.purple[100],

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
            currUserModel = snapshot.data; // Set currUserModel once future completes
            return buildChoresPage(); // Build the main content of the page
          }
        },
      ), 
    );
  }

  Widget buildChoresPage() {
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

                  for (var c in chores) {
                    var choreData = c.data() as Map<String, dynamic>;
                    var choreId = c.id;
                    var choreName = choreData['choreName'];
                    var assignee = choreData['assignee'];
                    var isCompleted = choreData['isCompleted'];
                    var deadline = choreData['deadline'] != null ? (choreData['deadline'] as Timestamp).toDate() : null;

                    var choreWidget = ListTile(
                      contentPadding: const EdgeInsets.all(0), // Remove default padding
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Checkbox(
                            value: isCompleted,
                            onChanged: (value) {
                              // choresCollection.doc(choreId).update({'isCompleted': value});
                               FirebaseFirestore.instance.collection('households').doc(currUserModel!.currHouse).collection('chores').doc(choreId).update({'isCompleted': value});
                            },
                          ),
                          const SizedBox(width: 8), // Add some spacing between checkbox and task details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Task: $choreName',
                                  style: TextStyle(
                                    decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                                  ),
                                ),
                                Text('Assignee: $assignee'),
                                if (deadline != null) Text('Deadline: $deadline'),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  _editChore(choreName, choreId, assignee, deadline);
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
                  // taskController.clear();
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

  void _editChore(String choreName, String choreId, String assignee, DateTime? deadline) {
    String editedChoreName = choreName;
    String editedAssignee = assignee;

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
                            setState(() {
                              autoAssignChecked = value!;
                              // _getRandomUser().then(selectedUser);
                            });
                          }
                        ),
                        const Text('Auto-assign this task'),
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
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    // Save the edited chore details and close the dialog
                    Navigator.of(context).pop();
                    Timestamp? deadline = selectedDate != null
                          ? Timestamp.fromDate(selectedDate!)
                          : null;
                    _updateChoreInFirestore(choreId, editedChoreName, editedAssignee, deadline);
                  },
                  child: const Text('Save'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Close the dialog without saving
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
                // String assignee = assigneeController.text.trim();
                Timestamp? deadline = selectedDate != null ? Timestamp.fromDate(selectedDate!) : null;

                if (choreName.isNotEmpty){
                  if (selectedUser != null || autoAssignChecked){
                    _addChoreToFirestoreDrop(choreName, selectedUser, deadline);
                  }
                //   else if (assignee.isNotEmpty){
                //      _addChoreToFirestore(choreName, assignee, deadline);
                //   }
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
}
                