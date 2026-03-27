import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/jar_provider.dart';
import '../../providers/entry_provider.dart';
import '../../providers/locale_provider.dart';

/// Detailed view of a year's emotion jars — 3-column month grid
class YearJarDetailScreen extends StatelessWidget {
  final int year;

  const YearJarDetailScreen({super.key, required this.year});

  static const List<String> _monthNamesZh = [
    '一月', '二月', '三月', '四月', '五月', '六月',
    '七月', '八月', '九月', '十月', '十一月', '十二月',
  ];

  static const List<String> _monthNamesEn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final jarProvider = context.watch<JarProvider>();
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final monthNames = isZh ? _monthNamesZh : _monthNamesEn;

    return Scaffold(
      appBar: AppBar(
        title: Text(isZh ? '$year 年情绪罐' : '$year Mood Jars'),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.85,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          final month = index + 1;
          final emotionMap = jarProvider.getMonthEmotionMap(year, month);
          final dominantEmotions = emotionMap.values
              .where((v) => v != null)
              .cast<String>()
              .take(5)
              .toList();
          final entryCount = context
              .read<EntryProvider>()
              .allEntries
              .where(
                  (e) => e.createdAt.year == year && e.createdAt.month == month)
              .length;

          return _MonthCell(
            year: year,
            month: month,
            monthName: monthNames[index],
            dominantEmotions: dominantEmotions,
            entryCount: entryCount,
            isZh: isZh,
          );
        },
      ),
    );
  }
}

class _MonthCell extends StatelessWidget {
  final int year;
  final int month;
  final String monthName;
  final List<String> dominantEmotions;
  final int entryCount;
  final bool isZh;

  const _MonthCell({
    required this.year,
    required this.month,
    required this.monthName,
    required this.dominantEmotions,
    required this.entryCount,
    required this.isZh,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: entryCount > 0
          ? () => _showMonthDayList(context)
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: entryCount > 0
              ? const Color(0xFFFFE082).withValues(alpha: 0.25)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: entryCount > 0
                ? const Color(0xFFFFB300).withValues(alpha: 0.4)
                : Colors.grey[300]!,
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              monthName,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            if (dominantEmotions.isNotEmpty)
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 1,
                runSpacing: 1,
                children: dominantEmotions
                    .map((e) => Text(e, style: const TextStyle(fontSize: 14)))
                    .toList(),
              )
            else
              Text(
                entryCount > 0
                    ? (isZh ? '无情绪' : 'No mood')
                    : (isZh ? '无记录' : 'Empty'),
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
            const SizedBox(height: 4),
            Text(
              isZh ? '$entryCount 条' : '$entryCount',
              style: TextStyle(
                fontSize: 11,
                color: entryCount > 0 ? Colors.grey[600] : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMonthDayList(BuildContext context) {
    final entries = context
        .read<EntryProvider>()
        .allEntries
        .where((e) => e.createdAt.year == year && e.createdAt.month == month)
        .toList();

    // Group by day
    final grouped = <int, List<String>>{};
    for (final entry in entries) {
      final day = entry.createdAt.day;
      grouped.putIfAbsent(day, () => []);
      if (entry.emotion != null) {
        grouped[day]!.add(entry.emotion!);
      }
    }
    final days = grouped.keys.toList()..sort();

    final title = isZh ? '$year年$month月' : '${_monthFull(month)} $year';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: days.length,
                itemBuilder: (context, index) {
                  final day = days[index];
                  final emotions = grouped[day] ?? [];
                  final dayEntries = entries
                      .where((e) => e.createdAt.day == day)
                      .toList();
                  return ListTile(
                    leading: Text(
                      isZh ? '$day日' : '$day',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    title: emotions.isNotEmpty
                        ? Text(emotions.join(' '))
                        : Text(
                            isZh ? '无情绪' : 'No mood',
                            style: const TextStyle(color: Colors.grey),
                          ),
                    subtitle: Text(
                      isZh
                          ? '${dayEntries.length} 条记录'
                          : '${dayEntries.length} ${dayEntries.length == 1 ? 'entry' : 'entries'}',
                    ),
                    trailing: dayEntries.isNotEmpty
                        ? Text(
                            dayEntries.first.content.length > 20
                                ? '${dayEntries.first.content.substring(0, 20)}...'
                                : dayEntries.first.content,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          )
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthFull(int m) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[m - 1];
  }
}
