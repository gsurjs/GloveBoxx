import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/upcoming_maintenance_view.dart';
import '../models/vehicle.dart';
import '../providers/theme_provider.dart';
import '../services/database_helper.dart';
import '../widgets/empty_state_message.dart';

class HomeDashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateRequest;

  const HomeDashboardScreen({super.key, this.onNavigateRequest});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  late Future<Map<String, dynamic>> _dashboardData;

  @override
  void initState() {
    super.initState();
    _dashboardData = _fetchDashboardData();
  }

  Future<Map<String, dynamic>> _fetchDashboardData() async {
    final vehicles = await DatabaseHelper.instance.readAllVehicles();
    final upcoming = await DatabaseHelper.instance.getUpcomingMaintenance();
    return {'vehicles': vehicles, 'upcoming': upcoming};
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
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("No data available."));
          }

          final List<Vehicle> vehicles = snapshot.data!['vehicles'];
          final List<UpcomingMaintenanceView> upcoming =
              snapshot.data!['upcoming'];

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _dashboardData = _fetchDashboardData();
              });
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Card(
                  color:
                      upcoming.isEmpty ? Colors.green[100] : Colors.yellow[100],
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
                if (upcoming.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...upcoming.map((item) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                            '${item.record.type} for ${item.vehicle.year} ${item.vehicle.make} ${item.vehicle.model} due on ${DateFormat.yMd().format(item.record.nextDueDate!)}'),
                      ),
                    );
                  }),
                ],
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
                        child: ListTile(
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