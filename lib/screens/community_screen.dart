import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_bottom_nav.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentTab = 0; // 0: News, 1: Help, 2: Chat, 3: Avis, 4: Profile Prompt

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C63FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('Communauté iCharge', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => context.go('/home')),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: _buildCurrentTab(),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 3,
        onTap: (i) {
          if (i == 3) return;
          if (i == 0) context.go('/home');
          if (i == 1) context.go('/search');
          if (i == 2) context.go('/favs');
          if (i == 4) context.go('/profile');
        },
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentTab) {
      case 0: return _buildNewsSection();
      case 1: return _buildHelpSection();
      case 2: return _buildChatSection();
      case 3: return _buildAvisSection();
      case 4: return _buildProfilePrompt();
      default: return _buildNewsSection();
    }
  }

  Widget _buildTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _tabItem(0, 'Actualités', Icons.newspaper),
          _tabItem(1, 'Help', Icons.help_center),
          _tabItem(2, 'Chat', Icons.chat),
          _tabItem(3, 'Avis', Icons.rate_review),
          _tabItem(4, 'Profile', Icons.person),
        ],
      ),
    );
  }

  Widget _tabItem(int index, String label, IconData icon) {
    final active = _currentTab == index;
    return GestureDetector(
      onTap: () => setState(() => _currentTab = index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Icon(icon, color: active ? const Color(0xFF6C63FF) : Colors.grey),
            Text(label, style: TextStyle(color: active ? const Color(0xFF6C63FF) : Colors.grey, fontSize: 12)),
            if (active)
              Container(margin: const EdgeInsets.only(top: 4), height: 2, width: 20, color: const Color(0xFF6C63FF)),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsSection() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Actualités VE', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const Text('Restez informé des dernières nouveautés', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 20),
        _newsCard(
          'Voitures électriques: nouveau plan pour le secteur public tunisien',
          'La Tunisie a mis en place un nouveau programme visant à promouvoir...',
          '2026-06-11',
          'https://images.unsplash.com/photo-1593941707882-a5bba14938c7?q=80&w=1000',
        ),
        _newsCard(
          'CHERY ACCÉLÈRE EN TUNISIE AVEC UNE OFFENSIVE HYBRIDE',
          'La marque Chery lance de nouveaux modèles hybrides rechargeables...',
          '2026-06-11',
          'https://images.unsplash.com/photo-1621360841013-c7683c659ec6?q=80&w=1000',
        ),
      ],
    );
  }

  Widget _newsCard(String title, String summary, String date, String imgUrl) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(imgUrl, height: 180, width: double.infinity, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(4)),
                      child: const Text('INFO', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(summary, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {},
                  child: const Row(
                    children: [
                      Text('Lire la suite', style: TextStyle(color: Color(0xFF6C63FF))),
                      Icon(Icons.arrow_forward, size: 16, color: Color(0xFF6C63FF)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvisSection() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Avis & Expériences', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text('Partagez vos photos et avis VE', style: TextStyle(color: Colors.grey)),
              ],
            ),
            FloatingActionButton.small(
              onPressed: () {},
              backgroundColor: const Color(0xFF11B67F),
              child: const Icon(Icons.add_photo_alternate, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          decoration: InputDecoration(
            hintText: 'Rechercher un modèle de voiture...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 20),
        _avisCard('Utilisateur Anonyme', 'BAKO BEE', 'https://images.unsplash.com/photo-1541899481282-d53bffe3c35d?q=80&w=1000', 0, 0, 0),
        _avisCard('sid', 'chery tiggo 7', 'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?q=80&w=1000', 4, 0, 1),
      ],
    );
  }

  Widget _avisCard(String user, String car, String img, int likes, int dislikes, int comments) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(car.toUpperCase(), style: const TextStyle(color: Color(0xFF6C63FF), fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(img, height: 200, width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _actionIcon(Icons.thumb_up_alt_outlined, likes, Colors.blue),
                const SizedBox(width: 16),
                _actionIcon(Icons.thumb_down_alt_outlined, dislikes, Colors.red),
                const Spacer(),
                _actionIcon(Icons.comment_outlined, comments, Colors.grey),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _actionIcon(IconData icon, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildProfilePrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
              child: const Icon(Icons.flash_on, size: 80, color: Color(0xFF11B67F)),
            ),
            const SizedBox(height: 40),
            const Text('Rejoignez iCharge', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            const Text(
              'Connectez-vous pour partager votre borne, vendre votre véhicule et interagir avec la communauté.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => _showLoginDialog(context),
                icon: const Icon(Icons.login),
                label: const Text('Se Connecter / S\'inscrire'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Connexion', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(hintText: 'Email', prefixIcon: const Icon(Icons.email_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 16),
            TextField(obscureText: true, decoration: InputDecoration(hintText: 'Mot de passe', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: const Icon(Icons.visibility_off), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: () {}, child: const Text('S\'inscrire', style: TextStyle(color: Color(0xFF6C63FF)))),
                TextButton(onPressed: () {}, child: const Text('Mot de passe oublié ?', style: TextStyle(color: Colors.grey, fontSize: 12))),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler', style: TextStyle(color: Colors.green))),
          ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)), child: const Text('Se connecter')),
        ],
      ),
    );
  }

  Widget _buildHelpSection() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF4B39EF)]),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.search, color: Colors.white, size: 30),
              const SizedBox(height: 12),
              const Text('Centre d\'Aide EV', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const Text('Trouvez des solutions aux problèmes fréquents et diagnostics.', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          decoration: InputDecoration(
            hintText: 'Rechercher un problème...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 24),
        _helpTopic('La recharge ne démarre pas', 'Le câble est branché mais la charge ne commence pas.', Icons.ev_station),
        _helpTopic('Port de charge bloqué', 'Le clapet ne s\'ouvre pas ou le connecteur est coincé.', Icons.lock_open),
        _helpTopic('Recharge qui s\'interrompt', 'La charge s\'arrête prématurément avant d\'atteindre 100%.', Icons.error_outline),
        _helpTopic('AC ne refroidit plus', 'Air tiède malgré l\'activation de la climatisation.', Icons.ac_unit),
      ],
    );
  }

  Widget _helpTopic(String title, String desc, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: Colors.red)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(desc),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildChatSection() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _chatBubble('sid', 'Bienvenue à tous sur la Community iCharge TN ! Ici, on échange, on s\'entraide...', false),
              _chatBubble('Anis Ben Ammar', 'Bonjour, j\'ai entendu dire qu\'une borne est installée à Kelibia...', true),
              _chatBubble('sid', 'oui en cours de instalation mais ne pas en cours fonctionnel', false),
            ],
          ),
        ),
        _buildChatInput(),
      ],
    );
  }

  Widget _chatBubble(String name, String message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) const CircleAvatar(radius: 18, child: Icon(Icons.person, size: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFF6C63FF) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(message, style: TextStyle(color: isMe ? Colors.white : Colors.black)),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 10),
          if (isMe) const CircleAvatar(radius: 18, child: Icon(Icons.person, size: 20)),
        ],
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(24)),
              child: const TextField(
                decoration: InputDecoration(hintText: 'Connectez-vous pour pa...', border: InputBorder.none),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const CircleAvatar(backgroundColor: Color(0xFF6C63FF), child: Icon(Icons.arrow_forward, color: Colors.white)),
        ],
      ),
    );
  }
}
