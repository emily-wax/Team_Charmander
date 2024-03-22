import 'package:flutter/material.dart';
import 'second_page.dart';
import 'fourth_page.dart';
import 'appliances_page.dart'; // Import the appliances page

class HomePage extends StatelessWidget {
  const HomePage({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
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
              const Icon(
                Icons.house,
                size: 100,
                color: Colors.green,
              ),
              const SizedBox(height: 20),
              Text(
                'Welcome to Your House!',
                style: TextStyle(
                  fontSize: 24,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SecondPage()),
                  );
                },
                child: const Text(
                  'Chores',
                  style: TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FourthPage()),
                  );
                },
                child: const Text(
                  'Account',
                  style: TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton( // New button added for navigating to AppliancesPage
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AppliancesPage()),
                  );
                },
                child: Text(
                  'Appliances',
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
