import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../providers/station_provider.dart';
import '../core/app_colors.dart';
import '../core/supabase_client.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/responsive_wrapper.dart';
import '../widgets/app_drawer.dart';

class HomeMapScreen extends ConsumerStatefulWidget {
  const HomeMapScreen({super.key});

  @override
  ConsumerState<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends ConsumerState<HomeMapScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final MapController _mapController = MapController();
  String _mapStyle = 'Moderne';
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _checkConnectivity();
  }

  // Point 6: Mode Hors-Ligne
  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = result.contains(ConnectivityResult.none);
    });
    
    Connectivity().onConnectivityChanged.listen((results) {
      if (results.isEmpty) return;
      setState(() {
        _isOffline = results.contains(ConnectivityResult.none);
      });
    });
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez activer la localisation.')));
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    try {
      final position = await Geolocator.getCurrentPosition();
      _mapController.move(LatLng(position.latitude, position.longitude), 13.0);
    } catch (e, stack) {
      debugPrint('[HomeMapScreen] getCurrentPosition failed: $e');
      debugPrint(stack.toString());
    }
  }

  String _getTileUrl() {
    if (_isOffline) {
      // In a real app, this would point to a local directory with mbtiles
      return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'; 
    }
    switch (_mapStyle) {
      case 'Satellite':
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case 'Terrain':
        return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
      default:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final stationsAsync = ref.watch(stationsProvider);
    final user = SupabaseConfig.client.auth.currentUser;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundDark,
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          // Map
          stationsAsync.when(
            data: (stations) {
              final markers = stations.map((station) {
                return Marker(
                  point: LatLng(station.latitude, station.longitude),
                  width: 50, height: 50,
                  child: GestureDetector(
                    onTap: () => context.push('/station/${station.id}', extra: station),
                    child: _CustomMarker(color: AppColors.statusColor(station.statut)),
                  ),
                );
              }).toList();

              return FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: LatLng(36.8, 10.1),
                  initialZoom: 10.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: _getTileUrl(),
                    userAgentPackageName: 'com.example.charge_tn',
                  ),
                  MarkerClusterLayerWidget(
                    options: MarkerClusterLayerOptions(
                      maxClusterRadius: 45,
                      size: const Size(44, 44),
                      alignment: Alignment.center,
                      markers: markers,
                      builder: (context, clusterMarkers) {
                        return Container(
                          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary, border: Border.all(color: Colors.white, width: 2)),
                          child: Center(child: Text(clusterMarkers.length.toString(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
            loading: () => Container(color: AppColors.backgroundDark),
            error: (e, _) => Center(child: Text('Erreur: $e')),
          ),

          // Search Bar
          SafeArea(
            child: ResponsiveWrapper(
              maxWidth: 500,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      height: 54,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                      child: Row(
                        children: [
                          IconButton(icon: const Icon(Icons.menu), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
                          const Expanded(child: TextField(decoration: InputDecoration(hintText: 'Rechercher une borne', border: InputBorder.none, filled: false))),
                          if (_isOffline)
                            const Padding(padding: EdgeInsets.only(right: 8), child: Icon(Icons.cloud_off, color: Colors.orange, size: 20)),
                          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Offline Banner
          if (_isOffline)
            Positioned(
              top: 100, left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  children: [
                    Icon(Icons.wifi_off, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text('Mode Hors-Ligne : Données locales uniquement', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

          // Bottom Nav
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
}

class _CustomMarker extends StatelessWidget {
  final Color color;
  const _CustomMarker({required this.color});
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(width: 36, height: 36, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)])),
        Icon(Icons.flash_on, color: color, size: 22),
      ],
    );
  }
}
