import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../models/station.dart';

class MapUtils {
  static Future<void> launchMaps(
    BuildContext context,
    Station station,
  ) async {
    context.push('/navigate', extra: station);
  }

  static String getDistanceText(Position? position, double endLat, double endLng) {
    if (position == null) return '- km';
    final distInMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      endLat,
      endLng,
    );
    if (distInMeters < 1000) {
      return '${distInMeters.toStringAsFixed(0)} m';
    } else {
      return '${(distInMeters / 1000).toStringAsFixed(1)} km';
    }
  }
}
