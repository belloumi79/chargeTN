import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../core/map_utils.dart';
import '../models/station.dart';
import '../providers/favorites_provider.dart';
import '../providers/station_provider.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/responsive_wrapper.dart';
import '../providers/location_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);
    final locationAsync = ref.watch(userLocationProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: ResponsiveWrapper(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Mes Favoris',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: favoritesAsync.when(
                  data: (favoriteIds) {
                    final stationsAsync = ref.watch(stationsProvider);
                    return stationsAsync.when(
                      data: (stations) {
                        final favoriteStations = stations.where((s) => favoriteIds.contains(s.id)).toList();
                        if (favoriteStations.isEmpty) return _buildEmptyState();
                        return _buildList(context, ref, favoriteStations, locationAsync.value);
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Erreur: $e', style: const TextStyle(color: Colors.white))),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Erreur: $e', style: const TextStyle(color: Colors.white))),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
        onTap: (i) {
          if (i == 2) return;
          if (i == 0) context.go('/home');
          if (i == 1) context.go('/search');
          if (i == 3) context.go('/social');
          if (i == 4) context.go('/profile');
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_outline, color: AppColors.textSecondary, size: 64),
          const SizedBox(height: 16),
          const Text('Vous n\'avez pas encore de favoris.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          const Text('Ajoutez des bornes en cliquant sur le cœur.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref, List<Station> stations, dynamic userLocation) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: stations.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final station = stations[index];
        final statusColor = AppColors.statusColor(station.statut);

        return GestureDetector(
          onTap: () => context.push('/station/${station.id}', extra: station),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: const Icon(Icons.ev_station, color: AppColors.primary, size: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              station.name ?? 'Station',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => ref.read(favoritesProvider.notifier).toggleFavorite(station.id),
                            child: const Icon(Icons.favorite, color: Colors.red, size: 20),
                          ),
                        ],
                      ),
                      if (station.address != null)
                        Text(
                          station.address!,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              station.statut,
                              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.bolt, color: AppColors.textSecondary, size: 14),
                          Text(
                            '${station.puissanceKw.isNotEmpty ? station.puissanceKw.first : '22'} kW',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.location_on_outlined, color: AppColors.textSecondary, size: 14),
                          Text(
                            MapUtils.getDistanceText(userLocation, station.latitude, station.longitude),
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => MapUtils.launchMaps(context, station),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Icon(Icons.directions, color: AppColors.primary, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
