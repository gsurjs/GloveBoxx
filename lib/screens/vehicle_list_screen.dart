import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../models/vehicle.dart';
import '../providers/vehicle_provider.dart';
import '../widgets/empty_state_message.dart';
import '../widgets/local_image_widget.dart';
import 'add_vehicle_screen.dart';
import 'maintenance_log_screen.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  VehicleListScreenState createState() => VehicleListScreenState();
}

class VehicleListScreenState extends State<VehicleListScreen> {
  void navigateToAddOrEditVehicleScreen({Vehicle? vehicle}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => AddVehicleScreen(
          vehicle: vehicle, // Pass the vehicle if editing
          onSave: (updatedVehicle) {
            final vehicleProvider = Provider.of<VehicleProvider>(context, listen: false);
            if (vehicle == null) {
              // This is a new vehicle
              vehicleProvider.addVehicle(updatedVehicle);
            } else {
              // This is an existing vehicle being updated
              vehicleProvider.updateVehicle(updatedVehicle);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehicleProvider = Provider.of<VehicleProvider>(context);
    final vehicles = vehicleProvider.vehicles;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Vehicles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => navigateToAddOrEditVehicleScreen(),
          ),
        ],
      ),
      body: vehicleProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vehicles.isEmpty
              ? EmptyStateMessage(
                  icon: Icons.garage_outlined,
                  title: 'No Vehicles Yet',
                  message: 'Tap the "+" button to add your first vehicle.',
                  actionButton: ElevatedButton.icon(
                    onPressed: () => navigateToAddOrEditVehicleScreen(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Vehicle'),
                  ),
                )
              : ListView.builder(
                  itemCount: vehicles.length,
                  itemBuilder: (ctx, index) {
                    final vehicle = vehicles[index];
                    return Slidable(
                      endActionPane: ActionPane(
                        motion: const StretchMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (context) {
                              navigateToAddOrEditVehicleScreen(vehicle: vehicle);
                            },
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            icon: Icons.edit,
                            label: 'Edit',
                          ),
                          SlidableAction(
                            onPressed: (context) {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Vehicle'),
                                  content: Text(
                                      'Are you sure you want to delete the ${vehicle.year} ${vehicle.make} ${vehicle.model}? All of its maintenance records will also be deleted.'),
                                  actions: [
                                    TextButton(
                                      child: const Text('Cancel'),
                                      onPressed: () => Navigator.of(ctx).pop(),
                                    ),
                                    TextButton(
                                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                      onPressed: () {
                                        final provider = Provider.of<VehicleProvider>(ctx, listen: false);
                                        Navigator.of(ctx).pop();
                                        provider.deleteVehicle(vehicle.id!);
                                        HapticFeedback.mediumImpact();
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            label: 'Delete',
                          ),
                        ],
                      ),
                      child: Card(
                        elevation: 2.0,
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
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => navigateToAddOrEditVehicleScreen(),
        child: const Icon(Icons.add),
      ),
    );
  }
}