import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/station.dart';
import '../core/app_colors.dart';
import '../widgets/responsive_wrapper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/location_provider.dart';

class InAppNavigationScreen extends ConsumerStatefulWidget {
  final Station station;

  const InAppNavigationScreen({super.key, required this.station});

  @override
  ConsumerState<InAppNavigationScreen> createState() =>
      _InAppNavigationScreenState();
}

class _InAppNavigationScreenState extends ConsumerState<InAppNavigationScreen> {
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = true;
  String _routeError = '';
  double _routeDistance = 0.0;
  double _routeDuration = 0.0;

  @override
  void initState() {
    super.initState();
    // Use Future microtask to wait for provider resolution
    Future.microtask(() => _fetchRoute());
  }

  Future<void> _fetchRoute() async {
    setState(() => _isLoadingRoute = true);
    // Force refresh to get latest position
    final position = await ref.refresh(userLocationProvider.future);
    if (position == null) {
      if (mounted) {
        setState(() {
          _routeError = 'Localisation désactivée ou refusée.';
          _isLoadingRoute = false;
        });
      }
      return;
    }

    final startLat = position.latitude;
    final startLng = position.longitude;
    final endLat = widget.station.latitude;
    final endLng = widget.station.longitude;

    final url =
        'https://router.project-osrm.org/route/v1/driving/$startLng,$startLat;$endLng,$endLat?overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          final coordinates = geometry['coordinates'] as List;

          final points = coordinates
              .map((coord) => LatLng(coord[1] as double, coord[0] as double))
              .toList();

          if (mounted) {
            setState(() {
              _routePoints = points;
              _routeDistance = (route['distance'] as num).toDouble() / 1000.0; // km
              _routeDuration = (route['duration'] as num).toDouble() / 60.0; // minutes
              _isLoadingRoute = false;
            });
            _fitRoute();
          }
        } else {
          setState(() {
            _routeError = 'Aucun itinéraire trouvé.';
            _isLoadingRoute = false;
          });
        }
      } else {
        setState(() {
          _routeError = 'Erreur serveur de routage (OSRM).';
          _isLoadingRoute = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _routeError = 'Problème de connexion.';
          _isLoadingRoute = false;
        });
      }
    }
  }

  void _fitRoute() {
    if (_routePoints.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(_routePoints);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(userLocationProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: ResponsiveWrapper(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Text(
                        'Trajet vers ${widget.station.name ?? "Station"}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // spacer
                  ],
                ),
              ),

              // Summary card
              if (!_isLoadingRoute && _routeError.isEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.speed, color: AppColors.primary, size: 28),
                          const SizedBox(height: 6),
                          Text(
                            '${_routeDistance.toStringAsFixed(1)} km',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 40, color: Colors.white24),
                      Column(
                        children: [
                          const Icon(Icons.schedule, color: Colors.blueAccent, size: 28),
                          const SizedBox(height: 6),
                          Text(
                            '${_routeDuration.toStringAsFixed(0)} min',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Map
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: LatLng(
                              widget.station.latitude, widget.station.longitude),
                          initialZoom: 14.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.charge_tn',
                            tileBuilder: _darkModeTileBuilder,
                          ),
                          if (_routePoints.isNotEmpty)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: _routePoints,
                                  strokeWidth: 4.5,
                                  color: AppColors.primary,
                                  borderStrokeWidth: 1.5,
                                  borderColor: Colors.black.withValues(alpha: 0.8),
                                ),
                              ],
                            ),
                          MarkerLayer(
                            markers: [
                              // Destination
                              Marker(
                                point: LatLng(widget.station.latitude,
                                    widget.station.longitude),
                                width: 44,
                                height: 54,
                                child: const _SimpleMarker(
                                    color: Colors.red, icon: Icons.location_on),
                              ),
                              // Origin
                              if (locationAsync.value != null)
                                Marker(
                                  point: LatLng(locationAsync.value!.latitude,
                                      locationAsync.value!.longitude),
                                  width: 44,
                                  height: 54,
                                  child: const _SimpleMarker(
                                      color: Colors.blue, icon: Icons.my_location),
                                ),
                            ],
                          ),
                        ],
                      ),
                      if (_isLoadingRoute)
                        const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      if (_routeError.isNotEmpty)
                        Container(
                          color: Colors.black87,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_off_outlined, color: Colors.redAccent, size: 48),
                                  const SizedBox(height: 16),
                                  Text(
                                    _routeError,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    ),
                                    onPressed: _fetchRoute,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Réessayer'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _darkModeTileBuilder(
    BuildContext context,
    Widget tileWidget,
    TileImage tile,
  ) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        -1, 0, 0, 0, 255, //
        0, -1, 0, 0, 255, //
        0, 0, -1, 0, 255, //
        0, 0, 0, 1, 0, //
      ]),
      child: tileWidget,
    );
  }
}

class _SimpleMarker extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _SimpleMarker({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.location_on, color: color, size: 44),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
          ],
        ),
      ],
    );
  }
}
