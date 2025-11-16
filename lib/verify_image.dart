// lib/verify_image.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:typed_data';
import 'models/photo_step.dart';  // ✅ Import shared enum

// Import the PhotoStep enum from camera_screen
// enum PhotoStep { center, left, right }

class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;
  final PhotoStep photoStep;

  DisplayPictureScreen({
    required this.imagePath,
    required this.photoStep,
  });

  @override
  _DisplayPictureScreenState createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  String _validationMessage = "Processing image...";
  bool _isValidated = false;
  bool _isProcessing = true;

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  String _getPhotoTypeTitle() {
    switch (widget.photoStep) {
      case PhotoStep.center:
        return 'Center Face Photo';
      case PhotoStep.left:
        return 'Left Profile Photo';
      case PhotoStep.right:
        return 'Right Profile Photo';
    }
  }

  Future<void> _processImage() async {
    try {
      File imageFile = File(widget.imagePath);
      final InputImage inputImage = InputImage.fromFile(imageFile);
      final faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableLandmarks: true,
          enableContours: true,
          enableClassification: true,
        ),
      );

      final List<Face> faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();

      if (faces.isEmpty) {
        setState(() {
          _validationMessage = "No face detected. Please retake the photo.";
          _isValidated = false;
          _isProcessing = false;
        });
        return;
      }

      Face face = faces.first;
      bool validationResult = false;

      switch (widget.photoStep) {
        case PhotoStep.center:
          validationResult = await _validateCenterFace(face, imageFile);
          break;
        case PhotoStep.left:
          validationResult = await _validateLeftProfile(face, imageFile);
          break;
        case PhotoStep.right:
          validationResult = await _validateRightProfile(face, imageFile);
          break;
      }

      setState(() {
        _isValidated = validationResult;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _validationMessage = "Error processing image: $e";
        _isValidated = false;
        _isProcessing = false;
      });
    }
  }

  Future<bool> _validateCenterFace(Face face, File imageFile) async {
    // Validate both eyes are visible
    bool bothEyesVisible = face.landmarks[FaceLandmarkType.leftEye] != null &&
        face.landmarks[FaceLandmarkType.rightEye] != null;

    if (!bothEyesVisible) {
      setState(() {
        _validationMessage = "Please face the camera directly. Both eyes should be visible.";
      });
      return false;
    }

    // Check head pose for center-facing
    if (face.headEulerAngleY != null && face.headEulerAngleY!.abs() > 15) {
      setState(() {
        _validationMessage = "Please face the camera directly. Turn your head straight.";
      });
      return false;
    }

    setState(() {
      _validationMessage = "Center face photo validated successfully!";
    });
    return true;
  }

  Future<bool> _validateLeftProfile(Face face, File imageFile) async {
    // Check head pose - should be turned to the left (negative Y angle)
    if (face.headEulerAngleY != null) {
      double headAngle = face.headEulerAngleY!;
      if (headAngle > -20 || headAngle < -70) {
        setState(() {
          _validationMessage = "Please turn your head more to the left.";
        });
        return false;
      }
    }

    setState(() {
      _validationMessage = "Left profile photo validated successfully!";
    });
    return true;
  }

  Future<bool> _validateRightProfile(Face face, File imageFile) async {
    // Check head pose - should be turned to the right (positive Y angle)
    if (face.headEulerAngleY != null) {
      double headAngle = face.headEulerAngleY!;
      if (headAngle < 20 || headAngle > 70) {
        setState(() {
          _validationMessage = "Please turn your head more to the right.";
        });
        return false;
      }
    }

    setState(() {
      _validationMessage = "Right profile photo validated successfully!";
    });
    return true;
  }

  void _handleAccept() {
    Navigator.pop(context, {'isValid': true});
  }

  void _handleRetake() {
    Navigator.pop(context, {'isValid': false});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Review ${_getPhotoTypeTitle()}'),
        backgroundColor: _isValidated ? Colors.green[700] : Colors.red[700],
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              child: Image.file(
                File(widget.imagePath),
                fit: BoxFit.contain,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                if (_isProcessing)
                  Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        _validationMessage,
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isValidated ? Colors.green[50] : Colors.red[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _isValidated ? Colors.green : Colors.red,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isValidated ? Icons.check_circle : Icons.error,
                              color: _isValidated ? Colors.green : Colors.red,
                              size: 30,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _validationMessage,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: _isValidated ? Colors.green[800] : Colors.red[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _handleRetake,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[600],
                                padding: EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: Text(
                                "Retake Photo",
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isValidated ? _handleAccept : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isValidated ? Colors.green : Colors.grey,
                                padding: EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: Text(
                                _isValidated ? "Accept Photo" : "Not Valid",
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
