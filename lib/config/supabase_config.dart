// lib/config/supabase_config.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // ✅ Replace with your Supabase credentials
  static const String supabaseUrl = 'https://pxurqsoiasybgtcwzjzk.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB4dXJxc29pYXN5Ymd0Y3d6anprIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMwMDIwOTQsImV4cCI6MjA2ODU3ODA5NH0.Jmtz3JW1Dv9sIJZe2AdSXnTG0E8g-zL44XAbp9q0UKc';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
