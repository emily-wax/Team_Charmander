import 'dart:html';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'HomePage.dart';

void main() {
  runApp(Chores());
}

class Chores extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ToDoList(),
    );
  }
}

class ToDoList extends StatefulWidget {
  @override
  _ToDoListState createState() => _ToDoListState();
}

class _ToDoListState extends State<ToDoList> {
  TextEditingController taskController = TextEditingController();
  TextEditingController titleController = TextEditingController();
  TextEditingController assigneeController = TextEditingController();
  CollectionReference choresCollection = FirebaseFirestore.instance.collection('tasks-temp');

  // add chore to firestore given an assignee who was manually typed
  // I'm commenting this out because more options isn't always better - manual assignees could lead to weird edge cases in other parts of the app
  // because the way things are saved to Firestore must be specific and clear; allowing users to manually assign could lead to typos and non-existent roommates!
  // void _addChoreToFirestore(String choreName, String assignee, Timestamp? deadline) {
  //   choresCollection.add({
  //     'choreName': choreName,
  //     'assignee': assignee,
  //     'isCompleted': false,
  //     'deadline': deadline,
  //   });
  // }

  // add chore to firestore given an assignee that was selected from a dropdown
  void _addChoreToFirestoreDrop(String choreName, String? assignee, Timestamp? deadline) {
    choresCollection.add({
      'choreName': choreName,
      'assignee': assignee,
      'isCompleted': false,
      'deadline': deadline,
    });
  }

  void _deleteChore(String choreId) {
    choresCollection.doc(choreId).delete();
  }

  @override
  void initState() {
    super.initState();
    _loadRoommates(); // Load users from Firestore when the dialog is initialized
  }

  Future<void> _loadRoommates() async {
     try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      setState(() {
        _users = querySnapshot.docs
            .map((doc) => (doc.data() as Map<String, dynamic>)['email'] as String)
            .toList();
      });
    } catch (e) {
      print("Error loading users: $e");
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
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: choresCollection.snapshots(),
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
                      leading: Checkbox(
                      value: isCompleted,
                      onChanged: (value) {
                        choresCollection.doc(choreId).update({'isCompleted': value});
                      },
                    ),
                    title: Text('Task: $choreName',
                      style: TextStyle(
                        decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                      ),
                      ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Assignee: $assignee'),
                        if (deadline != null)
                          Text('Deadline: $deadline'),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            _deleteChore(choreId);
                          },
                        )
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
                _showAddTaskDialog(context);
              },
              child: const Text('Add Task'),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    // bool autoAssignChecked = false;
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
                hint: Text('Select Assignee'),
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
                  if (selectedUser != null){
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
