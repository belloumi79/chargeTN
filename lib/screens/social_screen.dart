import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/responsive_wrapper.dart';
import 'package:go_router/go_router.dart';

class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: ResponsiveWrapper(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Communauté',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group_outlined, color: AppColors.textSecondary, size: 64),
                      const SizedBox(height: 16),
                      const Text(
                        'Rejoignez la communauté Charge Tn.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Leaderboard et défis bientôt disponibles.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
}
