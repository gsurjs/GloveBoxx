import 'package:flutter/material.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Dashboard'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Upcoming Maintenance Card
          Card(
            color: Colors.yellow[100],
            child: const ListTile(
              leading: Icon(Icons.warning_amber_rounded, color: Colors.orange),
              title: Text('Upcoming Maintenance'),
              subtitle: Text('2 services due within 2 weeks'), // Static for now
            ),
          ),
          const SizedBox(height: 20),
          
          // Section title for 'My Vehicles'
          const Text(
            'My Vehicles',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // Placeholder for vehicle summary
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text('Vehicle summary will be displayed here.'),
            ),
          ),
        ],
      ),
    );
  }
}