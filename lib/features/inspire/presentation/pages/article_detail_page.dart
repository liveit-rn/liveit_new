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

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  final ArticlesPublicRemoteDataSource _remote =
      getIt<ArticlesPublicRemoteDataSource>();

  bool _isLoading = true;
  Object? _error;
  PublicArticleDetail? _detail;

  @override
  void initState() {
    super.initState();
    _load();
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
    return DateFormat('dd MMM yyyy').format(publishedAt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          detail?.title ?? 'Renungan',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : (_error != null)
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Gagal memuat artikel',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error.toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _load,
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                ),
              )
            : (detail == null)
            ? Center(
                child: Text(
                  'Artikel tidak ditemukan.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            : _buildContent(context, detail),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PublicArticleDetail detail) {
    final colorScheme = Theme.of(context).colorScheme;

    final assetById = {for (final asset in detail.assets) asset.id: asset.url};

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (detail.coverUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  detail.coverUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: colorScheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.image_outlined,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    );
                  },
                ),
              ),
            ),
          if (detail.coverUrl != null) const SizedBox(height: 16),

          Text(
            detail.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          if (detail.subtitle != null && detail.subtitle!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                detail.subtitle!.trim(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              Text(
                _formatPublishedAt(detail.publishedAt),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${detail.readingTimeMinutes} menit baca',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (detail.authorDisplayName != null &&
                  detail.authorDisplayName!.trim().isNotEmpty)
                Text(
                  'oleh ${detail.authorDisplayName!.trim()}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          ProseMirrorRenderer(
            document: detail.contentJson,
            resolveAssetUrl: (assetId) => assetById[assetId],
          ),
        ],
      ),
    );
  }
}
