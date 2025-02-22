// main.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'camera_screen.dart';
import 'skin_care_analysis_page.dart';
import 'custom_bottom_navigation_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final frontCamera = cameras.firstWhere(
    (camera) => camera.lensDirection == CameraLensDirection.front,
    orElse: () => cameras.first,
  );

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: MainScreen(camera: frontCamera),
    ),
  );
}

class MainScreen extends StatefulWidget {
  final CameraDescription camera;

  MainScreen({required this.camera});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SkinCareAnalysisPage(camera: widget.camera),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        onCameraPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TakePictureScreen(camera: widget.camera),
            ),
          );
        },
      ),
    );
  }
}