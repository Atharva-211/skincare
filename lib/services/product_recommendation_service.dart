// lib/services/product_recommendation_service.dart
import '../models/scan_history.dart';
import '../models/product.dart';
import 'product_service.dart';

class ProductRecommendationService {
  // Product name mappings based on acne level
  static Map<String, List<String>> _getProductQueries(String acneLevel) {
    switch (acneLevel) {
      case 'high':
        return {
          'Facewash': [
            'CeraVe Acne Foaming Cream Cleanser',
            'Neutrogena Rapid Clear Stubborn Acne Cleanser',
            'The Derma Co Salicylic Acid Face Wash',
          ],
          'Serum': [
            'The Ordinary Niacinamide 10% Zinc 1%',
            'Minimalist Niacinamide Face Serum',
            'Paula\'s Choice BHA Liquid Exfoliant',
          ],
          'Moisturiser': [
            'Cetaphil PRO Oil Control Moisturizer',
            'Neutrogena Oil-Free Moisture',
          ],
          'Sunscreen': [
            'La Roche-Posay Anthelios Oil Control',
            'Neutrogena Ultra Sheer Dry-Touch Sunscreen',
          ],
        };
      case 'medium':
        return {
          'Facewash': [
            'Cetaphil Gentle Foaming Cleanser',
            'Plum Green Tea Face Wash',
          ],
          'Serum': [
            'Minimalist Alpha Arbutin Serum',
            'The Ordinary AHA BHA Peeling Solution',
          ],
          'Moisturiser': [
            'CeraVe Moisturizing Lotion',
            'Minimalist Sepicalm Oat Moisturizer',
          ],
          'Sunscreen': [
            'Minimalist SPF 50 Sunscreen',
            'Neutrogena Hydro Boost Water Gel',
          ],
        };
      case 'low':
      default:
        return {
          'Facewash': [
            'CeraVe Hydrating Cleanser',
            'Simple Refreshing Facial Wash',
          ],
          'Serum': [
            'The Ordinary Hyaluronic Acid 2% B5',
            'Minimalist Vitamin C Face Serum',
          ],
          'Moisturiser': [
            'CeraVe Daily Moisturizing Lotion',
            'Neutrogena Hydro Boost Gel-Cream',
          ],
          'Sunscreen': [
            'Cetaphil Daily Facial Moisturizer SPF 50',
            'Neutrogena Beach Defense SPF 50',
          ],
        };
    }
  }

  static String getAcneLevel(ScanHistory? latestScan) {
    if (latestScan == null) return 'low';

    if (latestScan.totalHigh > latestScan.totalMedium &&
        latestScan.totalHigh > latestScan.totalLow) {
      return 'high';
    } else if (latestScan.totalMedium >= latestScan.totalLow) {
      return 'medium';
    } else {
      return 'low';
    }
  }

  static Future<Map<String, List<Product>>> getRecommendations(String acneLevel) async {
    final queries = _getProductQueries(acneLevel);
    Map<String, List<Product>> recommendations = {};

    for (var category in queries.entries) {
      List<Product> categoryProducts = [];

      for (var productName in category.value) {
        try {
          final products = await ProductService.searchProducts(productName);
          if (products.isNotEmpty) {
            categoryProducts.addAll(products.take(2)); // Take 2 products per query
          }
        } catch (e) {
          print('Error fetching $productName: $e');
        }
      }

      if (categoryProducts.isNotEmpty) {
        recommendations[category.key] = categoryProducts;
      }
    }

    return recommendations;
  }

  static List<String> getAvoidIngredients(String acneLevel) {
    switch (acneLevel) {
      case 'high':
        return [
          'Heavy oils (coconut, palm)',
          'Comedogenic ingredients',
          'Alcohol-based products',
          'Fragrance',
          'Harsh physical exfoliants'
        ];
      case 'medium':
        return [
          'Heavy moisturizers',
          'Silicones',
          'Mineral oil',
          'Strong fragrances'
        ];
      case 'low':
      default:
        return [
          'Over-exfoliation',
          'Strong acids',
          'Heavy fragrances'
        ];
    }
  }
}
