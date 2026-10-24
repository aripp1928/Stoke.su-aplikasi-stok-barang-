import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

/// Initializes and provides global access to the Supabase client.
class SupabaseService {
  SupabaseService._();

  static bool _isInitialized = false;

  static bool get isConfigured =>
      SupabaseConfig.url.isNotEmpty &&
      SupabaseConfig.anonKey.isNotEmpty &&
      !SupabaseConfig.url.contains('YOUR_PROJECT_REF') &&
      !SupabaseConfig.anonKey.contains('YOUR_ANON_KEY');

  static bool get isInitialized => _isInitialized;

  /// Returns null if Supabase is not initialized yet.
  static SupabaseClient? get clientOrNull {
    if (!_isInitialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Global client instance. Throws StateError with friendly message if not initialized.
  static SupabaseClient get client {
    if (!_isInitialized) {
      throw StateError(
        'Supabase belum diinisialisasi. Masukkan URL dan Key Anda di lib/data/services/supabase_config.dart',
      );
    }
    return Supabase.instance.client;
  }

  /// Call once in main() before runApp().
  static Future<void> initialize() async {
    if (!isConfigured) return;
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );
      _isInitialized = true;
    } catch (_) {
      _isInitialized = false;
      rethrow;
    }
  }

  /// Shortcut for the auth module.
  static GoTrueClient? get auth => clientOrNull?.auth;

  /// Shortcut to the currently signed-in user (nullable).
  static User? get currentUser => auth?.currentUser;

  /// Shortcut to check authentication state.
  static bool get isAuthenticated => currentUser != null;
}
