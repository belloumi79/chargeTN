import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/station.dart';
import '../core/supabase_client.dart';

/// Real-time stream of stations.
/// This ensures that when a station is added, updated, or deleted (e.g. by an admin),
/// the UI (map and list) updates immediately everywhere.
final stationsProvider = StreamProvider<List<Station>>((ref) {
  final box = Hive.box('stations_cache');

  // We listen to the real-time stream from Supabase.
  // This automatically handles inserts, updates, and deletes.
  return SupabaseConfig.client
      .from('stations')
      .stream(primaryKey: ['id'])
      .map((data) {
        final stations = data.map((json) => Station.fromJson(json)).toList();
        
        // Update Hive cache in the background for offline support
        _updateCache(box, stations);
        
        return stations;
      });
});

/// Helper to update the local Hive cache.
///
/// We write the new snapshot in two batched operations instead of N+1
/// individual puts. For stations with hundreds of entries this is the
/// difference between an instant refresh and a visible UI hitch on
/// each realtime push.
Future<void> _updateCache(Box box, List<Station> stations) async {
  try {
    final entries = <String, Map<String, dynamic>>{
      for (final s in stations) s.id: s.toJson(),
    };
    await box.clear();
    await box.putAll(entries);
  } catch (e, stack) {
    debugPrint('[StationProvider] cache update failed: $e');
    debugPrint(stack.toString());
  }
}

/// Fallback for offline mode: a simple provider that reads only from Hive.
/// Used when the stream is in error or connection is lost.
final cachedStationsProvider = Provider<List<Station>>((ref) {
  final box = Hive.box('stations_cache');
  if (box.isEmpty) return [];
  try {
    return box.values
        .map((e) => Station.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  } catch (e) {
    return [];
  }
});
