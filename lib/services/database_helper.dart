import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/vehicle.dart';
import '../models/maintenance_record.dart';
import '../models/upcoming_maintenance_view.dart';
import '../models/expense_category_data.dart';
import '../models/expense_monthly_data.dart';

class DatabaseHelper {
  // A singleton pattern that ensures one instance of the database helper.
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<List<UpcomingMaintenanceView>> getUpcomingMaintenance() async {
    final db = await instance.database;
    final fourteenDaysFromNow = DateTime.now().add(const Duration(days: 14)).toIso8601String();
    final now = DateTime.now().toIso8601String();

    // This query joins the two tables to get all info at once.
    final result = await db.rawQuery('''
      SELECT
        m.id as recordId, m.vehicleId, m.type, m.date, m.mileage, m.cost, m.nextDueDate,
        v.id as vehicleId, v.make, v.model, v.year, v.mileage as vehicleMileage
      FROM maintenance_records m
      JOIN vehicles v ON m.vehicleId = v.id
      WHERE m.nextDueDate IS NOT NULL AND m.nextDueDate BETWEEN ? AND ?
      ORDER BY m.nextDueDate ASC
    ''', [now, fourteenDaysFromNow]);

    List<UpcomingMaintenanceView> upcomingList = [];
    for (var json in result) {
      final record = MaintenanceRecord(
        id: json['recordId'] as int,
        vehicleId: json['vehicleId'] as int,
        type: json['type'] as String,
        date: DateTime.parse(json['date'] as String),
        mileage: json['mileage'] as int,
        cost: json['cost'] as double,
        nextDueDate: DateTime.parse(json['nextDueDate'] as String),
      );
      final vehicle = Vehicle(
        id: json['vehicleId'] as int,
        make: json['make'] as String,
        model: json['model'] as String,
        year: json['year'] as int,
        mileage: json['vehicleMileage'] as int,
      );
      upcomingList.add(UpcomingMaintenanceView(record: record, vehicle: vehicle));
    }
    return upcomingList;
  }

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
    await db.insert('maintenance_records', record.toMap());
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

  // Maintenance Record CRUD
  Future<int> updateMaintenanceRecord(MaintenanceRecord record) async {
    final db = await instance.database;
    return await db.update(
      'maintenance_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deleteMaintenanceRecord(int id) async {
    final db = await instance.database;
    return await db.delete(
      'maintenance_records',
      where: 'id = ?',
      whereArgs: [id],
    );
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
  // New method to get expenses by category
  Future<List<ExpenseCategoryData>> getExpensesByCategory() async {
    final db = await instance.database;

    final result = await db.rawQuery('''
      SELECT type, SUM(cost) as total
      FROM maintenance_records
      GROUP BY type
      ORDER BY total DESC
    ''');

    return result.map((json) {
      return ExpenseCategoryData(
        category: json['type'] as String,
        totalCost: json['total'] as double,
      );
    }).toList();
  }

  Future<List<ExpenseMonthlyData>> getExpensesByMonth() async {
    final db = await instance.database;

    final result = await db.rawQuery('''
      SELECT strftime('%Y-%m', date) as month, SUM(cost) as total
      FROM maintenance_records
      GROUP BY month
      ORDER BY month ASC
    ''');

    return result.map((json) {
      return ExpenseMonthlyData(
        month: json['month'] as String,
        totalCost: json['total'] as double,
      );
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getAllRecordsForReport() async {
  final db = await instance.database;
  final result = await db.rawQuery('''
    SELECT
      m.date,
      m.type,
      m.cost,
      m.mileage,
      m.notes,
      v.year,
      v.make,
      v.model
    FROM maintenance_records m
    JOIN vehicles v ON m.vehicleId = v.id
    ORDER BY m.date DESC
  ''');
  return result;
}

  // Vehicle CRUD Methods

  Future<Vehicle> createVehicle(Vehicle vehicle) async {
    final db = await instance.database;
    await db.insert('vehicles', vehicle.toMap());
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

  Future<int> deleteVehicle(int id) async {
    final db = await instance.database;
    return await db.delete(
      'vehicles',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateVehicle(Vehicle vehicle) async {
    final db = await instance.database;
    return await db.update(
      'vehicles',
      vehicle.toMap(),
      where: 'id = ?',
      whereArgs: [vehicle.id],
    );
  }
  

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}