import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart'; // Import the necessary package
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceAuthentication extends StatefulWidget {
  const FaceAuthentication({Key? key}) : super(key: key);

  @override
  State<FaceAuthentication> createState() => _FaceAuthenticationState();
}

class _FaceAuthenticationState extends State<FaceAuthentication> {
  late FaceDetector faceDetector;
  bool isDetecting = false;
  CameraController? cameraController;

  @override
  void initState() {
    super.initState();

    // Initialize the face detector with options for landmark and classification
    final options = FaceDetectorOptions(
      enableLandmarks: true,
      enableClassification: true,
      enableTracking: true,
    );
    faceDetector = FaceDetector(options: options);

    initializeCamera();
  }

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
    );

    cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await cameraController!.initialize();

    cameraController!.startImageStream((CameraImage image) {
      if (!isDetecting) {
        isDetecting = true;
        processCameraImage(image);
      }
    });
  }

  Future<void> processCameraImage(CameraImage image) async {
    try {
      final inputImage = _convertCameraImageToInputImage(image);

      // Perform face detection
      final List<Face> faces = await faceDetector.processImage(inputImage);

      for (Face face in faces) {
        // Get face bounding box
        final Rect boundingBox = face.boundingBox;

        // Get rotation angles of the head
        final double? rotX = face.headEulerAngleX;
        final double? rotY = face.headEulerAngleY;
        final double? rotZ = face.headEulerAngleZ;

        // Detect specific landmarks if enabled (e.g., left ear position)
        final FaceLandmark? leftEar = face.landmarks[FaceLandmarkType.leftEar];
        if (leftEar != null) {
          final Point<int> leftEarPos = leftEar.position;
          print("Left ear position: $leftEarPos");
        }

        // Get the probability of a smile if classification was enabled
        if (face.smilingProbability != null) {
          final double smileProb = face.smilingProbability!;
          print("Smile probability: $smileProb");
        }

        // Get the unique tracking ID if tracking was enabled
        if (face.trackingId != null) {
          final int id = face.trackingId!;
          print("Face tracking ID: $id");
        }

        // Additional code for comparing with stored user data can be added here
      }
    } catch (e) {
      print("Error processing camera image: $e");
    } finally {
      isDetecting = false;
    }
  }

  InputImage _convertCameraImageToInputImage(CameraImage image) {
    // Collects all bytes from the image planes
    final WriteBuffer allBytes = WriteBuffer();
    for (final plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(size: null, rotation: null, format: null, bytesPerRow: null), // Adjust based on camera orientation
    );
  }

  @override
  void dispose() {
    faceDetector.close();
    cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Face Authentication"),
      ),
      body: cameraController != null && cameraController!.value.isInitialized
          ? CameraPreview(cameraController!)
          : const Center(child: CircularProgressIndicator()),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Capture image and validate against the stored image here
        },
        child: const Icon(Icons.camera),
      ),
    );
  }
}
