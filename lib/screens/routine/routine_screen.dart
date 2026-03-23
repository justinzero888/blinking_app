import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/file_service.dart';
import '../../providers/routine_provider.dart';
import '../../providers/locale_provider.dart';
import '../../models/routine.dart';

/// Renders a routine's icon: custom image if set, else emoji fallback.
Widget _buildRoutineIcon(Routine routine, {double size = 20}) {
  if (routine.iconImagePath != null) {
    final file = File(routine.iconImagePath!);
    if (file.existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.file(file,
            width: size, height: size, fit: BoxFit.cover),
      );
    }
  }
  return Text(routine.effectiveIcon, style: TextStyle(fontSize: size));
}

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // Adhoc routines manually added to today's list (in-memory, not persisted)
  final Set<String> _manuallyAddedToday = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    return Scaffold(
      appBar: AppBar(
        title: Text(isZh ? '日常' : 'Routines'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddRoutineDialog(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: isZh ? '全部' : 'All'),
            Tab(text: isZh ? '今日' : 'Today'),
            Tab(text: isZh ? '记录' : 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AllTab(onEdit: _showEditRoutineDialog),
          _TodayTab(
            manuallyAdded: _manuallyAddedToday,
            onManualAdd: (id) => setState(() => _manuallyAddedToday.add(id)),
          ),
          const _RecordTab(),
        ],
      ),
    );
  }

  void _showAddRoutineDialog(BuildContext context) {
    _RoutineDialog.show(context, existing: null);
  }

  void _showEditRoutineDialog(BuildContext context, Routine routine) {
    _RoutineDialog.show(context, existing: routine);
  }
}

// ─────────────────────────────────────────────
// Tab 1 — 全部
// ─────────────────────────────────────────────
class _AllTab extends StatelessWidget {
  final void Function(BuildContext, Routine) onEdit;
  const _AllTab({required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final routines = context.watch<RoutineProvider>().routines;
    final active = routines.where((r) => r.isActive).toList();
    final paused = routines.where((r) => !r.isActive).toList();

    if (routines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(isZh ? '还没有日常习惯' : 'No routines yet',
                style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (active.isNotEmpty) ...[
          _sectionHeader(isZh ? '活跃' : 'Active'),
          const SizedBox(height: 8),
          ...active.map((r) => _RoutineTile(
                routine: r,
                onEdit: () => onEdit(context, r),
              )),
          const SizedBox(height: 16),
        ],
        if (paused.isNotEmpty) ...[
          _sectionHeader(isZh ? '已暂停' : 'Paused'),
          const SizedBox(height: 8),
          ...paused.map((r) => _RoutineTile(
                routine: r,
                onEdit: () => onEdit(context, r),
              )),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Tab 2 — 今日
// ─────────────────────────────────────────────
class _TodayTab extends StatelessWidget {
  final Set<String> manuallyAdded;
  final void Function(String id) onManualAdd;

  const _TodayTab({required this.manuallyAdded, required this.onManualAdd});

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final provider = context.watch<RoutineProvider>();
    final today = DateTime.now();
    final scheduled = provider.getRoutinesForDate(today);

    // Include manually-added adhoc routines
    final adhocAdded = provider.adhocRoutines
        .where((r) => manuallyAdded.contains(r.id))
        .toList();
    final allToday = [...scheduled, ...adhocAdded];

    final pending = allToday.where((r) => !r.isCompletedToday).toList();
    final completed = allToday.where((r) => r.isCompletedToday).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pending.isNotEmpty) ...[
          _sectionHeader(isZh ? '待完成' : 'Pending'),
          const SizedBox(height: 8),
          ...pending.map((r) => _TodayRoutineTile(routine: r, isCompleted: false)),
          const SizedBox(height: 16),
        ],
        if (completed.isNotEmpty) ...[
          _sectionHeader(isZh ? '已完成' : 'Completed'),
          const SizedBox(height: 8),
          ...completed.map((r) => _TodayRoutineTile(routine: r, isCompleted: true)),
          const SizedBox(height: 16),
        ],
        if (allToday.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(
              isZh
                  ? '今日无安排\n点击"手动加入"添加临时习惯'
                  : 'Nothing scheduled today\nTap "Add" to include an ad-hoc routine',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
        // Manual add button for adhoc routines
        _ManualAddButton(
          manuallyAdded: manuallyAdded,
          onAdd: onManualAdd,
        ),
      ],
    );
  }
}

class _TodayRoutineTile extends StatelessWidget {
  final Routine routine;
  final bool isCompleted;
  const _TodayRoutineTile({required this.routine, required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: GestureDetector(
          onTap: () {
            if (isCompleted) {
              context.read<RoutineProvider>().unmarkRoutine(routine.id);
            } else {
              context.read<RoutineProvider>().completeRoutine(routine.id);
            }
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.green.withValues(alpha: 0.15)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: isCompleted
                ? const Icon(Icons.check_circle, color: Colors.green, size: 24)
                : Center(
                    child: _buildRoutineIcon(routine, size: 20),
                  ),
          ),
        ),
        title: Text(
          routine.name,
          style: TextStyle(
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Text(
          routine.frequencyLabelFor(isZh),
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ),
    );
  }
}

class _ManualAddButton extends StatelessWidget {
  final Set<String> manuallyAdded;
  final void Function(String) onAdd;
  const _ManualAddButton({required this.manuallyAdded, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final adhoc = context.read<RoutineProvider>().adhocRoutines;
    if (adhoc.isEmpty) return const SizedBox.shrink();

    return TextButton.icon(
      onPressed: () => _showPicker(context, adhoc),
      icon: const Icon(Icons.add),
      label: Text(isZh ? '手动加入' : 'Add'),
    );
  }

  void _showPicker(BuildContext context, List<Routine> adhoc) {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        children: [
          Text(isZh ? '选择临时习惯' : 'Select Ad-hoc Routine',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ...adhoc.map((r) => ListTile(
                leading: _buildRoutineIcon(r, size: 22),
                title: Text(r.name),
                trailing: manuallyAdded.contains(r.id)
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  onAdd(r.id);
                  Navigator.pop(context);
                },
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Tab 3 — 记录
// ─────────────────────────────────────────────
class _RecordTab extends StatelessWidget {
  const _RecordTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoutineProvider>();
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);

    // Build list of past 60 days (excluding today), most recent first
    final days = List.generate(60, (i) {
      return todayNorm.subtract(Duration(days: i + 1));
    });

    // Only include days that had at least one scheduled routine
    final daysWithData = days.where((day) {
      return provider.getRoutinesForDate(day).isNotEmpty;
    }).toList();

    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    if (daysWithData.isEmpty) {
      return Center(
        child: Text(
          isZh ? '还没有历史记录' : 'No history yet',
          style: TextStyle(color: Colors.grey[500]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: daysWithData.length,
      itemBuilder: (context, index) {
        final day = daysWithData[index];
        final routines = provider.getRoutinesForDate(day);
        return _DayRecord(day: day, routines: routines, provider: provider);
      },
    );
  }
}

class _DayRecord extends StatelessWidget {
  final DateTime day;
  final List<Routine> routines;
  final RoutineProvider provider;

  const _DayRecord({
    required this.day,
    required this.routines,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final label = isZh
        ? DateFormat('M月d日 (EEE)', 'zh').format(day)
        : DateFormat('MMM d (EEE)').format(day);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(width: 8),
              const Expanded(child: Divider()),
            ],
          ),
        ),
        ...routines.map((r) {
          final done = r.isCompletedOn(day);
          final missed = provider.isMissedOn(r, day);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                _buildRoutineIcon(r, size: 18),
                const SizedBox(width: 12),
                Expanded(child: Text(r.name)),
                if (done)
                  const Icon(Icons.check_circle, color: Colors.green, size: 20)
                else if (missed)
                  const Icon(Icons.cancel, color: Colors.red, size: 20)
                else
                  Icon(Icons.remove, color: Colors.grey[400], size: 20),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Shared tile for 全部 tab
// ─────────────────────────────────────────────
class _RoutineTile extends StatelessWidget {
  final Routine routine;
  final VoidCallback onEdit;
  const _RoutineTile({required this.routine, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: routine.isActive
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: _buildRoutineIcon(routine, size: 20),
          ),
        ),
        title: Text(
          routine.name,
          style: TextStyle(color: routine.isActive ? null : Colors.grey),
        ),
        subtitle: Text(
          routine.frequencyLabelFor(isZh),
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: Builder(
          builder: (ctx) {
            final isZh = ctx.watch<LocaleProvider>().locale.languageCode == 'zh';
            return PopupMenuButton<String>(
              onSelected: (value) => _onMenuSelected(context, value),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Text(isZh ? '编辑' : 'Edit'),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(routine.isActive
                      ? (isZh ? '暂停' : 'Pause')
                      : (isZh ? '恢复' : 'Resume')),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(isZh ? '删除' : 'Delete',
                      style: const TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _onMenuSelected(BuildContext context, String value) {
    final provider = context.read<RoutineProvider>();
    switch (value) {
      case 'edit':
        onEdit();
      case 'toggle':
        provider.toggleActive(routine.id);
      case 'delete':
        _confirmDelete(context, provider);
    }
  }

  void _confirmDelete(BuildContext context, RoutineProvider provider) {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isZh ? '确认删除' : 'Confirm Delete'),
        content: Text(isZh ? '确定要删除这个习惯吗？' : 'Delete this routine?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isZh ? '取消' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteRoutine(routine.id);
              Navigator.pop(ctx);
            },
            child: Text(isZh ? '删除' : 'Delete',
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Section header helper
// ─────────────────────────────────────────────
Widget _sectionHeader(String title) {
  return Text(
    title,
    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
  );
}

// ─────────────────────────────────────────────
// Add / Edit dialog
// ─────────────────────────────────────────────
class _RoutineDialog {
  static void show(BuildContext context, {Routine? existing}) {
    showDialog(
      context: context,
      builder: (_) => _RoutineDialogWidget(existing: existing),
    );
  }
}

class _RoutineDialogWidget extends StatefulWidget {
  final Routine? existing;
  const _RoutineDialogWidget({this.existing});

  @override
  State<_RoutineDialogWidget> createState() => _RoutineDialogWidgetState();
}

class _RoutineDialogWidgetState extends State<_RoutineDialogWidget> {
  late TextEditingController _nameController;
  late TextEditingController _reminderController;
  late RoutineFrequency _frequency;
  late List<int> _selectedDays; // for weekly
  DateTime? _scheduledDate;     // for scheduled
  RoutineCategory? _category;
  String? _iconImagePath;

  static const List<String> _dayLabelsZh = ['', '一', '二', '三', '四', '五', '六', '日'];
  static const List<String> _dayLabelsEn = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    final r = widget.existing;
    _nameController = TextEditingController(text: r?.name ?? '');
    _reminderController = TextEditingController(text: r?.reminderTime ?? '');
    _frequency = r?.frequency ?? RoutineFrequency.daily;
    _selectedDays = List<int>.from(r?.scheduledDaysOfWeek ?? []);
    _scheduledDate = r?.scheduledDate;
    _category = r?.category;
    _iconImagePath = r?.iconImagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _reminderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? (isZh ? '编辑习惯' : 'Edit Routine') : (isZh ? '添加习惯' : 'Add Routine')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon picker
            Center(
              child: GestureDetector(
                onTap: _pickIcon,
                onLongPress: () => setState(() => _iconImagePath = null),
                child: Stack(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _iconImagePath != null &&
                              File(_iconImagePath!).existsSync()
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(File(_iconImagePath!),
                                  fit: BoxFit.cover),
                            )
                          : Center(
                              child: Text(
                                widget.existing?.effectiveIcon ?? '⭐',
                                style: const TextStyle(fontSize: 32),
                              ),
                            ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: isZh ? '名称' : 'Name',
                hintText: isZh ? '例如: 喝水' : 'e.g. Drink water',
              ),
            ),
            const SizedBox(height: 12),

            // Reminder
            TextField(
              controller: _reminderController,
              decoration: InputDecoration(
                labelText: isZh ? '提醒时间 (可选)' : 'Reminder (optional)',
                hintText: isZh ? '例如: 09:00' : 'e.g. 09:00',
                helperText: isZh ? '仅本地提醒，不发送任何数据' : 'Local only — no data is sent anywhere',
              ),
            ),
            const SizedBox(height: 12),

            // Frequency
            Text(isZh ? '频率' : 'Frequency',
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 6),
            DropdownButton<RoutineFrequency>(
              value: _frequency,
              isExpanded: true,
              items: [
                DropdownMenuItem(
                    value: RoutineFrequency.daily,
                    child: Text(isZh ? '每天' : 'Daily')),
                DropdownMenuItem(
                    value: RoutineFrequency.weekly,
                    child: Text(isZh ? '每周 (指定星期)' : 'Weekly (select days)')),
                DropdownMenuItem(
                    value: RoutineFrequency.scheduled,
                    child: Text(isZh ? '指定日期 (一次性)' : 'Scheduled (one-time)')),
                DropdownMenuItem(
                    value: RoutineFrequency.adhoc,
                    child: Text(isZh ? '随时 (手动加入)' : 'Ad-hoc (manual)')),
              ],
              onChanged: (v) => setState(() {
                _frequency = v!;
              }),
            ),

            // Day-of-week picker (for weekly)
            if (_frequency == RoutineFrequency.weekly) ...[
              const SizedBox(height: 8),
              Text(isZh ? '选择星期' : 'Select days',
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: List.generate(7, (i) {
                  final day = i + 1; // 1=Mon…7=Sun
                  final selected = _selectedDays.contains(day);
                  return FilterChip(
                    label: Text((isZh ? _dayLabelsZh : _dayLabelsEn)[day]),
                    selected: selected,
                    onSelected: (v) => setState(() {
                      if (v) {
                        _selectedDays.add(day);
                      } else {
                        _selectedDays.remove(day);
                      }
                    }),
                  );
                }),
              ),
            ],

            // Date picker (for scheduled)
            if (_frequency == RoutineFrequency.scheduled) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    _scheduledDate == null
                        ? (isZh ? '未选择日期' : 'No date selected')
                        : isZh
                            ? '${_scheduledDate!.year}年${_scheduledDate!.month}月${_scheduledDate!.day}日'
                            : '${_scheduledDate!.year}-${_scheduledDate!.month.toString().padLeft(2, '0')}-${_scheduledDate!.day.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: _scheduledDate == null ? Colors.grey : null,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _pickDate,
                    child: Text(isZh ? '选择日期' : 'Pick date'),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // Category
            Text(isZh ? '分类 (可选)' : 'Category (optional)',
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: RoutineCategory.values.map((cat) {
                final selected = _category == cat;
                return GestureDetector(
                  onTap: () => setState(() {
                    _category = selected ? null : cat;
                  }),
                  child: Chip(
                    avatar: Text(kCategoryIcon[cat]!,
                        style: const TextStyle(fontSize: 14)),
                    label: Text(cat.name, style: const TextStyle(fontSize: 12)),
                    backgroundColor: selected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(isZh ? '取消' : 'Cancel'),
        ),
        TextButton(
          onPressed: _save,
          child: Text(widget.existing != null
              ? (isZh ? '保存' : 'Save')
              : (isZh ? '添加' : 'Add')),
        ),
      ],
    );
  }

  Future<void> _pickIcon() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    try {
      final savedRelative = await FileService().saveFile(picked.path);
      final fullPath = await FileService().getFullPath(savedRelative);
      if (mounted) setState(() => _iconImagePath = fullPath);
    } catch (e) {
      if (mounted) {
        final isZhPick = context.read<LocaleProvider>().locale.languageCode == 'zh';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isZhPick ? '图片保存失败: $e' : 'Failed to save image: $e')),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _scheduledDate = picked);
  }

  void _save() {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isZh ? '请输入习惯名称' : 'Please enter a name')),
      );
      return;
    }
    if (_frequency == RoutineFrequency.scheduled && _scheduledDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isZh ? '请选择指定日期' : 'Please select a date')),
      );
      return;
    }

    final reminder = _reminderController.text.trim().isEmpty
        ? null
        : _reminderController.text.trim();
    final days = _frequency == RoutineFrequency.weekly && _selectedDays.isNotEmpty
        ? List<int>.from(_selectedDays)
        : null;
    final schedDate =
        _frequency == RoutineFrequency.scheduled ? _scheduledDate : null;

    final provider = context.read<RoutineProvider>();

    if (widget.existing != null) {
      final updated = widget.existing!.copyWith(
        name: name,
        nameEn: name,
        reminderTime: reminder,
        updatedAt: DateTime.now(),
        category: _category,
        clearCategory: _category == null,
        frequency: _frequency,
        scheduledDaysOfWeek: days,
        scheduledDate: schedDate,
        clearScheduledDate: schedDate == null,
        iconImagePath: _iconImagePath,
        clearIconImagePath: _iconImagePath == null,
      );
      provider.updateRoutine(updated);
    } else {
      provider.addRoutine(
        name: name,
        nameEn: name,
        frequency: _frequency,
        reminderTime: reminder,
        category: _category,
        scheduledDaysOfWeek: days,
        scheduledDate: schedDate,
        iconImagePath: _iconImagePath,
      );
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(widget.existing != null
              ? (isZh ? '习惯已更新' : 'Routine updated')
              : (isZh ? '习惯已添加' : 'Routine added'))),
    );
  }
}
