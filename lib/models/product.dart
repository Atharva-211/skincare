// lib/models/product.dart

class Product {
  final String id;
  final String name;
  final String brand;
  final String category; // ✅ Added category field
  final String imageUrl;
  final double price;
  final String seller;
  final double rating;
  final int reviews;
  final String productUrl;
  final bool isAvailable;
  final double? originalPrice;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category, // ✅ Added to constructor
    this.imageUrl = '', // ✅ Made optional with default
    this.price = 0.0, // ✅ Made optional with default
    this.seller = '', // ✅ Made optional with default
    this.rating = 0.0,
    this.reviews = 0,
    this.productUrl = '', // ✅ Made optional with default
    this.isAvailable = true,
    this.originalPrice,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      brand: json['brand'] ?? '',
      category: json['category'] ?? '', // ✅ Added category
      imageUrl: json['imageUrl'] ?? '',
      price: _parsePrice(json['price']),
      seller: json['seller'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      reviews: json['reviews'] ?? 0,
      productUrl: json['productUrl'] ?? '',
      isAvailable: json['isAvailable'] ?? true,
      originalPrice: json['originalPrice'] != null
          ? _parsePrice(json['originalPrice'])
          : null,
    );
  }

  static double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) {
      final numStr = price.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(numStr) ?? 0.0;
    }
    return 0.0;
  }

  double get discountPercentage {
    if (originalPrice != null && originalPrice! > price) {
      return ((originalPrice! - price) / originalPrice!) * 100;
    }
    return 0.0;
  }

  String get formattedPrice {
    return '₹${price.toStringAsFixed(0)}';
  }

  String get formattedOriginalPrice {
    if (originalPrice != null) {
      return '₹${originalPrice!.toStringAsFixed(0)}';
    }
    return '';
  }
}
