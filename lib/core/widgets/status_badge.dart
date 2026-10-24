import 'package:flutter/material.dart';

enum StockStatus {
  safe('Aman', Color(0xFF2E7D32), Color(0xFFE8F5E9)),
  warning('Menipis', Color(0xFFD97706), Color(0xFFFEF3C7)),
  danger('Habis', Color(0xFFDC2626), Color(0xFFFEE2E2)),
  expiring('Mendekati', Color(0xFFD97706), Color(0xFFFEF3C7)),
  almostExpired('Hampir basi', Color(0xFFDC2626), Color(0xFFFEE2E2));

  final String label;
  final Color textColor;
  final Color bgColor;

  const StockStatus(this.label, this.textColor, this.bgColor);
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color bgColor;

  const StatusBadge({
    super.key,
    required this.label,
    required this.textColor,
    required this.bgColor,
  });

  factory StatusBadge.fromStock({
    required double current,
    required double minimum,
  }) {
    if (current <= 0) {
      return const StatusBadge(
        label: 'Habis',
        textColor: Color(0xFFDC2626),
        bgColor: Color(0xFFFEE2E2),
      );
    } else if (current <= minimum) {
      return const StatusBadge(
        label: 'Menipis',
        textColor: Color(0xFFD97706),
        bgColor: Color(0xFFFEF3C7),
      );
    } else {
      return const StatusBadge(
        label: 'Aman',
        textColor: Color(0xFF2E7D32),
        bgColor: Color(0xFFE8F5E9),
      );
    }
  }

  factory StatusBadge.custom(String label, {bool isWarning = false, bool isDanger = false}) {
    if (isDanger) {
      return StatusBadge(
        label: label,
        textColor: const Color(0xFFDC2626),
        bgColor: const Color(0xFFFEE2E2),
      );
    }
    if (isWarning) {
      return StatusBadge(
        label: label,
        textColor: const Color(0xFFD97706),
        bgColor: const Color(0xFFFEF3C7),
      );
    }
    return StatusBadge(
      label: label,
      textColor: const Color(0xFF2E7D32),
      bgColor: const Color(0xFFE8F5E9),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
