// lib/screens/home/recommendations_screen.dart
import 'package:flutter/material.dart';
import '../../config/supabase_config.dart';
import '../../models/scan_history.dart';
import '../../models/product.dart';
import '../../services/product_recommendation_service.dart';
import '../../services/product_service.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({Key? key}) : super(key: key);

  @override
  State<RecommendationsScreen> createState() => RecommendationsScreenState();
}

class RecommendationsScreenState extends State<RecommendationsScreen> {
  ScanHistory? _latestScan;
  String _acneLevel = 'low';
  Map<String, List<Product>> _recommendations = {};
  List<String> _avoidIngredients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadRecommendations();
  }

  Future<void> loadRecommendations() async {
    setState(() => _isLoading = true);

    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;

      // Get latest scan for acne level
      final scanData = await SupabaseConfig.client
          .from('scan_history')
          .select()
          .eq('user_id', user.id)
          .order('scan_date', ascending: false)
          .limit(1);

      if (scanData.isNotEmpty) {
        _latestScan = ScanHistory.fromJson(scanData.first);
        _acneLevel = ProductRecommendationService.getAcneLevel(_latestScan);
      }

      // Get product name recommendations based on user profile
      final recommendedNames = await ProductRecommendationService.getRecommendations();

      // ✅ Fetch real product data from API for each category
      Map<String, List<Product>> fetchedProducts = {};

      for (var entry in recommendedNames.entries) {
        String category = entry.key;
        List<String> productNames = entry.value;

        print('Fetching products for category: $category');
        List<Product> categoryProducts = [];

        // Try to fetch products for top 2-3 product names in this category
        for (int i = 0; i < productNames.length && i < 3; i++) {
          String productName = productNames[i];
          print('Searching API for: $productName');

          try {
            List<Product> apiProducts = await ProductService.searchProducts(productName);

            // ✅ Only add products that have valid data (non-zero price or image)
            for (var product in apiProducts) {
              if (product.price > 0 || product.imageUrl.isNotEmpty) {
                categoryProducts.add(product);
                if (categoryProducts.length >= 6) break; // Max 6 per category
              }
            }

            if (categoryProducts.length >= 6) break;
          } catch (e) {
            print('Error fetching $productName: $e');
            continue; // ✅ Skip products that fail to fetch
          }
        }

        // ✅ Only add category if we found products
        if (categoryProducts.isNotEmpty) {
          fetchedProducts[category] = categoryProducts;
          print('Added ${categoryProducts.length} products for $category');
        } else {
          print('No products found for $category - skipping');
        }
      }

      _recommendations = fetchedProducts;

      // Get ingredients to avoid
      _avoidIngredients = await ProductRecommendationService.getAvoidIngredients();

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading recommendations: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFFD9FBFF),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading personalized recommendations...'),
              SizedBox(height: 8),
              Text(
                'This may take a few moments',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFD9FBFF),
      appBar: AppBar(
        backgroundColor: Color(0xFFBDF4EA),
        elevation: 0,
        title: Text(
          'Product Recommendations',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: loadRecommendations,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_latestScan != null) ...[
                _buildAcneLevelCard(),
                SizedBox(height: 20),
              ],

              if (_recommendations.isNotEmpty) ...[
                ..._recommendations.entries.map((entry) {
                  return _buildCategorySection(entry.key, entry.value);
                }).toList(),
                SizedBox(height: 20),
                if (_avoidIngredients.isNotEmpty) _buildAvoidSection(),
              ] else
                _buildNoProductsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAcneLevelCard() {
    final levelColors = {
      'high': Colors.red,
      'medium': Colors.orange,
      'low': Colors.green,
    };
    final levelIcons = {
      'high': Icons.priority_high,
      'medium': Icons.warning_amber_rounded,
      'low': Icons.check_circle,
    };

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            levelColors[_acneLevel]?.withOpacity(0.8) ?? Colors.grey,
            levelColors[_acneLevel] ?? Colors.grey,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  levelIcons[_acneLevel],
                  size: 40,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Acne Level',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _acneLevel.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '${_latestScan?.totalDetections ?? 0}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'detections',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_latestScan != null) ...[
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 14, color: Colors.white70),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Based on your latest scan',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategorySection(String category, List<Product> products) {
    if (products.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12, top: 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: Color(0xFF6FDFFF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 8),
              Text(
                category,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 320,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 4),
            itemCount: products.length > 6 ? 6 : products.length,
            separatorBuilder: (_, __) => SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _buildProductCard(products[index]);
            },
          ),
        ),
      ],
    );
  }

  // ✅ Original product card with image and price
  Widget _buildProductCard(Product product) {
    return Container(
      width: 247,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Color(0xFFBDF4EA).withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFF6FDFFF).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6FDFFF).withOpacity(0.2),
            offset: Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image with gradient overlay
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                colors: [
                  Color(0xFFBDF4EA).withOpacity(0.1),
                  Colors.white,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: product.imageUrl.isNotEmpty
                  ? Image.network(
                product.imageUrl,
                fit: BoxFit.contain,
                height: 120,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Color(0xFF6FDFFF).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: Color(0xFF6FDFFF),
                      ),
                    ),
                  );
                },
              )
                  : Center(
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(0xFF6FDFFF).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shopping_bag,
                    size: 48,
                    color: Color(0xFF6FDFFF),
                  ),
                ),
              ),
            ),
          ),

          // Product Details
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand badge with gradient
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFBDF4EA),
                          Color(0xFF6FDFFF).withOpacity(0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF6FDFFF).withOpacity(0.3),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      product.brand,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: 8),

                  // Product Name
                  Expanded(
                    child: Text(
                      product.name.length > 50
                          ? '${product.name.substring(0, 50)}...'
                          : product.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: 8),

                  // Price Row with background
                  // Price Row with new color scheme
                  if (product.price > 0)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFBDF4EA),
                            Color(0xFFBDF4EA).withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF6FDFFF).withOpacity(0.2),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.currency_rupee,
                            size: 16,
                            color: Colors.black87,
                          ),
                          Flexible(
                            child: Text(
                              product.formattedPrice.replaceAll('₹', ''),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (product.originalPrice != null && product.originalPrice! > product.price) ...[
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                product.formattedOriginalPrice,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.red[600],
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: Colors.red[600],
                                  decorationThickness: 2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                  SizedBox(height: 6),

                  // Rating with star background
                  if (product.rating > 0)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 14, color: Colors.orange),
                          SizedBox(width: 4),
                          Text(
                            '${product.rating.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (product.reviews > 0) ...[
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '(${product.reviews})',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildAvoidSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
              ),
              SizedBox(width: 12),
              Text(
                'Ingredients to Avoid',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade900,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ..._avoidIngredients.map((ingredient) {
            return Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.close, size: 18, color: Colors.red),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ingredient,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildNoProductsCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey.shade300),
          SizedBox(height: 16),
          Text(
            'No Products Available',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
          SizedBox(height: 8),
          Text(
            'Unable to fetch product recommendations at this time. Please try again later.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
