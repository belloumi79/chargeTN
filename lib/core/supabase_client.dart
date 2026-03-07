import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://hsvtflbvapnrwvgaohby.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhzdnRmbGJ2YXBucnd2Z2FvaGJ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI0MDY3NjcsImV4cCI6MjA4Nzk4Mjc2N30.mja6unKXqjkhRC0omvBZucQTdDaWk45U_XHQIMD_ePk';
  
  static Future<void> init() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
