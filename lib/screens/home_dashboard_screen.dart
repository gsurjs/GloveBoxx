import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../models/vehicle.dart';
import '../providers/theme_provider.dart';
import '../providers/vehicle_provider.dart';
import '../widgets/empty_state_message.dart';
import '../widgets/local_image_widget.dart';
import 'maintenance_log_screen.dart';
import 'package:intl/intl.dart';

class HomeDashboardScreen extends StatefulWidget {
  final Function({Vehicle? vehicle})? onNavigateRequest;

  const HomeDashboardScreen({super.key, this.onNavigateRequest});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    // This screen now gets all its data from the provider
    final vehicleProvider = Provider.of<VehicleProvider>(context);
    final upcoming = vehicleProvider.upcomingMaintenance;
    final vehicles = vehicleProvider.vehicles;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Dashboard'),
        actions: [
          IconButton(
            icon: Icon(
              Provider.of<ThemeProvider>(context).themeMode == ThemeMode.light
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
            ),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          )
        ],
      ),
      body: vehicleProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => vehicleProvider.fetchAllData(),
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Upcoming Maintenance Card (now uses data from provider)
                  Card(
                    elevation: 2.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    color: upcoming.isEmpty ? Colors.green[100] : Colors.yellow[100],
                    child: ListTile(
                      leading: Icon(
                        upcoming.isEmpty
                            ? Icons.check_circle_outline
                            : Icons.warning_amber_rounded,
                        color: upcoming.isEmpty
                            ? Colors.green.shade800
                            : Colors.orange.shade800,
                      ),
                      title: Text(
                        'Upcoming Maintenance',
                        style: TextStyle(
                          color: Colors.grey.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        upcoming.isEmpty
                            ? 'No services due soon!'
                            : '${upcoming.length} service(s) due within 2 weeks',
                        style: TextStyle(color: Colors.grey.shade800),
                      ),
                    ),
                  ),

                  if (upcoming.isNotEmpty)
                    ...upcoming.map((item) {
                      return Card(
                        elevation: 1.0,
                        child: ListTile(
                          title: Text('${item.record.type} for ${item.vehicle.make} ${item.vehicle.model}'),
                          subtitle: Text('Due on ${DateFormat.yMd().format(item.record.nextDueDate!)}'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => MaintenanceLogScreen(vehicle: item.vehicle),
                              ),
                            ).then((_) => Provider.of<VehicleProvider>(context, listen: false).fetchAllData());
                          },
                        ),
                      );
                    }),

                  const SizedBox(height: 20),
                  const Text('My Vehicles',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  if (vehicles.isEmpty)
                    EmptyStateMessage(
                      icon: Icons.directions_car_outlined,
                      title: 'No Vehicles Added',
                      message:
                          'Add your first vehicle to see a summary here and start tracking its maintenance.',
                      actionButton: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Vehicle'),
                        onPressed: () => widget.onNavigateRequest?.call(),
                      ),
                    )
                  else
                    ...vehicles.map((vehicle) => Slidable(
                          endActionPane: ActionPane(
                            motion: const StretchMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (context) {
                                  widget.onNavigateRequest?.call(vehicle: vehicle);
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
                                          'Are you sure you want to delete the ${vehicle.year} ${vehicle.make} ${vehicle.model}?'),
                                      actions: [
                                        TextButton(
                                          child: const Text('Cancel'),
                                          onPressed: () => Navigator.of(ctx).pop(),
                                        ),
                                        TextButton(
                                          child: const Text('Delete',
                                              style: TextStyle(color: Colors.red)),
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
                            child: ListTile(
                              leading: LocalImage(
                                fileName: vehicle.photoPath,
                                placeholderIcon: Icons.directions_car,
                              ),
                              title: Text(
                                  '${vehicle.year} ${vehicle.make} ${vehicle.model}'),
                              subtitle:
                                  Text('Current Mileage: ${vehicle.mileage} mi'),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        MaintenanceLogScreen(vehicle: vehicle),
                                  ),
                                ).then((_) => vehicleProvider.fetchAllData()); // Refresh when returning
                              },
                            ),
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}