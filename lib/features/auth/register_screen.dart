import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app/router/route_names.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../state/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String _selectedRole = 'admin'; // 'admin' or 'crew'
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _storeNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  Future<void> _handleRegister() async {
    final authState = context.read<AuthState>();
    final name = _nameController.text.trim();
    final storeName = _storeNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty) {
      setState(() => _errorMessage = _selectedRole == 'admin'
          ? 'Nama lengkap Admin / Owner wajib diisi'
          : 'Nama lengkap kru / barista wajib diisi');
      return;
    }
    if (storeName.isEmpty) {
      setState(() => _errorMessage = _selectedRole == 'admin'
          ? 'Nama kedai / toko wajib diisi'
          : 'Kode toko atau nama kedai dari Admin wajib diisi');
      return;
    }
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Alamat email wajib diisi');
      return;
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _errorMessage = 'Format email tidak valid (cth: nama@email.com)');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Password wajib diisi');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password minimal 6 karakter');
      return;
    }

    setState(() => _errorMessage = null);
    final success = await authState.signUp(
      email: email,
      password: password,
      fullName: name,
      storeName: storeName,
      role: _selectedRole,
    );
    if (!mounted) return;

    if (success) {
      context.goNamed(RouteNames.dashboard);
    } else {
      setState(() => _errorMessage = authState.error ?? 'Pendaftaran akun gagal. Silakan coba lagi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    final isAdmin = _selectedRole == 'admin';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),

              // Brand Header
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFD8C7B8), width: 1.2),
                    ),
                    child: const Icon(
                      Icons.local_cafe_outlined,
                      size: 16,
                      color: Color(0xFF6E5649),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'SETOKE.SU',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                      fontFamily: 'serif',
                      color: Color(0xFF2E1E19),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Role Selector Pills (Placed at Top)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEBE6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_selectedRole != 'admin') {
                            setState(() {
                              _selectedRole = 'admin';
                              _errorMessage = null;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isAdmin ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: isAdmin
                                ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.storefront_outlined,
                                size: 16,
                                color: isAdmin ? const Color(0xFF2E1E19) : const Color(0xFF8D7B75),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Owner / Admin',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isAdmin ? FontWeight.w700 : FontWeight.w500,
                                  color: isAdmin ? const Color(0xFF2E1E19) : const Color(0xFF8D7B75),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_selectedRole != 'crew') {
                            setState(() {
                              _selectedRole = 'crew';
                              _errorMessage = null;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !isAdmin ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: !isAdmin
                                ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.badge_outlined,
                                size: 16,
                                color: !isAdmin ? const Color(0xFF2E1E19) : const Color(0xFF8D7B75),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Barista / Crew',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: !isAdmin ? FontWeight.w700 : FontWeight.w500,
                                  color: !isAdmin ? const Color(0xFF2E1E19) : const Color(0xFF8D7B75),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Dynamic Headline
              Text(
                isAdmin ? 'Daftar Kedai Baru.' : 'Gabung ke Kedai.',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'serif',
                  color: Color(0xFF2E1E19),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isAdmin
                    ? 'Buat kedai kopi Anda dan kelola seluruh persediaan dari awal.'
                    : 'Terhubung ke kedai kopi Anda untuk mencatat pesanan kasir & stok.',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF7D6B63),
                ),
              ),

              const SizedBox(height: 16),

              // Crew Notice Callout
              if (!isAdmin) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF4E8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF3E3C7)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.vpn_key_outlined, size: 16, color: Color(0xFF8A5812)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Anda membutuhkan Kode Toko dari Admin/Owner Anda (dapat dilihat di tab Profil Admin) untuk bergabung.',
                          style: TextStyle(fontSize: 11, height: 1.35, color: Color(0xFF8A5812)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Field 1: Nama Lengkap
              AppTextField(
                label: isAdmin ? 'Nama pemilik / admin' : 'Nama lengkap kru / barista',
                hint: isAdmin ? 'cth. Ghani Pratama' : 'cth. Dina Laras',
                controller: _nameController,
                onChanged: (_) => _clearError(),
                suffix: const Icon(Icons.person_outline, size: 18, color: Color(0xFFA89F99)),
              ),
              const SizedBox(height: 14),

              // Field 2: Nama Toko (Admin) vs Kode Toko (Crew)
              AppTextField(
                label: isAdmin ? 'Nama kedai kopi' : 'Kode Toko Admin (atau nama kedai)',
                hint: isAdmin ? 'cth. KOPI JAHAT' : 'cth. #E45B8A92 atau KOPI JAHAT',
                controller: _storeNameController,
                onChanged: (_) => _clearError(),
                helperText: isAdmin
                    ? 'Nama kedai yang akan tampil pada nota dan laporan'
                    : 'Masukkan kode toko 8 karakter dari Admin Anda',
                suffix: Icon(
                  isAdmin ? Icons.storefront_outlined : Icons.vpn_key_outlined,
                  size: 18,
                  color: const Color(0xFFA89F99),
                ),
              ),
              const SizedBox(height: 14),

              // Field 3: Email
              AppTextField(
                label: isAdmin ? 'Email admin' : 'Email kru',
                hint: isAdmin ? 'admin@setoke.su' : 'kru@email.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => _clearError(),
                suffix: const Icon(Icons.mail_outline, size: 18, color: Color(0xFFA89F99)),
              ),
              const SizedBox(height: 14),

              // Field 4: Password
              AppTextField(
                label: 'Password',
                hint: 'Masukkan password Anda',
                controller: _passwordController,
                obscureText: _obscurePassword,
                helperText: 'Minimal 6 karakter',
                onChanged: (_) => _clearError(),
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 18,
                    color: const Color(0xFFA89F99),
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),

              if (_errorMessage != null || authState.error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: Color(0xFFDC2626)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage ?? authState.error ?? '',
                          style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Submit Button
              AppButton(
                text: isAdmin ? 'Daftar Kedai Baru' : 'Gabung ke Kedai',
                isLoading: authState.isLoading,
                icon: Icon(
                  isAdmin ? Icons.arrow_forward_rounded : Icons.login_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                onPressed: _handleRegister,
              ),

              const SizedBox(height: 16),

              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: const Text(
                    'Sudah punya akun? Masuk',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5D4E48),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Center(
                child: Text(
                  'STOK TERTATA, KOPI TETAP ISTIMEWA.',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFAFA49D),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
