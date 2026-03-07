import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/supabase_client.dart';
import 'core/app_colors.dart';
import 'models/station.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_map_screen.dart';
import 'screens/station_detail_screen.dart';
import 'screens/submit_report_screen.dart';
import 'screens/my_reports_screen.dart';
import 'screens/admin_panel_screen.dart';
import 'screens/search_list_screen.dart';
import 'screens/add_station_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/social_screen.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseConfig.init();
  await Hive.initFlutter();
  await Hive.openBox('stations_cache');

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Charge Tn',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      themeMode: ThemeMode.dark,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr'),
        Locale('ar'),
      ],
      routerConfig: _router,
    );
  }

  ThemeData _buildTheme() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primaryDark,
        surface: AppColors.surfaceDark,
        onPrimary: AppColors.backgroundDark,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
      redirect: (context, state) {
        final session = SupabaseConfig.client.auth.currentSession;
        if (session != null) return '/home';
        return null;
      },
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeMapScreen(),
    ),
    GoRoute(
      path: '/station/:id',
      builder: (context, state) {
        final station = state.extra as Station;
        return StationDetailScreen(station: station);
      },
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchListScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/favs',
      builder: (context, state) => const FavoritesScreen(),
    ),
    GoRoute(
      path: '/social',
      builder: (context, state) => const SocialScreen(),
    ),
    GoRoute(
      path: '/my_reports',
      builder: (context, state) => const MyReportsScreen(),
    ),
    GoRoute(
      path: '/add_station',
      builder: (context, state) => const AddStationScreen(),
      redirect: (context, state) {
        final session = SupabaseConfig.client.auth.currentSession;
        if (session == null) return '/auth';
        return null;
      },
    ),
    GoRoute(
      path: '/report',
      builder: (context, state) {
        final station = state.extra as Station;
        return SubmitReportScreen(station: station);
      },
      redirect: (context, state) {
        final session = SupabaseConfig.client.auth.currentSession;
        if (session == null) return '/auth';
        return null;
      },
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminPanelScreen(),
      redirect: (context, state) {
        final user = SupabaseConfig.client.auth.currentUser;
        if (user == null) return '/auth';
        final role = user.userMetadata?['role'];
        final email = user.email;
        if (role != 'admin' && email != 'belloumi.karim.professional@gmail.com') return '/home';
        return null;
      },
    ),
  ],
);
