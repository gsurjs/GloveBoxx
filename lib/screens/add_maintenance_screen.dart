import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/maintenance_record.dart';
import '../services/database_helper.dart';

class AddMaintenanceScreen extends StatefulWidget {
  final int vehicleId;
  const AddMaintenanceScreen({super.key, required this.vehicleId});

  @override
  State<AddMaintenanceScreen> createState() => _AddMaintenanceScreenState();
}

class _AddMaintenanceScreenState extends State<AddMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _typeController = TextEditingController();
  final _mileageController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _selectedDate;

  bool _setReminder = false;
  int _reminderValue = 3;
  String _reminderUnit = 'Months';

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    ).then((pickedDate) {
      if (pickedDate == null) return;
      setState(() => _selectedDate = pickedDate);
    });
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a date.')),
        );
        return;
      }

      DateTime? nextDueDate;
      if (_setReminder) {
        int daysToAdd = 0;
        if (_reminderUnit == 'Days') {
          daysToAdd = _reminderValue;
        } else if (_reminderUnit == 'Weeks') {
          daysToAdd = _reminderValue * 7;
        } else if (_reminderUnit == 'Months') {
          daysToAdd = _reminderValue * 30;
        }
        nextDueDate = _selectedDate!.add(Duration(days: daysToAdd));
      }

      final newRecord = MaintenanceRecord(
        vehicleId: widget.vehicleId,
        type: _typeController.text,
        date: _selectedDate!,
        mileage: int.parse(_mileageController.text.replaceAll(',', '')),
        cost: double.parse(_costController.text.replaceAll('\$', '').replaceAll(',', '')),
        notes: _notesController.text,
        nextDueDate: nextDueDate,
      );

      await DatabaseHelper.instance.createMaintenanceRecord(newRecord);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Maintenance Entry')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: 'Maintenance Type *'),
                validator: (value) => value!.isEmpty ? 'Please enter a type' : null,
              ),
              TextFormField(
                controller: _mileageController,
                decoration: const InputDecoration(labelText: 'Mileage *'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Please enter mileage' : null,
              ),
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(labelText: 'Cost *'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) => value!.isEmpty ? 'Please enter a cost' : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDate == null
                          ? 'No Date Chosen!'
                          : 'Date: ${DateFormat.yMd().format(_selectedDate!)}',
                    ),
                  ),
                  TextButton(
                    onPressed: _presentDatePicker,
                    child: const Text('Choose Date', style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
              ),
              const Divider(height: 30),
              CheckboxListTile(
                title: const Text('Set Reminder'),
                value: _setReminder,
                onChanged: (bool? value) {
                  setState(() => _setReminder = value!);
                },
              ),
              if (_setReminder)
                Row(
                  children: [
                    const SizedBox(width: 16),
                    const Text('Remind me in:'),
                    const SizedBox(width: 10),
                    DropdownButton<int>(
                      value: _reminderValue,
                      items: List.generate(12, (i) => i + 1)
                          .map((val) => DropdownMenuItem(value: val, child: Text(val.toString())))
                          .toList(),
                      onChanged: (val) => setState(() => _reminderValue = val!),
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: _reminderUnit,
                      items: ['Days', 'Weeks', 'Months']
                          .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
                          .toList(),
                      onChanged: (val) => setState(() => _reminderUnit = val!),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Save Entry'),
              )
            ],
          ),
        ),
      ),
    );
  }
}