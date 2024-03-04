import 'package:flutter/material.dart';

class ThirdPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Appliances Page'),
      ),
      body: Center(
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

  ApplianceButton({required this.applianceName});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // Add any action related to the specific appliance
        print('Button pressed for $applianceName');
      },
      child: Text(applianceName),
    );
  }
}
