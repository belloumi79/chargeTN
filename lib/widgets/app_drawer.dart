import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.help_outline,
                  label: 'Help',
                  onTap: () {},
                ),
                _buildDrawerItem(
                  icon: Icons.person_outline,
                  label: 'Profile',
                  onTap: () => context.push('/profile'),
                ),
                _buildDrawerItem(
                  icon: Icons.chat_bubble_outline,
                  label: 'Chat',
                  onTap: () => context.push('/social'),
                ),
                _buildDrawerItem(
                  icon: Icons.report_problem_outlined,
                  label: 'Problem',
                  onTap: () => context.push('/my_reports'),
                ),
                _buildDrawerItem(
                  icon: Icons.directions_car_outlined,
                  label: 'Voitures',
                  onTap: () => context.push('/marketplace'),
                ),
                _buildDrawerItem(
                  icon: Icons.newspaper_outlined,
                  label: 'News',
                  onTap: () {},
                ),
                _buildDrawerItem(
                  icon: Icons.rate_review_outlined,
                  label: 'Avis',
                  onTap: () {},
                ),
              ],
            ),
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.policy_outlined,
            label: 'Politique de confidentialité',
            onTap: () {},
            small: true,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return DrawerHeader(
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Image.asset('assets/images/logo.png', width: 40),
          ),
          const SizedBox(height: 10),
          const Text(
            'Communauté iCharge',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const Text(
            'Tunisie EV Network',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool small = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700], size: small ? 20 : 24),
      title: Text(
        label,
        style: TextStyle(
          color: Colors.black,
          fontSize: small ? 14 : 16,
          fontWeight: small ? FontWeight.normal : FontWeight.w500,
        ),
      ),
      onTap: onTap,
      dense: small,
    );
  }
}
