// lib/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'https://model-detection-api.onrender.com';
  static const String detectEndpoint = '/detect_raw';
  static const String healthEndpoint = '/health';

  // Product categories for recommendations
  static const List<String> productList = [
    'Cleansers',
    'Moisturizers',
    'Treatments',
    'Sunscreens',
  ];
}
