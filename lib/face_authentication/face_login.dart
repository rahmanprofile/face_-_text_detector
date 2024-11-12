// Updated face_login_screen.dart

import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';

import '../controller/databse_helper.dart';

class FaceLoginScreen extends StatefulWidget {
  @override
  _FaceLoginScreenState createState() => _FaceLoginScreenState();
}

class _FaceLoginScreenState extends State<FaceLoginScreen> {
  final ImagePicker _picker = ImagePicker();
  late FaceDetector _faceDetector;
  DatabaseHelper _dbHelper = DatabaseHelper();
  TextEditingController _nameController = TextEditingController();
  String _message = "Enter your name and take a photo to log in.";

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

  Future<void> loginOrMarkAttendance() async {
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
      final Uint8List detectedFaceEmbedding = await extractFaceEmbedding(inputImage);
      var user = await _dbHelper.getUserByName(_nameController.text);
      if (user != null && compareEmbeddings(detectedFaceEmbedding, user['face_data'])) {
        setState(() {
          _message = "Login successful! Welcome, ${user['name']}.";
        });
      } else {
        setState(() {
          _message = "Face not recognized. Try again.";
        });
      }
    }
  }

  Future<Uint8List> extractFaceEmbedding(InputImage image) async {
    return Uint8List.fromList(List.generate(128, (index) => index % 256));
  }


  bool compareEmbeddings(Uint8List embedding1, Uint8List embedding2) {
    return calculateSimilarity(embedding1, embedding2) > 0.8;
  }

  double calculateSimilarity(Uint8List embedding1, Uint8List embedding2) {
    if (embedding1.length != embedding2.length) {
      throw ArgumentError("Embeddings must have the same length");
    }

    double dotProduct = 0.0;
    double magnitude1 = 0.0;
    double magnitude2 = 0.0;

    for (int i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
      magnitude1 += embedding1[i] * embedding1[i];
      magnitude2 += embedding2[i] * embedding2[i];
    }

    magnitude1 = sqrt(magnitude1);
    magnitude2 = sqrt(magnitude2);

    return magnitude1 == 0 || magnitude2 == 0 ? 0 : dotProduct / (magnitude1 * magnitude2);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Face Login')),
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
                onPressed: loginOrMarkAttendance,
                child: const Text('Log in or Mark Attendance'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
