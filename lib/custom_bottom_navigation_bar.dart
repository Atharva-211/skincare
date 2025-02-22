// custom_bottom_navigation_bar.dart
import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final VoidCallback onCameraPressed;

  const CustomBottomNavigationBar({
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onCameraPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: EdgeInsets.fromLTRB(20, 0, 20, 20), // Adjusted margin
      decoration: BoxDecoration(
        color: Colors.grey[850], // Matches the container color from skin care page
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Changed to spaceEvenly
            children: [
              Expanded(child: _buildNavItem(0, Icons.home, 'Home')),
              Expanded(child: _buildNavItem(1, Icons.chat_bubble_outline, 'Chat')),
              // Empty space for center button
              const Expanded(child: SizedBox(width: 60)),
              Expanded(child: _buildNavItem(3, Icons.settings, 'Settings')),
              Expanded(child: _buildNavItem(4, Icons.favorite_border, 'Favorites')),
            ],
          ),
          Positioned(
            top: -20,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: onCameraPressed,
              child: Center(
                child: Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[850], // Matches nav bar color
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey[800]!, // Subtle border
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.face,
                    size: 30,
                    color: Colors.white, // Changed to white to match theme
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: isSelected ? Colors.black45 : Colors.transparent,
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.grey[400],
          size: 24,
        ),
      ),
    );
  }
}