import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:transparent_image/transparent_image.dart';

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
          return ClipOval(
            child: FadeInImage(
              placeholder: MemoryImage(kTransparentImage),
              image: FileImage(snapshot.data!),
              width: 50, // Set a fixed size for consistency
              height: 50,
              fit: BoxFit.cover,
            ),
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