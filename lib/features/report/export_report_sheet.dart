import 'package:flutter/material.dart';
import '../../core/widgets/bottom_sheet_wrapper.dart';
import '../../core/widgets/app_button.dart';
import '../../data/models/item.dart';
import '../../data/models/sale.dart';
import 'services/report_export_service.dart';

class ExportReportSheet extends StatefulWidget {
  final String storeName;
  final String userName;
  final String periodLabel;
  final List<Sale> sales;
  final List<Item> items;

  const ExportReportSheet({
    super.key,
    required this.storeName,
    required this.userName,
    required this.periodLabel,
    required this.sales,
    required this.items,
  });

  static Future<void> show(
    BuildContext context, {
    required String storeName,
    required String userName,
    required String periodLabel,
    required List<Sale> sales,
    required List<Item> items,
  }) {
    final subtitle = '$userName · $storeName · $periodLabel';
    return BottomSheetWrapper.show(
      context: context,
      title: 'Unduh laporan',
      subtitle: subtitle,
      child: ExportReportSheet(
        storeName: storeName,
        userName: userName,
        periodLabel: periodLabel,
        sales: sales,
        items: items,
      ),
    );
  }

  @override
  State<ExportReportSheet> createState() => _ExportReportSheetState();
}

class _ExportReportSheetState extends State<ExportReportSheet> {
  String _selectedFormat = 'PDF';
  bool _isExporting = false;

  Future<void> _handleDownload() async {
    setState(() => _isExporting = true);
    try {
      if (_selectedFormat == 'PDF') {
        await ReportExportService.exportPdf(
          storeName: widget.storeName,
          periodLabel: widget.periodLabel,
          sales: widget.sales,
          items: widget.items,
        );
      } else {
        await ReportExportService.exportCsv(
          storeName: widget.storeName,
          periodLabel: widget.periodLabel,
          sales: widget.sales,
          items: widget.items,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Laporan $_selectedFormat berhasil diunduh ke perangkat Anda!'),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengunduh laporan: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // PDF option
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _isExporting ? null : () => setState(() => _selectedFormat = 'PDF'),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _selectedFormat == 'PDF' ? const Color(0xFFF9F6F1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedFormat == 'PDF' ? const Color(0xFF38241D) : const Color(0xFFE8E3DD),
                width: _selectedFormat == 'PDF' ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf_outlined, size: 24, color: Color(0xFFDC2626)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('PDF Dokumen', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2E1E19))),
                      SizedBox(height: 2),
                      Text('Format dokumen resmi, rapi & siap diprint/dibagikan', style: TextStyle(fontSize: 11, color: Color(0xFF8D7B75))),
                    ],
                  ),
                ),
                Icon(
                  _selectedFormat == 'PDF' ? Icons.check_circle : Icons.radio_button_off,
                  size: 20,
                  color: _selectedFormat == 'PDF' ? const Color(0xFF38241D) : const Color(0xFFD6CDC4),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // CSV option
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _isExporting ? null : () => setState(() => _selectedFormat = 'CSV'),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _selectedFormat == 'CSV' ? const Color(0xFFF9F6F1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedFormat == 'CSV' ? const Color(0xFF38241D) : const Color(0xFFE8E3DD),
                width: _selectedFormat == 'CSV' ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.table_chart_outlined, size: 24, color: Color(0xFF16A34A)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('CSV / Microsoft Excel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2E1E19))),
                      SizedBox(height: 2),
                      Text('Data mentah angka penjualan, menu & rincian potongan bahan baku', style: TextStyle(fontSize: 11, color: Color(0xFF8D7B75))),
                    ],
                  ),
                ),
                Icon(
                  _selectedFormat == 'CSV' ? Icons.check_circle : Icons.radio_button_off,
                  size: 20,
                  color: _selectedFormat == 'CSV' ? const Color(0xFF38241D) : const Color(0xFFD6CDC4),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFBF4E8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 15, color: Color(0xFF8A5812)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Laporan mencakup ${widget.sales.length} transaksi penjualan dan ${widget.items.length} item inventaris untuk periode "${widget.periodLabel}".',
                  style: const TextStyle(fontSize: 11, height: 1.4, color: Color(0xFF8A5812)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AppButton(
          text: _isExporting ? 'Sedang memproses...' : 'Unduh file $_selectedFormat',
          isLoading: _isExporting,
          icon: const Icon(Icons.download_rounded, size: 18, color: Colors.white),
          onPressed: _isExporting ? null : _handleDownload,
        ),
      ],
    );
  }
}
