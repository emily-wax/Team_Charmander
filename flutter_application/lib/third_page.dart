import 'package:flutter/material.dart';
import 'appliance_details_page.dart'; // Import the new ApplianceDetailsPage

class ThirdPage extends StatelessWidget {
  const ThirdPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appliances Page'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ApplianceButton(applianceName: 'Washing Machine'),
            SizedBox(height: 20),
            ApplianceButton(applianceName: 'Dryer'),
            SizedBox(height: 20),
            ApplianceButton(applianceName: 'Oven'),
            SizedBox(height: 20),
            ApplianceButton(applianceName: 'Dishwasher'),
          ],
        ),
      ),
    );
  }
}

class ApplianceButton extends StatelessWidget {
  final String applianceName;

  const ApplianceButton({super.key, required this.applianceName});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // Navigate to ApplianceDetailsPage when the button is pressed
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ApplianceDetailsPage(applianceName: applianceName),
          ),
        );
      },
      child: Text(applianceName),
    );
  }
}
