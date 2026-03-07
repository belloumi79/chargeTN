import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/responsive_wrapper.dart';
import 'package:go_router/go_router.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

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
                  'Mes Favoris',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_outline, color: AppColors.textSecondary, size: 64),
                      const SizedBox(height: 16),
                      const Text(
                        'Vous n\'avez pas encore de favoris.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ajoutez des bornes en cliquant sur le cœur.',
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
        currentIndex: 2,
        onTap: (i) {
          if (i == 2) return;
          if (i == 0) context.go('/home');
          if (i == 1) context.go('/search');
          if (i == 3) context.go('/social');
          if (i == 4) context.go('/profile');
        },
      ),
    );
  }
}
