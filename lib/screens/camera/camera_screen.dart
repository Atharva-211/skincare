// lib/screens/camera/camera_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../services/detection_service.dart';
import '../../models/analysis_result.dart';
import '../../models/photo_step.dart';
import '../../verify_image.dart';
import '../../config/supabase_config.dart';
import '../results/results_screen.dart';

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
  final ImagePicker _picker = ImagePicker();

  PhotoStep currentStep = PhotoStep.center;
  bool isServerWaking = false;
  bool isServerReady = false;
  bool isFlipping = false;

  Map<PhotoStep, File?> capturedImages = {
    PhotoStep.center: null,
    PhotoStep.left: null,
    PhotoStep.right: null,
  };

  Map<PhotoStep, AnalysisResult?> apiResults = {
    PhotoStep.center: null,
    PhotoStep.left: null,
    PhotoStep.right: null,
  };

  Map<PhotoStep, bool> isProcessing = {
    PhotoStep.center: false,
    PhotoStep.left: false,
    PhotoStep.right: false,
  };

  static const int TARGET_SIZE = 1024;

  @override
  void initState() {
    super.initState();
    _loadAvailableCameras();
    _wakeUpServer();
  }

  // ✅ Load cameras and default to FRONT camera
  Future<void> _loadAvailableCameras() async {
    try {
      _availableCameras = await availableCameras();

      // ✅ Default to FRONT camera
      _currentCamera = _availableCameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => widget.camera,
      );

      _initializeCamera();
    } catch (e) {
      print('Error loading cameras: $e');
      _currentCamera = widget.camera;
      _initializeCamera();
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

  // ✅ Just pop, don't navigate to MainNavigation
  void _closeCamera() {
    Navigator.of(context).pop();
  }

  Future<void> _flipCamera() async {
    if (isFlipping || _availableCameras.isEmpty) return;

    setState(() => isFlipping = true);

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

      setState(() => isFlipping = false);

      _showSnackBar(
        _currentCamera.lensDirection == CameraLensDirection.front
            ? '📸 Switched to Front Camera'
            : '📸 Switched to Back Camera',
        Colors.blue,
      );
    } catch (e) {
      print('Error flipping camera: $e');
      setState(() => isFlipping = false);
      _showSnackBar('❌ Failed to switch camera', Colors.red);
    }
  }

  // ✅ Fixed: Don't mirror gallery images
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);

        // ✅ Don't mirror gallery images - they're already correct

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DisplayPictureScreen(
              imagePath: imageFile.path,
              photoStep: currentStep,
            ),
          ),
        );

        if (result != null && result['isValid'] == true) {
          imageFile = await _processImageToTargetSize(imageFile);
          setState(() {
            capturedImages[currentStep] = imageFile;
          });
          _showSnackBar('📸 Photo validated!', Colors.green);

          _processImageInBackground(currentStep, imageFile);

          if (capturedImages.values.every((img) => img != null)) {
            _waitAndNavigateToResults();
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
    setState(() => isServerWaking = true);
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

  // ✅ Only mirror when taking photos with FRONT camera (not gallery)
  Future<File> _mirrorImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) return imageFile;

      final flippedImage = img.flipHorizontal(originalImage);
      final flippedPath = imageFile.path.replaceAll('.jpg', '_flipped.jpg');
      final flippedFile = File(flippedPath);

      await flippedFile.writeAsBytes(img.encodeJpg(flippedImage, quality: 95));

      return flippedFile;
    } catch (e) {
      print('Error mirroring image: $e');
      return imageFile;
    }
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

      print('Original size: ${originalImage.width}x${originalImage.height}');

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

      img.Image resizedImage = img.copyResize(
        croppedImage,
        width: TARGET_SIZE,
        height: TARGET_SIZE,
      );

      print('✅ Final size: ${resizedImage.width}x${resizedImage.height}');

      final processedPath = originalFile.path
          .replaceAll('.jpg', '_1024.jpg')
          .replaceAll('.png', '_1024.jpg');
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

      // ✅ Only mirror camera captures from FRONT camera
      if (_currentCamera.lensDirection == CameraLensDirection.front) {
        imageFile = await _mirrorImage(imageFile);
      }

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DisplayPictureScreen(
            imagePath: imageFile.path,
            photoStep: currentStep,
          ),
        ),
      );

      if (result != null && result['isValid'] == true) {
        imageFile = await _processImageToTargetSize(imageFile);
        setState(() {
          capturedImages[currentStep] = imageFile;
        });
        _showSnackBar('📸 Photo validated!', Colors.green);

        _processImageInBackground(currentStep, imageFile);

        if (capturedImages.values.every((img) => img != null)) {
          _waitAndNavigateToResults();
        } else {
          _nextStep();
        }
      }
    } catch (e) {
      print('Error capturing image: $e');
      _showSnackBar('❌ Failed to capture image', Colors.red);
    }
  }

  Future<void> _processImageInBackground(PhotoStep step, File imageFile) async {
    setState(() {
      isProcessing[step] = true;
    });

    try {
      print('🔄 Processing ${step.toString()} in background...');

      Map<String, File> singleImageMap = {
        step.toString().split('.').last: imageFile,
      };

      final results = await DetectionService.analyzeMultipleImages(
        singleImageMap,
            (progress) => print(progress),
      );

      if (results.isNotEmpty) {
        setState(() {
          apiResults[step] = results.first;
          isProcessing[step] = false;
        });
        print('✅ ${step.toString()} processed successfully');
      } else {
        throw Exception('No results returned');
      }
    } catch (e) {
      print('❌ Error processing ${step.toString()}: $e');
      setState(() {
        isProcessing[step] = false;
      });
      _handleApiFailure();
    }
  }

  void _handleApiFailure() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Analysis Failed'),
        content: Text('Image analysis failed. Please start again from the beginning.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetCapture();
            },
            child: Text('Start Over'),
          ),
        ],
      ),
    );
  }

  void _resetCapture() {
    setState(() {
      capturedImages = {
        PhotoStep.center: null,
        PhotoStep.left: null,
        PhotoStep.right: null,
      };
      apiResults = {
        PhotoStep.center: null,
        PhotoStep.left: null,
        PhotoStep.right: null,
      };
      isProcessing = {
        PhotoStep.center: false,
        PhotoStep.left: false,
        PhotoStep.right: false,
      };
      currentStep = PhotoStep.center;
    });
  }

  Future<void> _waitAndNavigateToResults() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
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
                  'Please wait for all images to process',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    while (apiResults.values.any((result) => result == null) ||
        isProcessing.values.any((processing) => processing == true)) {
      await Future.delayed(Duration(milliseconds: 500));
    }

    if (apiResults.values.every((result) => result != null)) {
      final results = [
        apiResults[PhotoStep.center]!,
        apiResults[PhotoStep.left]!,
        apiResults[PhotoStep.right]!,
      ];

      await _saveScanToDatabase(results);
      Navigator.of(context).pop(); // Close loading dialog

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ResultsScreen(
            analysisResults: results,
            camera: widget.camera,
          ),
        ),
      );
    } else {
      Navigator.of(context).pop();
      _handleApiFailure();
    }
  }

  Future<void> _saveScanToDatabase(List<AnalysisResult> results) async {
    try {
      print('💾 Saving scan to database...');

      int totalHigh = 0;
      int totalMedium = 0;
      int totalLow = 0;

      for (var result in results) {
        totalHigh += result.severityCounts['high'] ?? 0;
        totalMedium += result.severityCounts['medium'] ?? 0;
        totalLow += result.severityCounts['low'] ?? 0;
      }

      final totalDetections = totalHigh + totalMedium + totalLow;
      final user = SupabaseConfig.client.auth.currentUser;

      if (user == null) {
        print('❌ No user logged in');
        return;
      }

      final scanData = {
        'user_id': user.id,
        'total_high': totalHigh,
        'total_medium': totalMedium,
        'total_low': totalLow,
        'total_detections': totalDetections,
      };

      await SupabaseConfig.client.from('scan_history').insert(scanData);

      print('✅ Scan saved successfully!');
      print('   High: $totalHigh, Medium: $totalMedium, Low: $totalLow');
    } catch (e) {
      print('❌ Error saving scan: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _closeCamera(); // ✅ Just pop instead of navigate
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: CameraPreview(_controller),
                  ),

                  // Progress Bar
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Container(
                        color: Colors.black.withOpacity(0.7),
                        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildProgressDot(PhotoStep.center),
                            Container(width: 50, height: 3, color: Colors.white38),
                            _buildProgressDot(PhotoStep.left),
                            Container(width: 50, height: 3, color: Colors.white38),
                            _buildProgressDot(PhotoStep.right),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Top Bar
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.photo_library, color: Colors.white, size: 24),
                              ),
                              onPressed: _pickImageFromGallery,
                              tooltip: 'Pick from Gallery',
                            ),
                            IconButton(
                              icon: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.close, color: Colors.white, size: 24),
                              ),
                              onPressed: _closeCamera, // ✅ Just close
                              tooltip: 'Cancel',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Instruction Card
                  Positioned(
                    top: 120,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getStepTitle(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  _getStepInstruction(),
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Crop Box Overlay
                  Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final screenWidth = MediaQuery.of(context).size.width;
                        final squareSize = screenWidth * 0.75;

                        return Container(
                          width: squareSize,
                          height: squareSize,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(12),
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

                  // Camera Type Indicator
                  Positioned(
                    bottom: 180,
                    right: 16,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          SizedBox(width: 6),
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

                  // ✅ Bottom Controls - Show flip button on ALL pages
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.9),
                              Colors.black.withOpacity(0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // ✅ Left - Always show flip OR back button
                            currentStep != PhotoStep.center
                                ? _buildControlButton(
                              icon: Icons.arrow_back,
                              onTap: _previousStep,
                              tooltip: 'Previous',
                            )
                                : _buildControlButton(
                              icon: isFlipping ? Icons.hourglass_empty : Icons.flip_camera_ios,
                              onTap: isFlipping ? null : _flipCamera,
                              tooltip: 'Flip Camera',
                            ),

                            // Center - Capture Button
                            GestureDetector(
                              onTap: _captureAndProcess,
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.5),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.black, width: 3),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // ✅ Right - Retake OR Flip Camera
                            capturedImages[currentStep] != null
                                ? _buildControlButton(
                              icon: Icons.refresh,
                              onTap: () {
                                setState(() {
                                  capturedImages[currentStep] = null;
                                  apiResults[currentStep] = null;
                                  isProcessing[currentStep] = false;
                                });
                              },
                              tooltip: 'Retake',
                            )
                                : _buildControlButton(
                              icon: isFlipping ? Icons.hourglass_empty : Icons.flip_camera_ios,
                              onTap: isFlipping ? null : _flipCamera,
                              tooltip: 'Flip Camera',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            } else {
              return Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onTap,
    required String tooltip,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildProgressDot(PhotoStep step) {
    bool isCompleted = capturedImages[step] != null;
    bool isActive = currentStep == step;
    bool isApiProcessing = isProcessing[step] ?? false;
    bool apiSuccess = apiResults[step] != null;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: apiSuccess
            ? Colors.green
            : isCompleted
            ? Colors.blue
            : isActive
            ? Colors.white
            : Colors.white24,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: isApiProcessing
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        )
            : apiSuccess
            ? Icon(Icons.check, color: Colors.white, size: 20)
            : isCompleted
            ? Icon(Icons.check, color: Colors.white, size: 20)
            : Text(
          ['C', 'L', 'R'][step.index],
          style: TextStyle(
            color: isActive ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
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
