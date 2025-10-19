import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../services/database_helper.dart'; 
import 'add_vehicle_screen.dart';
import 'maintenance_log_screen.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
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

  void _navigateToAddVehicleScreen() {
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
            onPressed: _navigateToAddVehicleScreen,
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
            return const Center(child: Text('No vehicles found. Add one!'));
          } else {
            final vehicles = snapshot.data!;
            return ListView.builder(
              itemCount: vehicles.length,
              itemBuilder: (ctx, index) {
                final vehicle = vehicles[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.directions_car, size: 40),
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
        onPressed: _navigateToAddVehicleScreen,
        child: const Icon(Icons.add),
      ),
    );
  }
}