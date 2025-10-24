import 'package:flutter/material.dart';
import '../models/expense_category_data.dart';
import '../models/expense_monthly_data.dart';
import '../models/upcoming_maintenance_view.dart';
import '../models/vehicle.dart';
import '../services/database_helper.dart';

class VehicleProvider with ChangeNotifier {
  List<Vehicle> _vehicles = [];
  List<ExpenseCategoryData> _expenseByCategory = [];
  List<ExpenseMonthlyData> _expenseByMonth = [];
  List<UpcomingMaintenanceView> _upcomingMaintenance = []; // Added to store upcoming maintenance data
  bool _isLoading = true;

  List<Vehicle> get vehicles => _vehicles;
  List<ExpenseCategoryData> get expenseByCategory => _expenseByCategory;
  List<ExpenseMonthlyData> get expenseByMonth => _expenseByMonth;
  List<UpcomingMaintenanceView> get upcomingMaintenance => _upcomingMaintenance; // Getter for upcoming maintenance data
  bool get isLoading => _isLoading;

  VehicleProvider() {
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    _isLoading = true;
    notifyListeners();
    // Fetch all data concurrently
    final results = await Future.wait([
      DatabaseHelper.instance.readAllVehicles(),
      DatabaseHelper.instance.getExpensesByCategory(),
      DatabaseHelper.instance.getExpensesByMonth(),
      DatabaseHelper.instance.getUpcomingMaintenance(), // Fetch the data
    ]);
    _vehicles = results[0] as List<Vehicle>;
    _expenseByCategory = results[1] as List<ExpenseCategoryData>;
    _expenseByMonth = results[2] as List<ExpenseMonthlyData>;
    _upcomingMaintenance = results[3] as List<UpcomingMaintenanceView>; // Store the data
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    await DatabaseHelper.instance.createVehicle(vehicle);
    await fetchAllData();
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    await DatabaseHelper.instance.updateVehicle(vehicle);
    await fetchAllData();
  }

  Future<void> deleteVehicle(int id) async {
    await DatabaseHelper.instance.deleteVehicle(id);
    await fetchAllData();
  }
}