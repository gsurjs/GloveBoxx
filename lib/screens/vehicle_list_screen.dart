import '../widgets/local_image_widget.dart';
import 'package:flutter/material.dart';
import 'add_vehicle_screen.dart';
import 'maintenance_log_screen.dart';
import '../widgets/empty_state_message.dart';
import 'package:provider/provider.dart';
import '../providers/vehicle_provider.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  VehicleListScreenState createState() => VehicleListScreenState();
}

class VehicleListScreenState extends State<VehicleListScreen> {
  void navigateToAddVehicleScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => AddVehicleScreen(
          onAddVehicle: (vehicle) {
            // Call the provider to add the vehicle
            Provider.of<VehicleProvider>(context, listen: false).addVehicle(vehicle);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the provider
    final vehicleProvider = Provider.of<VehicleProvider>(context);
    final vehicles = vehicleProvider.vehicles;

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
      body: vehicleProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vehicles.isEmpty
              ? const EmptyStateMessage(
                  icon: Icons.garage_outlined,
                  title: 'No Vehicles Yet',
                  message: 'Tap the "+" button to add your first vehicle.',
                )
              : ListView.builder(
                  itemCount: vehicles.length,
                  itemBuilder: (ctx, index) {
                    final vehicle = vehicles[index];
                    return Card(
                      // A subtle shadow for depth
                      elevation: 2.0, 
                      // Slightly rounded corners for a modern look
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
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
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: navigateToAddVehicleScreen,
        child: const Icon(Icons.add),
      ),
    );
  }
}