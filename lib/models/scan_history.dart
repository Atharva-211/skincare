// lib/models/scan_history.dart
class ScanHistory {
  final String id;
  final String userId;
  final DateTime scanDate;
  final int totalHigh;
  final int totalMedium;
  final int totalLow;
  final int totalDetections;
  final String? notes;

  ScanHistory({
    required this.id,
    required this.userId,
    required this.scanDate,
    required this.totalHigh,
    required this.totalMedium,
    required this.totalLow,
    required this.totalDetections,
    this.notes,
  });

  factory ScanHistory.fromJson(Map<String, dynamic> json) {
    return ScanHistory(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      scanDate: DateTime.parse(json['scan_date'] as String),
      totalHigh: json['total_high'] as int,
      totalMedium: json['total_medium'] as int,
      totalLow: json['total_low'] as int,
      totalDetections: json['total_detections'] as int,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'total_high': totalHigh,
      'total_medium': totalMedium,
      'total_low': totalLow,
      'total_detections': totalDetections,
      'notes': notes,
    };
  }

  // Helper to get severity level
  String get severityLevel {
    if (totalHigh > totalMedium && totalHigh > totalLow) return 'High';
    if (totalMedium > totalLow) return 'Medium';
    return 'Low';
  }
}
