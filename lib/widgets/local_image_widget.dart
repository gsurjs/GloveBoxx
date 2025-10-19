import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class LocalImage extends StatefulWidget {
  final String? fileName;
  final IconData placeholderIcon;

  const LocalImage({super.key, required this.fileName, required this.placeholderIcon});

  @override
  State<LocalImage> createState() => _LocalImageState();
}

class _LocalImageState extends State<LocalImage> {
  Future<File?> _getImageFile() async {
    if (widget.fileName == null) return null;
    final appDir = await getApplicationDocumentsDirectory();
    final filePath = '${appDir.path}/${widget.fileName}';
    return File(filePath);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: _getImageFile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.data != null && snapshot.data!.existsSync()) {
          return CircleAvatar(
            radius: 25,
            backgroundImage: FileImage(snapshot.data!),
          );
        } else {
          return CircleAvatar(
            radius: 25,
            child: Icon(widget.placeholderIcon),
          );
        }
      },
    );
  }
}