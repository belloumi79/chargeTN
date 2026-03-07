import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/station.dart';
import '../core/supabase_client.dart';

final stationsProvider = StreamProvider<List<Station>>((ref) async* {
  final box = Hive.box('stations_cache');
  
  // Yield cached data first
  if (box.isNotEmpty) {
    final cachedData = box.values.toList();
    final cachedStations = cachedData.map((e) => Station.fromJson(Map<String, dynamic>.from(e))).toList();
    yield cachedStations;
  }

  // Stream from Supabase where verified=true
  final stream = SupabaseConfig.client
      .from('stations')
      .stream(primaryKey: ['id'])
      .eq('verified', true);
      
  await for (final data in stream) {
    final stations = data.map((json) => Station.fromJson(json)).toList();
    
    // Update cache
    await box.clear();
    for (var station in stations) {
      await box.put(station.id, station.toJson());
    }
    
    yield stations;
  }
});
