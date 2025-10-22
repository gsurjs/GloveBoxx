import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../models/upcoming_maintenance_view.dart';
import '../providers/theme_provider.dart';
import '../providers/vehicle_provider.dart';
import '../services/database_helper.dart';
import '../widgets/empty_state_message.dart';
import '../widgets/local_image_widget.dart';
import 'maintenance_log_screen.dart';
import '../models/vehicle.dart';

class HomeDashboardScreen extends StatefulWidget {
  // 1. CHANGE the function type to accept an optional Vehicle
  final Function({Vehicle? vehicle})? onNavigateRequest;

  const HomeDashboardScreen({super.key, this.onNavigateRequest});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  late Future<List<UpcomingMaintenanceView>> _upcomingMaintenanceFuture;

  @override
  void initState() {
    super.initState();
    _refreshUpcoming();
  }

  void _refreshUpcoming() {
    setState(() {
      _upcomingMaintenanceFuture = DatabaseHelper.instance.getUpcomingMaintenance();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // ... AppBar code remains the same
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
      body: Consumer<VehicleProvider>(
        builder: (context, vehicleProvider, child) {
          if (vehicleProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final vehicles = vehicleProvider.vehicles;

          return RefreshIndicator(
            onRefresh: () async {
              await vehicleProvider.fetchAllData();
              _refreshUpcoming();
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // ... FutureBuilder for Upcoming Maintenance remains the same
                FutureBuilder<List<UpcomingMaintenanceView>>(
                  future: _upcomingMaintenanceFuture,
                  builder: (context, snapshot) {
                    final upcoming = snapshot.data ?? [];
                    return Card(
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
                    );
                  },
                ),
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
                      // 2. UPDATE the onPressed call for the "Add" button
                      onPressed: () => widget.onNavigateRequest?.call(),
                    ),
                  )
                else
                  ...vehicles.map((vehicle) => Slidable(
                        endActionPane: ActionPane(
                          motion: const StretchMotion(),
                          children: [
                            // 3. ADD the new "Edit" action
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
                                          final vehicleProvider = Provider.of<VehicleProvider>(ctx, listen: false);
                                          Navigator.of(ctx).pop();
                                          vehicleProvider.deleteVehicle(vehicle.id!);
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
                          // ... Card contents remain the same
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
                              ).then((_) {
                                _refreshUpcoming();
                              });
                            },
                          ),
                        ),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }
}