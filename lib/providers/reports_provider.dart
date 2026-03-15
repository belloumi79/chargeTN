import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase_client.dart';
import '../models/report.dart';

final userReportsProvider = StreamProvider<List<Report>>((ref) {
  final user = SupabaseConfig.client.auth.currentUser;
  if (user == null) return Stream.value([]);

  return SupabaseConfig.client
      .from('reports')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id)
      .map((maps) => maps.map((e) => Report.fromJson(e)).toList());
});

final userStatsProvider = Provider((ref) {
  final reportsAsync = ref.watch(userReportsProvider);
  
  return reportsAsync.when(
    data: (reports) {
      final total = reports.length;
      final points = reports.where((r) => r.status != 'rejected').length;
      
      String rank;
      if (points >= 50) {
        rank = 'Légende 🏅';
      } else if (points >= 30) {
        rank = 'Expert ⚡';
      } else if (points >= 15) {
        rank = 'Contributeur 🤝';
      } else if (points >= 5) {
        rank = 'Éclaireur 🗺️';
      } else {
        rank = 'Débutant 🥚';
      }

      return {
        'total': total,
        'points': points,
        'rank': rank,
        'nextRankPoints': _getNextRankPoints(points),
      };
    },
    loading: () => {'total': 0, 'points': 0, 'rank': 'Chargement...', 'nextRankPoints': 5},
    error: (error, stack) => {'total': 0, 'points': 0, 'rank': 'Erreur', 'nextRankPoints': 5},
  );
});

int _getNextRankPoints(int points) {
  if (points < 5) return 5;
  if (points < 15) return 15;
  if (points < 30) return 30;
  if (points < 50) return 50;
  return points;
}

