import 'package:flutter/material.dart';
import '../models/vehicle.dart'; // Import the Vehicle model
import 'add_vehicle_screen.dart'; // Import the AddVehicleScreen

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  // Using temporary in-memory data for vehicles
  final List<Vehicle> _vehicles = [
    Vehicle(id: 1, make: 'Honda', model: 'Accord', year: 2020, mileage: 45230),
    Vehicle(id: 2, make: 'Toyota', model: 'Camry', year: 2018, mileage: 62450),
  ];

  void _addVehicle(Vehicle vehicle) {
    setState(() {
      _vehicles.add(vehicle);
    });
  }

  void _navigateToAddVehicleScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddVehicleScreen(onAddVehicle: _addVehicle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Vehicles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToAddVehicleScreen,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _vehicles.length,
        itemBuilder: (ctx, index) {
          final vehicle = _vehicles[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.directions_car, size: 40),
              title: Text('${vehicle.year} ${vehicle.make} ${vehicle.model}'),
              subtitle: Text('${vehicle.mileage} mi'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Navigate to Maintenance Log Screen for this vehicle
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddVehicleScreen,
        child: const Icon(Icons.add),
      ),
    );
  }
}