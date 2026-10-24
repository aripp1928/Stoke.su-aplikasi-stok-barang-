import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/utils/formatters.dart';
import '../../../core/utils/file_downloader/file_downloader.dart';
import '../../../data/models/item.dart';
import '../../../data/models/sale.dart';

class ReportExportService {
  ReportExportService._();

  /// Generate and download CSV report.
  static Future<void> exportCsv({
    required String storeName,
    required String periodLabel,
    required List<Sale> sales,
    required List<Item> items,
  }) async {
    final now = DateTime.now();
    final dateStr = Formatters.shortDate(now).replaceAll(' ', '_');
    final filename = 'Laporan_${storeName.replaceAll(' ', '_')}_$dateStr.csv';

    final totalSalesQty = sales.fold<int>(0, (sum, s) => sum + s.quantity);
    final totalRevenue = sales.fold<double>(0, (sum, s) => sum + s.totalPrice);

    // Group sales by product
    final Map<String, _ProductStat> productMap = {};
    for (final s in sales) {
      if (!productMap.containsKey(s.productName)) {
        productMap[s.productName] = _ProductStat(s.productName);
      }
      productMap[s.productName]!.add(s.quantity, s.totalPrice);
    }
    final productStats = productMap.values.toList()
      ..sort((a, b) => b.quantity.compareTo(a.quantity));

    final buffer = StringBuffer();

    // Store & Period Header
    buffer.writeln('LAPORAN PENJUALAN & INVENTARIS KEDAI KOPI');
    buffer.writeln('Nama Toko,"${_escape(storeName)}"');
    buffer.writeln('Periode,"${_escape(periodLabel)}"');
    buffer.writeln('Tanggal Unduh,"${Formatters.dateTime(now)}"');
    buffer.writeln();

    // Ringkasan
    buffer.writeln('RINGKASAN PENJUALAN');
    buffer.writeln('Total Omzet,"${Formatters.currency(totalRevenue)}"');
    buffer.writeln('Total Cup Terjual,$totalSalesQty cup');
    buffer.writeln('Total Transaksi,${sales.length} transaksi');
    buffer.writeln();

    // Tabel Penjualan per Menu
    buffer.writeln('KINERJA PER MENU');
    buffer.writeln('Peringkat,Nama Menu,Jumlah Cup,Total Omzet (Rp),Kontribusi (%)');
    for (int i = 0; i < productStats.length; i++) {
      final p = productStats[i];
      final pct = totalSalesQty > 0 ? (p.quantity / totalSalesQty * 100).toStringAsFixed(1) : '0';
      buffer.writeln('${i + 1},"${_escape(p.name)}",${p.quantity},${p.revenue.toStringAsFixed(0)},$pct%');
    }
    buffer.writeln();

    // Tabel Rincian Transaksi
    buffer.writeln('RINCIAN TRANSAKSI PENJUALAN');
    buffer.writeln('No,Waktu,Nama Menu,Porsi (Cup),Total Bayar (Rp),Kasir / Kru,Potongan Bahan Baku FEFO');
    for (int i = 0; i < sales.length; i++) {
      final s = sales[i];
      final timeStr = Formatters.dateTime(s.createdAt);
      final cashier = s.performedByName ?? 'Staf';
      final deductionsStr = s.deductions.map((d) {
        return '${d.itemName ?? "Bahan"}: -${Formatters.number(d.quantityDeducted)} ${d.itemUnit ?? ""}';
      }).join('; ');

      buffer.writeln(
        '${i + 1},"$timeStr","${_escape(s.productName)}",${s.quantity},${s.totalPrice.toStringAsFixed(0)},"${_escape(cashier)}","${_escape(deductionsStr)}"',
      );
    }
    buffer.writeln();

    // Tabel Stok Bahan
    buffer.writeln('STATUS INVENTARIS BAHAN BAKU');
    buffer.writeln('Nama Bahan,Kategori,Stok Tersedia,Satuan,Batas Minimum,Status');
    for (final item in items) {
      String status = 'Aman';
      if (item.currentStock <= 0) {
        status = 'Habis';
      } else if (item.isLowStock) {
        status = 'Menipis';
      }
      buffer.writeln(
        '"${_escape(item.name)}","${_escape(item.category)}",${item.currentStock},"${_escape(item.unit)}",${item.minStock},"$status"',
      );
    }

    // UTF-8 BOM for Excel compatibility
    final bytes = [0xEF, 0xBB, 0xBF, ...utf8.encode(buffer.toString())];

    await FileDownloader.download(
      bytes: bytes,
      filename: filename,
      mimeType: 'text/csv;charset=utf-8',
    );
  }

  /// Generate and download PDF report.
  static Future<void> exportPdf({
    required String storeName,
    required String periodLabel,
    required List<Sale> sales,
    required List<Item> items,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateStr = Formatters.shortDate(now).replaceAll(' ', '_');
    final filename = 'Laporan_${storeName.replaceAll(' ', '_')}_$dateStr.pdf';

    final totalSalesQty = sales.fold<int>(0, (sum, s) => sum + s.quantity);
    final totalRevenue = sales.fold<double>(0, (sum, s) => sum + s.totalPrice);

    // Group sales by product
    final Map<String, _ProductStat> productMap = {};
    for (final s in sales) {
      if (!productMap.containsKey(s.productName)) {
        productMap[s.productName] = _ProductStat(s.productName);
      }
      productMap[s.productName]!.add(s.quantity, s.totalPrice);
    }
    final productStats = productMap.values.toList()
      ..sort((a, b) => b.quantity.compareTo(a.quantity));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'SETOKE.SU',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#2E1E19'),
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Laporan Penjualan & Inventaris',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColor.fromHex('#5D4E48'),
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      storeName,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#2E1E19'),
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Periode: $periodLabel',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColor.fromHex('#8D7B75'),
                      ),
                    ),
                    pw.Text(
                      'Dicetak: ${Formatters.dateTime(now)}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColor.fromHex('#8D7B75'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 1, color: PdfColor.fromHex('#D8C7B8')),
            pw.SizedBox(height: 12),

            // KPI Summary Cards
            pw.Row(
              children: [
                _buildPdfMetricCard('Total Pendapatan', Formatters.currency(totalRevenue)),
                pw.SizedBox(width: 10),
                _buildPdfMetricCard('Total Terjual', '$totalSalesQty cup'),
                pw.SizedBox(width: 10),
                _buildPdfMetricCard('Total Transaksi', '${sales.length} pesanan'),
              ],
            ),
            pw.SizedBox(height: 16),

            // Tabel Menu Terlaris
            pw.Text(
              'Ringkasan Kinerja Menu',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#2E1E19')),
            ),
            pw.SizedBox(height: 6),
            if (productStats.isEmpty)
              pw.Text('Tidak ada menu terjual pada periode ini.', style: const pw.TextStyle(fontSize: 10))
            else
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColor.fromHex('#E8E3DD'), width: 0.5),
                headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#2E1E19')),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#F9F6F1')),
                headers: ['No', 'Nama Menu', 'Jumlah Cup', 'Total Omzet', 'Porsi %'],
                data: productStats.asMap().entries.map((entry) {
                  final i = entry.key;
                  final p = entry.value;
                  final pct = totalSalesQty > 0 ? (p.quantity / totalSalesQty * 100).toStringAsFixed(1) : '0';
                  return [
                    '${i + 1}',
                    p.name,
                    '${p.quantity} cup',
                    Formatters.currency(p.revenue),
                    '$pct%',
                  ];
                }).toList(),
              ),

            pw.SizedBox(height: 18),

            // Tabel Transaksi Penjualan Terbaru
            pw.Text(
              'Rincian Transaksi Penjualan',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#2E1E19')),
            ),
            pw.SizedBox(height: 6),
            if (sales.isEmpty)
              pw.Text('Belum ada transaksi pada periode ini.', style: const pw.TextStyle(fontSize: 10))
            else
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColor.fromHex('#E8E3DD'), width: 0.5),
                headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#2E1E19')),
                cellStyle: const pw.TextStyle(fontSize: 8),
                headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#F9F6F1')),
                headers: ['Waktu', 'Menu', 'Porsi', 'Total Bayar', 'Kasir', 'Bahan FEFO Terpotong'],
                data: sales.take(30).map((s) {
                  final deductions = s.deductions.map((d) => '${d.itemName}: -${Formatters.number(d.quantityDeducted)}${d.itemUnit}').join(', ');
                  return [
                    Formatters.dateTime(s.createdAt),
                    s.productName,
                    '${s.quantity}',
                    Formatters.currency(s.totalPrice),
                    s.performedByName ?? '-',
                    deductions.isNotEmpty ? deductions : 'Sesuai resep',
                  ];
                }).toList(),
              ),

            pw.SizedBox(height: 18),

            // Footer
            pw.Divider(thickness: 0.5, color: PdfColor.fromHex('#E8E3DD')),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'SETOKE.SU — Sistem Inventaris Kedai Kopi',
                  style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('#8D7B75')),
                ),
                pw.Text(
                  'Halaman laporan otomatis',
                  style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('#8D7B75')),
                ),
              ],
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();

    await FileDownloader.download(
      bytes: bytes,
      filename: filename,
      mimeType: 'application/pdf',
    );
  }

  static pw.Widget _buildPdfMetricCard(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#F9F6F1'),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(color: PdfColor.fromHex('#E8E3DD'), width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('#8D7B75'))),
            pw.SizedBox(height: 2),
            pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#2E1E19'))),
          ],
        ),
      ),
    );
  }

  static String _escape(String value) {
    return value.replaceAll('"', '""');
  }
}

class _ProductStat {
  final String name;
  int quantity = 0;
  double revenue = 0.0;

  _ProductStat(this.name);

  void add(int qty, double amount) {
    quantity += qty;
    revenue += amount;
  }
}
