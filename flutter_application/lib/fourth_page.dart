import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'SignInPage.dart';

class FourthPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Account Page'),
      ),
      body: Container(
        color: Colors.orange, // Set the background color to orange
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 10,),
              StreamBuilder<List<UserModel>>(
                stream: _readData(), 
                builder: (context, snapshot){
                  if(snapshot.connectionState == ConnectionState.waiting){
                    return Center(child: CircularProgressIndicator(),);
                  } if(snapshot.data!.isEmpty){
                    return Center(child:Text("No Data Yet"));
                  }
                  final users = snapshot.data;
                  return Padding(padding: EdgeInsets.all(8),
                  child: Column(
                    children: users!.map((user) {
                      return ListTile(
                        leading: GestureDetector(
                          child: Icon(Icons.delete),
                        ),
                        trailing: GestureDetector(
                          child: Icon(Icons.update)
                        ),
                        title: Text(user.email!),
                      );
                    }).toList()
                  ),
                  );
                })

            ],
          )
        ),
      ),
    );
  }
}

Stream<List<UserModel>> _readData(){
  final userCollection = FirebaseFirestore.instance.collection("users");

  return userCollection.snapshots().map((QuerySnapshot)
  => QuerySnapshot.docs.map((e) 
  => UserModel.fromSnapshot(e),).toList());
}


