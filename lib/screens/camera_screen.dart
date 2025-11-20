// lib/screens/camera_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';  // ✅ Add this
import '../services/detection_service.dart';
import '../models/analysis_result.dart';
import '../models/photo_step.dart';
import '../verify_image.dart';
import 'results/results_screen.dart';

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraScreen({Key? key, required this.camera}) : super(key: key);

  @override
  CameraScreenState createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late CameraDescription _currentCamera;
  List<CameraDescription> _availableCameras = [];
  final ImagePicker _picker = ImagePicker();  // ✅ Add this

  PhotoStep currentStep = PhotoStep.center;
  bool isServerWaking = false;
  bool isServerReady = false;
  bool isFlipping = false;

  Map<PhotoStep, File?> capturedImages = {
    PhotoStep.center: null,
    PhotoStep.left: null,
    PhotoStep.right: null,
  };

  static const int TARGET_SIZE = 1024;

  @override
  void initState() {
    super.initState();
    _currentCamera = widget.camera;
    _initializeCamera();
    _loadAvailableCameras();
    _wakeUpServer();
  }

  Future<void> _loadAvailableCameras() async {
    try {
      _availableCameras = await availableCameras();
    } catch (e) {
      print('Error loading cameras: $e');
    }
  }

  void _initializeCamera() {
    _controller = CameraController(
      _currentCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  Future<void> _flipCamera() async {
    if (isFlipping || _availableCameras.isEmpty) return;

    setState(() {
      isFlipping = true;
    });

    try {
      await _controller.dispose();

      if (_currentCamera.lensDirection == CameraLensDirection.back) {
        _currentCamera = _availableCameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _availableCameras.first,
        );
      } else {
        _currentCamera = _availableCameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => _availableCameras.first,
        );
      }

      _initializeCamera();
      await _initializeControllerFuture;

      setState(() {
        isFlipping = false;
      });

      _showSnackBar(
        _currentCamera.lensDirection == CameraLensDirection.front
            ? '📸 Switched to Front Camera'
            : '📸 Switched to Back Camera',
        Colors.blue,
      );
    } catch (e) {
      print('Error flipping camera: $e');
      setState(() {
        isFlipping = false;
      });
      _showSnackBar('❌ Failed to switch camera', Colors.red);
    }
  }

  // ✅ NEW: Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);

        // Navigate to face validation screen
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DisplayPictureScreen(
              imagePath: imageFile.path,
              photoStep: currentStep,
            ),
          ),
        );

        // Check if image was validated and accepted
        if (result != null && result['isValid'] == true) {
          // Process to 1024x1024 after validation
          imageFile = await _processImageToTargetSize(imageFile);

          setState(() {
            capturedImages[currentStep] = imageFile;
          });

          _showSnackBar('📸 Photo validated!', Colors.green);

          // Check if all photos are captured
          if (capturedImages.values.every((img) => img != null)) {
            _processAllImages();
          } else {
            _nextStep();
          }
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      _showSnackBar('❌ Failed to pick image', Colors.red);
    }
  }

  Future<void> _wakeUpServer() async {
    setState(() {
      isServerWaking = true;
    });

    print('🚀 Waking up detection server...');
    final isHealthy = await DetectionService.waitForServerWakeup(maxRetries: 5);

    setState(() {
      isServerWaking = false;
      isServerReady = isHealthy;
    });

    if (isHealthy) {
      _showSnackBar('✅ Server is ready! Start capturing photos.', Colors.green);
    } else {
      _showSnackBar('⚠️ Server timeout. You can still capture photos.', Colors.orange);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _getStepTitle() {
    switch (currentStep) {
      case PhotoStep.center:
        return 'Center Face Photo';
      case PhotoStep.left:
        return 'Left Profile Photo';
      case PhotoStep.right:
        return 'Right Profile Photo';
    }
  }

  String _getStepInstruction() {
    switch (currentStep) {
      case PhotoStep.center:
        return 'Face the camera directly\nKeep your face centered';
      case PhotoStep.left:
        return 'Turn your head to the left\nShow your left profile';
      case PhotoStep.right:
        return 'Turn your head to the right\nShow your right profile';
    }
  }

  void _nextStep() {
    setState(() {
      if (currentStep == PhotoStep.center) {
        currentStep = PhotoStep.left;
      } else if (currentStep == PhotoStep.left) {
        currentStep = PhotoStep.right;
      }
    });
  }

  void _previousStep() {
    setState(() {
      if (currentStep == PhotoStep.right) {
        currentStep = PhotoStep.left;
      } else if (currentStep == PhotoStep.left) {
        currentStep = PhotoStep.center;
      }
    });
  }

  Future<File> _processImageToTargetSize(File originalFile) async {
    try {
      print('📐 Processing image to ${TARGET_SIZE}x${TARGET_SIZE}...');

      final bytes = await originalFile.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) {
        print('❌ Failed to decode image');
        return originalFile;
      }

      print('Original captured size: ${originalImage.width}x${originalImage.height}');

      int smallerDimension = originalImage.width < originalImage.height
          ? originalImage.width
          : originalImage.height;

      int cropX = (originalImage.width - smallerDimension) ~/ 2;
      int cropY = (originalImage.height - smallerDimension) ~/ 2;

      img.Image croppedImage = img.copyCrop(
        originalImage,
        x: cropX,
        y: cropY,
        width: smallerDimension,
        height: smallerDimension,
      );

      print('After center crop: ${croppedImage.width}x${croppedImage.height}');

      img.Image resizedImage = img.copyResize(
        croppedImage,
        width: TARGET_SIZE,
        height: TARGET_SIZE,
      );

      print('✅ Final size: ${resizedImage.width}x${resizedImage.height}');

      final processedPath = originalFile.path.replaceAll('.jpg', '_1024.jpg').replaceAll('.png', '_1024.jpg');
      final processedFile = File(processedPath);
      await processedFile.writeAsBytes(img.encodeJpg(resizedImage, quality: 95));

      return processedFile;
    } catch (e) {
      print('❌ Error processing image: $e');
      return originalFile;
    }
  }

  Future<void> _captureAndProcess() async {
    try {
      await _initializeControllerFuture;
      final XFile image = await _controller.takePicture();
      File imageFile = File(image.path);

      // Navigate to face validation screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DisplayPictureScreen(
            imagePath: imageFile.path,
            photoStep: currentStep,
          ),
        ),
      );

      // Check if image was validated and accepted
      if (result != null && result['isValid'] == true) {
        // Process to 1024x1024 after validation
        imageFile = await _processImageToTargetSize(imageFile);

        setState(() {
          capturedImages[currentStep] = imageFile;
        });

        _showSnackBar('📸 Photo validated!', Colors.green);

        // Check if all photos are captured
        if (capturedImages.values.every((img) => img != null)) {
          _processAllImages();
        } else {
          _nextStep();
        }
      }
    } catch (e) {
      print('Error capturing image: $e');
      _showSnackBar('❌ Failed to capture image', Colors.red);
    }
  }

  Future<void> _processAllImages() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProcessingDialog(),
    );

    Map<String, File> imageMap = {
      'center': capturedImages[PhotoStep.center]!,
      'left': capturedImages[PhotoStep.left]!,
      'right': capturedImages[PhotoStep.right]!,
    };

    try {
      List<AnalysisResult> results = await DetectionService.analyzeMultipleImages(
        imageMap,
            (progress) => print(progress),
      );

      Navigator.of(context).pop();

      if (results.isNotEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ResultsScreen(
              analysisResults: results,
              camera: widget.camera,
            ),
          ),
        );
      } else {
        _showSnackBar('❌ Analysis failed. Please try again.', Colors.red);
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showSnackBar('❌ Error: $e', Colors.red);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_getStepTitle()),
        backgroundColor: Colors.black87,
        actions: [
          // ✅ Gallery button
          IconButton(
            icon: Icon(Icons.photo_library, color: Colors.white),
            onPressed: _pickImageFromGallery,
            tooltip: 'Pick from Gallery',
          ),
          IconButton(
            icon: Icon(
              isFlipping ? Icons.hourglass_empty : Icons.flip_camera_ios,
              color: Colors.white,
            ),
            onPressed: isFlipping ? null : _flipCamera,
            tooltip: 'Flip Camera',
          ),
          SizedBox(width: 8),
          if (isServerWaking)
            Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            )
          else if (isServerReady)
            Padding(
              padding: EdgeInsets.all(16),
              child: Icon(Icons.check_circle, color: Colors.green),
            )
          else
            Padding(
              padding: EdgeInsets.all(16),
              child: Icon(Icons.warning, color: Colors.orange),
            ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                _buildProgressBar(),
                _buildInstructionCard(),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(_controller),

                      Center(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final screenWidth = MediaQuery.of(context).size.width;
                            final squareSize = screenWidth * 0.8;

                            return Container(
                              width: squareSize,
                              height: squareSize,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  CustomPaint(
                                    size: Size(squareSize, squareSize),
                                    painter: SquareOverlayPainter(),
                                  ),
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Padding(
                                      padding: EdgeInsets.only(bottom: 12),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '1:1 Crop Area',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _currentCamera.lensDirection == CameraLensDirection.front
                                    ? Icons.camera_front
                                    : Icons.camera_rear,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                _currentCamera.lensDirection == CameraLensDirection.front
                                    ? 'Front'
                                    : 'Back',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildCaptureControls(),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildProgressDot(PhotoStep.center),
          Container(width: 40, height: 2, color: Colors.white38),
          _buildProgressDot(PhotoStep.left),
          Container(width: 40, height: 2, color: Colors.white38),
          _buildProgressDot(PhotoStep.right),
        ],
      ),
    );
  }

  Widget _buildProgressDot(PhotoStep step) {
    bool isCompleted = capturedImages[step] != null;
    bool isActive = currentStep == step;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted ? Colors.green : isActive ? Colors.blue : Colors.white24,
      ),
      child: Center(
        child: isCompleted
            ? Icon(Icons.check, color: Colors.white, size: 18)
            : Text(
          ['C', 'L', 'R'][step.index],
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            currentStep == PhotoStep.center
                ? Icons.face
                : currentStep == PhotoStep.left
                ? Icons.arrow_back
                : Icons.arrow_forward,
            color: Colors.white,
            size: 32,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              _getStepInstruction(),
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ UPDATED: Added gallery button option
  Widget _buildCaptureControls() {
    return Container(
      height: 120,
      color: Colors.black87,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Back button or Gallery button
          if (currentStep != PhotoStep.center)
            IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white, size: 32),
              onPressed: _previousStep,
            )
          else
            IconButton(
              icon: Icon(Icons.photo, color: Colors.white70, size: 28),
              onPressed: _pickImageFromGallery,
              tooltip: 'Pick from Gallery',
            ),

          // Capture button
          FloatingActionButton(
            backgroundColor: Colors.white,
            onPressed: _captureAndProcess,
            child: Icon(Icons.camera_alt, color: Colors.black, size: 32),
          ),

          // Refresh or placeholder
          if (capturedImages[currentStep] != null)
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white, size: 32),
              onPressed: () {
                setState(() {
                  capturedImages[currentStep] = null;
                });
              },
            )
          else
            SizedBox(width: 48),
        ],
      ),
    );
  }
}

class SquareOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cornerLength = 50.0;

    canvas.drawLine(Offset(0, 0), Offset(cornerLength, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(0, cornerLength), paint);

    canvas.drawLine(Offset(size.width - cornerLength, 0), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), paint);

    canvas.drawLine(Offset(0, size.height - cornerLength), Offset(0, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), paint);

    canvas.drawLine(Offset(size.width - cornerLength, size.height), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height - cornerLength), Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ProcessingDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Analyzing your skin with AI...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'This may take 10-30 seconds',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
