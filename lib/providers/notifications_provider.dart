import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase_client.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime createdAt;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    required this.isRead,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> j) => NotificationItem(
        id: j['id'],
        title: j['title'],
        body: j['body'],
        type: j['type'] ?? 'info',
        createdAt: DateTime.parse(j['created_at']),
        isRead: j['is_read'] ?? false,
      );
}

final notificationsProvider = StreamProvider<List<NotificationItem>>((ref) {
  final user = SupabaseConfig.client.auth.currentUser;
  if (user == null) return Stream.value([]);

  return SupabaseConfig.client
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id)
      .order('created_at', ascending: false)
      .map((maps) => maps.map((e) => NotificationItem.fromJson(e)).toList());
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider).value ?? [];
  return notifications.where((n) => !n.isRead).length;
});
