import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MapUtils {
  static Future<void> launchMaps(BuildContext context, double lat, double lng) async {
    // URL pour l'itinéraire via OpenStreetMap (OSRM)
    // Format: destination lat,lng
    final Uri url = Uri.parse('https://www.openstreetmap.org/directions?engine=fossgis_osrm_car&route=;$lat,$lng');
    
    // Alternative via protocole géo pour laisser le choix à l'utilisateur sur mobile
    final Uri geoUrl = Uri.parse('geo:$lat,$lng?q=$lat,$lng');

    try {
      // On tente d'abord d'ouvrir une application capable de gérer le lien OSM ou géo
      if (await canLaunchUrl(geoUrl)) {
        await launchUrl(geoUrl);
      } else if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible d\'ouvrir la navigation')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }
}
