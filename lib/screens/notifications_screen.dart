import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_colors.dart';
import '../widgets/responsive_wrapper.dart';
import 'package:intl/intl.dart';
import '../providers/notifications_provider.dart';
import '../core/supabase_client.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _markAsRead(String id) async {
    try {
      await SupabaseConfig.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
    } catch (_) {}
  }

  Future<void> _markAllAsRead(List<NotificationItem> notifications) async {
    try {
      final unreadIds = notifications.where((n) => !n.isRead).map((n) => n.id).toList();
      if (unreadIds.isEmpty) return;
      
      await SupabaseConfig.client
          .from('notifications')
          .update({'is_read': true})
          .inFilter('id', unreadIds);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          notificationsAsync.when(
            data: (list) => list.any((n) => !n.isRead) 
              ? TextButton(
                  onPressed: () => _markAllAsRead(list),
                  child: const Text('Tout lire', style: TextStyle(color: AppColors.primary)),
                )
              : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (e, s) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: ResponsiveWrapper(
        child: notificationsAsync.when(
          data: (notifications) => notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.white10),
                      SizedBox(height: 16),
                      Text('Aucune notification', style: TextStyle(color: Colors.white38)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, i) {
                    final n = notifications[i];
                    return _NotificationTile(
                      notification: n,
                      onTap: () => _markAsRead(n.id),
                    );
                  },
                ),
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, s) => Center(child: Text('Erreur: $e', style: const TextStyle(color: Colors.redAccent))),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isRead = notification.isRead;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isRead ? AppColors.surfaceDark.withValues(alpha: 0.5) : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: isRead ? 0.02 : 0.08)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          title: Text(notification.title,
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                  fontSize: 15)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Text(notification.body, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Text(DateFormat('dd MMM, HH:mm', 'fr').format(notification.createdAt),
                  style: const TextStyle(color: Colors.white24, fontSize: 11)),
            ],
          ),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _getColor(notification.type).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_getIcon(notification.type), color: _getColor(notification.type), size: 18),
          ),
        ),
      ),
    );
  }

  Color _getColor(String type) {
    switch (type) {
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      case 'error':
        return Colors.redAccent;
      default:
        return AppColors.primary;
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'success':
        return Icons.check_circle_outline;
      case 'warning':
        return Icons.error_outline;
      case 'info':
        return Icons.info_outline;
      case 'error':
        return Icons.cancel_outlined;
      default:
        return Icons.notifications_none;
    }
  }
}
