import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;
  DisplayPictureScreen({required this.imagePath});

  @override
  _DisplayPictureScreenState createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  String _validationMessage = "Processing image...";

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    try {
      File imageFile = File(widget.imagePath);
      final InputImage inputImage = InputImage.fromFile(imageFile);

      final faceDetector = FaceDetector(
        options: FaceDetectorOptions(enableClassification: true),
      );

      final List<Face> faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();

      if (faces.isEmpty) {
        setState(() {
          _validationMessage = "No face detected. Please retake the photo.";
        });
        return;
      }

      Face face = faces.first;
      double faceCenterX = face.boundingBox.center.dx;
      double faceCenterY = face.boundingBox.center.dy;

      double imageCenterX = MediaQuery.of(context).size.width / 2;
      double imageCenterY = MediaQuery.of(context).size.height / 2;

      double xOffset = (faceCenterX - imageCenterX).abs();
      double yOffset = (faceCenterY - imageCenterY).abs();

      // Define acceptable angle thresholds
      double maxOffset = 50.0; // Adjust threshold as needed
      if (xOffset > maxOffset || yOffset > maxOffset) {
        setState(() {
          _validationMessage =
              "Face not centered. Please align your face properly.";
        });
      } else {
        setState(() {
          _validationMessage = "Face validated successfully!";
        });
      }
    } catch (e) {
      setState(() {
        _validationMessage = "Error processing image: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Review Picture')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.file(File(widget.imagePath)),
          SizedBox(height: 20),
          Text(
            _validationMessage,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Retake Photo"),
          ),
        ],
      ),
    );
  }
}
