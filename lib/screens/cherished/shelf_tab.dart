import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/jar_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/emoji_jar.dart';
import 'year_jar_detail_screen.dart';

/// 书架 tab — shows a vertical list of year cards with mini emoji jars
class ShelfTab extends StatelessWidget {
  const ShelfTab({super.key});

  @override
  Widget build(BuildContext context) {
    final jarProvider = context.watch<JarProvider>();
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final years = jarProvider.yearsWithData;

    if (years.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🫙', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              isZh ? '情绪罐书架' : 'Mood Jar Shelf',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              isZh
                  ? '开始记录情绪，这里将收藏每一天的心情'
                  : 'Start recording your mood — each day will be saved here',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: years.length,
      itemBuilder: (context, index) {
        final year = years[index];
        return _YearCard(year: year, jarProvider: jarProvider, isZh: isZh);
      },
    );
  }
}

class _YearCard extends StatelessWidget {
  final int year;
  final JarProvider jarProvider;
  final bool isZh;

  const _YearCard({required this.year, required this.jarProvider, required this.isZh});

  @override
  Widget build(BuildContext context) {
    final emotions = jarProvider.getYearEmotions(year);
    final count = jarProvider.getYearEntryCount(year);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => YearJarDetailScreen(year: year),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Mini emoji jar — reuses EmojiJarWidget with yearly aggregates
              EmojiJarWidget(
                date: DateTime(year),
                size: 80,
                emotionsOverride: emotions,
                showAskAi: false,
              ),
              const SizedBox(width: 16),
              // Year info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isZh ? '$year 年' : '$year',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isZh ? '$count 条记录' : '$count entries',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    if (emotions.isNotEmpty)
                      Text(
                        isZh ? '${emotions.length} 个情绪' : '${emotions.length} moods',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
