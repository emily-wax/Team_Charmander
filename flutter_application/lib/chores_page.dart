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

   void _addChoreToFirestore(String choreName, String assignee) {
    FirebaseFirestore.instance.collection('tasks-temp').add({
      'taskName': choreName,
      'assignee': assignee,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('To-Do List'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: chores.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(chores[index]),
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
              child: Text('Add Task'),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Task'),
          content: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: 'Enter task title',
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: assigneeController,
                decoration: InputDecoration(
                  hintText: 'Enter assignee name',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                String choreName = titleController.text.trim();
                String assignee = assigneeController.text.trim();

                if (choreName.isNotEmpty && assignee.isNotEmpty) {
                  _addChoreToFirestore(choreName, assignee);
                  setState(() {
                    String choreString = choreName + assignee;
                    chores.add(choreString);
                    // chores.add(choreName + ", " + assignee);
                  });
                }

                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }
}

//   void _showAddTaskDialog(BuildContext context) {

//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Add Task'),
//           content: TextField(
//             controller: titleController,
//             decoration: InputDecoration(
//               hintText: 'Enter task title',
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 String task = taskController.text.trim();
//                 if (task.isNotEmpty) {
//                   setState(() {
//                     tasks.add(task);
//                   });
//                 }
//                 Navigator.of(context).pop();
//                 // adds user to database when signing up
//                 String title = titleController.text.trim();
//                 String assignee = assigneeController.text.trim();

//                 _createData(ChoreModel('0', title, assignee));
//               },
//               child: Text('Add'),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }

//  void _createData(ChoreModel choreModel) {
//     final choreCollection = FirebaseFirestore.instance.collection("tasks-temp");

//     String id = choreCollection.doc().id;

//     final newChore = ChoreModel(
//       choreModel.id,
//       choreModel.title,
//       choreModel.assignee,
//     ).toJson();

//     choreCollection.doc(id).set(newChore);

//   }

// // User Model: should be edited as we add more users
// class ChoreModel{
//   final String? id;
//   final String? title;
//   final String? assignee;

//   ChoreModel(this.id, this.title, this.assignee);

//   static ChoreModel fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot){
//     return ChoreModel(
//       snapshot['id'],
//       snapshot['title'],
//       snapshot['assignee'],
//     );
//   }

//   Map<String, dynamic> toJson(){
//     return{
//       "id": id,
//       "title": title,
//       "assignee": assignee,
//     };
//   }
// }