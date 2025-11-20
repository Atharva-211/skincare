// lib/main.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'config/supabase_config.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseConfig.initialize();

  // Get available cameras
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  const MyApp({Key? key, required this.camera}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Acne Detection App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFFBDF4EA),
        scaffoldBackgroundColor: Color(0xFFD9FBFF),
        colorScheme: ColorScheme.light(
          primary: Color(0xFFBDF4EA),
          secondary: Color(0xFF6FDFFF),
        ),
        useMaterial3: true,
      ),
      home: SplashScreen(camera: camera),
    );
  }
}
