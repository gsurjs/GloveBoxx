import 'package:vehicle_maintenance_app/models/maintenance_record.dart';
import 'package:vehicle_maintenance_app/models/vehicle.dart';

// This class is a "View Model" to hold combined data for the UI.
class UpcomingMaintenanceView {
  final MaintenanceRecord record;
  final Vehicle vehicle;

  UpcomingMaintenanceView({required this.record, required this.vehicle});
}