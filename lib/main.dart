// lib/main.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'screens/dashboard_screen.dart';  // Correct path

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cameras = await availableCameras();
  final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
    orElse: () => cameras.first,
  );

  runApp(MyApp(camera: frontCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  const MyApp({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skin Care App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFFBDF4EA)),
        useMaterial3: true,
      ),
      home: DashboardScreen(camera: camera),
    );
  }
}
