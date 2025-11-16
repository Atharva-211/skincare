// lib/models/analysis_result.dart
import 'detection_result.dart';

class AnalysisResult {
  final String imagePath;
  final String imageType; // 'center', 'left', 'right'
  final DetectionResult detectionResult;

  AnalysisResult({
    required this.imagePath,
    required this.imageType,
    required this.detectionResult,
  });

  // Get severity counts from detection result
  Map<String, int> get severityCounts => detectionResult.severityCounts;

  // Get total count
  int get totalDetections => detectionResult.count;
}
