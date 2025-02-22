// skin_care_analysis_page.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'camera_screen.dart';

class SkinCareAnalysisPage extends StatelessWidget {
  final CameraDescription camera;

  const SkinCareAnalysisPage({Key? key, required this.camera}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 24),
            _buildScoresContainer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          Text(
            '6969 points',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Hello XYZ',
            style: TextStyle(fontSize: 20),
          ),
          Text(
            'Let\'s Take care of your skin!',
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildScoresContainer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildScore('Wrinkles Score', 100),
          _buildScore('Uniformness Score', 80),
          _buildScore('Pores Score', 60),
          _buildScore('Acne Score', 40),
          _buildScore('Pigmentation Score', 20),
          _buildScore('Sagging Score', 50),
          _buildScore('Redness Score', 70),
          _buildScore('Eye Area Condition', 90),
        ],
      ),
    );
  }

  Widget _buildScore(String label, int score) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16),
          ),
          Row(
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getScoreColor(score),
                ),
              ),
              SizedBox(width: 8),
              _buildScoreBar(score),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBar(int score) {
    return Container(
      width: 60,
      height: 6,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: _getScoreColor(score).withOpacity(0.3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: score / 100,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: _getScoreColor(score),
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.yellow;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }
}