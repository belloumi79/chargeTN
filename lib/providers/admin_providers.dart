import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase_client.dart';
import '../models/report.dart';
/// Real-time stream of pending reports enriched with station + user info.
final pendingReportsProvider =
    StreamProvider.autoDispose<List<Report>>((ref) {
  return SupabaseConfig.client
      .from('reports_detailed')
      .stream(primaryKey: ['id'])
      .eq('status', 'pending')
      .order('created_at', ascending: true)
      .map((rows) => rows.map(Report.fromJson).toList());
});

/// Whether the stations tab should show all stations (true) or
/// only those awaiting verification (false).
class ShowAllStationsNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  // ignore: use_setters_to_change_properties
  void set(bool value) => state = value;
  void toggle(bool value) {
    if (value) state = true;
  }
}

final showAllStationsProvider =
    NotifierProvider<ShowAllStationsNotifier, bool>(ShowAllStationsNotifier.new);

/// Real-time stream of stations (filtered by [showAllStationsProvider]).
/// Resubscribes whenever the filter changes.
final adminStationsProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final showAll = ref.watch(showAllStationsProvider);
  final query = SupabaseConfig.client.from('stations').stream(primaryKey: ['id']);
  final filtered = showAll ? query : query.eq('verified', false);
  return filtered
      .order('created_at', ascending: true)
      .map((rows) => rows.map<Map<String, dynamic>>(Map<String, dynamic>.from).toList());
});
