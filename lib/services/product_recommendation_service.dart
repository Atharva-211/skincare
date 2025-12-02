// lib/services/product_recommendation_service.dart
import '../config/supabase_config.dart';
import '../models/scan_history.dart';
import '../data/product_recommendations_data.dart';

class ProductRecommendationService {
  // Get acne level based on scan history
  static String getAcneLevel(ScanHistory? scan) {
    if (scan == null) return 'low';

    int totalHigh = scan.totalHigh;
    int totalMedium = scan.totalMedium;

    if (totalHigh >= 10) return 'high';
    if (totalHigh >= 5 || totalMedium >= 15) return 'medium';
    return 'low';
  }

  // Get product recommendations based on user profile
  static Future<Map<String, List<String>>> getRecommendations() async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) {
        // Return default recommendations for Normal skin
        return ProductRecommendationsData.getRecommendations('Normal', []);
      }

      // Get user profile
      final profileData = await SupabaseConfig.client
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profileData == null) {
        // Return default recommendations for Normal skin
        return ProductRecommendationsData.getRecommendations('Normal', []);
      }

      // Extract skin type (default to 'Normal' if not provided)
      String skinType = profileData['skin_type'] ?? 'Normal';

      // Extract sensitivities from known_allergies
      List<String> sensitivities = [];
      if (profileData['known_allergies'] != null) {
        List<dynamic> allergies = profileData['known_allergies'];
        sensitivities = allergies.cast<String>();
      }

      // Get recommendations
      return ProductRecommendationsData.getRecommendations(skinType, sensitivities);
    } catch (e) {
      print('Error getting recommendations: $e');
      // Return default recommendations for Normal skin on error
      return ProductRecommendationsData.getRecommendations('Normal', []);
    }
  }

  // Get ingredients to avoid based on user sensitivities
  static Future<List<String>> getAvoidIngredients() async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return [];

      // Get user profile
      final profileData = await SupabaseConfig.client
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profileData == null) return [];

      // Extract sensitivities
      List<String> sensitivities = [];
      if (profileData['known_allergies'] != null) {
        List<dynamic> allergies = profileData['known_allergies'];
        sensitivities = allergies.cast<String>();
      }

      return ProductRecommendationsData.getAvoidIngredients(sensitivities);
    } catch (e) {
      print('Error getting avoid ingredients: $e');
      return [];
    }
  }
}
