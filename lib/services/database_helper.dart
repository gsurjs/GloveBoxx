import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/vehicle.dart';
import '../models/maintenance_record.dart';

class DatabaseHelper {
  // A singleton pattern that ensures one instance of the database helper.
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('maintenance.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<MaintenanceRecord> createMaintenanceRecord(MaintenanceRecord record) async {
    final db = await instance.database;
    final id = await db.insert('maintenance_records', record.toMap());
    return record; // You can enhance this to return the record with the new ID
  }

  Future<List<MaintenanceRecord>> readMaintenanceRecordsForVehicle(int vehicleId) async {
    final db = await instance.database;
    final result = await db.query(
      'maintenance_records',
      orderBy: 'date DESC', // Show the most recent records first
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
    );

    return result.map((json) => MaintenanceRecord.fromMap(json)).toList();
  }

  // This method is called when the database is created for the first time.
  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const doubleType = 'REAL NOT NULL';

    // Create the vehicles table
    await db.execute('''
    CREATE TABLE vehicles ( 
      id $idType, 
      make $textType,
      model $textType,
      year $intType,
      mileage $intType,
      vin TEXT,
      photoPath TEXT
      )
    ''');

    // Create the maintenance_records table
    await db.execute('''
    CREATE TABLE maintenance_records (
      id $idType,
      vehicleId $intType,
      type $textType,
      date $textType,
      mileage $intType,
      cost $doubleType,
      serviceProvider TEXT,
      notes TEXT,
      receiptPath TEXT,
      nextDueDate TEXT,
      FOREIGN KEY (vehicleId) REFERENCES vehicles (id) ON DELETE CASCADE
    )
    ''');
  }

  // Vehicle CRUD Methods

  Future<Vehicle> createVehicle(Vehicle vehicle) async {
    final db = await instance.database;
    final id = await db.insert('vehicles', vehicle.toMap());
    return vehicle;
  }

  Future<List<Vehicle>> readAllVehicles() async {
    final db = await instance.database;
    final result = await db.query('vehicles', orderBy: 'year DESC');
    return result.map((json) => Vehicle(
      id: json['id'] as int,
      make: json['make'] as String,
      model: json['model'] as String,
      year: json['year'] as int,
      mileage: json['mileage'] as int,
      vin: json['vin'] as String?,
      photoPath: json['photoPath'] as String?,
    )).toList();
  }
  

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}