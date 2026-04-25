import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/routine_provider.dart';
import '../../providers/entry_provider.dart';
import '../../providers/locale_provider.dart';
import '../../models/routine.dart';
import '../../models/entry.dart';
import '../../widgets/calendar_widget.dart';
import '../../widgets/entry_card.dart';
import '../../widgets/emoji_jar.dart';
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
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('onboarding_done') ?? false;
    if (!done && mounted) {
      setState(() => _showOnboarding = true);
    }
  }

  Future<void> _dismissOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) setState(() => _showOnboarding = false);
  }

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
          // Onboarding banner (first-launch only)
          if (_showOnboarding) _OnboardingBanner(onDismiss: _dismissOnboarding),
          // Calendar
          CalendarWidget(
            focusedMonth: _focusedMonth,
            selectedDate: _selectedDate,
            entryCounts: _getEntryCounts(),
            dayEmotions: _getDayEmotions(),
            dayHabitStatus: _getDayHabitStatus(),
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

  /// Get dominant emotion per date for calendar display
  Map<DateTime, String?> _getDayEmotions() {
    final entryProvider = context.read<EntryProvider>();
    final datesWithEntries = entryProvider.getDatesWithEntries();
    final Map<DateTime, String?> emotions = {};
    for (final date in datesWithEntries) {
      final emotion = entryProvider.getDayEmotion(date);
      if (emotion != null) {
        emotions[date] = emotion;
      }
    }
    return emotions;
  }

  /// Compute habit completion status for each date in the focused month.
  Map<DateTime, ({int completed, int total})> _getDayHabitStatus() {
    final routineProvider = context.read<RoutineProvider>();
    final result = <DateTime, ({int completed, int total})>{};
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    for (int i = 0; i < lastDay.day; i++) {
      final day = firstDay.add(Duration(days: i));
      final dayKey = DateTime(day.year, day.month, day.day);
      final scheduled = routineProvider.getRoutinesForDate(day);
      if (scheduled.isEmpty) continue;
      final completed = scheduled.where((r) => r.isCompletedOn(day)).length;
      result[dayKey] = (completed: completed, total: scheduled.length);
    }
    return result;
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
    final routineProvider = context.watch<RoutineProvider>();
    final isToday = _isSameDay(_selectedDate, DateTime.now());
    final isPastDay = !isToday && _selectedDate.isBefore(DateTime.now());
    final dayRoutines = routineProvider.getRoutinesForDate(_selectedDate);

    // Get selected day's entries
    final dayEntries = entries.where((e) =>
      _isSameDay(e.createdAt, _selectedDate)
    ).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Date Header
        Row(
          children: [
            Expanded(
              child: Text(
                DateFormat(isZh ? 'yyyy年M月d日 EEEE' : 'EEEE, MMMM d, yyyy')
                    .format(_selectedDate),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Builder(builder: (context) {
              final emotion = context.watch<EntryProvider>().getDayEmotion(_selectedDate);
              if (emotion == null) return const SizedBox.shrink();
              return Text(emotion, style: const TextStyle(fontSize: 22));
            }),
          ],
        ),
        const SizedBox(height: 16),

        // Routines Section
        if (dayRoutines.isNotEmpty) ...[
          Text(
            isZh ? '✅ 习惯打卡' : '✅ Habit Check-in',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          // Pending: for past days consolidate into a red icon row;
          // for today show individually with checkbox
          Builder(builder: (context) {
            final pending = dayRoutines
                .where((r) => !r.isCompletedOn(_selectedDate))
                .toList();
            if (pending.isEmpty) return const SizedBox.shrink();
            if (isPastDay) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 18),
                        const SizedBox(width: 8),
                        Wrap(
                          spacing: 6,
                          children: pending
                              .map((r) => Text(r.effectiveIcon,
                                  style: const TextStyle(fontSize: 22)))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: pending
                  .map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildRoutineChecklistItem(context, r),
                      ))
                  .toList(),
            );
          }),
          // Completed: one consolidated icon row
          Builder(builder: (context) {
            final done = dayRoutines
                .where((r) => r.isCompletedOn(_selectedDate))
                .toList();
            if (done.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Wrap(
                        spacing: 6,
                        children: done
                            .map((r) => Text(r.effectiveIcon,
                                style: const TextStyle(fontSize: 22)))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
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

        // Emoji Jar Section — show when there are entries for the day
        if (dayEntries.isNotEmpty) ...[
          const SizedBox(height: 16),
          _EmojiJarSection(date: _selectedDate),
        ],

        // Empty State
        if (dayEntries.isEmpty && dayRoutines.isEmpty)
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

  Widget _buildRoutineChecklistItem(BuildContext context, Routine routine, {bool readOnly = false}) {
    final isCompleted = routine.isCompletedOn(_selectedDate);
    final isMissed = readOnly && !isCompleted;
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';

    return Card(
      child: CheckboxListTile(
        secondary: readOnly
            ? Icon(
                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isCompleted ? Colors.green : Colors.grey,
              )
            : Icon(
                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isCompleted ? Colors.green : Colors.grey,
              ),
        title: Text(
          routine.displayName(isZh),
          style: TextStyle(
            color: isMissed ? Colors.red[300] : null,
          ),
        ),
        value: isCompleted,
        onChanged: readOnly
            ? null
            : (value) {
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

/// First-launch onboarding banner shown at the top of the Calendar screen
class _OnboardingBanner extends StatelessWidget {
  final VoidCallback onDismiss;
  const _OnboardingBanner({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              isZh
                  ? '欢迎使用 Blinking 记忆闪烁。生命是一呼一吸、一食一化、一睁一闭。留意、记取，且惜取身边点滴清欢。'
                  : 'Welcome to Blinking Notes. Life is breath in and out, eat and digest, blink — eyes open and shut. Notice, note, and cherish the little things around you.',
              style: TextStyle(
                color: primaryColor,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(Icons.close, size: 18, color: primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Collapsible "今日情绪罐" section with EmojiJarWidget
class _EmojiJarSection extends StatefulWidget {
  final DateTime date;
  const _EmojiJarSection({required this.date});

  @override
  State<_EmojiJarSection> createState() => _EmojiJarSectionState();
}

class _EmojiJarSectionState extends State<_EmojiJarSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Text('🫙', style: TextStyle(fontSize: 20)),
            title: Text(isZh ? '今日情绪罐' : "Today's Mood Jar",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: IconButton(
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: EmojiJarWidget(date: widget.date),
            ),
        ],
      ),
    );
  }
}
