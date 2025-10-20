import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../services/database_helper.dart';

class VehicleProvider with ChangeNotifier {
  List<Vehicle> _vehicles = [];
  bool _isLoading = true;

  List<Vehicle> get vehicles => _vehicles;
  bool get isLoading => _isLoading;

  VehicleProvider() {
    fetchVehicles();
  }

  Future<void> fetchVehicles() async {
    _isLoading = true;
    notifyListeners();
    _vehicles = await DatabaseHelper.instance.readAllVehicles();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    await DatabaseHelper.instance.createVehicle(vehicle);
    await fetchVehicles(); // This will refresh the list and notify all listeners
  }
  Future<void> deleteVehicle(int id) async {
    await DatabaseHelper.instance.deleteVehicle(id);
    await fetchVehicles(); // This will refresh the list and notify all listeners
  }
}