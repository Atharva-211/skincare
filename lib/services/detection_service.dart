// lib/services/detection_service.dart
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/detection_result.dart';
import '../models/analysis_result.dart';

class DetectionService {
  // ✅ Your actual API URL
  static const String baseUrl = 'https://model-detection-api.onrender.com';
  static const String detectEndpoint = '/detect_raw';  // Note: underscore, not hyphen

  // Check if server is awake
  static Future<bool> waitForServerWakeup({int maxRetries = 5}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        print('🔄 Attempt ${i + 1}/$maxRetries: Checking server health...');
        final response = await http.get(
          Uri.parse('$baseUrl/health'),
        ).timeout(Duration(seconds: 10));

        if (response.statusCode == 200) {
          print('✅ Server is healthy!');
          print('Response: ${response.body}');
          return true;
        }
      } catch (e) {
        print('⚠️ Attempt ${i + 1} failed: $e');
        if (i < maxRetries - 1) {
          await Future.delayed(Duration(seconds: 3));
        }
      }
    }
    print('❌ Server health check failed after $maxRetries attempts');
    return false;
  }

  // Analyze single image
  static Future<DetectionResult?> analyzeSingleImage(
      File imageFile,
      void Function(String) onProgress,
      ) async {
    try {
      print('\n🚀 === ANALYZING SINGLE IMAGE ===');
      print('Image path: ${imageFile.path}');

      final fileSize = await imageFile.length();
      print('Image size: ${(fileSize / 1024).toStringAsFixed(2)} KB');

      onProgress('Uploading image...');

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$detectEndpoint'),
      );

      // Add the image file with field name 'image'
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',  // ✅ This matches backend's expected field name
          imageFile.path,
          filename: 'upload.jpg',
        ),
      );

      print('📤 Sending request to: $baseUrl$detectEndpoint');
      print('📤 Field name: image');

      onProgress('Processing with AI...');

      // Send request
      final streamedResponse = await request.send().timeout(
        Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException('Request timed out after 60 seconds');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response headers: ${response.headers}');
      print('📥 Response body (first 500 chars): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('✅ Successfully decoded JSON response');
        print('Raw JSON structure: ${jsonResponse.keys}');

        final detectionResult = DetectionResult.fromJson(jsonResponse);

        print('✅ Detection completed!');
        print('   Total detections: ${detectionResult.count}');
        print('   Severity breakdown:');
        detectionResult.severityCounts.forEach((key, value) {
          print('     - $key: $value');
        });

        // Print first 3 detections for debugging
        if (detectionResult.detections.isNotEmpty) {
          print('   Sample detections:');
          for (int i = 0; i < (detectionResult.detections.length > 3 ? 3 : detectionResult.detections.length); i++) {
            final d = detectionResult.detections[i];
            print('     ${i + 1}. ${d.className} - ${d.confidencePercent} at (${d.bbox.x1}, ${d.bbox.y1})');
          }
        }

        return detectionResult;
      } else {
        print('❌ API Error: ${response.statusCode}');
        print('❌ Error body: ${response.body}');
        throw Exception('API returned status ${response.statusCode}: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('❌ Error analyzing image: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Analyze multiple images
  static Future<List<AnalysisResult>> analyzeMultipleImages(
      Map<String, File> images,
      void Function(String) onProgress,
      ) async {
    List<AnalysisResult> results = [];

    print('\n🎯 === ANALYZING MULTIPLE IMAGES ===');
    print('Total images to analyze: ${images.length}');
    print('Image types: ${images.keys.join(", ")}');

    int successCount = 0;
    int failCount = 0;

    for (var entry in images.entries) {
      try {
        print('\n📸 Processing ${entry.key} image...');
        onProgress('Analyzing ${entry.key} image...');

        final detectionResult = await analyzeSingleImage(
          entry.value,
          onProgress,
        );

        if (detectionResult != null) {
          results.add(AnalysisResult(
            imagePath: entry.value.path,
            imageType: entry.key,
            detectionResult: detectionResult,
          ));
          successCount++;
          print('✅ ${entry.key} image analyzed successfully - ${detectionResult.count} detections found');
        }
      } catch (e) {
        failCount++;
        print('❌ Failed to analyze ${entry.key} image: $e');
      }
    }

    print('\n🎉 === ANALYSIS COMPLETE ===');
    print('Successfully analyzed: $successCount/${images.length} images');
    print('Failed: $failCount/${images.length} images');

    if (results.isNotEmpty) {
      int totalDetections = results.fold(0, (sum, r) => sum + r.totalDetections);
      print('Total detections across all images: $totalDetections');
    }

    return results;
  }
}
