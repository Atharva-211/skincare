// lib/screens/onboarding/onboarding_flow.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../config/supabase_config.dart';
import '../home/main_navigation.dart';

class OnboardingFlow extends StatefulWidget {
  final CameraDescription camera;

  const OnboardingFlow({Key? key, required this.camera}) : super(key: key);

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  final Map<String, dynamic> _formData = {
    'known_allergies': <String>[],
    'diet_dairy': 2,
    'diet_sugar': 2,
    'diet_oily': 2,
    'diet_balanced': 2,
    'exercise_frequency': 2,
  };

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitProfile();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitProfile() async {
    setState(() => _isLoading = true);

    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      print('📝 Submitting profile for user: ${user.id}');

      _formData['id'] = user.id;
      _formData['email'] = user.email;

      print('Form data: $_formData');

      await SupabaseConfig.client.from('user_profiles').insert(_formData);

      print('✅ Profile saved successfully!');

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MainNavigation(camera: widget.camera),
          ),
        );
      }
    } catch (e) {
      print('❌ Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD9FBFF),
      appBar: AppBar(
        backgroundColor: Color(0xFFBDF4EA),
        elevation: 0,
        title: Text(
          'Complete Your Profile',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: _currentPage > 0
            ? IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: _previousPage,
        )
            : null,
      ),
      body: Column(
        children: [
          // ✅ Progress indicator - REMOVED white background
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: SmoothPageIndicator(
              controller: _pageController,
              count: 3,
              effect: WormEffect(
                activeDotColor: Color(0xFF6FDFFF),
                dotColor: Colors.grey.shade300,
                dotHeight: 10,
                dotWidth: 10,
                spacing: 16,
              ),
            ),
          ),

          // Pages
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              physics: NeverScrollableScrollPhysics(),
              children: [
                _buildBasicProfilePage(),
                _buildLifestylePage(),
                _buildSkincareAndAllergiesPage(),
              ],
            ),
          ),

          // ✅ Next/Submit Button - REMOVED white container background
          Padding(
            padding: EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFBDF4EA),
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8, // ✅ Increased shadow for depth
                  shadowColor: Colors.black26,
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.black87)
                    : Text(
                  _currentPage < 2 ? 'Next' : 'Complete Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // Page 1: Basic Profile
  Widget _buildBasicProfilePage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader('1. Basic Profile', 'Tell us about yourself'),
          SizedBox(height: 24),

          TextFormField(
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('Age', Icons.cake),
            onChanged: (value) => _formData['age'] = int.tryParse(value),
          ),
          SizedBox(height: 16),

          DropdownButtonFormField<String>(
            decoration: _inputDecoration('Gender', Icons.person),
            items: ['Male', 'Female', 'Other']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (value) => setState(() => _formData['gender'] = value),
          ),
          SizedBox(height: 16),

          DropdownButtonFormField<String>(
            decoration: _inputDecoration('Skin Type', Icons.face),
            items: ['Oily', 'Dry', 'Combination', 'Normal', 'Sensitive']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (value) => setState(() => _formData['skin_type'] = value),
          ),
        ],
      ),
    );
  }

  // Page 2: Lifestyle & Diet
  Widget _buildLifestylePage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader('2. Lifestyle & Diet', 'Your daily habits'),
          SizedBox(height: 24),

          _buildSliderField('High dairy consumption?', 'diet_dairy', Icons.local_drink),
          _buildSliderField('High sugar/junk food?', 'diet_sugar', Icons.fastfood),
          _buildSliderField('High oily/greasy food?', 'diet_oily', Icons.restaurant),
          _buildSliderField('Balanced diet?', 'diet_balanced', Icons.restaurant_menu),

          DropdownButtonFormField<String>(
            decoration: _inputDecoration('Water Intake', Icons.water_drop),
            items: [
              'Less than 1L',
              '1-2L',
              '2-3L',
              'More than 3L',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (value) => setState(() => _formData['water_intake'] = value),
          ),
          SizedBox(height: 16),

          DropdownButtonFormField<String>(
            decoration: _inputDecoration('Sleep Duration', Icons.bedtime),
            items: ['Less than 6h', '6-8h', 'More than 8h']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (value) => setState(() => _formData['sleep_duration'] = value),
          ),
          SizedBox(height: 16),

          _buildSliderField('Exercise Frequency', 'exercise_frequency', Icons.fitness_center),
        ],
      ),
    );
  }

  // Page 3: Skincare & Allergies
  Widget _buildSkincareAndAllergiesPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader('3. Skincare & Allergies', 'Your routine and sensitivities'),
          SizedBox(height: 24),

          _buildSectionHeader('Skincare Routine'),
          SizedBox(height: 12),

          TextFormField(
            decoration: _inputDecoration('Cleanser (Optional)', Icons.soap),
            onChanged: (value) => _formData['products_cleanser'] = value,
          ),
          SizedBox(height: 16),

          TextFormField(
            decoration: _inputDecoration('Moisturizer (Optional)', Icons.water),
            onChanged: (value) => _formData['products_moisturizer'] = value,
          ),
          SizedBox(height: 16),

          TextFormField(
            decoration: _inputDecoration('Sunscreen (Optional)', Icons.wb_sunny),
            onChanged: (value) => _formData['products_sunscreen'] = value,
          ),
          SizedBox(height: 16),

          DropdownButtonFormField<String>(
            decoration: _inputDecoration('Face Washing Frequency', Icons.face_retouching_natural),
            items: ['Once a day', 'Twice a day', 'More than twice']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (value) => setState(() => _formData['face_washing_frequency'] = value),
          ),
          SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: CheckboxListTile(
              title: Text('Uses Makeup', style: TextStyle(fontWeight: FontWeight.w500)),
              value: _formData['uses_makeup'] ?? false,
              activeColor: Color(0xFF6FDFFF), // ✅ Matching accent color
              onChanged: (value) {
                setState(() => _formData['uses_makeup'] = value);
              },
            ),
          ),

          SizedBox(height: 24),
          Divider(thickness: 2),
          SizedBox(height: 24),

          _buildSectionHeader('Known Allergies'),
          SizedBox(height: 12),

          ..._buildMultiSelect(
            ['Fragrance', 'Alcohol', 'Benzoyl Peroxide', 'Salicylic Acid', 'None'],
            'known_allergies',
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87, // ✅ Matching text color
          ),
        ),
        SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Color(0xFFBDF4EA), // ✅ Matching primary color
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.black87, size: 20),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87, // ✅ Matching text color
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMultiSelect(List<String> options, String key) {
    _formData[key] ??= <String>[];
    return options.map((option) {
      return Container(
        margin: EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: CheckboxListTile(
          title: Text(option, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
          value: (_formData[key] as List<String>).contains(option),
          activeColor: Color(0xFF6FDFFF), // ✅ Matching accent color
          onChanged: (selected) {
            setState(() {
              if (selected == true) {
                (_formData[key] as List<String>).add(option);
              } else {
                (_formData[key] as List<String>).remove(option);
              }
            });
          },
        ),
      );
    }).toList();
  }

  Widget _buildSliderField(String label, String key, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Color(0xFF6FDFFF)), // ✅ Matching accent color
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Slider(
            value: (_formData[key] ?? 2).toDouble(),
            min: 1,
            max: 3,
            divisions: 2,
            label: ['Low', 'Medium', 'High'][(_formData[key] ?? 2) - 1],
            activeColor: Color(0xFF6FDFFF), // ✅ Matching accent color
            inactiveColor: Colors.grey.shade300,
            onChanged: (value) {
              setState(() => _formData[key] = value.toInt());
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Low', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text('Medium', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text('High', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade700),
      prefixIcon: Icon(icon, color: Color(0xFF6FDFFF)), // ✅ Matching accent color
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFF6FDFFF), width: 2), // ✅ Matching accent color
      ),
    );
  }
}
