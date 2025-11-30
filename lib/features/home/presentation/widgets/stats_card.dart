import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class StatsCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String trend;
  final String variant;

  const StatsCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.trend,
    this.variant = 'default',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantic = theme.extension<AppSemanticColors>();

    Color bgColor;
    Color iconColor;
    Color textOnBgColor; // WHY: untuk konsistensi warna text di atas bgColor

    switch (variant) {
      case 'primary':
        bgColor = semantic?.highlight ?? colorScheme.tertiary;
        iconColor = colorScheme.onTertiary;
        textOnBgColor = colorScheme.onTertiary;
        break;
      case 'success':
        bgColor = colorScheme.primary;
        iconColor = colorScheme.onPrimary;
        textOnBgColor = colorScheme.onPrimary;
        break;
      default:
        bgColor = colorScheme.surface;
        iconColor = colorScheme.onSurfaceVariant;
        textOnBgColor = colorScheme.onSurface;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: variant == 'default'
            ? Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
                width: 0.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: variant == 'default'
                        ? colorScheme.onSurfaceVariant
                        : textOnBgColor.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: variant == 'default'
                  ? colorScheme.onSurface
                  : textOnBgColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            trend,
            style: theme.textTheme.labelSmall?.copyWith(
              color: variant == 'default'
                  ? colorScheme.onSurfaceVariant
                  : textOnBgColor.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
