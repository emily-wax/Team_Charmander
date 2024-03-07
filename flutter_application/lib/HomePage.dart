import 'package:flutter/material.dart';
import 'third_page.dart';
import 'fourth_page.dart';
import 'chores_page.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () {
              print('Home icon pressed!');
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.yellow[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.house,
                size: 100,
                color: Colors.green,
              ),
              SizedBox(height: 20),
              Text(
                'Welcome to Your House!',
                style: TextStyle(
                  fontSize: 24,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Chores()),
                  );
                },
                child: Text(
                  'Chores',
                  style: TextStyle(fontSize: 20),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ThirdPage()),
                  );
                },
                child: Text(
                  'Appliances',
                  style: TextStyle(fontSize: 20),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => FourthPage()),
                  );
                },
                child: Text(
                  'Account',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
