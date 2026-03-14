import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/routine_provider.dart';
import '../../providers/entry_provider.dart';
import '../../providers/locale_provider.dart';
import '../../models/routine.dart';
import '../../models/entry.dart';
import '../../widgets/calendar_widget.dart';
import '../../widgets/entry_card.dart';
import '../add_entry_screen.dart';

/// Home Screen - Calendar View
/// Shows monthly calendar + today's overview
class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const HomeScreen({super.key, this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final isZh = locale.languageCode == 'zh';

    return Scaffold(
      appBar: AppBar(
        title: Text(isZh ? '日历' : 'Calendar'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: _goToToday,
            tooltip: isZh ? '今天' : 'Today',
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar
          CalendarWidget(
            focusedMonth: _focusedMonth,
            selectedDate: _selectedDate,
            entryCounts: _getEntryCounts(),
            onDateSelected: _onDateSelected,
            onMonthChanged: _onMonthChanged,
          ),
          const Divider(height: 1),
          // Today's Overview
          Expanded(
            child: _buildTodayOverview(context),
          ),
        ],
      ),
    );
  }

  /// Get entry counts per date for calendar indicators
  Map<DateTime, int> _getEntryCounts() {
    final entries = context.read<EntryProvider>().entries;
    final Map<DateTime, int> counts = {};
    for (final entry in entries) {
      final date = DateTime(
        entry.createdAt.year,
        entry.createdAt.month,
        entry.createdAt.day,
      );
      counts[date] = (counts[date] ?? 0) + 1;
    }
    return counts;
  }

  void _goToToday() {
    setState(() {
      _selectedDate = DateTime.now();
      _focusedMonth = DateTime.now();
    });
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  void _onMonthChanged(DateTime month) {
    setState(() {
      _focusedMonth = month;
    });
  }

  Widget _buildTodayOverview(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final isZh = locale.languageCode == 'zh';
    final entries = context.watch<EntryProvider>().entries;
    final routines = context.watch<RoutineProvider>().routines;
    final isToday = _isSameDay(_selectedDate, DateTime.now());

    // Get selected day's entries
    final dayEntries = entries.where((e) =>
      _isSameDay(e.createdAt, _selectedDate)
    ).toList();

    // Get selected day's active routines (all routines that should be done daily)
    final activeRoutines = routines.where((r) => r.isActive).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Date Header
        Text(
          DateFormat(isZh ? 'yyyy年M月d日 EEEE' : 'EEEE, MMMM d, yyyy')
              .format(_selectedDate),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Routines Section
        if (activeRoutines.isNotEmpty) ...[
          Text(
            isZh ? '✅ 习惯打卡' : '✅ Habit Check-in',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ...activeRoutines.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildRoutineChecklistItem(context, r),
          )),
          const SizedBox(height: 16),
        ],

        // Entries Section
        if (dayEntries.isNotEmpty) ...[
          Text(
            isZh
                ? (isToday ? '📝 今日记录' : '📝 当日记录')
                : (isToday ? '📝 Today\'s Entries' : '📝 Entries'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ...dayEntries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: EntryCard(
              entry: entry,
              onTap: () => _onEntryTapped(entry),
            ),
          )),
        ],

        // Empty State
        if (dayEntries.isEmpty && activeRoutines.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit_note,
                    size: 48,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isZh
                        ? (isToday ? '今天还没有记录' : '当天没有记录')
                        : (isToday ? 'No entries today' : 'No entries on this day'),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isZh ? '点击 + 添加记录' : 'Tap + to add an entry',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRoutineChecklistItem(BuildContext context, Routine routine) {
    final isCompleted = routine.isCompletedOn(_selectedDate);
    
    return Card(
      child: CheckboxListTile(
        secondary: Icon(
          isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isCompleted ? Colors.green : Colors.grey,
        ),
        title: Text(routine.name),
        value: isCompleted,
        onChanged: (value) {
          context.read<RoutineProvider>().toggleComplete(routine.id, date: _selectedDate);
        },
      ),
    );
  }

  void _onEntryTapped(Entry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEntryScreen(existingEntry: entry),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
