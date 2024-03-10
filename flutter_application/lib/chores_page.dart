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
  List<String> chores = [];
  TextEditingController taskController = TextEditingController();
  TextEditingController titleController = TextEditingController();
  TextEditingController assigneeController = TextEditingController();
  CollectionReference choresCollection = FirebaseFirestore.instance.collection('tasks-temp');

   void _addChoreToFirestore(String choreName, String assignee, Timestamp? deadline) {
    choresCollection.add({
      'choreName': choreName,
      'assignee': assignee,
      'isCompleted': false,
      'deadline': deadline,
    });
  }

  void _updateTaskCompletion(String taskId, bool? isCompleted) {
    choresCollection.doc(taskId).update({'isCompleted': isCompleted ?? false});
  }

  bool autoAssignChecked = false;
  DateTime? selectedDate;

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
                  // var deadline = choreData['deadline'];
                  var deadline = choreData['deadline'] != null ? (choreData['deadline'] as Timestamp).toDate() : null;

                  var choreWidget = ListTile(
                      leading: Checkbox(
                      value: isCompleted,
                      onChanged: (value) {
                        // Update the task's isCompleted status in the Firestore database
                        choresCollection.doc(choreId).update({'isCompleted': value});
                      },
                    ),
                    title: Text('Task: $choreName',
                      style: TextStyle(
                        decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                      ),
                      ), //, style: TextStyle(decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Assignee: $assignee'),
                        if (deadline != null)
                          Text('Deadline: $deadline'),
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
              const SizedBox(height: 10),
              TextField(
                controller: assigneeController,
                decoration: const InputDecoration(
                  hintText: 'Enter assignee name',
                ),
              ),
             const SizedBox(height: 10),
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
            const SizedBox(height: 10),
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
                String assignee = assigneeController.text.trim();
                Timestamp? format = selectedDate != null ? Timestamp.fromDate(selectedDate!) : null;

                if (choreName.isNotEmpty && assignee.isNotEmpty) {
                  _addChoreToFirestore(choreName, assignee, format);
                  setState(() {
                    String choreString = choreName + assignee;
                    chores.add(choreString);
                    // chores.add(choreName + ", " + assignee);
                  });
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
