import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/station.dart';
import '../core/map_utils.dart';
import '../core/app_colors.dart';
import '../core/supabase_client.dart';

class StationDetailScreen extends StatefulWidget {
  final Station station;
  const StationDetailScreen({super.key, required this.station});

  @override
  State<StationDetailScreen> createState() => _StationDetailScreenState();
}

class _StationDetailScreenState extends State<StationDetailScreen> {
  bool _isFavorite = false;

  Future<void> _launchMaps() async {
    await MapUtils.launchMaps(context, widget.station.latitude, widget.station.longitude);
  }

  Station get s => widget.station;

  Color get _statusColor => AppColors.statusColor(s.statut);
  String get _statusLabel => s.statut;

  @override
  Widget build(BuildContext context) {
    final user = SupabaseConfig.client.auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Hero Image ─────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.38,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background colour
                      Container(color: AppColors.surfaceDark),
                      // Gradient overlay
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
                      // Top buttons
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _CircleButton(
                                icon: Icons.arrow_back,
                                onTap: () => context.pop(),
                              ),
                              Row(
                                children: [
                                  _CircleButton(icon: Icons.share_outlined, onTap: () {}),
                                  const SizedBox(width: 10),
                                  _CircleButton(
                                    icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
                                    iconColor: _isFavorite ? Colors.red : Colors.white,
                                    onTap: () => setState(() => _isFavorite = !_isFavorite),
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

              // ── Content ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.backgroundDark,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                          _StatusBadge(label: _statusLabel, color: _statusColor),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Address
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: AppColors.primary, size: 18),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              s.address ?? 'Adresse inconnue',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Rating row
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          const Text('4.5', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text(
                            ' (128 avis)',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                          ),
                          const SizedBox(width: 12),
                          Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.textSecondary, shape: BoxShape.circle)),
                          const SizedBox(width: 12),
                          const Text('24h/24', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Price card
                      _SurfaceCard(
                        child: Row(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.currency_exchange, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Prix Standard',
                                      style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.2)),
                                  const Text('0.450 TND/kWh',
                                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            Text('Détails', style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Connectors
                      const Text('Connecteurs',
                          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
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
                            final pw = e.key < powers.length ? powers[e.key] : '22';
                            return _ConnectorCard(type: e.value, power: '$pw kW', available: e.key == 0);
                          }),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Action buttons
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

                      // Reviews header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Avis récents',
                              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                          Text('Voir tout', style: const TextStyle(color: AppColors.primary, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const _ReviewItem(
                        name: 'Ahmed B.',
                        time: 'il y a 2j',
                        rating: 5,
                        comment: 'Chargement rapide et station propre. Le café à côté est top.',
                      ),
                      const SizedBox(height: 12),
                      const _ReviewItem(
                        name: 'Sara M.',
                        time: 'il y a 1 sem',
                        rating: 4,
                        comment: 'Fonctionne bien mais un peu cher par rapport aux autres.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  const _CircleButton({required this.icon, required this.onTap, this.iconColor});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        shape: BoxShape.circle,
      ),
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
        Container(width: 7, height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
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
  const _ConnectorCard({required this.type, required this.power, required this.available});

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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(power, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              Icon(Icons.ev_station, color: Colors.white.withValues(alpha: 0.3), size: 18),
            ],
          ),
          const Spacer(),
          Text(type, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
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
  const _ActionButton({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 54,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    ),
  );
}

class _ReviewItem extends StatelessWidget {
  final String name;
  final String time;
  final int rating;
  final String comment;
  const _ReviewItem({required this.name, required this.time, required this.rating, required this.comment});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.surfaceDark,
          child: Text(name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(time, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
              Row(children: List.generate(5, (i) => Icon(
                i < rating ? Icons.star : Icons.star_border,
                color: Colors.amber, size: 13,
              ))),
              const SizedBox(height: 4),
              Text(comment, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
            ],
          ),
        ),
      ],
    ),
  );
}
