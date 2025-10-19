import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/maintenance_record.dart';
import '../models/vehicle.dart';
import '../services/database_helper.dart';
import 'add_maintenance_screen.dart';


class MaintenanceLogScreen extends StatefulWidget {
  final Vehicle vehicle;

  const MaintenanceLogScreen({super.key, required this.vehicle});

  @override
  State<MaintenanceLogScreen> createState() => _MaintenanceLogScreenState();
}

class _MaintenanceLogScreenState extends State<MaintenanceLogScreen> {
  late Future<List<MaintenanceRecord>> _maintenanceRecordsFuture;

  @override
  void initState() {
    super.initState();
    _refreshLogs();
  }

  void _refreshLogs() {
    setState(() {
      _maintenanceRecordsFuture = DatabaseHelper.instance
          .readMaintenanceRecordsForVehicle(widget.vehicle.id!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.vehicle.model} Log'),
      ),
      body: FutureBuilder<List<MaintenanceRecord>>(
        future: _maintenanceRecordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No maintenance records yet.'));
          } else {
            final records = snapshot.data!;
            return ListView.builder(
              itemCount: records.length,
              itemBuilder: (ctx, index) {
                final record = records[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(record.type),
                    subtitle: Text(
                      '${DateFormat.yMMMd().format(record.date)} - ${record.mileage} mi',
                    ),
                    trailing: Text(
                      NumberFormat.currency(symbol: '\$').format(record.cost),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddMaintenanceScreen(vehicleId: widget.vehicle.id!),
            ),
          ).then((_) {
            // This code runs after the AddMaintenanceScreen is closed.
            // refresh the list to show the new entry.
            _refreshLogs();
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}