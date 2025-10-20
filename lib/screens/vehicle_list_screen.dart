import 'dart:io';
import '../widgets/local_image_widget.dart';
import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../services/database_helper.dart'; 
import 'add_vehicle_screen.dart';
import 'maintenance_log_screen.dart';
import '../widgets/empty_state_message.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  VehicleListScreenState createState() => VehicleListScreenState();
}

class VehicleListScreenState extends State<VehicleListScreen> {
  late Future<List<Vehicle>> _vehiclesFuture;

  @override
  void initState() {
    super.initState();
    _refreshVehicles();
  }
  
  void _refreshVehicles() {
    setState(() {
      _vehiclesFuture = DatabaseHelper.instance.readAllVehicles();
    });
  }

  void _addVehicle(Vehicle vehicle) async {
    await DatabaseHelper.instance.createVehicle(vehicle);
    _refreshVehicles();
  }

  void navigateToAddVehicleScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddVehicleScreen(onAddVehicle: _addVehicle),
      ),
    ).then((_) => _refreshVehicles());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Vehicles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: navigateToAddVehicleScreen,
          ),
        ],
      ),
      body: FutureBuilder<List<Vehicle>>(
        future: _vehiclesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const EmptyStateMessage(
              icon: Icons.garage_outlined,
              title: 'No Vehicles Yet',
              message: 'Tap the "+" button to add your first vehicle and start tracking its maintenance.',
            );
          } else {
            final vehicles = snapshot.data!;
            return ListView.builder(
              itemCount: vehicles.length,
              itemBuilder: (ctx, index) {
                final vehicle = vehicles[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: LocalImage(
                      fileName: vehicle.photoPath,
                      placeholderIcon: Icons.directions_car,
                    ),
                    title: Text('${vehicle.year} ${vehicle.make} ${vehicle.model}'),
                    subtitle: Text('${vehicle.mileage} mi'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                       Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => MaintenanceLogScreen(vehicle: vehicle),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: navigateToAddVehicleScreen,
        child: const Icon(Icons.add),
      ),
    );
  }
}