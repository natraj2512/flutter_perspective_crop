import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_perspective_crop/flutter_perspective_crop.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Perspective Crop Example',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const ExamplePage(),
    );
  }
}

class ExamplePage extends StatefulWidget {
  const ExamplePage({super.key});

  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  String? _croppedPath;
  final _picker = ImagePicker();

  Future<void> _pickAndCrop() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _croppedPath = null;
    });

    if (!mounted) return;

    final croppedPath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PerspectiveCropPage(imagePath: picked.path, title: 'Crop Image'),
      ),
    );

    if (croppedPath != null && mounted) {
      setState(() {
        _croppedPath = croppedPath;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perspective Crop Example')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _pickAndCrop,
                icon: const Icon(Icons.crop),
                label: const Text('Pick & Crop Image'),
              ),
              const SizedBox(height: 32),
              if (_croppedPath != null) ...[
                const Text(
                  'Cropped Result',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_croppedPath!),
                    width: 300,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                SelectableText(
                  'Saved at:\n$_croppedPath',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
