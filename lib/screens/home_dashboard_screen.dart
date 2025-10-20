import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/upcoming_maintenance_view.dart';
import '../providers/theme_provider.dart';
import '../providers/vehicle_provider.dart';
import '../services/database_helper.dart';
import '../widgets/empty_state_message.dart';
import '../widgets/local_image_widget.dart';

class HomeDashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateRequest;

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
              // Refresh both providers/futures
              await vehicleProvider.fetchVehicles();
              _refreshUpcoming();
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Upcoming Maintenance Card
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
                      onPressed: widget.onNavigateRequest,
                    ),
                  )
                else
                  ...vehicles.map((vehicle) => Card(
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