import 'package:flutter/material.dart';
import 'home_dashboard_screen.dart';
import 'vehicle_list_screen.dart';
import 'expense_summary_screen.dart';
import '../models/vehicle.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final GlobalKey<VehicleListScreenState> _vehicleListKey = GlobalKey<VehicleListScreenState>();

  // This list is now a 'late final' field instead of 'static const'.
  // This is the critical change.
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    // We initialize the list here, inside the state.
    // This allows us to pass the _onItemTapped function to the home screen.
    _widgetOptions = <Widget>[
      HomeDashboardScreen(onNavigateRequest: _showAddOrEditVehicleScreen),
      // Assign the key to the VehicleListScreen
      VehicleListScreen(key: _vehicleListKey),
      const ExpenseSummaryScreen(),
    ];
  }

  void _showAddOrEditVehicleScreen({Vehicle? vehicle}) {
    // Pass the optional vehicle to the method that opens the screen
    _vehicleListKey.currentState?.navigateToAddOrEditVehicleScreen(vehicle: vehicle);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Vehicles',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment),
            label: 'Expenses',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}