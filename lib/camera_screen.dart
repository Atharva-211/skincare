import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'verify_image.dart';
import 'package:camera_app/frontend/pages/mainDashboard.dart';
import 'package:fl_chart/fl_chart.dart'; // <-- Add this line



enum PhotoStep { front, leftProfile, rightProfile }

class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;

  TakePictureScreen({required this.camera});

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  PhotoStep currentStep = PhotoStep.front;
  Map<PhotoStep, String?> capturedImages = {
    PhotoStep.front: null,
    PhotoStep.leftProfile: null,
    PhotoStep.rightProfile: null,
  };

  Map<PhotoStep, bool> validationResults = {
    PhotoStep.front: false,
    PhotoStep.leftProfile: false,
    PhotoStep.rightProfile: false,
  };

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getStepTitle() {
    switch (currentStep) {
      case PhotoStep.front:
        return 'Take Front Face Photo';
      case PhotoStep.leftProfile:
        return 'Take Right Profile Photo';
      case PhotoStep.rightProfile:
        return 'Take Left Profile Photo';
    }
  }

  String _getStepInstruction() {
    switch (currentStep) {
      case PhotoStep.front:
        return 'Look directly at the camera\nEnsure both eyes are visible';
      case PhotoStep.leftProfile:
        return 'Turn your head to the Right\nShow your Right profile';
      case PhotoStep.rightProfile:
        return 'Turn your head to the Left\nShow your Left profile';
    }
  }

  IconData _getStepIcon() {
    switch (currentStep) {
      case PhotoStep.front:
        return Icons.face;
      case PhotoStep.leftProfile:
        return Icons.arrow_back;
      case PhotoStep.rightProfile:
        return Icons.arrow_forward;
    }
  }

  void _goToNextStep() {
    setState(() {
      switch (currentStep) {
        case PhotoStep.front:
          currentStep = PhotoStep.leftProfile;
          break;
        case PhotoStep.leftProfile:
          currentStep = PhotoStep.rightProfile;
          break;
        case PhotoStep.rightProfile:
        // All photos taken, check if all are validated
          _checkAllValidations();
          break;
      }
    });
  }

  void _goToPreviousStep() {
    setState(() {
      switch (currentStep) {
        case PhotoStep.rightProfile:
          currentStep = PhotoStep.leftProfile;
          break;
        case PhotoStep.leftProfile:
          currentStep = PhotoStep.front;
          break;
        case PhotoStep.front:
        // Already at first step
          break;
      }
    });
  }

  void _retakeCurrentPhoto() {
    setState(() {
      capturedImages[currentStep] = null;
      validationResults[currentStep] = false;
    });
  }

  void _checkAllValidations() {
    bool allValidated = validationResults.values.every((result) => result == true);
    if (allValidated) {
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 30),
              SizedBox(width: 10),
              Text('Success!'),
            ],
          ),
          content: Text('All face photos have been validated successfully!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => SkinCareApp(
                      camera: widget.camera,
                      radarData: [
                        RadarEntry(value: 60),
                        RadarEntry(value: 60),
                        RadarEntry(value: 60),
                        RadarEntry(value: 65),
                        RadarEntry(value: 55),
                        RadarEntry(value: 60),
                        RadarEntry(value: 68),
                        RadarEntry(value: 60),
                        RadarEntry(value: 58),
                        RadarEntry(value: 85),
                      ],
                      showRecommendations: true, // <--- Pass the flag
                    ),
                  ),
                );
              },
              child: Text('Continue'),
            ),



          ],
        );
      },
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepIndicator(PhotoStep.front, 1),
          Container(width: 30, height: 2, color: Colors.white54),
          _buildStepIndicator(PhotoStep.leftProfile, 2),
          Container(width: 30, height: 2, color: Colors.white54),
          _buildStepIndicator(PhotoStep.rightProfile, 3),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(PhotoStep step, int stepNumber) {
    bool isActive = currentStep == step;
    bool isCompleted = validationResults[step] == true;

    Color backgroundColor;
    Color textColor;
    Widget icon;

    if (isCompleted) {
      backgroundColor = Colors.green;
      textColor = Colors.white;
      icon = Icon(Icons.check, color: Colors.white, size: 16);
    } else if (isActive) {
      backgroundColor = Colors.blue;
      textColor = Colors.white;
      icon = Text('$stepNumber', style: TextStyle(color: textColor, fontWeight: FontWeight.bold));
    } else {
      backgroundColor = Colors.white24;
      textColor = Colors.white54;
      icon = Text('$stepNumber', style: TextStyle(color: textColor));
    }

    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
      ),
      child: Center(child: icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getStepTitle()),
        backgroundColor: Colors.black,
        leading: currentStep != PhotoStep.front
            ? IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _goToPreviousStep,
        )
            : null,
      ),
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                _buildProgressIndicator(),
                SizedBox(height: 20),
                // Instruction card
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(_getStepIcon(), color: Colors.white, size: 30),
                      SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          _getStepInstruction(),
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                    ),
                    child: Center(
                      child: CameraPreview(_controller),
                    ),
                  ),
                ),
                Container(
                  height: 120,
                  color: Colors.black,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Retake button (only show if current step has been captured)
                      if (capturedImages[currentStep] != null)
                        FloatingActionButton(
                          backgroundColor: Colors.red,
                          heroTag: "retake",
                          onPressed: _retakeCurrentPhoto,
                          child: Icon(Icons.refresh, color: Colors.white),
                        )
                      else
                        SizedBox(width: 56), // Placeholder for spacing

                      // Capture button
                      FloatingActionButton(
                        backgroundColor: Colors.white,
                        heroTag: "capture",
                        onPressed: () async {
                          try {
                            await _initializeControllerFuture;
                            final image = await _controller.takePicture();
                            if (!context.mounted) return;

                            // Navigate to verification screen
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => DisplayPictureScreen(
                                  imagePath: image.path,
                                  photoStep: currentStep,
                                ),
                              ),
                            );

                            // Handle result from verification
                            if (result != null && result is Map) {
                              setState(() {
                                if (result['isValid'] == true) {
                                  capturedImages[currentStep] = image.path;
                                  validationResults[currentStep] = true;
                                  _goToNextStep();
                                } else {
                                  // Photo was not valid, stay on current step
                                  capturedImages[currentStep] = null;
                                  validationResults[currentStep] = false;
                                }
                              });
                            }
                          } catch (e) {
                            print(e);
                          }
                        },
                        child: Icon(Icons.camera_alt, color: Colors.black, size: 30),
                      ),

                      // Skip button (only for profile photos, and only if front is validated)
                      if ((currentStep == PhotoStep.leftProfile || currentStep == PhotoStep.rightProfile) &&
                          validationResults[PhotoStep.front] == true)
                        FloatingActionButton(
                          backgroundColor: Colors.orange,
                          heroTag: "skip",
                          onPressed: () {
                            setState(() {
                              validationResults[currentStep] = true; // Mark as completed
                              _goToNextStep();
                            });
                          },
                          child: Icon(Icons.skip_next, color: Colors.white),
                        )
                      else
                        SizedBox(width: 56), // Placeholder for spacing
                    ],
                  ),
                ),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}