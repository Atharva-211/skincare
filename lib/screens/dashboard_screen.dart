// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:camera/camera.dart';
import '../models/analysis_result.dart';  // ADD THIS
import 'camera_screen.dart';

class DashboardScreen extends StatelessWidget {
  final CameraDescription camera;
  final List<AnalysisResult>? analysisResults;

  const DashboardScreen({
    Key? key,
    required this.camera,
    this.analysisResults,
  }) : super(key: key);

  List<RadarEntry> _computeRadarData() {
    if (analysisResults == null || analysisResults!.isEmpty) {
      return List.generate(10, (_) => RadarEntry(value: 0));
    }

    Map<String, int> totalDetections = {'high': 0, 'medium': 0, 'low': 0};

    for (var result in analysisResults!) {
      for (var detection in result.detectionResult.detections) {
        totalDetections[detection.className.toLowerCase()] =
            (totalDetections[detection.className.toLowerCase()] ?? 0) + 1;
      }
    }

    // FIX: Cast to double explicitly
    double highScore = 100.0 - (totalDetections['high']! * 5).clamp(0, 100).toDouble();
    double mediumScore = 100.0 - (totalDetections['medium']! * 3).clamp(0, 100).toDouble();
    double lowScore = 100.0 - (totalDetections['low']! * 1).clamp(0, 100).toDouble();

    return [
      RadarEntry(value: highScore),
      RadarEntry(value: mediumScore),
      RadarEntry(value: lowScore),
      RadarEntry(value: (highScore + mediumScore) / 2),
      RadarEntry(value: (mediumScore + lowScore) / 2),
      RadarEntry(value: highScore),
      RadarEntry(value: mediumScore),
      RadarEntry(value: lowScore),
      RadarEntry(value: (highScore + lowScore) / 2),
      RadarEntry(value: (highScore + mediumScore + lowScore) / 3),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD9FBFF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              SizedBox(height: 30),
              Text(
                'Hello!',
                style: GoogleFonts.italiana(fontSize: 32, color: Colors.black),
              ),
              SizedBox(height: 5),
              Text(
                "Let's Take care of your skin!",
                style: GoogleFonts.itim(fontSize: 16, color: Colors.black),
              ),
              SizedBox(height: 30),
              _buildRadarChart(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: Color(0xFFBDF4EA),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        Text(
          '6969 points',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        CircleAvatar(
          radius: 16,
          backgroundColor: Color(0xFF4E4E5A),
        ),
      ],
    );
  }

  Widget _buildRadarChart() {
    return Container(
      width: double.infinity,
      height: 380,
      decoration: BoxDecoration(
        color: Color(0xFFBDF4EA),
        borderRadius: BorderRadius.circular(43),
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(40),
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.polygon,
          dataSets: [
            RadarDataSet(
              fillColor: Colors.blue.withOpacity(0.1),
              borderColor: Colors.blue,
              entryRadius: 3,
              dataEntries: _computeRadarData(),
            ),
          ],
          radarBackgroundColor: Colors.transparent,
          tickCount: 5,
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 25, vertical: 9),
      decoration: BoxDecoration(
        color: Color(0xFFBDF4EA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, -5),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Icon(Icons.home, size: 30),
          Icon(Icons.notifications_none, size: 30),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CameraScreen(camera: camera),
                ),
              );
            },
            child: CircleAvatar(
              radius: 38,
              backgroundColor: Color(0xFFFEEED9),
              child: Icon(Icons.camera_alt, size: 32),
            ),
          ),
          Icon(Icons.settings, size: 30),
          Icon(Icons.favorite_border, size: 30),
        ],
      ),
    );
  }
}
