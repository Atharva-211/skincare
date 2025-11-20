// lib/screens/home/recommendations_screen.dart
import 'package:flutter/material.dart';
import '../../config/supabase_config.dart';
import '../../models/scan_history.dart';
import '../../models/product.dart';
import '../../services/product_recommendation_service.dart';

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

      _recommendations = await ProductRecommendationService.getRecommendations(_acneLevel);
      _avoidIngredients = ProductRecommendationService.getAvoidIngredients(_acneLevel);

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
              Text('Loading recommendations...'),
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

              if (_latestScan != null && _recommendations.isNotEmpty) ...[
                // ✅ No spacing between categories - removed SizedBox
                ..._recommendations.entries.map((entry) {
                  return _buildCategorySection(entry.key, entry.value);
                }).toList(),
                SizedBox(height: 20), // Only spacing before avoid section
                _buildAvoidSection(),
              ] else
                _buildNoScanCard(),
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
              // Icon section
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
              // Text section
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
              // Stats section
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


  // ✅ Removed bottom spacing from category sections
  Widget _buildCategorySection(String category, List<Product> products) {
    if (products.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12, top: 12), // ✅ Added small top padding
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

  Widget _buildProductCard(Product product) {
    return Container(
      width: 247,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              color: Colors.grey.shade100,
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
                    child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                  );
                },
              )
                  : Center(
                child: Icon(Icons.shopping_bag, size: 48, color: Colors.grey),
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
                  // Brand
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFFBDF4EA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      product.brand,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
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
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: 8),
                  // ✅ Fixed Price Row - Prevent overflow
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          product.formattedPrice,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6FDFFF),
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
                              color: Colors.grey[600],
                              decoration: TextDecoration.lineThrough,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4),
                  // Rating
                  if (product.rating > 0)
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.orange),
                        SizedBox(width: 4),
                        Text(
                          '${product.rating.toStringAsFixed(1)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w600),
                        ),
                        if (product.reviews > 0) ...[
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '(${product.reviews})',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
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
      width: double.infinity, // ✅ Full width
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

  Widget _buildNoScanCard() {
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
          Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey.shade300),
          SizedBox(height: 16),
          Text(
            'No Scan Data',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
          SizedBox(height: 8),
          Text(
            'Complete a scan to get personalized product recommendations',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
