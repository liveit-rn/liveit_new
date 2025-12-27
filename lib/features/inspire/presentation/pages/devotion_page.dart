import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../widgets/devotional_card.dart';

@RoutePage()
class DevotionPage extends StatelessWidget {
  const DevotionPage({super.key});

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

            // Devotional Cards List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  DevotionalCard(
                    title: 'Hidup dalam Terang-Nya',
                    verse: 'Yohanes 8:12',
                    excerpt:
                        'Aku adalah terang dunia; barangsiapa mengikut Aku, ia tidak akan berjalan dalam kegelapan, melainkan ia akan mempunyai terang hidup.',
                    date: '29 Okt 2025',
                    likes: 124,
                    onTap: () {
                      // Navigate to detail
                    },
                    onLike: () {
                      // Handle like
                    },
                  ),
                  const SizedBox(height: 12),
                  DevotionalCard(
                    title: 'Kasih yang Sempurna',
                    verse: '1 Yohanes 4:18',
                    excerpt:
                        'Di dalam kasih tidak ada ketakutan: kasih yang sempurna melenyapkan ketakutan; sebab ketakutan mengandung hukuman...',
                    date: '28 Okt 2025',
                    likes: 98,
                    onTap: () {
                      // Navigate to detail
                    },
                    onLike: () {
                      // Handle like
                    },
                  ),
                  const SizedBox(height: 12),
                  DevotionalCard(
                    title: 'Berjalan dalam Terang',
                    verse: '1 Yohanes 1:7',
                    excerpt:
                        'Tetapi jika kita hidup di dalam terang sama seperti Dia ada di dalam terang...',
                    date: '27 Okt 2025',
                    likes: 51,
                    onTap: () {
                      // Navigate to detail
                    },
                    onLike: () {
                      // Handle like
                    },
                  ),
                ]),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }
}
