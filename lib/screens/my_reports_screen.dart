import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/supabase_client.dart';
import '../core/app_colors.dart';
import '../models/report.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  late Stream<List<Report>> _stream;

  @override
  void initState() {
    super.initState();
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      _stream = const Stream.empty();
      return;
    }
    // Real-time stream of the user's own reports
    _stream = SupabaseConfig.client
        .from('reports')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .map((maps) => maps.map((e) => Report.fromJson(e)).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text('Mes signalements',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: AppColors.primary, size: 8),
                SizedBox(width: 5),
                Text('Temps réel',
                    style:
                        TextStyle(color: AppColors.primary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Report>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Erreur: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)),
            );
          }

          final reports = snapshot.data ?? [];

          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 64, color: Colors.white10),
                  const SizedBox(height: 16),
                  const Text('Vous n\'avez pas encore de signalements',
                      style: TextStyle(color: Colors.white38, fontSize: 14)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/home'),
                    icon: const Icon(Icons.ev_station),
                    label: const Text('Voir les bornes'),
                  ),
                ],
              ),
            );
          }

          // Group by status for quick overview
          final pending =
              reports.where((r) => r.status == 'pending').length;
          final approved =
              reports.where((r) => r.status == 'approved').length;
          final rejected =
              reports.where((r) => r.status == 'rejected').length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary cards
              Row(
                children: [
                  _SummaryCard(
                      label: 'En attente',
                      count: pending,
                      color: Colors.orange),
                  const SizedBox(width: 8),
                  _SummaryCard(
                      label: 'Approuvés',
                      count: approved,
                      color: Colors.green),
                  const SizedBox(width: 8),
                  _SummaryCard(
                      label: 'Rejetés',
                      count: rejected,
                      color: Colors.red),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Historique',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...reports.map((r) => _ReportStatusCard(report: r)),
            ],
          );
        },
      ),
    );
  }
}

// ── Summary card ────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SummaryCard(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                    color: color,
                    fontSize: 24,
                    fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(color: color.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}

// ── Report status card ───────────────────────────────────────────────────────

class _ReportStatusCard extends StatelessWidget {
  final Report report;

  const _ReportStatusCard({required this.report});

  Color get _statusColor {
    switch (report.status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData get _statusIcon {
    switch (report.status) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.hourglass_empty;
    }
  }

  String get _statusText => Report.statusLabel(report.status);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _statusColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status header ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(_statusIcon, color: _statusColor, size: 16),
                const SizedBox(width: 8),
                Text(
                  _statusText,
                  style: TextStyle(
                      color: _statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
                const Spacer(),
                Text(
                  _formatDate(report.createdAt),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),

          // ── Body ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // What was reported
                if (report.newStatut != null)
                  _InfoRow(
                    icon: Icons.info_outline,
                    label: 'Statut signalé',
                    value: report.newStatut!,
                    valueColor: _statusColor,
                  ),
                if (report.newEncombrement != null)
                  _InfoRow(
                    icon: Icons.traffic,
                    label: 'Encombrement',
                    value: report.newEncombrement!,
                    valueColor: Colors.blue,
                  ),
                if (report.notes != null && report.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '"${report.notes}"',
                      style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontStyle: FontStyle.italic),
                    ),
                  ),

                // Image thumbnail
                if (report.imageUrl != null) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      report.imageUrl!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, s) => Container(
                        height: 60,
                        color: Colors.black26,
                        child: const Center(
                            child: Icon(Icons.image_not_supported,
                                color: Colors.white30)),
                      ),
                    ),
                  ),
                ],

                // Admin response (if any)
                if (report.adminNotes != null &&
                    report.adminNotes!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: _statusColor.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.admin_panel_settings,
                                size: 12, color: _statusColor),
                            const SizedBox(width: 6),
                            Text(
                              'Note de l\'administrateur',
                              style: TextStyle(
                                  color: _statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          report.adminNotes!,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],

                // Community votes
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.people_outline,
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.3)),
                    const SizedBox(width: 6),
                    Text(
                      '${report.upvotes} confirment · ${report.downvotes} infirment',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(dt.toLocal());
    } catch (e, stack) {
      debugPrint('[MyReportsScreen] _formatDate($dt) failed: $e');
      debugPrint(stack.toString());
      return dt.toString();
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.value,
      required this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Icon(icon, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: valueColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(value,
                  style: TextStyle(
                      color: valueColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
}
