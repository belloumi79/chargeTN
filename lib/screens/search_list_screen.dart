import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/station_provider.dart';
import '../core/app_colors.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/responsive_wrapper.dart';
import '../core/map_utils.dart';

class SearchListScreen extends ConsumerStatefulWidget {
  const SearchListScreen({super.key});
  @override
  ConsumerState<SearchListScreen> createState() => _SearchListScreenState();
}

class _SearchListScreenState extends ConsumerState<SearchListScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  int _activeFilter = 0;
  final _filters = ['Tous', 'Disponible', 'Rapide', 'Gratuit', 'Type 2'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stationsAsync = ref.watch(stationsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: ResponsiveWrapper(
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Trouver une borne',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.filter_list, color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              // ── Search bar ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.transparent),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 14),
                        child: Icon(Icons.search, color: AppColors.textSecondary),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                          onChanged: (v) => setState(() => _query = v.toLowerCase()),
                          decoration: InputDecoration(
                            hintText: 'Chercher une ville ou une station',
                            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                            isDense: true,
                          ),
                        ),
                      ),
                      if (_query.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.cancel, color: Colors.white.withValues(alpha: 0.4)),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                    ],
                  ),
                ),
              ),
              // ── Filter chips ──────────────────────────────────────────────────
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final active = _activeFilter == i;
                    return GestureDetector(
                      onTap: () => setState(() => _activeFilter = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary : AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: active ? Colors.transparent : Colors.white.withValues(alpha: 0.07)),
                          boxShadow: active
                              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 8)]
                              : [],
                        ),
                        child: Text(
                          _filters[i],
                          style: TextStyle(
                            color: active ? AppColors.backgroundDark : AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
              // ── Results header ────────────────────────────────────────────────
              stationsAsync.when(
                data: (stations) {
                  final filtered = stations.where((s) {
                    if (_query.isEmpty) return true;
                    return (s.name ?? '').toLowerCase().contains(_query) ||
                        (s.address?.toLowerCase().contains(_query) ?? false);
                  }).toList();

                  return Expanded(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${filtered.length} résultats',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                              const Text('Trier: Recommandé',
                                  style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final station = filtered[i];
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
                                      // Thumbnail
                                      Stack(
                                        children: [
                                          Container(
                                            width: 72, height: 72,
                                            decoration: BoxDecoration(
                                              color: AppColors.backgroundDark,
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                            ),
                                            child: const Icon(Icons.ev_station, color: AppColors.primary, size: 32),
                                          ),
                                          Positioned(
                                            bottom: -2, right: -2,
                                            child: Container(
                                              width: 18, height: 18,
                                              decoration: BoxDecoration(
                                                color: AppColors.surfaceDark,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: AppColors.backgroundDark, width: 2),
                                              ),
                                              child: Center(
                                                child: Container(
                                                  width: 8, height: 8,
                                                  decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
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
                                                Text(
                                                  '${(station.latitude * 10 % 15).abs().toStringAsFixed(1)} km',
                                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
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
                                                const Spacer(),
                                                GestureDetector(
                                                  onTap: () => MapUtils.launchMaps(context, station.latitude, station.longitude),
                                                  child: Container(
                                                    width: 30, height: 30,
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
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
                error: (e, _) => Expanded(child: Center(child: Text('Erreur: $e', style: const TextStyle(color: Colors.white)))),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 1,
        onTap: (i) {
          if (i == 1) return;
          if (i == 0) context.go('/home');
          if (i == 2) context.go('/favs');
          if (i == 3) context.go('/social');
          if (i == 4) context.go('/profile');
        },
      ),
    );
  }
}
