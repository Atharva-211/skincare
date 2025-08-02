// frontend/pages/mainDashboard.dart

// ignore_for_file: use_super_parameters, prefer_const_constructors_in_immutables

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:camera/camera.dart';
import '../../camera_screen.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../widgets/product_card.dart';

class SkinCareApp extends StatelessWidget {
  final CameraDescription camera;
  final List radarData;
  final bool showRecommendations;

  const SkinCareApp({
    Key? key,
    required this.camera,
    required this.radarData,
    this.showRecommendations = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SkinCareHomePage(
        camera: camera,
        radarData: radarData,
        showRecommendations: showRecommendations,
      ),
    );
  }
}

class SkinCareHomePage extends StatefulWidget {
  final Color backgroundColor = Color(0xFFD9FBFF);
  final Color boxColor = Color(0xFFBDF4EA);
  final CameraDescription camera;
  final List radarData;
  final bool showRecommendations;

  SkinCareHomePage({
    Key? key,
    required this.camera,
    required this.radarData,
    this.showRecommendations = false,
  }) : super(key: key);

  @override
  _SkinCareHomePageState createState() => _SkinCareHomePageState();
}

class _SkinCareHomePageState extends State<SkinCareHomePage> {
  List<List<Product>> recommendedProducts = [];
  bool isLoadingProducts = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.showRecommendations) {
      _loadRecommendedProducts();
    }
  }

  Future<void> _loadRecommendedProducts() async {
    setState(() {
      isLoadingProducts = true;
      errorMessage = null;
    });

    try {
      print('Loading recommended products...');
      final products = await ProductService.getRecommendedProducts();
      setState(() {
        recommendedProducts = products;
        isLoadingProducts = false;
      });
      print('Products loaded successfully: ${products.length} categories');
    } catch (e) {
      print('Error loading products: $e');
      setState(() {
        isLoadingProducts = false;
        errorMessage = 'Failed to load products. Please check your internet connection.';
      });
    }
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top content with 20px padding all around
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildTopBar(widget.boxColor),
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
                  _buildDailyRoutineCard(widget.boxColor),
                  SizedBox(height: 30),
                  RadarChartWidget(data: widget.radarData),
                  SizedBox(height: 20),
                ]),
              ),
            ),

            // Product Recommendations Section
            if (widget.showRecommendations) ...[
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

              // Loading, Error, or Products Display
              if (isLoadingProducts)
                SliverToBoxAdapter(
                  child: Container(
                    height: 265,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading products...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (errorMessage != null)
                SliverToBoxAdapter(
                  child: Container(
                    height: 265,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 60,
                            color: Colors.red[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            errorMessage!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _loadRecommendedProducts,
                            child: Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (recommendedProducts.isNotEmpty) ...[
                // Display each product category
                  for (int categoryIndex = 0; categoryIndex < recommendedProducts.length; categoryIndex++) ...[
                    // Add spacing *only* before the second section
                    if (categoryIndex > 0)
                      SliverToBoxAdapter(child: SizedBox(height: 30)),

                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Always show section title
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                            child: Text(
                              categoryIndex == 0 ? 'Dove Products' : 'Cetaphil Products',
                              style: GoogleFonts.itim(fontSize: 16, color: Colors.black),
                            ),
                          ),
                          SizedBox(
                            height: 320,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              itemCount: recommendedProducts[categoryIndex].length > 5
                                  ? 5
                                  : recommendedProducts[categoryIndex].length,
                              separatorBuilder: (_, __) => SizedBox(width: 16),
                              itemBuilder: (context, index) {
                                return ProductCard(
                                  product: recommendedProducts[categoryIndex][index],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
              ]
              else
                SliverToBoxAdapter(
                  child: Container(
                    height: 265,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No products found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _loadRecommendedProducts,
                            child: Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],

            // Bottom spacing
            SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: 25, vertical: 9),
        decoration: BoxDecoration(
          color: widget.boxColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, -5),
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
                    builder: (context) => TakePictureScreen(camera: widget.camera),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(0, 4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 38,
                  backgroundColor: Color(0xFFFEEED9),
                  backgroundImage: AssetImage('Assets/face.png'),
                ),
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
  final List data;

  RadarChartWidget({Key? key, required this.data}) : super(key: key);

  static const List categories = [
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
              dataEntries: data.cast<RadarEntry>(),
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