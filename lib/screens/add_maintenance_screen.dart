import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/maintenance_record.dart';
import '../services/database_helper.dart';

class AddMaintenanceScreen extends StatefulWidget {
  final int vehicleId;
  final MaintenanceRecord? record; // Add this line

  const AddMaintenanceScreen({
    super.key, 
    required this.vehicleId,
    this.record, // Add to constructor
  });

  @override
  State<AddMaintenanceScreen> createState() => _AddMaintenanceScreenState();
}

class _AddMaintenanceScreenState extends State<AddMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _typeController;
  late TextEditingController _mileageController;
  late TextEditingController _costController;
  late TextEditingController _notesController;
  DateTime? _selectedDate;
  File? _receiptImage;

  bool _setReminder = false;
  int _reminderValue = 3;
  String _reminderUnit = 'Months';

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _typeController = TextEditingController(text: record?.type ?? '');
    _mileageController = TextEditingController(text: record?.mileage.toString() ?? '');
    _costController = TextEditingController(text: record?.cost.toString() ?? '');
    _notesController = TextEditingController(text: record?.notes ?? '');
    _selectedDate = record?.date;

    if (record?.nextDueDate != null) {
      _setReminder = true;
      // Note: This doesn't reverse-calculate the exact dropdown values,
      // but it preserves the reminder status.
    }
    
    _loadInitialImage();
  }

  Future<void> _loadInitialImage() async {
    if (widget.record?.receiptPath != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fullPath = p.join(appDir.path, widget.record!.receiptPath!);
      if (mounted) {
        setState(() {
          _receiptImage = File(fullPath);
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = p.basename(image.path);
    final savedImage = await File(image.path).copy('${appDir.path}/$fileName');
    setState(() => _receiptImage = savedImage);
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
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
      if (_setReminder && widget.record?.nextDueDate == null) {
        int daysToAdd = 0;
        if (_reminderUnit == 'Days') daysToAdd = _reminderValue;
        else if (_reminderUnit == 'Weeks') daysToAdd = _reminderValue * 7;
        else if (_reminderUnit == 'Months') daysToAdd = _reminderValue * 30;
        nextDueDate = _selectedDate!.add(Duration(days: daysToAdd));
      } else {
        nextDueDate = widget.record?.nextDueDate;
      }

      final newOrUpdatedRecord = MaintenanceRecord(
        id: widget.record?.id,
        vehicleId: widget.vehicleId,
        type: _typeController.text,
        date: _selectedDate!,
        mileage: int.parse(_mileageController.text.replaceAll(',', '')),
        cost: double.parse(_costController.text.replaceAll('\$', '').replaceAll(',', '')),
        notes: _notesController.text,
        nextDueDate: nextDueDate,
        receiptPath: _receiptImage != null ? p.basename(_receiptImage!.path) : null,
      );

      if (widget.record == null) {
        await DatabaseHelper.instance.createMaintenanceRecord(newOrUpdatedRecord);
      } else {
        await DatabaseHelper.instance.updateMaintenanceRecord(newOrUpdatedRecord);
      }

      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.record == null ? 'New Maintenance Entry' : 'Edit Maintenance Entry')),
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
              
              // --- Receipt Upload UI ---
              const Divider(height: 30),
              const Text('Attach Receipt (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Attach Image'),
                  ),
                  const SizedBox(width: 10),
                  if (_receiptImage != null)
                    const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
              if (_receiptImage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Image.file(_receiptImage!, height: 150, fit: BoxFit.cover),
                ),

              const Divider(height: 30),
              // Reminder UI
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