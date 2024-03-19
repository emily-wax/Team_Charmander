import 'package:flutter/material.dart';

class ApplianceDetailsPage extends StatelessWidget {
  final String applianceName;

  const ApplianceDetailsPage({Key? key, required this.applianceName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(applianceName),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[200],
              ),
              child: Image.asset(
                _getImageAsset(applianceName),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            flex: 1,
            child: ElevatedButton(
              onPressed: () {
                // Add logic to claim the appliance
                print('Appliance claimed: $applianceName');
              },
              style: ElevatedButton.styleFrom(
                primary: Colors.green,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Claim',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getImageAsset(String applianceName) {
    // You should replace these paths with the actual paths of your appliance images
    switch (applianceName) {
      case 'Washing Machine':
        return '../pictures/washer.jpg';
      case 'Dryer':
        return '../pictures/dryer.jpg';
      case 'Oven':
        return '../pictures/oven.jpg';
      case 'Dishwasher':
        return '../pictures/dishwasher.jpg';
      default:
        return '';
    }
  }
}
