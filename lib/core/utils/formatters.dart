import 'package:intl/intl.dart';

/// Formatting helpers for currency, dates, and numbers.
class Formatters {
  Formatters._();

  static const List<String> _monthsFull = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  static const List<String> _monthsShort = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  /// Format a number as Indonesian Rupiah: Rp1.000.000
  static String currency(num value) {
    try {
      final f = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
      return f.format(value);
    } catch (_) {
      return 'Rp${number(value)}';
    }
  }

  /// Format a number with dot separator: 1.000
  static String number(num value) {
    return value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  /// Format a weight/volume value with unit: "500 g", "1.000 ml"
  static String quantity(num value, String unit) => '${number(value)} $unit';

  /// Full date: 3 Oktober 2026
  static String fullDate(DateTime date) {
    try {
      return DateFormat('d MMMM yyyy', 'id_ID').format(date);
    } catch (_) {
      final month = date.month >= 1 && date.month <= 12 ? _monthsFull[date.month] : '';
      return '${date.day} $month ${date.year}';
    }
  }

  /// Short date: 3 Okt 2026
  static String shortDate(DateTime date) {
    try {
      return DateFormat('d MMM yyyy', 'id_ID').format(date);
    } catch (_) {
      final month = date.month >= 1 && date.month <= 12 ? _monthsShort[date.month] : '';
      return '${date.day} $month ${date.year}';
    }
  }

  /// Date with time: 3 Okt 2026, 08:30
  static String dateTime(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '${shortDate(date)}, $h:$m';
  }

  /// Time only: 08:30
  static String time(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Relative time
  static String relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return shortDate(date);
  }

  static String apiDate(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);
}
