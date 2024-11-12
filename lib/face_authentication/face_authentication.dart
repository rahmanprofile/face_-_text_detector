import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';

class FaceAuthentication extends StatefulWidget {
  const FaceAuthentication({super.key});

  @override
  _FaceAuthenticationState createState() => _FaceAuthenticationState();
}

class _FaceAuthenticationState extends State<FaceAuthentication> {
  late FaceDetector faceDetector;
  bool isDetecting = false;
  CameraController? cameraController;
  CameraImage? latestImage;

  @override
  void initState() {
    super.initState();
    checkPermissions();
    initializeFaceDetector();
  }

  // Check for camera permissions
  Future<void> checkPermissions() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      await Permission.camera.request();
    }
  }

  // Initialize face detector
  void initializeFaceDetector() {
    final options = FaceDetectorOptions(
      enableLandmarks: true,
      enableClassification: true,
      enableTracking: true,
    );
    faceDetector = FaceDetector(options: options);
    initializeCamera();
  }

  // Initialize camera
  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.front);
    cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await cameraController!.initialize();
    setState(() {});
    cameraController!.startImageStream((CameraImage image) {
      if (!isDetecting) {
        isDetecting = true;
        latestImage = image;
        processCameraImage(image);
      }
    });
  }

  // Process camera image for face detection
  Future<void> processCameraImage(CameraImage image) async {
    if (!mounted || !cameraController!.value.isStreamingImages) return;

    try {
      final inputImage = _convertCameraImageToInputImage(image);
      final List<Face> faces = await faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        print("No faces detected.");
      } else {
        for (Face face in faces) {
          final boundingBox = face.boundingBox;
          final rotX = face.headEulerAngleX;
          final rotY = face.headEulerAngleY;
          final rotZ = face.headEulerAngleZ;

          print("Bounding Box: $boundingBox, RotX: $rotX, RotY: $rotY, RotZ: $rotZ");
        }
      }
    } catch (e) {
      print("Error processing camera image: $e");
    } finally {
      await Future.delayed(const Duration(milliseconds: 100)); // Add delay to reduce frequency
      isDetecting = false;
    }
  }

  // Convert camera image to InputImage
  InputImage _convertCameraImageToInputImage(CameraImage image) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();
    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
    const InputImageRotation rotation = InputImageRotation.rotation0deg;
    const InputImageFormat format = InputImageFormat.nv21;
    final List<int> bytesPerRow = image.planes.map((plane) => plane.bytesPerRow).toList();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: imageSize,
        rotation: rotation,
        format: format,
        bytesPerRow: bytesPerRow.first,
      ),
    );
  }

  // Capture photo
  Future<void> capturePhoto() async {
    try {
      // Capture the image
      final XFile photo = await cameraController!.takePicture();
      print("Captured photo path: ${photo.path}");

      // Process the captured image for face detection
      final inputImage = InputImage.fromFilePath(photo.path);
      final List<Face> faces = await faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        print("No faces detected.");
      } else {
        for (Face face in faces) {
          print("Face detected: ${face.boundingBox}");
        }
      }
    } catch (e) {
      print("Error capturing photo: $e");
    }
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
        centerTitle: true,
        title: const Text("Face Detector", style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: cameraController != null && cameraController!.value.isInitialized
          ? CameraPreview(cameraController!)
          : const Center(child: CircularProgressIndicator()),
      floatingActionButton: FloatingActionButton(
        onPressed: capturePhoto,
        child: const Icon(Icons.camera),
      ),
    );
  }
}
