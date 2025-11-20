// lib/screens/results/results_screen.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../models/detection_result.dart';
import '../../models/analysis_result.dart';
import '../home/main_navigation.dart';

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

  @override
  Widget build(BuildContext context) {
    final currentResult = widget.analysisResults[currentImageIndex];
    bool hasDetections = currentResult.detectionResult.count > 0;

    return Scaffold(
      backgroundColor: Color(0xFFD9FBFF),
      appBar: AppBar(
        title: Text(
          'Analysis Results',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFFBDF4EA),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.home, color: Colors.black87),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => MainNavigation(camera: widget.camera),
                ),
                    (route) => false,
              );
            },
            tooltip: 'View Dashboard',
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
            SizedBox(height: 80), // Space for bottom button
          ],
        ),
      ),
      floatingActionButton: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => MainNavigation(camera: widget.camera),
              ),
                  (route) => false,
            );
          },
          icon: Icon(Icons.dashboard),
          label: Text('View Dashboard'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFBDF4EA),
            foregroundColor: Colors.black87,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildImageSelector() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFBDF4EA),
            Color(0xFF6FDFFF).withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.photo_library, color: Colors.black87, size: 18),
              ),
              SizedBox(width: 10),
              Text(
                'Select View',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              widget.analysisResults.length,
                  (index) {
                bool isSelected = index == currentImageIndex;
                final labels = ['Center', 'Left', 'Right'];
                final icons = [Icons.face, Icons.arrow_back, Icons.arrow_forward];

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        currentImageIndex = index;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ✅ Image without icon overlay
                          Container(
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.3),
                                width: isSelected ? 3 : 2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.5),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ]
                                  : [],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                File(widget.analysisResults[index].imagePath),
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          // Label
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isSelected
                                  ? [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  icons[index],
                                  size: 12,
                                  color: isSelected ? Color(0xFF6FDFFF) : Colors.black54,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  labels[index],
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? Color(0xFF6FDFFF) : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
        color: Colors.green.shade50,
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
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle, color: Colors.white, size: 36),
          ),
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
                    color: Colors.green.shade800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Your skin looks healthy. Keep up the good work!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Fixed Detection Stats - No overflow
  Widget _buildDetectionStats(AnalysisResult result) {
    Map<String, int> severityCounts = result.severityCounts;
    int totalHigh = severityCounts['high'] ?? 0;
    int totalMedium = severityCounts['medium'] ?? 0;
    int totalLow = severityCounts['low'] ?? 0;

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFFBDF4EA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.analytics, color: Colors.black87, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Detection Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          // ✅ Fixed Row - Using Expanded to prevent overflow
          Row(
            children: [
              Expanded(child: _buildSeverityCard('High', totalHigh, Colors.red)),
              SizedBox(width: 12),
              Expanded(child: _buildSeverityCard('Medium', totalMedium, Colors.orange)),
              SizedBox(width: 12),
              Expanded(child: _buildSeverityCard('Low', totalLow, Colors.yellow.shade700)),
            ],
          ),

          SizedBox(height: 20),
          Divider(),
          SizedBox(height: 12),

          // Total Count
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.circle, color: Color(0xFF6FDFFF), size: 12),
              SizedBox(width: 8),
              Text(
                'Total Detections: ',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                '${result.detectionResult.count}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6FDFFF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ New card-style severity display - No overflow possible
  Widget _buildSeverityCard(String label, int count, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Detection Image Widget and Painter remain the same...
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

  Future<void> _loadImage() async {
    setState(() => _isLoading = true);
    try {
      final file = File(widget.imagePath);
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      setState(() {
        _image = frame.image;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading image: $e');
      setState(() => _isLoading = false);
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
        child: Center(child: Text('Failed to load image')),
      );
    }

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

// Detection Painter remains the same
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
    final scaleX = size.width / imageWidth;
    final scaleY = size.height / imageHeight;

    for (final detection in detections) {
      final originalRect = Rect.fromLTRB(
        detection.bbox.x1,
        detection.bbox.y1,
        detection.bbox.x2,
        detection.bbox.y2,
      );

      final canvasRect = Rect.fromLTRB(
        originalRect.left * scaleX,
        originalRect.top * scaleY,
        originalRect.right * scaleX,
        originalRect.bottom * scaleY,
      );

      // Draw box
      final boxPaint = Paint()
        ..color = detection.severityColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawRect(canvasRect, boxPaint);

      // Draw fill
      final fillPaint = Paint()
        ..color = detection.severityColor.withOpacity(0.12)
        ..style = PaintingStyle.fill;
      canvas.drawRect(canvasRect, fillPaint);

      // Draw label
      _drawLabel(canvas, canvasRect, detection);
    }
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
    final labelTop = rect.top > labelHeight + 5 ? rect.top - labelHeight - 2 : rect.bottom + 2;

    final labelBgPaint = Paint()
      ..color = detection.severityColor
      ..style = PaintingStyle.fill;

    final labelRect = Rect.fromLTWH(rect.left, labelTop, labelWidth, labelHeight);
    canvas.drawRect(labelRect, labelBgPaint);
    textPainter.paint(canvas, Offset(rect.left + 4, labelTop + 3));
  }

  @override
  bool shouldRepaint(covariant DetectionPainter oldDelegate) {
    return oldDelegate.detections != detections ||
        oldDelegate.imageWidth != imageWidth ||
        oldDelegate.imageHeight != imageHeight;
  }
}
