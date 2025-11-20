// lib/models/user_profile.dart
class UserProfile {
  final String id;
  final String email;

  // Basic Info
  final int? age;
  final String? gender;
  final String? skinType;
  final String? skinTone;

  // Acne Info
  final String? acneDuration;
  final String? currentSeverity;
  final List<String>? acneAreas;
  final int? skinSensitivity;

  // Lifestyle
  final int? dietDairy;
  final int? dietSugar;
  final int? dietOily;
  final int? dietBalanced;
  final String? waterIntake;
  final String? sleepDuration;
  final int? exerciseFrequency;

  // Hormonal
  final bool? menstrualRelation;
  final List<String>? medications;
  final List<String>? medicalConditions;
  final String? stressLevel;

  // Skincare
  final String? productsCleanser;
  final bool? productsRetinoids;
  final String? productsMoisturizer;
  final String? productsSunscreen;
  final String? faceWashingFrequency;
  final bool? usesMakeup;

  // Allergies
  final List<String>? knownAllergies;
  final String? pastReactions;

  UserProfile({
    required this.id,
    required this.email,
    this.age,
    this.gender,
    this.skinType,
    this.skinTone,
    this.acneDuration,
    this.currentSeverity,
    this.acneAreas,
    this.skinSensitivity,
    this.dietDairy,
    this.dietSugar,
    this.dietOily,
    this.dietBalanced,
    this.waterIntake,
    this.sleepDuration,
    this.exerciseFrequency,
    this.menstrualRelation,
    this.medications,
    this.medicalConditions,
    this.stressLevel,
    this.productsCleanser,
    this.productsRetinoids,
    this.productsMoisturizer,
    this.productsSunscreen,
    this.faceWashingFrequency,
    this.usesMakeup,
    this.knownAllergies,
    this.pastReactions,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      skinType: json['skin_type'] as String?,
      skinTone: json['skin_tone'] as String?,
      acneDuration: json['acne_duration'] as String?,
      currentSeverity: json['current_severity'] as String?,
      acneAreas: (json['acne_areas'] as List<dynamic>?)?.cast<String>(),
      skinSensitivity: json['skin_sensitivity'] as int?,
      dietDairy: json['diet_dairy'] as int?,
      dietSugar: json['diet_sugar'] as int?,
      dietOily: json['diet_oily'] as int?,
      dietBalanced: json['diet_balanced'] as int?,
      waterIntake: json['water_intake'] as String?,
      sleepDuration: json['sleep_duration'] as String?,
      exerciseFrequency: json['exercise_frequency'] as int?,
      menstrualRelation: json['menstrual_relation'] as bool?,
      medications: (json['medications'] as List<dynamic>?)?.cast<String>(),
      medicalConditions: (json['medical_conditions'] as List<dynamic>?)?.cast<String>(),
      stressLevel: json['stress_level'] as String?,
      productsCleanser: json['products_cleanser'] as String?,
      productsRetinoids: json['products_retinoids'] as bool?,
      productsMoisturizer: json['products_moisturizer'] as String?,
      productsSunscreen: json['products_sunscreen'] as String?,
      faceWashingFrequency: json['face_washing_frequency'] as String?,
      usesMakeup: json['uses_makeup'] as bool?,
      knownAllergies: (json['known_allergies'] as List<dynamic>?)?.cast<String>(),
      pastReactions: json['past_reactions'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'age': age,
      'gender': gender,
      'skin_type': skinType,
      'skin_tone': skinTone,
      'acne_duration': acneDuration,
      'current_severity': currentSeverity,
      'acne_areas': acneAreas,
      'skin_sensitivity': skinSensitivity,
      'diet_dairy': dietDairy,
      'diet_sugar': dietSugar,
      'diet_oily': dietOily,
      'diet_balanced': dietBalanced,
      'water_intake': waterIntake,
      'sleep_duration': sleepDuration,
      'exercise_frequency': exerciseFrequency,
      'menstrual_relation': menstrualRelation,
      'medications': medications,
      'medical_conditions': medicalConditions,
      'stress_level': stressLevel,
      'products_cleanser': productsCleanser,
      'products_retinoids': productsRetinoids,
      'products_moisturizer': productsMoisturizer,
      'products_sunscreen': productsSunscreen,
      'face_washing_frequency': faceWashingFrequency,
      'uses_makeup': usesMakeup,
      'known_allergies': knownAllergies,
      'past_reactions': pastReactions,
    };
  }
}
