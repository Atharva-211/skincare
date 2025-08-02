// services/product_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ProductService {
  static const String _serpApiKey = '25792c6200f22174c1c3d705fd70a3bd59e89dcad439b1c1b00d2e377ccf4b6f';
  static const String _baseUrl = 'https://serpapi.com/search';

  // Predefined product list
  static const List<String> _productList = [
    'Dove',
    'Cetaphil',
  ];

  // Fetch products using SerpAPI
  static Future<List<Product>> searchProducts(String query) async {
    try {
      print('Searching for: $query');
      final response = await http.get(
        Uri.parse(_baseUrl).replace(queryParameters: {
          'engine': 'google_shopping',
          'q': '$query skincare',
          'api_key': _serpApiKey,
          'gl': 'in', // India
          'hl': 'en', // English
          'num': '10', // Get more results to filter
        }),
      );

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> shoppingResults = data['shopping_results'] ?? [];

        print('Found ${shoppingResults.length} results');

        List<Product> products = [];

        for (int i = 0; i < shoppingResults.length && products.length < 5; i++) {
          final item = shoppingResults[i];

          // Extract product information
          final product = Product(
            id: (item['position'] ?? i).toString(),
            name: item['title'] ?? 'Unknown Product',
            brand: _extractBrand(item['title'] ?? '', query),
            imageUrl: item['thumbnail'] ?? '',
            price: _parsePrice(item['extracted_price']),
            seller: item['source'] ?? 'Unknown Seller',
            rating: (item['rating'] ?? 0).toDouble(),
            reviews: item['reviews'] ?? 0,
            productUrl: item['link'] ?? '',
            isAvailable: true,
          );

          products.add(product);
        }

        print('Returning ${products.length} products');
        return products;
      } else {
        print('SerpAPI request failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  // Get all recommended products
  static Future<List<List<Product>>> getRecommendedProducts() async {
    List<List<Product>> allProducts = [];

    for (String productName in _productList) {
      print('Fetching products for: $productName');
      final products = await searchProducts(productName);
      if (products.isNotEmpty) {
        allProducts.add(products);
      }
    }

    print('Total product categories found: ${allProducts.length}');
    return allProducts;
  }

  static String _extractBrand(String title, String searchQuery) {
    final lowerTitle = title.toLowerCase();
    final lowerQuery = searchQuery.toLowerCase();

    if (lowerTitle.contains('dove') || lowerQuery.contains('dove')) return 'Dove';
    if (lowerTitle.contains('cetaphil') || lowerQuery.contains('cetaphil')) return 'Cetaphil';

    // Try to extract brand from title
    final words = title.split(' ');
    if (words.isNotEmpty) {
      return words.first;
    }

    return searchQuery; // Use search query as fallback
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
}
