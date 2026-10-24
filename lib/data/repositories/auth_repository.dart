import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/store.dart';
import '../services/supabase_service.dart';

/// Result container for sign-in / sign-up so we return both profile + store
/// in a single call, avoiding an extra getStore() round-trip.
class AuthResult {
  final UserProfile profile;
  final Store store;
  const AuthResult({required this.profile, required this.store});
}

class AuthRepository {
  SupabaseClient get _client => SupabaseService.client;

  /// Sign in with email/password — returns profile + store in one call.
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    if (!SupabaseService.isInitialized) {
      throw Exception('Supabase belum dihubungkan.');
    }
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user == null) throw Exception('Login gagal');
    return _loadProfileAndStore(response.user!.id);
  }

  /// Register a new user + create store + profile in minimum round-trips.
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String fullName,
    required String storeName,
    required String role,
  }) async {
    if (!SupabaseService.isInitialized) {
      throw Exception('Supabase belum dihubungkan. Periksa konfigurasi Supabase.');
    }
    // 1. Create auth user with user metadata
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'store_name': storeName,
        'role': role,
      },
    );
    if (response.user == null) throw Exception('Registrasi gagal');
    final userId = response.user!.id;

    // If Supabase has "Confirm email" enabled, session will be null
    if (response.session == null) {
      throw Exception('EMAIL_CONFIRMATION_REQUIRED: Pendaftaran berhasil! Silakan periksa inbox email ($email) untuk konfirmasi akun Anda sebelum masuk.');
    }

    Store store;
    if (role == 'crew') {
      final cleanInput = storeName.replaceAll('#', '').trim().toLowerCase();
      Map<String, dynamic>? storeData;

      // 1. Try finding by full UUID if given
      if (cleanInput.length == 36 && cleanInput.contains('-')) {
        storeData = await _client
            .from('stores')
            .select()
            .eq('id', cleanInput)
            .maybeSingle();
      }

      // 2. Try finding by store name (case-insensitive)
      if (storeData == null) {
        storeData = await _client
            .from('stores')
            .select()
            .ilike('name', cleanInput)
            .maybeSingle();
      }

      // 3. Match by ID prefix (8-char code) or name safely in Dart
      if (storeData == null) {
        final allStores = await _client.from('stores').select();
        for (final s in allStores as List) {
          final sId = (s['id'] as String).toLowerCase();
          final sName = (s['name'] as String).toLowerCase();
          final shortCode = sId.length >= 8 ? sId.substring(0, 8) : sId;
          if (shortCode == cleanInput || sId.startsWith(cleanInput) || sName == cleanInput) {
            storeData = s as Map<String, dynamic>;
            break;
          }
        }
      }

      if (storeData == null) {
        await _client.auth.signOut();
        throw Exception('Kedai dengan kode atau nama "$storeName" tidak ditemukan. Pastikan kode toko dari Admin kedai sudah benar.');
      }
      store = Store.fromJson(storeData);
    } else {
      // 2. Admin: Create new store
      final storeData = await _client
          .from('stores')
          .insert({'name': storeName, 'owner_id': userId})
          .select()
          .single();
      store = Store.fromJson(storeData);
    }

    // 3. Create profile
    final profileData = await _client
        .from('profiles')
        .insert({
          'id': userId,
          'full_name': fullName,
          'email': email,
          'store_id': store.id,
          'role': role,
        })
        .select()
        .single();

    return AuthResult(
      profile: UserProfile.fromJson(profileData),
      store: store,
    );
  }

  /// Load profile + store in one helper. If profile doesn't exist yet
  /// (user created from Supabase dashboard), auto-provisions it.
  /// Also used by initialize() to restore session.
  Future<AuthResult> signInFromSession(String userId) => _loadProfileAndStore(userId);

  Future<AuthResult> _loadProfileAndStore(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data != null) {
      final profile = UserProfile.fromJson(data);
      // Fetch store in parallel — single extra request
      final storeData = await _client
          .from('stores')
          .select()
          .eq('id', profile.storeId)
          .single();
      return AuthResult(profile: profile, store: Store.fromJson(storeData));
    }

    // — Auto-provision: user was created via Supabase dashboard —
    final currentUser = _client.auth.currentUser;
    final email = currentUser?.email ?? 'admin@setoke.su';
    final userMeta = currentUser?.userMetadata ?? {};
    final customStoreName = (userMeta['store_name'] as String?)?.trim();
    final storeName = (customStoreName != null && customStoreName.isNotEmpty)
        ? customStoreName
        : 'Kedai Kopi';
    final customFullName = (userMeta['full_name'] as String?)?.trim();
    final fullName = (customFullName != null && customFullName.isNotEmpty)
        ? customFullName
        : email.split('@').first;
    final role = (userMeta['role'] as String?) ?? 'admin';

    var storeData = await _client
        .from('stores')
        .select()
        .eq('owner_id', userId)
        .maybeSingle();

    if (storeData == null && role == 'crew') {
      final cleanInput = customStoreName?.replaceAll('#', '').trim().toLowerCase() ?? '';
      if (cleanInput.isNotEmpty) {
        storeData = await _client
            .from('stores')
            .select()
            .ilike('name', cleanInput)
            .maybeSingle();

        if (storeData == null) {
          final allStores = await _client.from('stores').select();
          for (final s in allStores as List) {
            final sId = (s['id'] as String).toLowerCase();
            final sName = (s['name'] as String).toLowerCase();
            final shortCode = sId.length >= 8 ? sId.substring(0, 8) : sId;
            if (shortCode == cleanInput || sId.startsWith(cleanInput) || sName == cleanInput) {
              storeData = s as Map<String, dynamic>;
              break;
            }
          }
        }
      }
    }

    if (storeData == null) {
      storeData = await _client
          .from('stores')
          .insert({'name': storeName, 'owner_id': userId})
          .select()
          .single();
    }

    final store = Store.fromJson(storeData);

    final profileData = await _client
        .from('profiles')
        .insert({
          'id': userId,
          'full_name': fullName,
          'email': email,
          'store_id': store.id,
          'role': role,
        })
        .select()
        .single();

    return AuthResult(
      profile: UserProfile.fromJson(profileData),
      store: store,
    );
  }

  /// Get the store for the current user.
  Future<Store> getStore(String storeId) async {
    final data = await _client
        .from('stores')
        .select()
        .eq('id', storeId)
        .single();
    return Store.fromJson(data);
  }

  /// Update store name.
  Future<Store> updateStoreName(String storeId, String newName) async {
    if (!SupabaseService.isInitialized) {
      return Store(
        id: storeId,
        name: newName,
        ownerId: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    final data = await _client
        .from('stores')
        .update({
          'name': newName,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', storeId)
        .select()
        .single();
    return Store.fromJson(data);
  }

  /// Sign out.
  Future<void> signOut() async {
    if (SupabaseService.isInitialized) {
      await _client.auth.signOut();
    }
  }

  /// Check if a session exists.
  bool get isAuthenticated =>
      SupabaseService.isInitialized && (_client.auth.currentSession != null);

  /// Current auth user id.
  String? get currentUserId =>
      SupabaseService.isInitialized ? _client.auth.currentUser?.id : null;
}
