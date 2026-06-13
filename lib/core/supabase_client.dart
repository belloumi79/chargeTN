import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://hsvtflbvapnrwvgaohby.supabase.co';
  static const String anonKey = 'sb_publishable_HMSJjHrQuMldAcMgX6pykQ_GMIelqIJ';
  
  static Future<void> init() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
