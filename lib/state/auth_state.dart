import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/enums/user_role.dart';
import '../data/models/user_profile.dart';
import '../data/models/store.dart';
import '../data/repositories/auth_repository.dart';

/// Authentication & session state — completely separated from UI.
class AuthState extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();

  UserProfile? _profile;
  Store? _store;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // ── Getters ──
  UserProfile? get profile => _profile;
  Store? get store => _store;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _profile != null;
  bool get isAdmin => _profile?.isAdmin ?? false;
  bool get isCrew => _profile?.isCrew ?? false;
  String get storeId => _profile?.storeId ?? '';
  String get userId => _profile?.id ?? '';
  String get storeName => _store?.name ?? '';
  String get storeCode => _store?.code ?? '';
  String get userName => _profile?.fullName ?? '';
  String get userEmail => _profile?.email ?? '';
  bool get isInitialized => _isInitialized;

  /// Set demo role for testing without real backend
  void setDemoRole(UserRole role) {
    final isAdminRole = role == UserRole.admin;
    _profile = UserProfile(
      id: 'demo-user-id',
      fullName: isAdminRole ? 'Alya Putri' : 'Dina Laras',
      email: isAdminRole ? 'admin@setoke.su' : 'crew@setoke.su',
      storeId: 'demo-store-id',
      role: role,
      createdAt: DateTime.now(),
    );
    _store = Store(
      id: 'demo-store-id',
      name: 'Kopi Senja',
      ownerId: 'demo-user-id',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _error = null;
    notifyListeners();
  }

  /// Greeting based on time of day.
  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  /// Initialize — check if user is already logged in.
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isLoading = true;
    notifyListeners();

    try {
      if (_repo.isAuthenticated && _repo.currentUserId != null) {
        final result = await _repo.signInFromSession(_repo.currentUserId!);
        _profile = result.profile;
        _store = result.store;
      }
    } catch (e) {
      // Session expired or invalid — user needs to log in again
      _profile = null;
      _store = null;
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Sign in.
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    try {
      final result = await _repo.signIn(email: email, password: password);
      _profile = result.profile;
      _store = result.store;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Register.
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String storeName,
    required String role,
  }) async {
    _setLoading(true);
    try {
      final result = await _repo.signUp(
        email: email,
        password: password,
        fullName: fullName,
        storeName: storeName,
        role: role,
      );
      _profile = result.profile;
      _store = result.store;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update store name.
  Future<bool> updateStoreName(String newName) async {
    _setLoading(true);
    try {
      _store = await _repo.updateStoreName(storeId, newName);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    await _repo.signOut();
    _profile = null;
    _store = null;
    _error = null;
    notifyListeners();
  }

  /// Clear error.
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  String _parseError(dynamic e) {
    if (e == null) return 'Terjadi kendala. Silakan coba lagi.';
    final rawMsg = e.toString();
    if (rawMsg.contains('EMAIL_CONFIRMATION_REQUIRED:')) {
      return rawMsg.replaceFirst('Exception: EMAIL_CONFIRMATION_REQUIRED: ', '').replaceFirst('EMAIL_CONFIRMATION_REQUIRED: ', '');
    }

    final msg = rawMsg.toLowerCase();
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid_credentials') ||
        msg.contains('user not found')) {
      return 'Email atau password salah, atau akun belum terdaftar.';
    }
    if (msg.contains('user already registered') ||
        msg.contains('already registered') ||
        msg.contains('user_already_exists')) {
      return 'Email sudah terdaftar. Silakan gunakan email lain atau langsung masuk.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Email belum dikonfirmasi. Silakan periksa inbox email Anda untuk konfirmasi.';
    }
    if (msg.contains('password') && (msg.contains('least 6') || msg.contains('weak') || msg.contains('least 8'))) {
      return 'Password terlalu singkat (minimal 6 karakter).';
    }
    if (msg.contains('invalid email') || msg.contains('email format')) {
      return 'Format alamat email tidak valid.';
    }
    if (msg.contains('socketexception') ||
        msg.contains('network') ||
        msg.contains('failed host lookup') ||
        msg.contains('clientexception') ||
        msg.contains('connection refused') ||
        msg.contains('timeout')) {
      return 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
    }
    if (msg.contains('rate limit') || msg.contains('too many requests')) {
      return 'Terlalu banyak permintaan. Harap tunggu beberapa saat.';
    }
    if (msg.contains('row-level security') || msg.contains('violates row-level security')) {
      return 'Izin database ditolak (RLS). Pastikan konfigurasi RLS tabel di Supabase sudah sesuai.';
    }
    if (e is AuthException) {
      return e.message;
    }
    if (e is PostgrestException) {
      return e.message;
    }
    if (rawMsg.startsWith('Exception: ')) {
      return rawMsg.replaceFirst('Exception: ', '');
    }
    return 'Terjadi kendala saat memproses autentikasi. Silakan coba lagi.';
  }
}
