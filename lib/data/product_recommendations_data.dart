// lib/data/product_recommendations_data.dart

class ProductRecommendationsData {
  // Hardcoded product data based on questionnaire

  static Map<String, Map<String, List<String>>> skinTypeProducts = {
    'Oily': {
      'Facewash': [
        'Dewdrop Anti-Acne Face Wash',
        'CeraVe Foaming Facial Cleanser',
        'Neutrogena Oil-Free Acne Wash',
        'The Body Shop Tea Tree Skin Clearing Facial Wash',
        'La Roche-Posay Effaclar Purifying Gel',
        'Biotique Bio Neem Purifying Face Wash',
      ],
      'Moisturizer': [
        'Beauty of Joseon Red Bean Water Gel',
        'Clinique Moisture Surge 100H Hydrator',
        'Kiehl\'s Ultra Facial Oil-Free Gel Cream',
        'Dior Hydra Life Fresh Sorbet Crème',
        '82°E Ashwagandha Bounce Moisturiser',
        'Clarins Hydra-Essentiel Light Cream',
      ],
      'Serum': [
        'Primally Pure Clarifying Serum',
        'Mario Badescu Anti-Acne Serum',
        'Paula\'s Choice Defense Antioxidant Pore Purifier',
        'Cocokind Vitamin C Serum (Sea Grape Caviar)',
        'Be The Skin Botanical Pore Serum',
        'Juice Beauty Blemish Clearing Serum',
      ],
      'Sunscreen': [
        'Clinikally SunProtect Sunscreen SPF 50/PA+++',
        'IPCA Acne-UV Gel Sunscreen SPF 50+',
        'Dermatica Ray Protect SPF 50',
        'UV Doux D-Tan Aqua SPF 50 Gel Lotion',
        'Yuderma Eclipse Solaire Active SPF 50',
        'Photoage Hydra Ultralight Invisible Gel SPF 50+',
      ],
    },
    'Dry': {
      'Facewash': [
        'CeraVe Hydrating Facial Cleanser',
        'Cetaphil Gentle Skin Cleanser',
        'Neutrogena Hydro Boost Cleanser',
        'Sebamed Clear Face Cleansing Foam',
        'Himalaya Gentle Foaming Face Wash',
        'Forest Essentials Delicate Facial Cleanser',
      ],
      'Moisturizer': [
        'CeraVe Moisturizing Cream',
        'Kiehl\'s Ultra Facial Cream (Squalane)',
        'Cetaphil Moisturizing Cream',
        'Vanicream Moisturizing Cream',
        'Laneige Water Bank Hydro Cream',
        'Avène Skin Recovery Cream',
      ],
      'Serum': [
        'Splash Hydrating Face Serum',
        'The Ordinary Hyaluronic Acid 2% + B5',
        'L\'Oréal Revitalift 1.5% Hyaluronic Serum',
        'Minimalist 2% HA + PGA Serum',
        'Plum 2% HA Serum (Bulgarian Rose)',
        'Mamaearth Skin Plump HA+Rosehip Serum',
      ],
      'Sunscreen': [
        'Neutrogena Hydro Boost Water Gel Lotion SPF 50',
        'Bioderma Photoderm MAX Aquafluide SPF 50+',
        'Cetaphil Sheer Mineral Sunscreen SPF 50+',
        'EltaMD UV Replenish SPF 44 (Tinted)',
        'Klairs Soft Airy UV Essence SPF 50+',
        'Minimalist Brightening SPF 65 Lotion',
      ],
    },
    'Combination': {
      'Facewash': [
        'Kama Ayurveda Argan & Moringa Face Wash',
        'The Derma Co. Niacinamide Face Wash',
        'Biotique Cucumber Pore Tightening Face Wash',
        'Innisfree Jeju Volcanic Pore Cleansing Foam',
        'Simple Kind to Skin Refreshing Facial Wash',
        'Dot & Key Ceramide Face Wash',
      ],
      'Moisturizer': [
        'Neutrogena Hydro Boost Gel-Cream',
        'Paula\'s Choice Omega+ Complex Moisturizer',
        'Simple Hydrating Light Moisturizer',
        'The Derma Co. Hydrating Gel Cream',
        'COSRX Snail 92 All-In-One Cream',
        'Klairs Supple Preparation Unscented Cream',
      ],
      'Serum': [
        'The Ordinary Niacinamide 10% + Zinc 1% Serum',
        'Paula\'s Choice Niacinamide 10% Serum',
        'Minimalist 10% Niacinamide Face Serum',
        'St. Botanica Niacinamide Serum',
        'Mamaearth Niacinamide Brightening Serum',
        'Garnier Vitamin C 10% Serum',
      ],
      'Sunscreen': [
        'Biore UV Aqua Rich Watery Essence SPF 50+',
        'Lotus Herbals Safe Sun UV Screen SPF 50 (Gel)',
        'Lakme Sun Expert SPF 50 PA+++',
        'Mamaearth Mineral Brightening Sunscreen SPF 50',
        'Sirona Sunscreen Face Gel SPF 50 PA+++',
        'Neutrogena Ultra Sheer Dry-Touch SPF 50+',
      ],
    },
    'Normal': {
      'Facewash': [
        'Sebamed Liquid Face & Body Wash',
        'Pond\'s White Beauty Gentle Facial Foam',
        'Forest Essentials Delicate Facial Cleanser',
        'Biotique Bio Papaya Revitalizing Face Wash',
        'Garnier Vitamin C Face Wash',
        'Lotus Herbals Lavendar Face Wash',
      ],
      'Moisturizer': [
        'Cetaphil Daily Hydrating Lotion',
        'Vichy Mineral 89 Serum-Cream',
        'Clinique Dramatically Different Hydrating Jelly',
        'Bioderma Atoderm Cream',
        'POND\'s Super Light Gel SPF 15',
        'Simple Kind to Skin Replenishing Rich Cream',
      ],
      'Serum': [
        'The Body Shop Vitamin C Serum',
        'Plum Vitamin C & Superoxide Dismutase Serum',
        'L\'Oréal Revitalift 10% Vitamin C Serum',
        'Vichy LiftActiv Vitamin C Serum',
        'Dot & Key Vitamin C Serum',
        'O3+ Radiance Brightening Serum',
      ],
      'Sunscreen': [
        'Biore UV Aqua Rich Watery Sunscreen SPF 50+/PA+++',
        'Lotus Herbals Safe Sun 3-in-1 Matte SPF 50',
        'Mamaearth Aloe Vera Sunscreen Gel SPF 50',
        'VLCC Matte Look Sunscreen Gel SPF 45',
      ],
    },
    'Sensitive': {
      'Facewash': [
        'Cetaphil Gentle Skin Cleanser',
        'La Roche-Posay Toleriane Hydrating Gentle Cleanser',
        'Vanicream Gentle Facial Cleanser',
        'Avene Extremely Gentle Cleanser Lotion',
        'Clinique Liquid Facial Soap',
        'Cetaphil Daily Facial Cleanser',
      ],
      'Moisturizer': [
        'Vanicream Moisturizing Cream',
        'Cetaphil Rich Hydrating Night Cream with HA',
        'Dr Jart+ Cicapair Tiger Grass Cream',
        'Avene Skin Recovery Cream',
        'La Roche-Posay Cicaplast Baume B5',
        'La Roche-Posay Toleriane Double Repair Cream',
      ],
      'Serum': [
        'La Roche-Posay Hyalu B5 Hyaluronic Acid Serum',
        'Cerave Skin Renewing Vitamin C Serum',
        'Dr. Sheth\'s Vitamin C + Niacinamide Serum',
        'Klairs Midnight Blue Calming Serum',
        'Minimalist 10% Niacinamide + Zinc',
      ],
      'Sunscreen': [
        'Clinikally SunProtect Sunscreen SPF 50/PA+++',
        'Suncros Aqua Lotion SPF 50',
        'Avene Mineral SPF 50+ Cream',
        'La Roche-Posay Anthelios SPF 50',
        'Cetaphil Sheer Mineral Sunscreen SPF 50+',
        'EltaMD UV Physical SPF 41 (Tinted)',
      ],
    },
  };

  // Ingredients to avoid based on sensitivities
  static Map<String, List<String>> sensitivityAvoidIngredients = {
    'Fragrance': [
      'Parfum',
      'Fragrance',
      'Essential Oils',
      'Linalool',
      'Limonene',
      'Citronellol',
    ],
    'Alcohol': [
      'Alcohol Denat',
      'SD Alcohol',
      'Isopropyl Alcohol',
      'Ethanol',
    ],
    'Benzoyl Peroxide': [
      'Benzoyl Peroxide',
      'BPO',
    ],
    'Salicylic Acid': [
      'Salicylic Acid',
      'BHA',
      'Beta Hydroxy Acid',
    ],
  };

  // Get recommendations based on user profile
  static Map<String, List<String>> getRecommendations(
      String? skinType,
      List<String> sensitivities,
      ) {
    // Default to 'Normal' if skin type is not provided or invalid
    String effectiveSkinType = skinType ?? 'Normal';
    if (!skinTypeProducts.containsKey(effectiveSkinType)) {
      effectiveSkinType = 'Normal';
    }

    // Get products for the skin type
    Map<String, List<String>> recommendations = Map.from(skinTypeProducts[effectiveSkinType]!);

    // Filter out products containing sensitive ingredients
    // (In real app, you'd have ingredient data for each product)
    // For now, we'll just return the recommendations as-is

    return recommendations;
  }

  // Get ingredients to avoid based on sensitivities
  static List<String> getAvoidIngredients(List<String> sensitivities) {
    Set<String> avoidIngredients = {};

    for (String sensitivity in sensitivities) {
      if (sensitivityAvoidIngredients.containsKey(sensitivity)) {
        avoidIngredients.addAll(sensitivityAvoidIngredients[sensitivity]!);
      }
    }

    return avoidIngredients.toList();
  }
}
