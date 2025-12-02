// lib/config/supabase_config.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // ✅ Replace with your Supabase credentials
  static const String supabaseUrl = 'https://url.supabase.co';
  static const String supabaseAnonKey = 'APIKEY';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
