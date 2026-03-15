import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../models/station.dart';
import '../models/report.dart';
import '../core/map_utils.dart';
import '../core/app_colors.dart';
import '../core/supabase_client.dart';
import '../providers/favorites_provider.dart';

class StationDetailScreen extends ConsumerStatefulWidget {
  final Station station;
  const StationDetailScreen({super.key, required this.station});

  @override
  ConsumerState<StationDetailScreen> createState() =>
      _StationDetailScreenState();
}

class _StationDetailScreenState extends ConsumerState<StationDetailScreen> {
  late Stream<Station> _stationStream;
  late Stream<List<Report>> _reportsStream;

  @override
  void initState() {
    super.initState();
    _stationStream = SupabaseConfig.client
        .from('stations')
        .stream(primaryKey: ['id'])
        .eq('id', widget.station.id)
        .map((maps) =>
            maps.isEmpty ? widget.station : Station.fromJson(maps.first));

    _reportsStream = SupabaseConfig.client
        .from('reports_with_votes')
        .stream(primaryKey: ['id'])
        .eq('station_id', widget.station.id)
        .order('created_at', ascending: false)
        .map((maps) => maps.map((e) => Report.fromJson(e)).toList());
  }

  Future<void> _launchMaps() async {
    await MapUtils.launchMaps(context, widget.station);
  }

  void _shareStation() {
    SharePlus.instance.share(ShareParams(
      text:
          'Découvrez la borne ${widget.station.name ?? "de recharge"} sur Charge Tn !\n\n📍 Adresse: ${widget.station.address ?? "Non spécifiée"}\n\nTéléchargez l\'app Charge Tn pour plus d\'informations.',
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseConfig.client.auth.currentUser;
    final favoritesAsync = ref.watch(favoritesProvider);
    final isFavorite = favoritesAsync.value?.contains(widget.station.id) ?? false;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: StreamBuilder<Station>(
        stream: _stationStream,
        initialData: widget.station,
        builder: (context, snapshot) {
          final s = snapshot.data ?? widget.station;
          final statusColor = AppColors.statusColor(s.statut);
          final statusLabel = s.statut;

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // ── Hero Image ──────────────────────────────────────
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.38,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(color: AppColors.surfaceDark),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.6),
                                  Colors.transparent,
                                  AppColors.backgroundDark,
                                ],
                              ),
                            ),
                          ),
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _CircleButton(
                                    icon: Icons.arrow_back,
                                    onTap: () => context.pop(),
                                  ),
                                  Row(
                                    children: [
                                      _CircleButton(
                                        icon: Icons.share_outlined,
                                        onTap: _shareStation,
                                      ),
                                      const SizedBox(width: 10),
                                      _CircleButton(
                                        icon: isFavorite
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        iconColor: isFavorite
                                            ? Colors.red
                                            : Colors.white,
                                        onTap: () => ref
                                            .read(favoritesProvider.notifier)
                                            .toggleFavorite(widget.station.id),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Content ─────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.backgroundDark,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title + Status
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  s.name ?? 'Station inconnue',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              _StatusBadge(
                                  label: statusLabel, color: statusColor),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Address
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  color: AppColors.primary, size: 18),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  s.address ?? 'Adresse inconnue',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Rating row
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              const Text(
                                '4.5',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                ' (128 avis)',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 12),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                    color: AppColors.textSecondary,
                                    shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                '24h/24',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Price card
                          _SurfaceCard(
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.currency_exchange,
                                      color: AppColors.primary, size: 20),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'PRIX STANDARD',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      Text(
                                        '0.450 TND/kWh',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Text(
                                  'Détails',
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Connectors
                          const Text(
                            'Connecteurs',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 10),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.6,
                            children: [
                              ...s.typePrise.asMap().entries.map((e) {
                                final powers = s.puissanceKw;
                                final pw =
                                    e.key < powers.length ? powers[e.key] : '22';
                                return _ConnectorCard(
                                  type: e.value,
                                  power: '$pw kW',
                                  available: e.key == 0,
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: _ActionButton(
                                  label: 'Naviguer',
                                  icon: Icons.navigation,
                                  color: AppColors.primary,
                                  onTap: _launchMaps,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ActionButton(
                                  label: 'Signaler',
                                  icon: Icons.report_problem_outlined,
                                  color: Colors.blue,
                                  onTap: () {
                                    if (user != null) {
                                      context.push('/report', extra: s);
                                    } else {
                                      context.push('/auth');
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Community Reports Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Signalements Communautaires',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'En direct',
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Real-time reports
                          StreamBuilder<List<Report>>(
                            stream: _reportsStream,
                            builder: (context, reportSnap) {
                              if (reportSnap.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              final reports = reportSnap.data ?? [];
                              if (reports.isEmpty) {
                                return const Padding(
                                  padding:
                                      EdgeInsets.symmetric(vertical: 20),
                                  child: Center(
                                    child: Text(
                                      'Aucun signalement. La voie est libre !',
                                      style: TextStyle(
                                          color: AppColors.textSecondary),
                                    ),
                                  ),
                                );
                              }
                              return Column(
                                children: reports
                                    .map((r) =>
                                        _CommunityReportItem(report: r))
                                    .toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────── Widget classes ────────────

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  const _CircleButton(
      {required this.icon, required this.onTap, this.iconColor});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle),
          child: Icon(icon, color: iconColor ?? Colors.white, size: 22),
        ),
      );
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 7,
                height: 7,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  const _SurfaceCard({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: child,
      );
}

class _ConnectorCard extends StatelessWidget {
  final String type;
  final String power;
  final bool available;
  const _ConnectorCard(
      {required this.type, required this.power, required this.available});

  @override
  Widget build(BuildContext context) {
    final color = available ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(power,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
              Icon(Icons.ev_station,
                  color: Colors.white.withValues(alpha: 0.3), size: 18),
            ],
          ),
          const Spacer(),
          Text(type,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          Text(available ? 'Disponible' : 'Occupé',
              style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
}

// ── Community Report Item (Waze-style) ──────────────────────────────────────

class _CommunityReportItem extends StatelessWidget {
  final Report report;
  const _CommunityReportItem({required this.report});

  Future<void> _upvote(BuildContext context) async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Connectez-vous pour voter'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    await SupabaseConfig.client
        .rpc('toggle_report_vote', params: {'p_report_id': report.id, 'p_vote_type': 'upvote'});
  }

  Future<void> _downvote(BuildContext context) async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Connectez-vous pour voter'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    await SupabaseConfig.client
        .rpc('toggle_report_vote', params: {'p_report_id': report.id, 'p_vote_type': 'downvote'});
  }

  void _showVoters(BuildContext context, String type) async {
    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder(
        future: SupabaseConfig.client
            .from('report_votes')
            .select('user_id, profiles(email, display_name)')
            .eq('report_id', report.id)
            .eq('vote_type', type),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final voters = (snapshot.data as List? ?? []);
          return AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            title: Text(type == 'upvote' ? 'Confirmations 👍' : 'Infirmations 👎',
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            content: SizedBox(
              width: double.maxFinite,
              child: voters.isEmpty
                  ? const Text('Aucun vote pour le moment', style: TextStyle(color: Colors.white38))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: voters.length,
                      itemBuilder: (context, i) {
                        final email = voters[i]['profiles']?['email'] ?? 'Utilisateur';
                        return ListTile(
                          leading: const Icon(Icons.person, color: AppColors.textSecondary, size: 20),
                          title: Text(email, style: const TextStyle(color: Colors.white, fontSize: 13)),
                        );
                      },
                    ),
            ),
          );
        },
      ),
    );
  }

  Color _statusColor(String? statut) {
    switch (statut?.toLowerCase()) {
      case 'disponible':
        return Colors.green;
      case 'occupé':
        return Colors.orange;
      case 'en panne':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUpvoted = report.myVote == 'upvote';
    final isDownvoted = report.myVote == 'downvote';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUpvoted
              ? Colors.green.withValues(alpha: 0.3)
              : isDownvoted
                  ? Colors.red.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            child: const Icon(Icons.person, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Rapport Communautaire',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const Spacer(),
                    if (report.imageUrl != null)
                      const Icon(Icons.image_outlined, size: 14, color: AppColors.primary),
                  ],
                ),
                const SizedBox(height: 4),
                if (report.newStatut != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor(report.newStatut).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Statut signalé: ${report.newStatut}',
                      style: TextStyle(
                          color: _statusColor(report.newStatut),
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                if (report.notes != null && report.notes!.isNotEmpty)
                  Text(
                    report.notes!,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _upvote(context),
                      onLongPress: () => _showVoters(context, 'upvote'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isUpvoted
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.green.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: isUpvoted ? Colors.green : Colors.transparent),
                        ),
                        child: Row(
                          children: [
                            Icon(isUpvoted ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                                size: 13, color: Colors.green),
                            const SizedBox(width: 4),
                            Text('${report.upvotes}',
                                style: const TextStyle(color: Colors.green, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _downvote(context),
                      onLongPress: () => _showVoters(context, 'downvote'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDownvoted
                              ? Colors.red.withValues(alpha: 0.2)
                              : Colors.red.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: isDownvoted ? Colors.red : Colors.transparent),
                        ),
                        child: Row(
                          children: [
                            Icon(isDownvoted ? Icons.thumb_down_alt : Icons.thumb_down_alt_outlined,
                                size: 13, color: Colors.red),
                            const SizedBox(width: 4),
                            Text('${report.downvotes}',
                                style: const TextStyle(color: Colors.red, fontSize: 12)),
                          ],
                        ),
                      ),
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
}
