import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/station_provider.dart';
import '../core/app_colors.dart';
import '../core/supabase_client.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/responsive_wrapper.dart';

class HomeMapScreen extends ConsumerStatefulWidget {
  const HomeMapScreen({super.key});

  @override
  ConsumerState<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends ConsumerState<HomeMapScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _activeFilter = 0;
  final List<String> _filters = ['Toutes prises', 'Charge Rapide', 'Gratuit', 'Disponible'];
  final MapController _mapController = MapController();
  bool _isSatelliteMode = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    _mapController.move(LatLng(position.latitude, position.longitude), 13.0);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stationsAsync = ref.watch(stationsProvider);
    final user = SupabaseConfig.client.auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // ── Map layer ──────────────────────────────────────────────────────
          stationsAsync.when(
            data: (stations) {
              final markers = stations.map((station) {
                final color = AppColors.statusColor(station.statut);
                return Marker(
                  point: LatLng(station.latitude, station.longitude),
                  width: 44,
                  height: 54,
                  child: GestureDetector(
                    onTap: () => context.push('/station/${station.id}', extra: station),
                    child: _StitchMarker(color: color, status: station.statut),
                  ),
                );
              }).toList();

              return FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: LatLng(36.8, 10.1), // Center on Tunis by default
                  initialZoom: 10.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: _isSatelliteMode 
                        ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.charge_tn',
                    tileBuilder: _isSatelliteMode ? null : _darkModeTileBuilder,
                  ),
                  MarkerClusterLayerWidget(
                    options: MarkerClusterLayerOptions(
                      maxClusterRadius: 45,
                      size: const Size(44, 44),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(50),
                      markers: markers,
                      builder: (context, clusterMarkers) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            color: AppColors.primary,
                          ),
                          child: Center(
                            child: Text(
                              clusterMarkers.length.toString(),
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
            loading: () => const _MapPlaceholder(),
            error: (e, _) => Center(child: Text('Erreur: $e')),
          ),

          // ── Top Search Bar ─────────────────────────────────────────────────
          SafeArea(
            child: ResponsiveWrapper(
              maxWidth: 500,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search pill
                    Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 8),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.asset('assets/images/logo.png', fit: BoxFit.contain, width: 24, height: 24),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Rechercher des bornes...',
                                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                              onSubmitted: (v) => context.push('/search'),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.5)),
                            onPressed: () => context.push('/search'),
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          IconButton(
                            icon: Icon(Icons.tune, color: Colors.white.withValues(alpha: 0.5)),
                            onPressed: () => _showFilterDrawer(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Quick filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(_filters.length, (i) {
                          final active = _activeFilter == i;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _activeFilter = i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: active
                                      ? AppColors.primary
                                      : AppColors.surfaceDark.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(999),
                                  border: active
                                      ? null
                                      : Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                  boxShadow: active
                                      ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 8)]
                                      : [],
                                ),
                                child: Text(
                                  _filters[i],
                                  style: TextStyle(
                                    color: active ? AppColors.backgroundDark : Colors.white.withValues(alpha: 0.7),
                                    fontSize: 12,
                                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Side controls ──────────────────────────────────────────────────
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MapButton(
                    icon: _isSatelliteMode ? Icons.map : Icons.layers_outlined, 
                    onTap: () => setState(() => _isSatelliteMode = !_isSatelliteMode)
                  ),
                  const SizedBox(height: 10),
                  _MapButton(
                    icon: Icons.near_me, 
                    onTap: () => _checkLocationPermission()
                  ),
                ],
              ),
            ),
          ),

          // ── FAB (Add Station) ─────────────────────────────────────────────
          if (user != null)
            Positioned(
              bottom: 80,
              right: 20,
              child: GestureDetector(
                onTap: () => context.push('/add_station'),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.black, size: 32),
                ),
              ),
            ),

          // ── Bottom Nav ─────────────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: AppBottomNav(
              currentIndex: 0,
              onTap: (i) {
                if (i == 0) return;
                if (i == 1) context.go('/search');
                if (i == 2) context.go('/favs');
                if (i == 3) context.go('/social');
                if (i == 4) context.go('/profile');
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: AppColors.backgroundDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('Filtres avancés', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const Expanded(child: Center(child: Text('Options de filtrage Stitch...', style: TextStyle(color: Colors.white54)))),
          ],
        ),
      ),
    );
  }

  Widget _darkModeTileBuilder(BuildContext context, Widget tileWidget, TileImage tile) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        -1, 0, 0, 0, 255,
        0, -1, 0, 0, 255,
        0, 0, -1, 0, 255,
        0, 0, 0, 1, 0,
      ]),
      child: tileWidget,
    );
  }
}

class _StitchMarker extends StatelessWidget {
  final Color color;
  final String? status;
  const _StitchMarker({required this.color, this.status});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.topCenter,
          children: [
            Icon(Icons.location_on, color: color, size: 44),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Icon(
                Icons.ev_station,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8)],
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 20),
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Container(color: AppColors.backgroundDark);
  }
}
