import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/summary_provider.dart';
import '../../providers/tag_provider.dart';

/// 总结 tab — visual summary charts for notes, routines, emotions and tags
class SummaryTab extends StatelessWidget {
  const SummaryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SummaryProvider>();
    final l = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Scope picker
        _ScopePicker(scope: provider.scope, onChanged: provider.setScope),
        const SizedBox(height: 20),

        // 1. Note counts bar chart
        _SectionTitle(title: l.summaryNoteCount),
        const SizedBox(height: 8),
        _NoteCountChart(provider: provider),
        const SizedBox(height: 24),

        // 2. Routine completion horizontal bar chart
        _SectionTitle(title: l.summaryHabitCompletion),
        const SizedBox(height: 8),
        _RoutineCompletionChart(provider: provider),
        const SizedBox(height: 24),

        // 3. Emotion trend line chart
        _SectionTitle(title: l.summaryMoodTrend),
        const SizedBox(height: 8),
        _EmotionTrendChart(provider: provider),
        const SizedBox(height: 24),

        // 4. Top tags
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final s in SummaryScope.values)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(_scopeLabel(s, context)),
              selected: scope == s,
              onSelected: (_) => onChanged(s),
            ),
          ),
      ],
    );
  }

  String _scopeLabel(SummaryScope s, BuildContext context) {
    final l = AppLocalizations.of(context)!;
    switch (s) {
      case SummaryScope.daily:
        return l.summaryScopeDay;
      case SummaryScope.weekly:
        return l.summaryScopeWeek;
      case SummaryScope.monthly:
        return l.summaryScopeMonth;
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.bold));
  }
}

// ============ NOTE COUNT CHART ============

class _NoteCountChart extends StatelessWidget {
  final SummaryProvider provider;
  const _NoteCountChart({required this.provider});

  @override
  Widget build(BuildContext context) {
    final data = provider.noteCounts;
    final hasData = data.any((d) => d.count > 0);

    if (!hasData) {
      return _EmptyPlaceholder(message: AppLocalizations.of(context)!.summaryNoNotes);
    }

    final locale = Localizations.localeOf(context).languageCode;
    final maxCount =
        data.map((d) => d.count).reduce((a, b) => a > b ? a : b).toDouble();

    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxCount + 1,
          barGroups: data
              .asMap()
              .entries
              .map(
                (e) => BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.count.toDouble(),
                      color: Theme.of(context).colorScheme.primary,
                      width: 16,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4)),
                    ),
                  ],
                ),
              )
              .toList(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < data.length) {
                    return Text(
                      _formatDate(data[idx].date, provider.scope, locale),
                      style: const TextStyle(fontSize: 9),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: maxCount > 4 ? (maxCount / 4).ceilToDouble() : 1,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: true),
        ),
      ),
    );
  }
}

// ============ ROUTINE COMPLETION CHART ============

class _RoutineCompletionChart extends StatelessWidget {
  final SummaryProvider provider;
  const _RoutineCompletionChart({required this.provider});

  @override
  Widget build(BuildContext context) {
    final rates = provider.routineCompletionRates;

    final allZero = rates.values.every((v) => v == 0.0);
    if (rates.isEmpty || allZero) {
      return _EmptyPlaceholder(message: AppLocalizations.of(context)!.summaryNoHabits);
    }

    final entries = rates.entries.toList();

    return SizedBox(
      height: (entries.length * 36.0).clamp(80, 250),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 1.0,
          barGroups: entries
              .asMap()
              .entries
              .map(
                (e) => BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.value,
                      color: e.value.value >= 0.7
                          ? Colors.green
                          : e.value.value >= 0.4
                              ? Colors.orange
                              : Colors.red,
                      width: 18,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4)),
                    ),
                  ],
                ),
              )
              .toList(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < entries.length) {
                    final name = entries[idx].key;
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        name.length > 4 ? '${name.substring(0, 4)}…' : name,
                        style: const TextStyle(fontSize: 9),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: 0.25,
                getTitlesWidget: (value, meta) => Text(
                  '${(value * 100).toInt()}%',
                  style: const TextStyle(fontSize: 9),
                ),
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: true, horizontalInterval: 0.25),
        ),
      ),
    );
  }
}

// ============ EMOTION TREND CHART ============

class _EmotionTrendChart extends StatelessWidget {
  final SummaryProvider provider;
  const _EmotionTrendChart({required this.provider});

  @override
  Widget build(BuildContext context) {
    final trend = provider.emotionTrend;
    final hasData = trend.any((d) => d.score > 0);

    if (!hasData) {
      return _EmptyPlaceholder(message: AppLocalizations.of(context)!.summaryNoMood);
    }

    final locale = Localizations.localeOf(context).languageCode;
    final spots = trend
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.score))
        .toList();

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 5.5,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.amber,
              barWidth: 2.5,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.amber.withValues(alpha: 0.15),
              ),
            ),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < trend.length) {
                    return Text(
                      _formatDate(trend[idx].date, provider.scope, locale),
                      style: const TextStyle(fontSize: 9),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final labels = {1.0: '😡', 2.0: '😢', 3.0: '😐', 4.0: '😌', 5.0: '😊'};
                  return Text(labels[value] ?? '', style: const TextStyle(fontSize: 12));
                },
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: true, horizontalInterval: 1),
        ),
      ),
    );
  }
}

// ============ TOP TAGS ============

class _TopTagsChart extends StatelessWidget {
  final SummaryProvider provider;
  const _TopTagsChart({required this.provider});

  @override
  Widget build(BuildContext context) {
    final tagProvider = context.watch<TagProvider>();
    final topTags = provider.topTags;

    if (topTags.isEmpty) {
      return _EmptyPlaceholder(message: AppLocalizations.of(context)!.summaryNoTags);
    }

    final maxCount =
        topTags.map((t) => t.count).reduce((a, b) => a > b ? a : b);

    return Column(
      children: topTags.map((t) {
        final tag = tagProvider.tags.where((tag) => tag.id == t.tagId).isNotEmpty
            ? tagProvider.tags.firstWhere((tag) => tag.id == t.tagId)
            : null;
        final ratio = maxCount > 0 ? t.count / maxCount : 0.0;
        Color tagColor = Colors.blue;
        if (tag != null) {
          final cleaned = tag.color.replaceFirst('#', '');
          final value = int.tryParse(cleaned, radix: 16);
          if (value != null) tagColor = Color(0xFF000000 | value);
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                child: Text(
                  tag?.name ?? t.tagId,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: ratio,
                  color: tagColor,
                  backgroundColor: tagColor.withValues(alpha: 0.15),
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 8),
              Text('${t.count}', style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ============ HELPERS ============

class _EmptyPlaceholder extends StatelessWidget {
  final String message;
  const _EmptyPlaceholder({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(message, style: const TextStyle(color: Colors.grey)),
    );
  }
}

String _formatDate(DateTime date, SummaryScope scope, String locale) {
  switch (scope) {
    case SummaryScope.daily:
      return DateFormat('M/d').format(date);
    case SummaryScope.weekly:
      return DateFormat('M/d').format(date);
    case SummaryScope.monthly:
      return locale.startsWith('zh')
          ? DateFormat('M月').format(date)
          : DateFormat('MMM').format(date);
  }
}
