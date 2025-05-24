// frontend/pages/mainDashboard.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:camera/camera.dart';
import '../../camera_screen.dart';

class SkinCareApp extends StatelessWidget {
  final CameraDescription camera;
  final List<RadarEntry> radarData;
  final bool showRecommendations; // <-- NEW



  const SkinCareApp({
    Key? key,
    required this.camera,
    required this.radarData,
    this.showRecommendations = false, // <-- Default false
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SkinCareHomePage(
        camera: camera,
        radarData: radarData,
        showRecommendations: showRecommendations, // <-- Pass to home
      ),
    );
  }
}

class SkinCareHomePage extends StatelessWidget {
  final Color backgroundColor = Color(0xFFD9FBFF);
  final Color boxColor = Color(0xFFBDF4EA);
  final CameraDescription camera;
  final List<RadarEntry> radarData;
  final bool showRecommendations;


  SkinCareHomePage({
    Key? key,
    required this.camera,
    required this.radarData,
    this.showRecommendations = false, // <-- Default
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top content with 20px padding all around
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildTopBar(boxColor),
                  SizedBox(height: 30),
                  Text(
                    'Hello XYZ,',
                    style: GoogleFonts.italiana(fontSize: 32, color: Colors.black),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Let's Take care of your skin!",
                    style: GoogleFonts.itim(fontSize: 16, color: Colors.black),
                  ),
                  SizedBox(height: 20),
                  _buildDailyRoutineCard(boxColor),
                  SizedBox(height: 30),
                  RadarChartWidget(data: radarData),
                  SizedBox(height: 20),
                ]),
              ),
            ),

            if (showRecommendations) ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'For you',
                    style: GoogleFonts.itim(fontSize: 16, color: Colors.black),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 10)),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 265,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.zero,
                    itemCount: 5,
                    separatorBuilder: (_, __) => SizedBox(width: 16),
                    itemBuilder: (context, index) => Container(
                      width: 247,
                      decoration: BoxDecoration(
                        color: boxColor,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            offset: Offset(2, 4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Image.asset(
                          'Assets/product.png',
                          fit: BoxFit.contain,
                          height: 200,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],


            // bottom spacing
            SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: 25, vertical: 12),
        decoration: BoxDecoration(
          color: boxColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, -5),   // lift the shadow upward
              blurRadius: 6,
              spreadRadius: 1,
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
                    builder: (context) => TakePictureScreen(camera: camera),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 28,
                backgroundColor: Color(0xFFFEEED9),
                backgroundImage: AssetImage('Assets/face.png'),
              ),
            ),
            Icon(Icons.settings, size: 30),
            Icon(Icons.favorite_border, size: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(Color boxColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: boxColor,
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

  Widget _buildDailyRoutineCard(Color boxColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(2, 4),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.black),
              SizedBox(width: 10),
              Text(
                'Daily Routine',
                style: GoogleFonts.itim(fontSize: 18, color: Colors.black),
              ),
            ],
          ),
          Switch(value: false, onChanged: (_) {}),
        ],
      ),
    );
  }
}

class RadarChartWidget extends StatelessWidget {
  final List<RadarEntry> data;
  RadarChartWidget({Key? key, required this.data}) : super(key: key);

  static const List<String> categories = [
    "Transparency",
    "Pores",
    "Acne",
    "Sagging",
    "Redness",
    "Eye Area Condition",
    "Pigmentation",
    "Hydration",
    "Wrinkles",
    "Uniformness",
  ];

  @override
  Widget build(BuildContext context) {
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
              dataEntries: data,
            ),
          ],
          radarBackgroundColor: Colors.transparent,
          tickCount: 5,
          ticksTextStyle: TextStyle(color: Colors.black38, fontSize: 10),
          tickBorderData: BorderSide(color: Colors.black26),
          gridBorderData: BorderSide(color: Colors.black26),
          getTitle: (index, angle) => RadarChartTitle(
            text: categories[index % categories.length],
          ),
        ),
      ),
    );
  }
}

