import 'package:flutter/material.dart';
import '../models/vehicle.dart';

class AddVehicleScreen extends StatefulWidget {
  final Function(Vehicle) onAddVehicle;

  const AddVehicleScreen({super.key, required this.onAddVehicle});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _mileageController = TextEditingController();

  void _submitData() {
    if (_formKey.currentState!.validate()) {
      final newVehicle = Vehicle(
        // Using a temporary ID
        id: DateTime.now().millisecondsSinceEpoch,
        make: _makeController.text,
        model: _modelController.text,
        year: int.parse(_yearController.text),
        mileage: int.parse(_mileageController.text),
      );
      widget.onAddVehicle(newVehicle);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Vehicle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _makeController,
                decoration: const InputDecoration(labelText: 'Vehicle Make *'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a make' : null,
              ),
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(labelText: 'Vehicle Model *'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a model' : null,
              ),
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(labelText: 'Year *'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a year' : null,
              ),
              TextFormField(
                controller: _mileageController,
                decoration: const InputDecoration(labelText: 'Current Mileage *'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter mileage' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitData,
                child: const Text('Save Vehicle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}