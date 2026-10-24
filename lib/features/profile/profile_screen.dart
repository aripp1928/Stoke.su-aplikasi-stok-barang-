import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_button.dart';
import '../../state/auth_state.dart';
import '../../app/router/route_names.dart';
import 'edit_store_name_sheet.dart';
import 'sign_out_sheet.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();

    if (!authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.goNamed(RouteNames.login);
        }
      });
      return const Scaffold(
        backgroundColor: Color(0xFFFAF7F2),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2E1E19)),
        ),
      );
    }

    final isAdmin = authState.isAdmin;
    final userName = authState.userName.isNotEmpty ? authState.userName : 'Pengguna';
    final userEmail = authState.userEmail.isNotEmpty ? authState.userEmail : '-';
    final storeName = authState.storeName.isNotEmpty ? authState.storeName : '-';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: const AppHeader(
        title: 'Profil & toko',
        subtitle: 'Pengaturan akun',
        showBack: true,
        showActions: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8E3DD)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'serif',
                      color: Color(0xFF2E1E19),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    userEmail,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF8D7B75)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0EAE1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      isAdmin ? 'Admin' : 'Crew',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF5D4037)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Store Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8E3DD)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Toko saya',
                        style: TextStyle(fontSize: 11, color: Color(0xFF8D7B75)),
                      ),
                      if (authState.storeCode.isNotEmpty)
                        InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: authState.storeCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Kode kedai #${authState.storeCode} disalin!'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF7F2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFE2DDD7)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.copy_rounded, size: 11, color: Color(0xFF5D4037)),
                                const SizedBox(width: 4),
                                Text(
                                  'Kode: #${authState.storeCode}',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF5D4037)),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    storeName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'serif',
                      color: Color(0xFF2E1E19),
                    ),
                  ),
                  if (isAdmin && authState.storeCode.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Bagikan kode #${authState.storeCode} atau nama "$storeName" ke kru Anda saat mendaftar.',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF8D7B75)),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (isAdmin)
                    AppButton(
                      text: 'Ubah nama toko',
                      isOutlined: true,
                      height: 38,
                      onPressed: () => EditStoreNameSheet.show(context),
                    )
                  else
                    const Text(
                      'Hubungi Admin untuk perubahan nama toko.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF8D7B75)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Permissions Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF4E8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF3E3C7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAdmin ? 'Hak akses Admin' : 'Hak akses Crew',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF8A5812)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAdmin
                        ? 'Kelola barang, harga beli, resep, supplier, laporan keuangan, dan identitas toko.'
                        : 'Tambah dan kurangi stok, catat penjualan & pemakaian, serta lihat laporan operasional. Harga, hapus barang & ubah toko tidak tersedia.',
                    style: const TextStyle(fontSize: 11, height: 1.4, color: Color(0xFFA67128)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Sign Out
            AppButton(
              text: 'Sign Out',
              isOutlined: true,
              textColor: const Color(0xFFDC2626),
              icon: const Icon(Icons.logout_rounded, size: 16, color: Color(0xFFDC2626)),
              onPressed: () => SignOutSheet.show(context),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'SETOKE.SU · v1.0.0',
                style: TextStyle(fontSize: 10, color: Color(0xFFAFA49D)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
