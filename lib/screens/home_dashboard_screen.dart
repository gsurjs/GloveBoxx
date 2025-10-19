import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/upcoming_maintenance_view.dart';
import '../models/vehicle.dart';
import '../services/database_helper.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

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
          final List<UpcomingMaintenanceView> upcoming = snapshot.data!['upcoming'];

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _dashboardData = _fetchDashboardData();
              });
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Upcoming Maintenance Card
                Card(
                  color: upcoming.isEmpty ? Colors.green[100] : Colors.yellow[100],
                  child: ListTile(
                    leading: Icon(
                      upcoming.isEmpty ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                      color: upcoming.isEmpty ? Colors.green : Colors.orange,
                    ),
                    title: const Text('Upcoming Maintenance'),
                    subtitle: Text(
                      upcoming.isEmpty
                          ? 'No services due soon!'
                          : '${upcoming.length} service(s) due within 2 weeks',
                    ),
                  ),
                ),
                if (upcoming.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  // List of upcoming services
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
                const Text('My Vehicles', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                if (vehicles.isEmpty)
                  const Center(child: Text('No vehicles added yet.'))
                else
                  ...vehicles.map((vehicle) => Card(
                        child: ListTile(
                          title: Text('${vehicle.year} ${vehicle.make} ${vehicle.model}'),
                          subtitle: Text('Current Mileage: ${vehicle.mileage} mi'),
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