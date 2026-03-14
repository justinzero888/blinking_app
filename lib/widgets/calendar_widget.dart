import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Calendar widget for home screen
/// Displays month view with indicators for days with entries
class CalendarWidget extends StatelessWidget {
  final DateTime selectedDate;
  final DateTime focusedMonth;
  final Map<DateTime, int> entryCounts; // date -> count of entries
  final Map<DateTime, String?> dayEmotions; // date -> dominant emotion emoji
  final Function(DateTime) onDateSelected;
  final Function(DateTime) onMonthChanged;

  const CalendarWidget({
    super.key,
    required this.selectedDate,
    required this.focusedMonth,
    required this.entryCounts,
    this.dayEmotions = const {},
    required this.onDateSelected,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        _buildWeekdayLabels(context),
        _buildCalendarGrid(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              final previousMonth = DateTime(
                focusedMonth.year,
                focusedMonth.month - 1,
              );
              onMonthChanged(previousMonth);
            },
          ),
          Text(
            DateFormat('yyyy年M月').format(focusedMonth),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              final nextMonth = DateTime(
                focusedMonth.year,
                focusedMonth.month + 1,
              );
              onMonthChanged(nextMonth);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayLabels(BuildContext context) {
    const weekdays = ['日', '一', '二', '三', '四', '五', '六'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: weekdays
            .map((day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    final days = _generateDaysInMonth();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        if (day == null) {
          return const SizedBox.shrink();
        }
        return _buildDayCell(context, day);
      },
    );
  }

  Widget _buildDayCell(BuildContext context, DateTime day) {
    final isToday = _isSameDay(day, DateTime.now());
    final isSelected = _isSameDay(day, selectedDate);
    final hasEntries = _hasEntries(day);
    final isCurrentMonth = day.month == focusedMonth.month;
    final dayKey = DateTime(day.year, day.month, day.day);
    final emotion = dayEmotions[dayKey];

    return GestureDetector(
      onTap: () => onDateSelected(day),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : isToday
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : isCurrentMonth
                        ? Colors.black87
                        : Colors.grey,
                fontWeight: isToday || isSelected ? FontWeight.bold : null,
                fontSize: 12,
              ),
            ),
            if (emotion != null)
              Text(emotion, style: const TextStyle(fontSize: 10))
            else if (hasEntries)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<DateTime?> _generateDaysInMonth() {
    final firstDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final lastDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month + 1, 0);
    
    // Get the weekday of the first day (1 = Monday, 7 = Sunday)
    // Convert to Sunday-first: Sunday(7)->0, Monday(1)->1, ..., Saturday(6)->6
    final firstWeekday = firstDayOfMonth.weekday % 7;
    
    final List<DateTime?> days = [];
    
    // Add empty cells for days before the first day of month
    for (int i = 0; i < firstWeekday; i++) {
      days.add(null);
    }
    
    // Add all days of the month
    for (int i = 1; i <= lastDayOfMonth.day; i++) {
      days.add(DateTime(focusedMonth.year, focusedMonth.month, i));
    }
    
    return days;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _hasEntries(DateTime day) {
    return entryCounts.keys.any((date) => _isSameDay(date, day));
  }
}
