import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/jar_provider.dart';
import 'year_jar_detail_screen.dart';

/// 书架 tab — shows a vertical list of year cards with mini emoji jars
class ShelfTab extends StatelessWidget {
  const ShelfTab({super.key});

  @override
  Widget build(BuildContext context) {
    final jarProvider = context.watch<JarProvider>();
    final years = jarProvider.yearsWithData;

    if (years.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🫙', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              '情绪罐书架',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '开始记录情绪，这里将收藏每一天的心情',
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
        return _YearCard(year: year, jarProvider: jarProvider);
      },
    );
  }
}

class _YearCard extends StatelessWidget {
  final int year;
  final JarProvider jarProvider;

  const _YearCard({required this.year, required this.jarProvider});

  @override
  Widget build(BuildContext context) {
    final emotions = jarProvider.getYearEmotions(year);
    final count = jarProvider.getYearEntryCount(year);
    final displayEmotions = emotions.take(20).toList();

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
              // Mini emoji jar display
              Container(
                width: 80,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE082).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.5),
                  ),
                ),
                child: displayEmotions.isEmpty
                    ? const Center(
                        child:
                            Text('空', style: TextStyle(color: Colors.grey)))
                    : Padding(
                        padding: const EdgeInsets.all(4),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 1,
                          runSpacing: 1,
                          children: displayEmotions
                              .map((e) =>
                                  Text(e, style: const TextStyle(fontSize: 12)))
                              .toList(),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              // Year info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$year 年',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count 条记录',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    if (emotions.isNotEmpty)
                      Text(
                        '${emotions.length} 个情绪',
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
