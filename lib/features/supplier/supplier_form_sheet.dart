import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/bottom_sheet_wrapper.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/supplier.dart';
import '../../state/auth_state.dart';
import '../../state/supplier_state.dart';

class SupplierFormSheet extends StatefulWidget {
  final bool isEdit;
  final Supplier? supplier;

  const SupplierFormSheet({super.key, this.isEdit = false, this.supplier});

  static Future<void> show(BuildContext context, {bool isEdit = false, Supplier? supplier}) {
    return BottomSheetWrapper.show(
      context: context,
      title: isEdit ? 'Edit supplier' : 'Tambah supplier',
      subtitle: 'Informasi kontak untuk pembelian berikutnya.',
      child: SupplierFormSheet(isEdit: isEdit, supplier: supplier),
    );
  }

  @override
  State<SupplierFormSheet> createState() => _SupplierFormSheetState();
}

class _SupplierFormSheetState extends State<SupplierFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _contactController;
  late final TextEditingController _notesController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.supplier?.name ?? '');
    _phoneController = TextEditingController(text: widget.supplier?.phone ?? '');
    _addressController = TextEditingController(text: widget.supplier?.address ?? '');
    _contactController = TextEditingController(text: widget.supplier?.contactPerson ?? '');
    _notesController = TextEditingController(text: widget.supplier?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama supplier wajib diisi')),
      );
      return;
    }

    final phone = _phoneController.text.trim();
    if (phone.isNotEmpty && phone.replaceAll(RegExp(r'[^0-9]'), '').length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor HP tidak valid (minimal 8 digit angka)')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final authState = context.read<AuthState>();
    final supplierState = context.read<SupplierState>();

    try {
      if (widget.isEdit && widget.supplier != null) {
        final updated = Supplier(
          id: widget.supplier!.id,
          storeId: widget.supplier!.storeId,
          name: name,
          phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
          address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
          contactPerson: _contactController.text.trim().isNotEmpty ? _contactController.text.trim() : null,
          notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
          createdAt: widget.supplier!.createdAt,
          updatedAt: DateTime.now(),
        );
        final success = await supplierState.updateSupplier(updated);
        if (mounted) {
          if (success) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Supplier $name berhasil diperbarui')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(supplierState.error ?? 'Gagal memperbarui supplier')),
            );
          }
        }
      } else {
        final newSupplier = Supplier(
          id: '',
          storeId: authState.storeId,
          name: name,
          phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
          address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
          contactPerson: _contactController.text.trim().isNotEmpty ? _contactController.text.trim() : null,
          notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final success = await supplierState.createSupplier(newSupplier);
        if (mounted) {
          if (success) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Supplier $name berhasil ditambahkan')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(supplierState.error ?? 'Gagal menambahkan supplier')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: 'Nama supplier',
          hint: 'cth. Bumi Roastery',
          controller: _nameController,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Nomor HP',
          hint: 'cth. 0812-3456-7801',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          suffix: const Icon(Icons.phone_outlined, size: 18, color: Color(0xFF5D4037)),
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Alamat',
          hint: 'cth. Jl. Kaliurang No. 18, Yogyakarta',
          controller: _addressController,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Nama kontak',
          hint: 'cth. Bima',
          controller: _contactController,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Catatan',
          hint: 'cth. Pengiriman Senin-Sabtu',
          controller: _notesController,
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFBF4E8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'Riwayat pembelian tetap tersimpan\nPerubahan kontak tidak mengubah batch atau transaksi sebelumnya.',
            style: TextStyle(fontSize: 10, height: 1.4, color: Color(0xFF8A5812)),
          ),
        ),
        const SizedBox(height: 20),
        AppButton(
          text: widget.isEdit ? 'Simpan perubahan' : 'Simpan supplier',
          isLoading: _isSaving,
          onPressed: _handleSave,
        ),
      ],
    );
  }
}
