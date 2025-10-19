class Vehicle {
  final int? id;
  final String make;
  final String model;
  final int year;
  final int mileage;
  final String? vin;
  final String? photoPath;

  Vehicle({
    this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.mileage,
    this.vin,
    this.photoPath,
  });

  // Method to convert a Vehicle object to a Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'make': make,
      'model': model,
      'year': year,
      'mileage': mileage,
      'vin': vin,
      'photoPath': photoPath,
    };
  }
}