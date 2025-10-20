import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:transparent_image/transparent_image.dart';
import '../models/maintenance_record.dart';
import '../models/vehicle.dart';
import '../services/database_helper.dart';
import '../widgets/empty_state_message.dart';
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
            return const EmptyStateMessage(
              icon: Icons.receipt_long_outlined,
              title: 'No Service History',
              message:
                  'Tap the "+" button to log your first maintenance activity for this vehicle.',
            );
          } else {
            final records = snapshot.data!;
            return ListView.builder(
              itemCount: records.length,
              itemBuilder: (ctx, index) {
                final record = records[index];
                return Slidable(
                  endActionPane: ActionPane(
                    motion: const StretchMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (context) {
                          Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (context) => AddMaintenanceScreen(
                                    vehicleId: widget.vehicle.id!,
                                    record: record,
                                  ),
                                ),
                              )
                              .then((_) => _refreshLogs());
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
                              title: const Text('Delete Log'),
                              content: Text(
                                  'Are you sure you want to delete the ${record.type} record from ${DateFormat.yMd().format(record.date)}?'),
                              actions: [
                                TextButton(
                                  child: const Text('Cancel'),
                                  onPressed: () => Navigator.of(ctx).pop(),
                                ),
                                TextButton(
                                  child: const Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                  onPressed: () async {
                                    Navigator.of(ctx).pop();
                                    await DatabaseHelper.instance
                                        .deleteMaintenanceRecord(record.id!);
                                    HapticFeedback.mediumImpact();
                                    _refreshLogs();
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
                        borderRadius: BorderRadius.circular(10.0)),
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(record.type),
                      subtitle: Text(
                        '${DateFormat.yMMMd().format(record.date)} - ${record.mileage} mi',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            NumberFormat.currency(symbol: '\$')
                                .format(record.cost),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (record.receiptPath != null)
                            IconButton(
                              icon: const Icon(Icons.receipt_long),
                              onPressed: () async {
                                final directory =
                                    await getApplicationDocumentsDirectory();
                                final fullPath = p.join(
                                    directory.path, record.receiptPath!);
                                final imageFile = File(fullPath);

                                if (await imageFile.exists() &&
                                    context.mounted) {
                                  showDialog(
                                    context: context,
                                    builder: (_) => Dialog(
                                      child: FadeInImage(
                                        placeholder:
                                            MemoryImage(kTransparentImage),
                                        image: FileImage(imageFile),
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
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (context) =>
                      AddMaintenanceScreen(vehicleId: widget.vehicle.id!),
                ),
              )
              .then((_) {
            _refreshLogs();
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}