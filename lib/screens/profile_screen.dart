import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_colors.dart';
import '../core/supabase_client.dart';
import '../widgets/app_bottom_nav.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = SupabaseConfig.client.auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Mon Profil', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: user == null ? _buildGuestView(context) : _buildUserView(context, user),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 4,
        onTap: (i) {
          if (i == 4) return;
          if (i == 0) context.go('/home');
          if (i == 1) context.go('/search');
          if (i == 2) context.go('/favs');
          if (i == 3) context.go('/social');
        },
      ),
    );
  }

  Widget _buildGuestView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            const Text('Connectez-vous pour voir votre profil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Gagnez des points Expert EV en participant à la communauté.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push('/auth'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
                child: const Text('SE CONNECTER'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserView(BuildContext context, dynamic user) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email?.split('@').first ?? 'Utilisateur', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(user.email ?? '', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                _buildExpertBadge(),
              ],
            ),
          ],
        ),
        const SizedBox(height: 40),
        
        // Point 5: Gamification Stats
        _buildGamificationCard(),
        
        const SizedBox(height: 32),
        const Text('Mes Activités', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _profileItem(Icons.history, 'Historique de charge'),
        _profileItem(Icons.ev_station, 'Mes bornes déclarées'),
        _profileItem(Icons.star_outline, 'Mes avis partagés'),
        
        const SizedBox(height: 32),
        const Text('Économies Réalisées', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildEconomySummary(),
        
        const SizedBox(height: 40),
        TextButton.icon(
          onPressed: () async {
            await SupabaseConfig.client.auth.signOut();
            context.go('/auth');
          },
          icon: const Icon(Icons.logout, color: Colors.red),
          label: const Text('Se déconnecter', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  Widget _buildExpertBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFF11B67F).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: Color(0xFF11B67F), size: 14),
          SizedBox(width: 4),
          Text('Expert EV - Niv. 4', style: TextStyle(color: Color(0xFF11B67F), fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildGamificationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF6C63FF), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: const Color(0xFF6C63FF).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 10))]),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Points de Contribution', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('1,250 PTS', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: const Icon(Icons.emoji_events, color: Colors.white, size: 30),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const LinearProgressIndicator(value: 0.75, backgroundColor: Colors.white24, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Niveau 4', style: TextStyle(color: Colors.white70, fontSize: 11)),
              Text('250 pts restants pour le Niv. 5', style: TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEconomySummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('CO2 Évité', '1.2 Tonnes'),
          _statItem('Économie', '4,200 DT'),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF6C63FF))),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _profileItem(IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () {},
    );
  }
}
