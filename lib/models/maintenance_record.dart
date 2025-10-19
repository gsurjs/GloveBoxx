class MaintenanceRecord {
  final int? id;
  final int vehicleId;
  final String type;
  final DateTime date;
  final int mileage;
  final double cost;
  final String? serviceProvider;
  final String? notes;
  final String? receiptPath;
  final DateTime? nextDueDate; // The missing property

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
    this.nextDueDate, // Added to the constructor
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'type': type,
      'date': date.toIso8601String(),
      'mileage': mileage,
      'cost': cost,
      'serviceProvider': serviceProvider,
      'notes': notes,
      'receiptPath': receiptPath,
      'nextDueDate': nextDueDate?.toIso8601String(), // Added for database saving
    };
  }

  factory MaintenanceRecord.fromMap(Map<String, dynamic> json) => MaintenanceRecord(
        id: json['id'] as int,
        vehicleId: json['vehicleId'] as int,
        type: json['type'] as String,
        date: DateTime.parse(json['date'] as String),
        mileage: json['mileage'] as int,
        cost: json['cost'] as double,
        serviceProvider: json['serviceProvider'] as String?,
        notes: json['notes'] as String?,
        receiptPath: json['receiptPath'] as String?,
        // Added to read from the database
        nextDueDate: json['nextDueDate'] == null ? null : DateTime.parse(json['nextDueDate'] as String),
      );
}