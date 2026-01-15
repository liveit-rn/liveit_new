import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/injection/injection_container.dart';
import '../../../../core/router/app_router.dart';
import '../../data/datasources/articles_public_remote_datasource.dart';
import '../../data/models/public_article_feed.dart';
import '../widgets/devotional_card.dart';

@RoutePage()
class DevotionPage extends StatefulWidget {
  const DevotionPage({super.key});

  @override
  State<DevotionPage> createState() => _DevotionPageState();
}

class _DevotionPageState extends State<DevotionPage> {
  final ArticlesPublicRemoteDataSource _remote =
      getIt<ArticlesPublicRemoteDataSource>();

  bool _isLoading = true;
  Object? _error;
  List<PublicArticleFeedItem> _items = const [];

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
      final response = await _remote.getPublicFeed(section: 'devotional');
      if (!mounted) return;
      setState(() {
        _items = response.items;
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

  String _subtitleForCard(PublicArticleFeedItem item) {
    final subtitle = item.subtitle?.trim();
    if (subtitle != null && subtitle.isNotEmpty) return subtitle;

    final author = item.authorDisplayName?.trim();
    if (author != null && author.isNotEmpty) return 'oleh $author';

    return '';
  }

  String _snippetForCard(PublicArticleFeedItem item) {
    final snippet = item.snippet?.trim();
    if (snippet != null && snippet.isNotEmpty) return snippet;
    return 'Tap untuk membaca';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Renungan Harian',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hidupi Firman Tuhan dalam tindakan nyata',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Gagal memuat renungan',
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
                ),
              )
            else if (_items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'Belum ada renungan.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index.isOdd) {
                      return const SizedBox(height: 12);
                    }

                    final item = _items[index ~/ 2];
                    return DevotionalCard(
                      title: item.title,
                      verse: _subtitleForCard(item),
                      excerpt: _snippetForCard(item),
                      date: _formatPublishedAt(item.publishedAt),
                      imageUrl: item.coverUrl,
                      likes: 0,
                      onTap: () {
                        context.router.push(
                          ArticleDetailRoute(slug: item.slug),
                        );
                      },
                      onLike: () {
                        // Likes not supported on public feed yet
                      },
                    );
                  }, childCount: (_items.length * 2) - 1),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }
}
