// lib/models/product_recommendation.dart
class ProductRecommendation {
  final String category;
  final String name;
  final String? brand;
  final List<String> keyIngredients;
  final String? description;

  ProductRecommendation({
    required this.category,
    required this.name,
    this.brand,
    required this.keyIngredients,
    this.description,
  });
}

class AcneLevel {
  static const String high = 'high';
  static const String medium = 'medium';
  static const String low = 'low';
}
