import 'dart:ui';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/injection/injection_container.dart';
import '../../data/datasources/articles_public_remote_datasource.dart';
import '../../data/models/public_article_detail.dart';
import '../widgets/prosemirror_renderer.dart';

@RoutePage()
class ArticleDetailPage extends StatefulWidget {
  final String slug;

  const ArticleDetailPage({@PathParam('slug') required this.slug, super.key});

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage>
    with SingleTickerProviderStateMixin {
  final ArticlesPublicRemoteDataSource _remote =
      getIt<ArticlesPublicRemoteDataSource>();

  late final AnimationController _animationController;
  bool _isLoading = true;
  Object? _error;
  PublicArticleDetail? _detail;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _load();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final detail = await _remote.getPublicBySlug(widget.slug);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  String _formatPublishedAt(DateTime publishedAt) {
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID')
        .format(publishedAt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.03),
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.02),
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const _LoadingContent()
              : (_error != null)
                  ? _ErrorContent(
                      error: _error!,
                      onRetry: _load,
                      controller: _animationController,
                    )
                  : (detail == null)
                      ? _NotFoundContent(
                          controller: _animationController,
                        )
                      : _buildContent(context, detail),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PublicArticleDetail detail) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final assetById = {for (final asset in detail.assets) asset.id: asset.url};

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        decelerationRate: ScrollDecelerationRate.fast,
      ),
      slivers: [
        // Glass App Bar
        _GlassAppBar(
          title: detail.title,
          controller: _animationController,
        ),

        // Content
        SliverToBoxAdapter(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final value = _animationController.value;
              return Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover Image
                if (detail.coverUrl != null)
                  _CoverImage(
                    coverUrl: detail.coverUrl!,
                    title: detail.title,
                    colorScheme: colorScheme,
                  ),

                // Article Body
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        detail.title,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                          fontSize: 28,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Meta info
                      _MetaInfo(
                        publishedAt: _formatPublishedAt(detail.publishedAt),
                        readingTime: '${detail.readingTimeMinutes} menit baca',
                        author: detail.authorDisplayName,
                        colorScheme: colorScheme,
                      ),

                      if (detail.subtitle != null &&
                          detail.subtitle!.trim().isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colorScheme.tertiary.withValues(alpha: 0.1),
                                colorScheme.tertiary.withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  colorScheme.tertiary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            '"${detail.subtitle!.trim()}"',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.tertiary,
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Divider
                      Container(
                        width: 60,
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary,
                              colorScheme.primary.withValues(alpha: 0.5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Content
                      ProseMirrorRenderer(
                        document: detail.contentJson,
                        resolveAssetUrl: (assetId) => assetById[assetId],
                      ),

                      const SizedBox(height: 32),

                      // Footer
                      _ArticleFooter(
                        author: detail.authorDisplayName,
                        publishedAt: _formatPublishedAt(detail.publishedAt),
                        colorScheme: colorScheme,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassAppBar extends StatelessWidget {
  final String title;
  final AnimationController controller;

  const _GlassAppBar({required this.title, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final value = controller.value;
          return Transform.translate(
            offset: Offset(0, -20 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.only(
            left: 8,
            right: 16,
            top: MediaQuery.of(context).padding.top + 8,
            bottom: 16,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.surface.withValues(alpha: 0.95),
                colorScheme.surface.withValues(alpha: 0.85),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => context.router.pop(),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  final String coverUrl;
  final String title;
  final ColorScheme colorScheme;

  const _CoverImage({
    required this.coverUrl,
    required this.title,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              coverUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: colorScheme.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.image_outlined,
                    color: colorScheme.onSurfaceVariant,
                    size: 48,
                  ),
                );
              },
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    colorScheme.surface.withValues(alpha: 0.3),
                    colorScheme.surface.withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaInfo extends StatelessWidget {
  final String publishedAt;
  final String readingTime;
  final String? author;
  final ColorScheme colorScheme;

  const _MetaInfo({
    required this.publishedAt,
    required this.readingTime,
    this.author,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _MetaChip(
          icon: Icons.calendar_today_rounded,
          text: publishedAt,
          color: colorScheme.primary,
        ),
        _MetaChip(
          icon: Icons.access_time_rounded,
          text: readingTime,
          color: colorScheme.tertiary,
        ),
        if (author != null && author!.trim().isNotEmpty)
          _MetaChip(
            icon: Icons.person_outline_rounded,
            text: author!.trim(),
            color: colorScheme.secondary,
          ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _MetaChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: theme.textTheme.labelMedium?.copyWith(
            color: color.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ArticleFooter extends StatelessWidget {
  final String? author;
  final String publishedAt;
  final ColorScheme colorScheme;

  const _ArticleFooter({
    this.author,
    required this.publishedAt,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.05),
            colorScheme.primary.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_stories_rounded,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Renungan dari LiveIt',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Semoga renungan ini memberkati hidupmu hari ini.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Dipublikasikan pada $publishedAt${author != null ? ' oleh $author' : ''}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Memuat artikel...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorContent extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  final AnimationController controller;

  const _ErrorContent({
    required this.error,
    required this.onRetry,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final value = controller.value;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.surface.withValues(alpha: 0.9),
                      colorScheme.surface.withValues(alpha: 0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colorScheme.error.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color:
                            colorScheme.errorContainer.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 32,
                        color: colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Gagal memuat artikel',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: onRetry,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colorScheme.primary,
                              colorScheme.primary.withValues(alpha: 0.85),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.refresh_rounded,
                              size: 18,
                              color: colorScheme.onPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Coba Lagi',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotFoundContent extends StatelessWidget {
  final AnimationController controller;

  const _NotFoundContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final value = controller.value;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                      colorScheme.onSurfaceVariant.withValues(alpha: 0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.article_outlined,
                  size: 48,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Artikel Tidak Ditemukan',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Artikel yang kamu cari mungkin sudah dihapus\natau URL tidak valid.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => context.router.pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withValues(alpha: 0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back_rounded,
                        size: 18,
                        color: colorScheme.onPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Kembali',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
