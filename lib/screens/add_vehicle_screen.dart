import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/vehicle.dart';
import 'package:flutter/services.dart';
import '../utils/text_formatters.dart';

class AddVehicleScreen extends StatefulWidget {
  final Function(Vehicle) onSave;
  final Vehicle? vehicle; // Make vehicle optional for editing

  const AddVehicleScreen({
    super.key, 
    required this.onSave,
    this.vehicle, // Add to constructor
  });

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _makeController;
  late TextEditingController _modelController;
  late TextEditingController _yearController;
  late TextEditingController _mileageController;
  File? _vehicleImage;

  @override
  void initState() {
    super.initState();
    // Initialize controllers synchronously
    _makeController = TextEditingController(text: widget.vehicle?.make ?? '');
    _modelController = TextEditingController(text: widget.vehicle?.model ?? '');
    _yearController = TextEditingController(text: widget.vehicle?.year.toString() ?? '');
    _mileageController = TextEditingController(text: widget.vehicle?.mileage.toString() ?? '');
    
    // Asynchronously load the initial image file
    _loadInitialImage();
  }

  Future<void> _loadInitialImage() async {
    if (widget.vehicle?.photoPath != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fullPath = p.join(appDir.path, widget.vehicle!.photoPath!);
      setState(() {
        _vehicleImage = File(fullPath);
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = p.basename(image.path);
    final savedImage = await File(image.path).copy('${appDir.path}/$fileName');
    setState(() => _vehicleImage = savedImage);
  }

  void _submitData() {
    if (_formKey.currentState!.validate()) {
      final cleanedMileage = _mileageController.text.replaceAll(',', '');
      final cleanedYear = _yearController.text.replaceAll(',', '');

      final newOrUpdatedVehicle = Vehicle(
        id: widget.vehicle?.id, // Use existing ID if editing, otherwise it's null
        make: _makeController.text,
        model: _modelController.text,
        year: int.parse(cleanedYear),
        mileage: int.parse(cleanedMileage),
        photoPath: _vehicleImage != null ? p.basename(_vehicleImage!.path) : null,
      );
      widget.onSave(newOrUpdatedVehicle);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Change title based on whether we are adding or editing
        title: Text(widget.vehicle == null ? 'Add Vehicle' : 'Edit Vehicle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _vehicleImage != null ? FileImage(_vehicleImage!) : null,
                    child: _vehicleImage == null
                        ? const Icon(Icons.camera_alt, size: 50, color: Colors.grey)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(child: TextButton(onPressed: _pickImage, child: const Text('Upload Photo'))),
              const SizedBox(height: 20),
              TextFormField(
                controller: _makeController,
                decoration: const InputDecoration(labelText: 'Vehicle Make *'),
                validator: (value) => value!.isEmpty ? 'Please enter a make' : null,
              ),
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(labelText: 'Vehicle Model *'),
                validator: (value) => value!.isEmpty ? 'Please enter a model' : null,
              ),
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(labelText: 'Year *'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Please enter a year' : null,
              ),
              TextFormField(
                controller: _mileageController,
                decoration: const InputDecoration(labelText: 'Current Mileage *'),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  ThousandsSeparatorInputFormatter(),
                ],
                validator: (value) => value!.isEmpty ? 'Please enter mileage' : null,
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