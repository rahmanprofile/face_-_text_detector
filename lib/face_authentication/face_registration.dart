import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:machine_learning/face_authentication/face_login.dart';
import 'package:machine_learning/face_authentication/users_pages.dart';
import '../controller/databse_helper.dart';

class FaceRegistrationScreen extends StatefulWidget {
  @override
  _FaceRegistrationScreenState createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  final ImagePicker _picker = ImagePicker();
  late FaceDetector _faceDetector;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _nameController = TextEditingController();
  String _message = "Enter your name and take a photo to register.";

  @override
  void initState() {
    super.initState();
    _faceDetector = GoogleMlKit.vision.faceDetector();
  }

  @override
  void dispose() {
    _faceDetector.close();
    super.dispose();
  }

  Future<void> registerFace() async {
    if (_nameController.text.isEmpty) {
      setState(() {
        _message = "Please enter your name.";
      });
      return;
    }

    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    final inputImage = InputImage.fromFilePath(image.path);
    final faces = await _faceDetector.processImage(inputImage);

    if (faces.isEmpty) {
      setState(() {
        _message = "No faces detected.";
      });
    } else {
      final face = faces.first;
      final faceData = extractFaceFeatures(face);
      int userId = await _dbHelper.registerUser(_nameController.text, faceData);

      setState(() {
        _message = "User registered with ID: $userId";
      });
      log("save: $_message");
    }
  }

  String extractFaceFeatures(Face face) {
    final String faceData = '${face.boundingBox.left},${face.boundingBox.top},${face.boundingBox.width},${face.boundingBox.height}';
    log("face_data: $faceData");
    return faceData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Face Registration'),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const UsersPages()));
              },
              icon: const Icon(CupertinoIcons.person_2_fill),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Enter your name',
                ),
              ),
              const SizedBox(height: 20),
              Text(_message),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: registerFace,
                child: const Text('Register'),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => FaceLoginScreen()));
                },
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
