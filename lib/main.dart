import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:fl_chart/fl_chart.dart'; // Import for RadarEntry
import 'frontend/pages/mainDashboard.dart';
import 'camera_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cameras = await availableCameras();
  final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
    orElse: () => cameras.first,
  );

  // Dummy radar data for testing
  final radarData = <RadarEntry>[
    RadarEntry(value: 0),
    RadarEntry(value: 0),
    RadarEntry(value: 0),
    RadarEntry(value: 0),
    RadarEntry(value: 0),
    RadarEntry(value: 0),
    RadarEntry(value: 0),
    RadarEntry(value: 0),
    RadarEntry(value: 0),
    RadarEntry(value: 0),
  ];

  runApp(MyApp(camera: frontCamera, radarData: radarData));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;
  final List<RadarEntry> radarData;

  const MyApp({super.key, required this.camera, required this.radarData});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skin Care App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: SkinCareApp(camera: camera, radarData: radarData),
    );
  }
}
