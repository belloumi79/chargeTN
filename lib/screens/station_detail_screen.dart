import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/station.dart';
import '../core/app_colors.dart';

class StationDetailScreen extends ConsumerStatefulWidget {
  final Station station;
  const StationDetailScreen({super.key, required this.station});

  @override
  ConsumerState<StationDetailScreen> createState() => _StationDetailScreenState();
}

class _StationDetailScreenState extends ConsumerState<StationDetailScreen> {
  bool _isArrivingSoon = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildReliabilityBadge(),
                  const SizedBox(height: 24),
                  _buildIntentionModule(),
                  const SizedBox(height: 24),
                  _buildSavingsCard(),
                  const SizedBox(height: 32),
                  const Text('Détails & Connecteurs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildTechGrid(),
                  const SizedBox(height: 32),
                  _buildPartnerRewards(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFF6C63FF),
        icon: const Icon(Icons.navigation, color: Colors.white),
        label: const Text('Y ALLER MAINTENANT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF6C63FF),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network('https://images.unsplash.com/photo-1593941707882-a5bba14938c7?q=80&w=1000', fit: BoxFit.cover),
            Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black38, Colors.transparent]))),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(widget.station.name ?? 'Borne de Recharge', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900))),
            const Icon(Icons.star_border, color: Color(0xFF6C63FF)),
          ],
        ),
        const SizedBox(height: 4),
        Text(widget.station.address ?? '', style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildReliabilityBadge() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF11B67F).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF11B67F).withValues(alpha: 0.2))),
      child: Row(
        children: [
          const Icon(Icons.verified, color: Color(0xFF11B67F)),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Indice de Confiance : 98%', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF11B67F))),
                Text('Confirmé par 12 conducteurs aujourd\'hui', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF11B67F)),
        ],
      ),
    );
  }

  Widget _buildIntentionModule() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          const Text('Planifiez votre arrivée', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _timeOption('J\'arrive'),
              _timeOption('Dans 15m'),
              _timeOption('Dans 30m'),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Informer la communauté évite l\'attente inutile.', style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _timeOption(String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _isArrivingSoon && label == 'Dans 15m',
      onSelected: (v) => setState(() => _isArrivingSoon = v),
      selectedColor: const Color(0xFF6C63FF).withValues(alpha: 0.2),
      labelStyle: TextStyle(color: _isArrivingSoon ? const Color(0xFF6C63FF) : Colors.black, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSavingsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)]), borderRadius: BorderRadius.circular(20)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💰 ÉCONOMIE TUNISIE', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          SizedBox(height: 8),
          Text('Ce plein vous coûte 80% moins cher que l\'essence Sans Plomb.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildTechGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.5,
      children: [
        _techChip(Icons.flash_on, '22 kW AC'),
        _techChip(Icons.settings_input_composite, 'Type 2'),
        _techChip(Icons.vpn_key, 'Libre Accès'),
        _techChip(Icons.cloud_done, 'Synchro Offline'),
      ],
    );
  }

  Widget _techChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6C63FF)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPartnerRewards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Récompenses à proximité', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.amber[200]!)),
          child: Row(
            children: [
              const Icon(Icons.local_cafe, color: Colors.orange),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Café Partenaire', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Présentez votre app pour -15% sur votre café.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('QR CODE', style: TextStyle(fontSize: 10))),
            ],
          ),
        ),
      ],
    );
  }
}
