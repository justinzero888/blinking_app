import 'package:flutter/foundation.dart';
import 'entry_provider.dart';
import 'routine_provider.dart';

enum SummaryScope { daily, weekly, monthly }

/// Simple date range helper
class _DateRange {
  final DateTime start;
  final DateTime end;
  const _DateRange({required this.start, required this.end});
}

/// Provides aggregated statistics for the visual summary tab
class SummaryProvider extends ChangeNotifier {
  EntryProvider _entryProvider;
  RoutineProvider _routineProvider;
  SummaryScope _scope = SummaryScope.weekly;

  SummaryProvider(this._entryProvider, this._routineProvider);

  void update(EntryProvider ep, RoutineProvider rp) {
    _entryProvider = ep;
    _routineProvider = rp;
    notifyListeners();
  }

  SummaryScope get scope => _scope;
  void setScope(SummaryScope s) {
    _scope = s;
    notifyListeners();
  }

  /// Returns date range for current scope ending now
  _DateRange get _currentRange {
    final now = DateTime.now();
    switch (_scope) {
      case SummaryScope.daily:
        return _DateRange(
          start: DateTime(now.year, now.month, now.day)
              .subtract(const Duration(days: 6)),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case SummaryScope.weekly:
        return _DateRange(
          start: DateTime(now.year, now.month, now.day)
              .subtract(const Duration(days: 7 * 7)),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case SummaryScope.monthly:
        return _DateRange(
          start: DateTime(now.year, now.month - 5, 1),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
    }
  }

  /// Note counts per period
  List<({DateTime date, int count})> get noteCounts {
    final entries = _entryProvider.allEntries;
    final now = DateTime.now();

    switch (_scope) {
      case SummaryScope.daily:
        return List.generate(7, (i) {
          final day = DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: 6 - i));
          final count = entries.where((e) =>
              e.createdAt.year == day.year &&
              e.createdAt.month == day.month &&
              e.createdAt.day == day.day).length;
          return (date: day, count: count);
        });

      case SummaryScope.weekly:
        return List.generate(8, (i) {
          final weekStart = DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: (7 - i) * 7));
          final weekEnd = weekStart.add(const Duration(days: 7));
          final count = entries.where((e) =>
              e.createdAt.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
              e.createdAt.isBefore(weekEnd)).length;
          return (date: weekStart, count: count);
        });

      case SummaryScope.monthly:
        return List.generate(6, (i) {
          final month = DateTime(now.year, now.month - (5 - i), 1);
          final count = entries.where((e) =>
              e.createdAt.year == month.year &&
              e.createdAt.month == month.month).length;
          return (date: month, count: count);
        });
    }
  }

  /// Routine completion rate per routine (name → % 0.0-1.0)
  Map<String, double> get routineCompletionRates {
    final routines = _routineProvider.routines;
    final range = _currentRange;
    final result = <String, double>{};

    for (final routine in routines) {
      if (!routine.isActive) continue;
      // Count days in range
      final totalDays = range.end.difference(range.start).inDays + 1;
      if (totalDays <= 0) continue;
      final completedDays = routine.completionLog.where((log) =>
          log.completedAt.isAfter(range.start.subtract(const Duration(days: 1))) &&
          log.completedAt.isBefore(range.end.add(const Duration(days: 1)))).length;
      result[routine.name] = (completedDays / totalDays).clamp(0.0, 1.0);
    }
    return result;
  }

  static const Map<String, double> _emotionScores = {
    '😊': 5.0,
    '🥰': 5.0,
    '🤩': 5.0,
    '😌': 4.0,
    '😐': 3.0,
    '😴': 3.0,
    '😔': 2.0,
    '😢': 2.0,
    '😰': 2.0,
    '😤': 2.0,
    '😡': 1.0,
  };

  /// Emotion trend: list of ({date, score})
  List<({DateTime date, double score})> get emotionTrend {
    final entries = _entryProvider.allEntries
        .where((e) => e.emotion != null)
        .toList();
    final now = DateTime.now();

    switch (_scope) {
      case SummaryScope.daily:
        return List.generate(7, (i) {
          final day = DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: 6 - i));
          final dayEntries = entries.where((e) =>
              e.createdAt.year == day.year &&
              e.createdAt.month == day.month &&
              e.createdAt.day == day.day);
          double score = 0;
          int count = 0;
          for (final e in dayEntries) {
            final s = _emotionScores[e.emotion] ?? 3.0;
            score += s;
            count++;
          }
          return (date: day, score: count > 0 ? score / count : 0.0);
        });

      case SummaryScope.weekly:
        return List.generate(8, (i) {
          final weekStart = DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: (7 - i) * 7));
          final weekEnd = weekStart.add(const Duration(days: 7));
          final weekEntries = entries.where((e) =>
              e.createdAt.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
              e.createdAt.isBefore(weekEnd));
          double score = 0;
          int count = 0;
          for (final e in weekEntries) {
            final s = _emotionScores[e.emotion] ?? 3.0;
            score += s;
            count++;
          }
          return (date: weekStart, score: count > 0 ? score / count : 0.0);
        });

      case SummaryScope.monthly:
        return List.generate(6, (i) {
          final month = DateTime(now.year, now.month - (5 - i), 1);
          final monthEntries = entries.where((e) =>
              e.createdAt.year == month.year &&
              e.createdAt.month == month.month);
          double score = 0;
          int count = 0;
          for (final e in monthEntries) {
            final s = _emotionScores[e.emotion] ?? 3.0;
            score += s;
            count++;
          }
          return (date: month, score: count > 0 ? score / count : 0.0);
        });
    }
  }

  /// Top 5 tags by usage count (tagId → count)
  List<({String tagId, int count})> get topTags {
    final counts = <String, int>{};
    for (final entry in _entryProvider.allEntries) {
      for (final tagId in entry.tagIds) {
        counts[tagId] = (counts[tagId] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .take(5)
        .map((e) => (tagId: e.key, count: e.value))
        .toList();
  }
}
