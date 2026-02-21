import 'package:flutter/material.dart';
import 'package:liveit_new/core/theme/app_theme.dart';

class HomeStatusBanners extends StatelessWidget {
  final bool isOffline;
  final bool hasError;
  final VoidCallback? onRetry;

  const HomeStatusBanners({
    super.key,
    required this.isOffline,
    required this.hasError,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOffline && !hasError) {
      return const SizedBox.shrink();
    }

    final AppSemanticColors? semanticColors = Theme.of(
      context,
    ).extension<AppSemanticColors>();

    final List<Widget> banners = [
      if (isOffline)
        _StatusBanner(
          icon: Icons.wifi_off_rounded,
          title: 'Sedang offline',
          message:
              'Kami akan menyinkronkan ulang begitu kamu kembali terhubung.',
          color: semanticColors?.warning ??
              Theme.of(context).colorScheme.secondary,
          onRetry: onRetry,
          retryLabel: 'Coba Sinkron',
        ),
      if (hasError)
        _StatusBanner(
          icon: Icons.cloud_off_outlined,
          title: 'Tidak dapat terhubung',
          message: 'Ada kendala jaringan. Coba lagi dalam beberapa saat.',
          color: Theme.of(context).colorScheme.error,
          onRetry: onRetry,
          retryLabel: 'Coba Lagi',
        ),
    ];

    return Column(
      children: [
        for (final Widget banner in banners) ...[
          banner,
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;
  final VoidCallback? onRetry;
  final String retryLabel;

  const _StatusBanner({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
    this.onRetry,
    required this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: textTheme.bodyMedium?.copyWith(
                    color: textTheme.bodyMedium?.color?.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    );
  }
}
