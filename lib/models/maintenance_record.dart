class MaintenanceRecord {
  final int? id;
  final int vehicleId; // Foreign key to link with a Vehicle
  final String type;
  final DateTime date;
  final int mileage;
  final double cost;
  final String? serviceProvider;
  final String? notes;
  final String? receiptPath;

  MaintenanceRecord({
    this.id,
    required this.vehicleId,
    required this.type,
    required this.date,
    required this.mileage,
    required this.cost,
    this.serviceProvider,
    this.notes,
    this.receiptPath,
  });

  // Method to convert a MaintenanceRecord object to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'type': type,
      'date': date.toIso8601String(), // Store dates as strings
      'mileage': mileage,
      'cost': cost,
      'serviceProvider': serviceProvider,
      'notes': notes,
      'receiptPath': receiptPath,
    };
  }
}