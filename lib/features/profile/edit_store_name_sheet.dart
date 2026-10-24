import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/bottom_sheet_wrapper.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../state/auth_state.dart';

class EditStoreNameSheet extends StatefulWidget {
  const EditStoreNameSheet({super.key});

  static Future<void> show(BuildContext context) {
    final authState = context.read<AuthState>();
    final subtitle = '${authState.userName.isNotEmpty ? authState.userName : "Admin"} · hanya Admin';
    return BottomSheetWrapper.show(
      context: context,
      title: 'Ubah nama toko',
      subtitle: subtitle,
      child: const EditStoreNameSheet(),
    );
  }

  @override
  State<EditStoreNameSheet> createState() => _EditStoreNameSheetState();
}

class _EditStoreNameSheetState extends State<EditStoreNameSheet> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthState>();
    _nameController = TextEditingController(
      text: authState.storeName,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: 'Nama toko',
          hint: 'Masukkan nama toko',
          controller: _nameController,
          helperText: '3-40 karakter · nama toko tidak boleh kosong',
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFBF4E8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nama saat ini: ${authState.storeName.isNotEmpty ? authState.storeName : "-"}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF8A5812)),
              ),
              const SizedBox(height: 2),
              const Text(
                'Nama baru akan tampil pada header dan laporan. Barang, batch dan riwayat tetap sama.',
                style: TextStyle(fontSize: 10, color: Color(0xFFA67128)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'Batal',
                isOutlined: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppButton(
                text: 'Simpan nama',
                onPressed: () async {
                  final newName = _nameController.text.trim();
                  if (newName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nama toko tidak boleh kosong')),
                    );
                    return;
                  }
                  if (newName.length < 3) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nama toko minimal 3 karakter')),
                    );
                    return;
                  }
                  if (newName.length > 40) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nama toko maksimal 40 karakter')),
                    );
                    return;
                  }
                  await authState.updateStoreName(newName);
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Nama toko berhasil diubah menjadi $newName')),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
