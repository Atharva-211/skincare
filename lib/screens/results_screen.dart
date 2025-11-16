// lib/screens/results_screen.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import '../models/detection_result.dart';
import '../models/analysis_result.dart';
import '../models/product.dart';
import '../config/api_config.dart';
import '../services/product_service.dart';
import '../widgets/product_card.dart';
import 'dashboard_screen.dart';

class ResultsScreen extends StatefulWidget {
  final List<AnalysisResult> analysisResults;
  final CameraDescription camera;

  const ResultsScreen({
    Key? key,
    required this.analysisResults,
    required this.camera,
  }) : super(key: key);

  @override
  _ResultsScreenState createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  int currentImageIndex = 0;
  List<List<Product>> recommendedProducts = [];
  bool isLoadingProducts = false;

  @override
  void initState() {
    super.initState();
    _loadRecommendedProducts();
  }

  Future<void> _loadRecommendedProducts() async {
    setState(() {
      isLoadingProducts = true;
    });

    try {
      final products = await ProductService.getRecommendedProducts();
      setState(() {
        recommendedProducts = products;
        isLoadingProducts = false;
      });
    } catch (e) {
      print('Error loading products: $e');
      setState(() {
        isLoadingProducts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentResult = widget.analysisResults[currentImageIndex];
    bool hasDetections = currentResult.detectionResult.count > 0;

    return Scaffold(
      backgroundColor: Color(0xFFD9FBFF),
      appBar: AppBar(
        title: Text('Analysis Results'),
        backgroundColor: Color(0xFFBDF4EA),
        actions: [
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => DashboardScreen(
                    camera: widget.camera,
                    analysisResults: widget.analysisResults,
                  ),
                ),
                    (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSelector(),
            _buildDetectionOverlay(currentResult),
            if (hasDetections)
              _buildDetectionStats(currentResult)
            else
              _buildNoAcneMessage(),
            _buildProductRecommendations(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSelector() {
    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20),
        itemCount: widget.analysisResults.length,
        itemBuilder: (context, index) {
          bool isSelected = index == currentImageIndex;
          return GestureDetector(
            onTap: () {
              setState(() {
                currentImageIndex = index;
              });
            },
            child: Container(
              width: 60,
              margin: EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey,
                  width: isSelected ? 3 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(widget.analysisResults[index].imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetectionOverlay(AnalysisResult result) {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: DetectionImageWidget(
          imagePath: result.imagePath,
          detections: result.detectionResult.detections,
        ),
      ),
    );
  }

  Widget _buildNoAcneMessage() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 48),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No Acne Detected!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Your skin looks healthy. Keep up the good work!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionStats(AnalysisResult result) {
    Map<String, int> severityCounts = result.severityCounts;

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFBDF4EA),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detection Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSeverityChip('High', severityCounts['high'] ?? 0, Colors.red),
              _buildSeverityChip('Medium', severityCounts['medium'] ?? 0, Colors.orange),
              _buildSeverityChip('Low', severityCounts['low'] ?? 0, Colors.yellow),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Total detections: ${result.detectionResult.count}',
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityChip(String label, int count, Color color) {
    return Chip(
      label: Text('$label: $count'),
      backgroundColor: color.withOpacity(0.3),
      avatar: CircleAvatar(
        backgroundColor: color,
        radius: 8,
      ),
    );
  }

  Widget _buildProductRecommendations() {
    if (isLoadingProducts) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (recommendedProducts.isEmpty) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Recommended Products',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        ...recommendedProducts.asMap().entries.map((entry) {
          int categoryIndex = entry.key;
          List<Product> products = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  ApiConfig.productList[categoryIndex],
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(
                height: 320,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: products.length > 5 ? 5 : products.length,
                  separatorBuilder: (_, __) => SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return ProductCard(product: products[index]);
                  },
                ),
              ),
              SizedBox(height: 16),
            ],
          );
        }).toList(),
      ],
    );
  }
}

// ✅ FIXED: Detection Image Widget with Proper Aspect Ratio Handling
class DetectionImageWidget extends StatefulWidget {
  final String imagePath;
  final List<Detection> detections;

  const DetectionImageWidget({
    Key? key,
    required this.imagePath,
    required this.detections,
  }) : super(key: key);

  @override
  _DetectionImageWidgetState createState() => _DetectionImageWidgetState();
}

class _DetectionImageWidgetState extends State<DetectionImageWidget> {
  ui.Image? _image;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(DetectionImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final file = File(widget.imagePath);
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();

      print('\n🖼️ === IMAGE LOADED ===');
      print('Image dimensions: ${frame.image.width}x${frame.image.height}');
      print('Detections count: ${widget.detections.length}');

      if (widget.detections.isNotEmpty) {
        print('\n📦 Sample detection bbox:');
        final firstDetection = widget.detections.first;
        print('  x1: ${firstDetection.bbox.x1}');
        print('  y1: ${firstDetection.bbox.y1}');
        print('  x2: ${firstDetection.bbox.x2}');
        print('  y2: ${firstDetection.bbox.y2}');
        print('  Width: ${firstDetection.bbox.x2 - firstDetection.bbox.x1}');
        print('  Height: ${firstDetection.bbox.y2 - firstDetection.bbox.y1}');
      }

      setState(() {
        _image = frame.image;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading image: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 400,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_image == null) {
      return Container(
        height: 400,
        child: Center(
          child: Text('Failed to load image', style: TextStyle(color: Colors.red)),
        ),
      );
    }

    // Use the actual image aspect ratio
    final imageAspect = _image!.width / _image!.height;

    return AspectRatio(
      aspectRatio: imageAspect,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(widget.imagePath),
            fit: BoxFit.contain,
          ),
          CustomPaint(
            painter: DetectionPainter(
              detections: widget.detections,
              imageWidth: _image!.width.toDouble(),
              imageHeight: _image!.height.toDouble(),
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ FINAL FIX: Detection Painter with Correct Coordinate Mapping
class DetectionPainter extends CustomPainter {
  final List<Detection> detections;
  final double imageWidth;
  final double imageHeight;

  DetectionPainter({
    required this.detections,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    print('\n🎨 === PAINTING DETECTIONS ===');
    print('Canvas size: ${size.width.toStringAsFixed(1)} x ${size.height.toStringAsFixed(1)}');
    print('Original image: ${imageWidth.toStringAsFixed(0)} x ${imageHeight.toStringAsFixed(0)}');

    if (detections.isEmpty) {
      print('⚠️ No detections to paint');
      return;
    }

    // Calculate scale factors from original image to display canvas
    final scaleX = size.width / imageWidth;
    final scaleY = size.height / imageHeight;

    print('Scale factors: X=${scaleX.toStringAsFixed(4)}, Y=${scaleY.toStringAsFixed(4)}');
    print('Drawing ${detections.length} detections...\n');

    for (int i = 0; i < detections.length; i++) {
      final detection = detections[i];

      // Backend coordinates are in original image space
      final originalRect = Rect.fromLTRB(
        detection.bbox.x1,
        detection.bbox.y1,
        detection.bbox.x2,
        detection.bbox.y2,
      );

      // Scale to canvas space
      final canvasRect = Rect.fromLTRB(
        originalRect.left * scaleX,
        originalRect.top * scaleY,
        originalRect.right * scaleX,
        originalRect.bottom * scaleY,
      );

      if (i < 3) {  // Print first 3 for debugging
        print('Detection ${i + 1}: ${detection.className} ${detection.confidencePercent}');
        print('  Original: (${originalRect.left.toStringAsFixed(0)}, ${originalRect.top.toStringAsFixed(0)}) → (${originalRect.right.toStringAsFixed(0)}, ${originalRect.bottom.toStringAsFixed(0)})');
        print('  Canvas: (${canvasRect.left.toStringAsFixed(1)}, ${canvasRect.top.toStringAsFixed(1)}) → (${canvasRect.right.toStringAsFixed(1)}, ${canvasRect.bottom.toStringAsFixed(1)})');
      }

      // Draw bounding box
      final boxPaint = Paint()
        ..color = detection.severityColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      canvas.drawRect(canvasRect, boxPaint);

      // Draw semi-transparent fill
      final fillPaint = Paint()
        ..color = detection.severityColor.withOpacity(0.12)
        ..style = PaintingStyle.fill;

      canvas.drawRect(canvasRect, fillPaint);

      // Draw label
      _drawLabel(canvas, canvasRect, detection);
    }

    print('\n✅ Painted ${detections.length} boxes');
  }

  void _drawLabel(Canvas canvas, Rect rect, Detection detection) {
    final labelText = '${detection.className.toUpperCase()} ${detection.confidencePercent}';

    final textPainter = TextPainter(
      text: TextSpan(
        text: labelText,
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    final labelWidth = textPainter.width + 8;
    final labelHeight = 20.0;

    // Position label above box (or below if near top)
    final labelTop = rect.top > labelHeight + 5
        ? rect.top - labelHeight - 2
        : rect.bottom + 2;

    // Draw label background
    final labelBgPaint = Paint()
      ..color = detection.severityColor
      ..style = PaintingStyle.fill;

    final labelRect = Rect.fromLTWH(rect.left, labelTop, labelWidth, labelHeight);
    canvas.drawRect(labelRect, labelBgPaint);

    // Draw text
    textPainter.paint(canvas, Offset(rect.left + 4, labelTop + 3));
  }

  @override
  bool shouldRepaint(covariant DetectionPainter oldDelegate) {
    return oldDelegate.detections != detections ||
        oldDelegate.imageWidth != imageWidth ||
        oldDelegate.imageHeight != imageHeight;
  }
}
