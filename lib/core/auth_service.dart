import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';

/// Centralizes all auth/admin checks so they don't get duplicated across
/// router redirects, splash, and auth screens.
class AuthService {
  AuthService._();

  /// The canonical list of admin emails.
  /// Anyone whose `role` metadata is "admin" is also authorized.
  /// Update this single constant to add/remove admin users.
  static const Set<String> _adminEmails = {
    'belloumi.karim.professional@gmail.com',
    'admin@charge.tn',
  };

  /// Returns the currently signed-in user (or null).
  static User? get currentUser => SupabaseConfig.client.auth.currentUser;

  /// Whether [user] has admin privileges.
  /// Checks both Supabase userMetadata.role and the explicit allowlist.
  static bool isAdmin(User? user) {
    if (user == null) return false;
    if (user.userMetadata?['role'] == 'admin') return true;
    final email = user.email?.toLowerCase();
    if (email == null) return false;
    return _adminEmails.contains(email);
  }

  /// Convenience for current-session checks.
  static bool get isCurrentUserAdmin => isAdmin(currentUser);

  /// Returns the admin redirect target for [user].
  /// '/' means "no redirect needed".
  static String adminRedirectTarget(User? user) {
    if (user == null) return '/auth';
    return isAdmin(user) ? '/admin' : '/home';
  }

  /// Logs a structured message for auth-related events.
  /// In release builds you may want to forward this to a remote service.
  static void logAuthEvent(String event, {Object? error, StackTrace? stack}) {
    debugPrint('[AuthService] $event${error != null ? ' — $error' : ''}');
    if (stack != null) debugPrint(stack.toString());
  }
}
