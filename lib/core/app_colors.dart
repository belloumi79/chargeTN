import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF11B67F);
  static const Color primaryDark = Color(0xFF0E9669);
  static const Color backgroundDark = Color(0xFF11211C);
  static const Color surfaceDark = Color(0xFF1C2E28);
  static const Color borderDark = Color(0xFF2D4A40);
  static const Color textSecondary = Color(0xFF9DB9B0);

  static Color statusColor(String? statut) {
    switch (statut?.toLowerCase()) {
      case 'disponible':
        return Colors.green;
      case 'occupé':
      case 'occupe':
        return Colors.orange;
      case 'hors service':
      case 'hors_service':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
