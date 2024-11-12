import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';

class FaceAuthentication extends StatefulWidget {
  const FaceAuthentication({super.key});

  @override
  _FaceAuthenticationState createState() => _FaceAuthenticationState();
}

class _FaceAuthenticationState extends State<FaceAuthentication> {
  late FaceDetector faceDetector;
  bool isDetecting = false;

  @override
  void initState() {
    super.initState();
    faceDetector = FaceDetector(options: FaceDetectorOptions(enableLandmarks: true, enableClassification: true));
  }

  @override
  void dispose() {
    faceDetector.close();
    super.dispose();
  }

  Future<void> detectFaceFromImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return; // If no image is selected
    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final faces = await faceDetector.processImage(inputImage);
      if (faces.isEmpty) {
        print("No faces detected.");
      } else {
        print("Faces detected:");
        for (Face face in faces) {
          print("Bounding Box: ${face.boundingBox}");
        }
      }
    } catch (e) {
      print("Error processing image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Face Detection Test')),
      body: Center(
        child: ElevatedButton(
          onPressed: detectFaceFromImage,
          child: Text("Pick an Image and Detect Faces"),
        ),
      ),
    );
  }
}

