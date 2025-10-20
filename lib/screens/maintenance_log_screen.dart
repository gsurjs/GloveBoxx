import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/maintenance_record.dart';
import '../models/vehicle.dart';
import '../services/database_helper.dart';
import 'add_maintenance_screen.dart';
import 'dart:io';
import '../widgets/empty_state_message.dart';


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
            return const EmptyStateMessage(
              icon: Icons.receipt_long_outlined,
              title: 'No Service History',
              message: 'Tap the "+" button to log your first maintenance activity for this vehicle.',
            );
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          NumberFormat.currency(symbol: '\$').format(record.cost),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        // Show receipt icon if a path exists
                        if (record.receiptPath != null)
                          IconButton(
                            icon: const Icon(Icons.receipt_long),
                            onPressed: () async { // Make the function async
                              // Find the app's documents directory
                              final directory = await getApplicationDocumentsDirectory();
                              // Create the full path by joining the directory and the filename
                              final fullPath = p.join(directory.path, record.receiptPath!);
                              final imageFile = File(fullPath);

                              if (await imageFile.exists() && context.mounted) {
                                showDialog(
                                  context: context,
                                  builder: (_) => Dialog(
                                    child: Image.file(
                                      imageFile, // Use the file with the full path
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                      ],
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