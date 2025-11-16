// lib/models/detection_result.dart
import 'package:flutter/material.dart';

class BoundingBox {
  final double x1;
  final double y1;
  final double x2;
  final double y2;

  BoundingBox({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    return BoundingBox(
      x1: (json['x1'] as num).toDouble(),
      y1: (json['y1'] as num).toDouble(),
      x2: (json['x2'] as num).toDouble(),
      y2: (json['y2'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x1': x1,
      'y1': y1,
      'x2': x2,
      'y2': y2,
    };
  }

  // ✅ Add this method
  Rect toRect() {
    return Rect.fromLTRB(x1, y1, x2, y2);
  }

  // Helper to get width and height
  double get width => x2 - x1;
  double get height => y2 - y1;
}

class Detection {
  final BoundingBox bbox;
  final int classId;
  final String className;
  final double confidence;

  Detection({
    required this.bbox,
    required this.classId,
    required this.className,
    required this.confidence,
  });

  factory Detection.fromJson(Map<String, dynamic> json) {
    return Detection(
      bbox: BoundingBox.fromJson(json['bbox']),
      classId: json['class_id'] as int,
      className: json['class_name'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bbox': bbox.toJson(),
      'class_id': classId,
      'class_name': className,
      'confidence': confidence,
    };
  }

  // Get severity color based on class name
  Color get severityColor {
    switch (className.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  // Get confidence as percentage string
  String get confidencePercent {
    return '${(confidence * 100).toStringAsFixed(1)}%';
  }
}

class DetectionResult {
  final int count;
  final List<Detection> detections;

  DetectionResult({
    required this.count,
    required this.detections,
  });

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    print('📦 Parsing DetectionResult from JSON...');
    print('Raw JSON: $json');

    final detectionsJson = json['detections'] as List<dynamic>;
    final detections = detectionsJson
        .map((d) => Detection.fromJson(d as Map<String, dynamic>))
        .toList();

    print('✅ Parsed ${detections.length} detections');

    return DetectionResult(
      count: json['count'] as int,
      detections: detections,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'detections': detections.map((d) => d.toJson()).toList(),
    };
  }

  // Get severity counts
  Map<String, int> get severityCounts {
    final counts = {'high': 0, 'medium': 0, 'low': 0};
    for (var detection in detections) {
      final severity = detection.className.toLowerCase();
      if (counts.containsKey(severity)) {
        counts[severity] = counts[severity]! + 1;
      }
    }
    return counts;
  }
}
