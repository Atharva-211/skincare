// lib/screens/home/main_navigation.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

// ✅ REMOVED: import '../camera_screen.dart' hide CameraScreen;  ← DELETE THIS LINE
import 'home_screen.dart';
import '../camera/camera_screen.dart';
import 'recommendations_screen.dart';

class MainNavigation extends StatefulWidget {
  final CameraDescription camera;

  const MainNavigation({Key? key, required this.camera}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<RecommendationsScreenState> _recommendationsKey = GlobalKey<RecommendationsScreenState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(key: _homeKey),
          CameraScreen(camera: widget.camera),
          RecommendationsScreen(key: _recommendationsKey),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);

            if (index == 0) {
              _homeKey.currentState?.loadData();
            } else if (index == 2) {
              _recommendationsKey.currentState?.loadRecommendations();
            }
          },
          backgroundColor: Color(0xFFBDF4EA),
          selectedItemColor: Colors.black87,
          unselectedItemColor: Colors.black45,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt),
              label: 'Scan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.recommend),
              label: 'Products',
            ),
          ],
        ),
      ),
    );
  }
}
