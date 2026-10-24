import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/supplier.dart';
import '../../state/auth_state.dart';
import '../../state/supplier_state.dart';
import 'supplier_form_sheet.dart';

class SupplierDetailScreen extends StatefulWidget {
  final String supplierName;

  const SupplierDetailScreen({super.key, this.supplierName = ''});

  @override
  State<SupplierDetailScreen> createState() => _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends State<SupplierDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDetails();
    });
  }

  void _loadDetails() {
    final supplierState = context.read<SupplierState>();
    final sup = supplierState.allSuppliers.firstWhere(
      (s) => s.id == widget.supplierName || s.name.toLowerCase() == widget.supplierName.toLowerCase(),
      orElse: () => supplierState.allSuppliers.isNotEmpty ? supplierState.allSuppliers.first : Supplier(
        id: '',
        storeId: '',
        name: 'Mitra Supplier',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    if (sup.id.isNotEmpty) {
      supplierState.loadSupplierDetail(sup.id);
    }
  }

  void _showDeleteConfirmation(BuildContext context, Supplier sup) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus supplier?'),
        content: Text('Supplier ${sup.name} akan dihapus dari daftar mitra aktif.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF8D7B75))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final authState = context.read<AuthState>();
              final success = await context.read<SupplierState>().deleteSupplier(sup.id);
              if (mounted) {
                if (success) {
                  await context.read<SupplierState>().loadSuppliers(authState.storeId);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${sup.name} berhasil dihapus')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gagal menghapus supplier')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    final supplierState = context.watch<SupplierState>();
    final isAdmin = authState.isAdmin;

    final sup = supplierState.allSuppliers.firstWhere(
      (s) => s.id == widget.supplierName || s.name.toLowerCase() == widget.supplierName.toLowerCase(),
      orElse: () => supplierState.selectedSupplier ?? Supplier(
        id: '',
        storeId: '',
        name: 'Mitra Supplier',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final history = supplierState.purchaseHistory;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppHeader(
        title: sup.name,
        subtitle: 'Mitra persediaan',
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Contact card
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
                    sup.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'serif',
                      color: Color(0xFF2E1E19),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Mitra persediaan kedai',
                    style: TextStyle(fontSize: 11, color: Color(0xFF8D7B75)),
                  ),
                  const SizedBox(height: 14),
                  if (sup.phone != null && sup.phone!.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 16, color: Color(0xFF5D4037)),
                        const SizedBox(width: 8),
                        Text(
                          sup.phone!,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2E1E19)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (sup.address != null && sup.address!.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF5D4037)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sup.address!,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF5D4E48)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (sup.contactPerson != null && sup.contactPerson!.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 16, color: Color(0xFF5D4037)),
                        const SizedBox(width: 8),
                        Text(
                          'Kontak: ${sup.contactPerson!}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF5D4E48)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (sup.notes != null && sup.notes!.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.notes_outlined, size: 16, color: Color(0xFF5D4037)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sup.notes!,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF5D4E48)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (isAdmin) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: 'Edit supplier',
                            isOutlined: true,
                            height: 38,
                            onPressed: () => SupplierFormSheet.show(context, isEdit: true, supplier: sup),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppButton(
                            text: 'Hapus',
                            isOutlined: true,
                            textColor: const Color(0xFFDC2626),
                            height: 38,
                            onPressed: () => _showDeleteConfirmation(context, sup),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Riwayat pembelian
            const Text(
              'Riwayat pembelian',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'serif',
                color: Color(0xFF2E1E19),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8E3DD)),
              ),
              child: history.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'Belum ada riwayat pembelian dari supplier ini.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF8D7B75)),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (int i = 0; i < history.length; i++) ...[
                          if (i > 0) const Divider(height: 1, color: Color(0xFFF2ECE6)),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF0EAE1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.arrow_downward_rounded, size: 14, color: Color(0xFF2E7D32)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${history[i]['items']?['name'] ?? 'Bahan'} +${history[i]['initial_quantity']} ${history[i]['items']?['unit'] ?? ''}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2E1E19)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Batch ${history[i]['batch_code']} · ${Formatters.shortDate(DateTime.parse(history[i]['received_date']))}',
                                        style: const TextStyle(fontSize: 10, color: Color(0xFF8D7B75)),
                                      ),
                                    ],
                                  ),
                                ),
                                const StatusBadge(label: 'Tersimpan', textColor: Color(0xFF2E7D32), bgColor: Color(0xFFE8F5E9)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
