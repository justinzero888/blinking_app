import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../providers/summary_provider.dart';
import '../../providers/tag_provider.dart';
import '../../providers/jar_provider.dart';
import '../../widgets/emoji_jar.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    return Scaffold(
      appBar: AppBar(
        title: Text(isZh ? '洞察' : 'Insights'),
        centerTitle: true,
      ),
      body: const _InsightsContent(),
    );
  }
}

class _InsightsContent extends StatelessWidget {
  const _InsightsContent();

  @override
  Widget build(BuildContext context) {
    final jarProvider = context.watch<JarProvider>();
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final years = jarProvider.yearsWithData;

    if (years.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.insights,
                  size: 48, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                isZh ? '开始记录即可查看洞察' : 'Start journaling to see insights',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _EmojiJarSection(years: years, isZh: isZh),
        const SizedBox(height: 24),
        const _SummaryCharts(),
      ],
    );
  }
}

class _EmojiJarSection extends StatelessWidget {
  final List<int> years;
  final bool isZh;

  const _EmojiJarSection({required this.years, required this.isZh});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isZh ? '🫙 情绪罐' : '🫙 Mood Jars',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: years.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final year = years[index];
              final jarProvider = context.watch<JarProvider>();
              final emotions = jarProvider.getYearEmotions(year);
              final entryCount = jarProvider.getYearEntryCount(year);

              return SizedBox(
                width: 120,
                child: Column(
                  children: [
                    EmojiJarWidget(
                      date: DateTime(year),
                      emotionsOverride: emotions,
                      size: 120,
                      showAskAi: false,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$year',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      isZh ? '$entryCount 条记录' : '$entryCount entries',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SummaryCharts extends StatelessWidget {
  const _SummaryCharts();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SummaryProvider>();
    final l = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ScopePicker(
            scope: provider.scope, onChanged: provider.setScope),
        const SizedBox(height: 20),

        _SectionTitle(title: l.summaryNoteCount),
        const SizedBox(height: 8),
        _NoteCountChart(provider: provider),
        const SizedBox(height: 24),

        _SectionTitle(title: l.summaryHabitCompletion),
        const SizedBox(height: 8),
        _RoutineCompletionChart(provider: provider),
        const SizedBox(height: 24),

        _SectionTitle(title: l.summaryMoodTrend),
        const SizedBox(height: 8),
        _EmotionTrendChart(provider: provider),
        const SizedBox(height: 24),

        _SectionTitle(title: l.summaryTopTags),
        const SizedBox(height: 8),
        _TopTagsChart(provider: provider),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _ScopePicker extends StatelessWidget {
  final SummaryScope scope;
  final void Function(SummaryScope) onChanged;

  const _ScopePicker({required this.scope, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ScopeChip(
          label: isZh ? '日' : 'Day',
          selected: scope == SummaryScope.daily,
          onTap: () => onChanged(SummaryScope.daily),
        ),
        const SizedBox(width: 8),
        _ScopeChip(
          label: isZh ? '周' : 'Week',
          selected: scope == SummaryScope.weekly,
          onTap: () => onChanged(SummaryScope.weekly),
        ),
        const SizedBox(width: 8),
        _ScopeChip(
          label: isZh ? '月' : 'Month',
          selected: scope == SummaryScope.monthly,
          onTap: () => onChanged(SummaryScope.monthly),
        ),
      ],
    );
  }
}

class _ScopeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ScopeChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleSmall
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _NoteCountChart extends StatelessWidget {
  final SummaryProvider provider;
  const _NoteCountChart({required this.provider});

  @override
  Widget build(BuildContext context) {
    final counts = provider.noteCounts;
    if (counts.isEmpty) {
      return const _EmptyChart();
    }
    final maxCount = counts.map((c) => c.count).reduce((a, b) => a > b ? a : b);
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final dateFormat = DateFormat(isZh ? 'M/d' : 'M/d');

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (maxCount * 1.2).ceilToDouble().clamp(1, double.infinity),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${counts[group.x.toInt()].count}',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < counts.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        dateFormat.format(counts[index].date),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: counts.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.count.toDouble(),
                  color: const Color(0xFF2A9D8F),
                  width: 16,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _RoutineCompletionChart extends StatelessWidget {
  final SummaryProvider provider;
  const _RoutineCompletionChart({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final rates = provider.routineCompletionRates(isZh: isZh);
    final allZero = rates.isEmpty || rates.values.every((v) => v == 0.0);
    if (allZero) {
      return const _EmptyChart();
    }
    final entries = rates.entries.toList();

    return SizedBox(
      height: entries.length * 40.0 + 20,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 1.0,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${(entries[group.x.toInt()].value * 100).toStringAsFixed(0)}%',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < entries.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        entries[index].key,
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: entries.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.value,
                  color: const Color(0xFF2A9D8F),
                  width: 16,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _EmotionTrendChart extends StatelessWidget {
  final SummaryProvider provider;
  const _EmotionTrendChart({required this.provider});

  @override
  Widget build(BuildContext context) {
    final trend = provider.emotionTrend;
    if (trend.isEmpty) {
      return const _EmptyChart();
    }

    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final dateFormat = DateFormat(isZh ? 'M/d' : 'M/d');
    final minVal = 1.0;
    final maxVal = 5.0;

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: minVal - 0.5,
          maxY: maxVal + 0.5,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  final emojis = ['', '😡', '😢', '😐', '😌', '😊'];
                  final idx = spot.y.round().clamp(1, 5);
                  return LineTooltipItem(
                    emojis[idx],
                    const TextStyle(fontSize: 20),
                  );
                }).toList();
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval:
                    (trend.length / 5).ceilToDouble().clamp(1, 100),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < trend.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        dateFormat.format(trend[index].date),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: trend.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value.score);
              }).toList(),
              isCurved: true,
              color: const Color(0xFF2A9D8F),
              barWidth: 2,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF2A9D8F).withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopTagsChart extends StatelessWidget {
  final SummaryProvider provider;
  const _TopTagsChart({required this.provider});

  @override
  Widget build(BuildContext context) {
    final tagProvider = context.watch<TagProvider>();
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final topTags = provider.topTags;
    if (topTags.isEmpty) {
      return const _EmptyChart();
    }
    final maxCount =
        topTags.map((t) => t.count).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: topTags.length * 36.0 + 20,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (maxCount * 1.2).ceilToDouble().clamp(1, double.infinity),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${topTags[group.x.toInt()].count}',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < topTags.length) {
                    final tagId = topTags[index].tagId;
                    final tag = tagProvider.tags.firstWhere(
                      (t) => t.id == tagId,
                      orElse: () => tagProvider.tags.first,
                    );
                    final name = isZh
                        ? tag.name
                        : (tag.nameEn.isNotEmpty ? tag.nameEn : tag.name);
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        name,
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: topTags.asMap().entries.map((e) {
            final tag = tagProvider.tags.firstWhere(
              (t) => t.id == e.value.tagId,
              orElse: () => tagProvider.tags.first,
            );
            final color = _parseHexColor(tag.color);
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.count.toDouble(),
                  color: color,
                  width: 16,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

Color _parseHexColor(String hex) {
  hex = hex.replaceFirst('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  return Color(int.parse(hex, radix: 16));
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    return SizedBox(
      height: 120,
      child: Center(
        child: Text(
          isZh ? '暂无数据' : 'No data yet',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.grey),
        ),
      ),
    );
  }
}
