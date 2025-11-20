// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../config/supabase_config.dart';
import '../services/detection_service.dart';
import 'auth/login_screen.dart';
import 'home/main_navigation.dart';

class SplashScreen extends StatefulWidget {
  final CameraDescription camera;

  const SplashScreen({Key? key, required this.camera}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Setup fade-in animation
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();
    _initialize();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    // Check API health
    print('🔍 Checking API health...');
    final isHealthy = await DetectionService.waitForServerWakeup(maxRetries: 3);

    if (!isHealthy) {
      print('⚠️ API not responding, but continuing...');
    }

    // Minimum splash screen display time
    await Future.delayed(Duration(seconds: 2));

    // Check if user is logged in
    final session = SupabaseConfig.client.auth.currentSession;

    if (mounted) {
      if (session != null) {
        // User is logged in
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MainNavigation(camera: widget.camera),
          ),
        );
      } else {
        // User not logged in
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => LoginScreen(camera: widget.camera),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD9FBFF),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Your custom logo
              Container(
                padding: EdgeInsets.all(20),
                child: Image.asset(
                  'assets/images/splash.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: 32),

              // App name (optional - remove if logo has text)
              Text(
                'Sundara',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),

              // Loading indicator
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFF6FDFFF)),
              ),
              SizedBox(height: 16),

              Text(
                'Initializing...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
