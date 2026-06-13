import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/supabase_client.dart';
import '../core/app_colors.dart';
import '../models/report.dart';
import '../providers/admin_providers.dart';

class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Map<String, dynamic>>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _usersFuture = _fetchUsers();
  }

  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    final res = await SupabaseConfig.client
        .from('profiles')
        .select('id, email, display_name, is_admin, created_at')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Report actions ───────────────────────────────────────────────────────

  Future<void> _approveReport(Report report, {String? adminNotes}) async {
    try {
      await SupabaseConfig.client.rpc('approve_report', params: {
        'p_report_id': report.id,
        'p_admin_notes': adminNotes,
      });
      _snack('✅ Rapport approuvé — station mise à jour', Colors.green);
    } catch (e) {
      _snack('❌ Erreur: $e', Colors.red);
    }
  }

  Future<void> _rejectReport(Report report, {String? adminNotes}) async {
    try {
      await SupabaseConfig.client.rpc('reject_report', params: {
        'p_report_id': report.id,
        'p_admin_notes': adminNotes,
      });
      _snack('🚫 Rapport rejeté', Colors.orange);
    } catch (e) {
      _snack('❌ Erreur: $e', Colors.red);
    }
  }

  Future<void> _verifyStation(String id) async {
    try {
      await SupabaseConfig.client
          .from('stations')
          .update({'verified': true, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id);
      _snack('✅ Borne vérifiée et publiée', Colors.green);
    } catch (e) {
      _snack('❌ Erreur: $e', Colors.red);
    }
  }

  Future<void> _deleteStation(String id) async {
    final confirm = await _showConfirmDialog(
      'Supprimer la borne ?',
      'Cette action est irréversible et supprimera également tous les signalements associés.',
    );
    if (confirm != true) return;

    try {
      await SupabaseConfig.client.from('stations').delete().eq('id', id);
      _snack('🗑️ Borne supprimée', Colors.orange);
    } catch (e) {
      _snack('❌ Erreur: $e', Colors.red);
    }
  }

  Future<void> _deleteUser(String id) async {
    final confirm = await _showConfirmDialog(
      'Supprimer l\'utilisateur ?',
      'Cette action supprimera le profil de l\'utilisateur. Ses signalements seront conservés (attaches anonymisées ou supprimées selon la config DB).',
    );
    if (confirm != true) return;

    try {
      await SupabaseConfig.client.from('profiles').delete().eq('id', id);
      _snack('🗑️ Utilisateur supprimé', Colors.orange);
      if (mounted) {
        setState(() {
          _usersFuture = _fetchUsers();
        });
      }
    } catch (e) {
      _snack('❌ Erreur: $e', Colors.red);
    }
  }

  Future<void> _toggleAdminRole(Map<String, dynamic> user) async {
    try {
      final isAdmin = user['is_admin'] == true;
      await SupabaseConfig.client
          .from('profiles')
          .update({'is_admin': !isAdmin})
          .eq('id', user['id']);
      _snack(isAdmin ? '👤 Rôle admin retiré' : '⭐ Rôle admin accordé', Colors.blue);
      if (mounted) {
        setState(() {
          _usersFuture = _fetchUsers();
        });
      }
    } catch (e) {
      _snack('❌ Erreur: $e', Colors.red);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _snack(String m, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<bool?> _showConfirmDialog(String title, String content) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        content: Text(content, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showNotesDialog(String title, String action, Color actionColor) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Note pour l\'utilisateur (optionnel)',
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.backgroundDark,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: actionColor),
            onPressed: () => Navigator.pop(ctx, controller.text.isEmpty ? null : controller.text),
            child: Text(action),
          ),
        ],
      ),
    );
  }

  void _showReportVotes(String reportId, String type) {
    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder(
        future: SupabaseConfig.client
            .from('report_votes')
            .select('profiles(email, display_name)')
            .eq('report_id', reportId)
            .eq('vote_type', type),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final votes = snapshot.data as List<dynamic>? ?? [];
          return AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            title: Text(type == 'upvote' ? 'Confirmations' : 'Informations', style: const TextStyle(color: Colors.white)),
            content: SizedBox(
              width: double.maxFinite,
              child: votes.isEmpty
                  ? const Text('Aucun vote', style: TextStyle(color: Colors.white54))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: votes.length,
                                            itemBuilder: (ctx, i) {
                        final p = votes[i]['profiles'];
                        return ListTile(
                          title: Text(p['display_name'] ?? p['email'] ?? 'Utilisateur', style: const TextStyle(color: Colors.white)),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
            ],
          );
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text('Administration', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.flag_outlined, size: 18), text: 'Signalements'),
            Tab(icon: Icon(Icons.ev_station, size: 18), text: 'Bornes'),
            Tab(icon: Icon(Icons.people_outline, size: 18), text: 'Comptes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildReportsTab(), _buildStationsTab(), _buildUsersTab()],
      ),
    );
  }

  // ── Tab 1: Reports ────────────────────────────────────────────────────────

  Widget _buildReportsTab() {
    final reportsAsync = ref.watch(pendingReportsProvider);
    final reports = reportsAsync.maybeWhen(data: (d) => d, orElse: () => const <Report>[]);
    if (reportsAsync.isLoading && reports.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (reports.isEmpty) {
      return _buildEmpty('✅ Aucun signalement en attente', Icons.check_circle_outline);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      itemBuilder: (context, i) => _AdminReportCard(
        report: reports[i],
        onApprove: () async {
          final notes = await _showNotesDialog('Approuver le signalement', 'Approuver', Colors.green);
          if (mounted) await _approveReport(reports[i], adminNotes: notes);
        },
        onReject: () async {
          final notes = await _showNotesDialog('Rejeter le signalement', 'Rejeter', Colors.red);
          if (mounted) await _rejectReport(reports[i], adminNotes: notes);
        },
        onShowVotes: (type) => _showReportVotes(reports[i].id, type),
      ),
    );
  }

  // ── Tab 2: Stations ───────────────────────────────────────────────────────

  Widget _buildStationsTab() {
    final showAll = ref.watch(showAllStationsProvider);
    final stationsAsync = ref.watch(adminStationsProvider);
    final stations = stationsAsync.maybeWhen(
      data: (d) => d,
      orElse: () => const <Map<String, dynamic>>[],
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Text('Afficher:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('À vérifier', style: TextStyle(fontSize: 12)),
                selected: !showAll,
                onSelected: (val) {
                  if (val) {
                    ref.read(showAllStationsProvider.notifier).set(false);
                  }
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                labelStyle: TextStyle(color: !showAll ? AppColors.primary : Colors.white38),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Toutes', style: TextStyle(fontSize: 12)),
                selected: showAll,
                onSelected: (val) {
                  if (val) {
                    ref.read(showAllStationsProvider.notifier).set(true);
                  }
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                labelStyle: TextStyle(color: showAll ? AppColors.primary : Colors.white38),
              ),
            ],
          ),
        ),
        Expanded(
          child: stationsAsync.isLoading && stations.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : stations.isEmpty
                  ? _buildEmpty(
                      showAll ? 'Aucune borne trouvée' : '✅ Aucune borne à vérifier',
                      Icons.electric_bolt_outlined,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: stations.length,
                      itemBuilder: (context, i) => _StationAdminCard(
                        station: stations[i],
                        onVerify: () => _verifyStation(stations[i]['id']),
                        onDelete: () => _deleteStation(stations[i]['id']),
                      ),
                    ),
        ),
      ],
    );
  }

  // ── Tab 3: Users ──────────────────────────────────────────────────────────

  Widget _buildUsersTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _usersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return _buildEmpty('Aucun utilisateur trouvé', Icons.people_outline);
        }
        return RefreshIndicator(
          onRefresh: () async => setState(() => _usersFuture = _fetchUsers()),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, i) => _UserCard(
              user: users[i],
              onToggleAdmin: () => _toggleAdminRole(users[i]),
              onDelete: () => _deleteUser(users[i]['id']),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmpty(String t, IconData icon) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.white10),
            const SizedBox(height: 16),
            Text(t, style: const TextStyle(color: Colors.white38, fontSize: 15)),
          ],
        ),
      );
}

// ─────────────────────────────────────── Admin Report Card ───────────────────

class _AdminReportCard extends StatelessWidget {
  final Report report;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final Function(String type) onShowVotes;

  const _AdminReportCard({
    required this.report, 
    required this.onApprove, 
    required this.onReject,
    required this.onShowVotes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Source
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.flag, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text(
                          report.stationName ?? 'Station inconnue',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 10, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Par: ${report.userEmail ?? 'Utilisateur'}',
                              style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Text(
                          report.stationAddress ?? '',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('EN ATTENTE',
                      style: TextStyle(color: Colors.orange, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reporter
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      report.userEmail ?? 'Utilisateur inconnu',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const Spacer(),
                    Text(_formatDate(report.createdAt),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 10),

                // Status change
                if (report.newStatut != null || report.newEncombrement != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundDark,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        if (report.newStatut != null)
                          _StatusRow(
                            label: 'Statut',
                            current: report.currentStatut ?? '?',
                            reported: report.newStatut!,
                          ),
                        if (report.newStatut != null && report.newEncombrement != null)
                          const SizedBox(height: 6),
                        if (report.newEncombrement != null)
                          _StatusRow(label: 'Encombrement', current: '?', reported: report.newEncombrement!),
                      ],
                    ),
                  ),

                if (report.notes != null && report.notes!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.15)),
                    ),
                    child: Text('"${report.notes}"',
                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic)),
                  ),
                ],

                if (report.imageUrl != null) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      report.imageUrl!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, s) => Container(
                        height: 80,
                        color: Colors.black26,
                        child: const Center(child: Icon(Icons.broken_image, color: Colors.white30)),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 10),
                Row(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onShowVotes('upvote'),
                      child: Row(
                        children: [
                          Icon(Icons.thumb_up_alt, size: 13, color: Colors.green.withValues(alpha: 0.8)),
                          const SizedBox(width: 4),
                          Text('${report.upvotes} confirment',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onShowVotes('downvote'),
                      child: Row(
                        children: [
                          Icon(Icons.thumb_down_alt, size: 13, color: Colors.red.withValues(alpha: 0.8)),
                          const SizedBox(width: 4),
                          Text('${report.downvotes} infirment',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _AdminActionBtn(label: 'Rejeter', icon: Icons.close, color: Colors.red, onTap: onReject)),
                    const SizedBox(width: 10),
                    Expanded(child: _AdminActionBtn(label: 'Approuver', icon: Icons.check, color: Colors.green, onTap: onApprove)),
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
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays}j';
  }
}

class _StatusRow extends StatelessWidget {
  final String label, current, reported;
  const _StatusRow({required this.label, required this.current, required this.reported});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          Text(current, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward, size: 12, color: Colors.orange),
          ),
          Text(reported, style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      );
}

// ─────────────────────────────────── Station Verification Card ───────────────

// ─────────────────────────────────── Station Admin Card ───────────────

class _StationAdminCard extends StatelessWidget {
  final Map<String, dynamic> station;
  final VoidCallback onVerify;
  final VoidCallback onDelete;

  const _StationAdminCard({required this.station, required this.onVerify, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isVerified = station['verified'] == true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isVerified 
              ? Colors.white.withValues(alpha: 0.05) 
              : AppColors.primary.withValues(alpha: 0.3)
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isVerified 
                  ? Colors.white.withValues(alpha: 0.02) 
                  : AppColors.primary.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.ev_station, 
                    color: isVerified ? AppColors.textSecondary : AppColors.primary, 
                    size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(station['name'] ?? 'Nouvelle Borne',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isVerified 
                        ? Colors.green.withValues(alpha: 0.2) 
                        : AppColors.primary.withValues(alpha: 0.2), 
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: Text(isVerified ? 'VÉRIFIÉE' : 'À VÉRIFIER',
                      style: TextStyle(
                        color: isVerified ? Colors.green : AppColors.primary, 
                        fontSize: 9, 
                        fontWeight: FontWeight.bold
                      )),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (station['address'] != null)
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(child: Text(station['address'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
                    ],
                  ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    if (station['type_prise'] != null)
                      ...(station['type_prise'] as List).map((t) => _Chip(t.toString(), Colors.blue)),
                    if (station['puissance_kw'] != null)
                      ...(station['puissance_kw'] as List).map((p) => _Chip('$p kW', AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _AdminActionBtn(
                        label: 'Supprimer', 
                        icon: Icons.delete_outline, 
                        color: Colors.red, 
                        onTap: onDelete
                      )
                    ),
                    if (!isVerified) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: _AdminActionBtn(
                          label: 'Publier', 
                          icon: Icons.verified_outlined, 
                          color: AppColors.primary, 
                          onTap: onVerify
                        )
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────── User Card ───────────────────────

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onToggleAdmin;
  final VoidCallback onDelete;

  const _UserCard({required this.user, required this.onToggleAdmin, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isAdmin = user['is_admin'] == true;
    final email = user['email'] ?? 'Email inconnu';
    final displayName = user['display_name'];
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAdmin ? AppColors.primary.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: isAdmin ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceDark,
            child: Text(initial,
                style: TextStyle(color: isAdmin ? AppColors.primary : Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName ?? email.split('@')[0],
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(email,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (isAdmin) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
              child: const Text('ADMIN',
                  style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
          const SizedBox(width: 8),
          IconButton(
            onPressed: onToggleAdmin,
            icon: Icon(isAdmin ? Icons.star : Icons.star_border,
                color: isAdmin ? AppColors.primary : Colors.white30),
            tooltip: isAdmin ? 'Retirer admin' : 'Rendre admin',
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Supprimer l\'utilisateur',
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────── Shared Widgets ──────────────────────

class _AdminActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AdminActionBtn({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      );
}
