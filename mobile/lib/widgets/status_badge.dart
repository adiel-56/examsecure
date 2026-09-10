import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

enum BadgeVariant { green, amber, red, blue, gray }

/// Reproduit les badges .b-green / .b-amber / .b-red / .b-blue / .b-gray
/// de la maquette HTML.
class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeVariant variant;

  const StatusBadge({super.key, required this.label, required this.variant});

  ({Color bg, Color fg}) get _colors {
    switch (variant) {
      case BadgeVariant.green:
        return (bg: AppColors.successSoft, fg: AppColors.success);
      case BadgeVariant.amber:
        return (bg: AppColors.warningSoft, fg: AppColors.warning);
      case BadgeVariant.red:
        return (bg: AppColors.dangerSoft, fg: AppColors.danger);
      case BadgeVariant.blue:
        return (bg: AppColors.primarySoft, fg: AppColors.primary);
      case BadgeVariant.gray:
        return (bg: const Color(0xFFEEF1F6), fg: AppColors.muted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: c.fg, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: .4),
      ),
    );
  }
}
