// import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_model.dart';
import 'household_model.dart';
import 'auto_assign_chores.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';

ThemeProvider theme = ThemeProvider();

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

  void _addChoreToFirestoreDrop(String choreName, String? assignee, Timestamp? deadline) {
    if (autoAssignChecked){
      debugPrint("Auto Assign checked!");
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
    selectedUser = null;
    selectedDate = null;
    
  }

  void _updateChoreInFirestore(String choreId, String choreName, String? assignee, Timestamp? deadline ) async {
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
          });
        });
      });
    }
    else{
      FirebaseFirestore.instance.collection('households').doc(currUserModel!.currHouse).collection('chores').doc(choreId).update({
        'choreName': choreName,
        'assignee': assignee,
        'deadline': deadline,
      });
    }
  }

  void _deleteChore(String choreId) {
    FirebaseFirestore.instance.collection('households').doc(currUserModel!.currHouse).collection('chores').doc(choreId).delete();
  }

  void _reassignChoreOnClaim(String choreName, String choreId, String assignee, DateTime? deadline, String? newAssigneeUser) {
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
  List<String> _users = [];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    theme = themeProvider;
    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do List'),
      ),

      body: FutureBuilder<UserModel>(
        future: readData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color.fromARGB(255, 8, 174, 245),),
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
    stream: FirebaseFirestore.instance.collection('households').doc(currUserModel!.currHouse).collection('chores').snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return Center(
          child: CircularProgressIndicator(),
        );
      }
      var chores = snapshot.data!.docs;
      return ListView.builder(
        padding: EdgeInsets.all(8),
        itemCount: chores.length,
        itemBuilder: (context, index) {
          var choreData = chores[index].data() as Map<String, dynamic>;
          var choreId = chores[index].id;
          var choreName = choreData['choreName'];
          var assignee = choreData['assignee'];
          var isCompleted = choreData['isCompleted'];
          var deadline = choreData['deadline'] != null ? (choreData['deadline'] as Timestamp).toDate() : null;

                    if (deadline != null){
                      formattedDate =
                      '${deadline.month.toString().padLeft(2, '0')}-${deadline.day.toString().padLeft(2, '0')}-${deadline.year.toString().substring(2)}';
                    }

                    if (assignee == currUserModel!.email){
                      assigneeMatchesCurrUser = true;
                    }
                    else {
                      assigneeMatchesCurrUser = false;
                    }

          return Container(
            margin: EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Row(
                children: [
                  Checkbox(
                    value: isCompleted,
                    activeColor: theme.buttonColor,
                    onChanged: (value) {
                      FirebaseFirestore.instance.collection('households').doc(currUserModel!.currHouse).collection('chores').doc(choreId).update({'isCompleted': value});
                    },
                  ),
                  SizedBox(width: 8),
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
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          _editChore(choreName, choreId, assignee, deadline);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          _deleteChore(choreId);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}



  void _editChore(String choreName, String choreId, String assignee, DateTime? deadline) {
    String editedChoreName = choreName;
    String? editedAssignee = assignee;

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
                      decoration: InputDecoration(labelText: 'Task Name', 
                      focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.buttonColor),
                      
                       // Border color when enabled
                  ),
                  floatingLabelStyle: TextStyle(color: theme.buttonColor),),
                      onChanged: (value) {
                        editedChoreName = value;
                      },
                      
                    ),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: theme.buttonColor), // Border color when enabled
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
                          Text('Select Deadline: ', style: TextStyle(color: theme.inputColor),),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: theme.buttonColor),
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
                                : 'Set Deadline...', style: TextStyle(color: Colors.white),),
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
                  style: ElevatedButton.styleFrom(backgroundColor: theme.buttonColor),
                  onPressed: () {
                    Timestamp? deadline = selectedDate != null
                          ? Timestamp.fromDate(selectedDate!)
                          : null;

                    if (editedChoreName.isNotEmpty) {
                      if (editedAssignee != null || autoAssignChecked) {
                        _updateChoreInFirestore(choreId, editedChoreName, editedAssignee, deadline);
                        Navigator.of(context).pop();
                      }
                    }


                  },
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: theme.buttonColor),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel', style: TextStyle(color: Colors.white)),
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
                cursorColor: theme.buttonColor,
                decoration: InputDecoration(
                  hintText: 'Enter task title',
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.buttonColor), // Border color when enabled
                  ),
                  floatingLabelStyle: TextStyle(color: theme.buttonColor),
                ),
                controller: titleController,
              ),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.buttonColor), // Border color when enabled
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
                hint: Text('Select Assignee', style: TextStyle(color: theme.inputColor)),
              ),
             Row(
              children: [
                Checkbox(
                  activeColor: theme.buttonColor,
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
                Text('Select Deadline: ', style: TextStyle(color: theme.inputColor),),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: theme.buttonColor),
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
                      : 'Set Deadline...', style: TextStyle(color: Colors.white),),
                ),
                if (selectedDate != null) Text('Deadline: $selectedDate', style: TextStyle(color: Colors.white),),
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
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              style: TextButton.styleFrom(backgroundColor: theme.buttonColor),
              onPressed: () {
                String choreName = titleController.text.trim();
                Timestamp? deadline = selectedDate != null ? Timestamp.fromDate(selectedDate!) : null;

                if (choreName.isNotEmpty){
                  if (selectedUser != null || autoAssignChecked){
                    _addChoreToFirestoreDrop(choreName, selectedUser, deadline);Navigator.of(context).pop();
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
                