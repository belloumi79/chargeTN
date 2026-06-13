import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase_client.dart';
import '../models/station.dart';
import 'station_provider.dart';

// Provider for favorites using Supabase for persistence
final favoritesProvider = AsyncNotifierProvider<FavoritesNotifier, Set<String>>(() {
  return FavoritesNotifier();
});

class FavoritesNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return {};

    try {
      final response = await SupabaseConfig.client
          .from('favorites')
          .select('station_id')
          .eq('user_id', user.id);
      
      final Set<String> ids = (response as List)
          .map((item) => item['station_id'] as String)
          .toSet();
      return ids;
    } catch (e) {
      return {};
    }
  }

  Future<void> toggleFavorite(String stationId) async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;

    final currentIds = state.value ?? <String>{};
    final isFav = currentIds.contains(stationId);
    // Snapshot the previous value so we can roll back if the DB write fails.
    final previousIds = Set<String>.from(currentIds);

    // Optimistic update so the heart icon flips immediately.
    if (isFav) {
      state = AsyncData(Set<String>.from(currentIds)..remove(stationId));
    } else {
      state = AsyncData({...currentIds, stationId});
    }

    try {
      if (isFav) {
        await SupabaseConfig.client
            .from('favorites')
            .delete()
            .match({'user_id': user.id, 'station_id': stationId});
      } else {
        await SupabaseConfig.client.from('favorites').insert({
          'user_id': user.id,
          'station_id': stationId,
        });
      }
    } catch (e, stack) {
      // Roll back the optimistic update so the UI matches reality.
      debugPrint('[Favorites] toggleFavorite($stationId) failed: $e');
      debugPrint(stack.toString());
      state = AsyncData(previousIds);
      rethrow;
    }
  }

  bool isFavorite(String stationId) {
    return state.value?.contains(stationId) ?? false;
  }
}

// Provider to get favorite stations
final favoriteStationsProvider = Provider<List<Station>>((ref) {
  final favoriteIdsAsync = ref.watch(favoritesProvider);
  final stationsAsync = ref.watch(stationsProvider);

  return favoriteIdsAsync.maybeWhen(
    data: (favoriteIds) {
      return stationsAsync.maybeWhen(
        data: (stations) =>
            stations.where((s) => favoriteIds.contains(s.id)).toList(),
        orElse: () => [],
      );
    },
    orElse: () => [],
  );
});
