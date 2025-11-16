// lib/widgets/detection_overlay.dart
import 'dart:io';

import 'package:flutter/material.dart';
import '../models/detection_result.dart';

class DetectionOverlay extends StatelessWidget {
  final String imagePath;
  final List<Detection> detections;

  const DetectionOverlay({
    Key? key,
    required this.imagePath,
    required this.detections,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.file(File(imagePath)),
        CustomPaint(
          painter: DetectionPainter(detections),
          child: Container(),
        ),
      ],
    );
  }
}

class DetectionPainter extends CustomPainter {
  final List<Detection> detections;

  DetectionPainter(this.detections);

  @override
  void paint(Canvas canvas, Size size) {
    for (var detection in detections) {
      // Draw bounding box
      final paint = Paint()
        ..color = detection.severityColor.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      final rect = detection.bbox.toRect();
      canvas.drawRect(rect, paint);

      // Draw filled background for label
      final labelBgPaint = Paint()
        ..color = detection.severityColor
        ..style = PaintingStyle.fill;

      final labelRect = Rect.fromLTWH(
        rect.left,
        rect.top - 20,
        120,
        20,
      );
      canvas.drawRect(labelRect, labelBgPaint);

      // Draw label text
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${detection.className} ${(detection.confidence * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(rect.left + 4, rect.top - 18));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
