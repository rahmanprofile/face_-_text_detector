import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';


class FaceAuthentication extends StatefulWidget {
  const FaceAuthentication({super.key});

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
    final options = FaceDetectorOptions(enableLandmarks: true, enableClassification: true, enableTracking: true);
    faceDetector = FaceDetector(options: options);
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.front);
    cameraController = CameraController(frontCamera,
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
    if (!mounted || !cameraController!.value.isStreamingImages) return;

    try {
      final inputImage = _convertCameraImageToInputImage(image);
      final List<Face> faces = await faceDetector.processImage(inputImage);

      for (Face face in faces) {
        final Rect boundingBox = face.boundingBox;
        final double? rotX = face.headEulerAngleX;
        final double? rotY = face.headEulerAngleY;
        final double? rotZ = face.headEulerAngleZ;

        // Example: Only print information about the first face detected
        print("Bounding Box: $boundingBox, RotX: $rotX, RotY: $rotY, RotZ: $rotZ");

        final FaceLandmark? leftEar = face.landmarks[FaceLandmarkType.leftEar];
        if (leftEar != null) {
          final Point<int> leftEarPos = leftEar.position;
          print("Left ear position: $leftEarPos");
        }

        if (face.smilingProbability != null) {
          final double smileProb = face.smilingProbability!;
          print("Smile probability: $smileProb");
        }

        if (face.trackingId != null) {
          final int id = face.trackingId!;
          print("Face tracking ID: $id");
        }
      }
    } catch (e) {
      print("Error processing camera image: $e");
    } finally {
      await Future.delayed(const Duration(milliseconds: 100)); // Adding delay to reduce frequency
      isDetecting = false;
    }
  }

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

  Future<void> capturePhoto() async {
    try {
      final image = await cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final List<Face> faces = await faceDetector.processImage(inputImage);
      for (Face face in faces) {
        print("Face detected: ${face.boundingBox}");
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
      body: cameraController != null && cameraController!.value.isInitialized ?
      CameraPreview(cameraController!) :
      const Center(child: CircularProgressIndicator()),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          capturePhoto();
        },
        child: const Icon(Icons.camera),
      ),
    );
  }
}
