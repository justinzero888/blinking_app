import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/routine_provider.dart';
import '../../models/routine.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('日常'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddRoutineDialog(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '全部'),
            Tab(text: '今日'),
            Tab(text: '记录'),
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
            Text('还没有日常习惯',
                style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (active.isNotEmpty) ...[
          _sectionHeader('活跃'),
          const SizedBox(height: 8),
          ...active.map((r) => _RoutineTile(
                routine: r,
                onEdit: () => onEdit(context, r),
              )),
          const SizedBox(height: 16),
        ],
        if (paused.isNotEmpty) ...[
          _sectionHeader('已暂停'),
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
          _sectionHeader('待完成'),
          const SizedBox(height: 8),
          ...pending.map((r) => _TodayRoutineTile(routine: r, isCompleted: false)),
          const SizedBox(height: 16),
        ],
        if (completed.isNotEmpty) ...[
          _sectionHeader('已完成'),
          const SizedBox(height: 8),
          ...completed.map((r) => _TodayRoutineTile(routine: r, isCompleted: true)),
          const SizedBox(height: 16),
        ],
        if (allToday.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(
              '今日无安排\n点击"手动加入"添加临时习惯',
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
                    child: Text(
                      routine.effectiveIcon,
                      style: const TextStyle(fontSize: 20),
                    ),
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
          routine.frequencyLabel,
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
    final adhoc = context.read<RoutineProvider>().adhocRoutines;
    if (adhoc.isEmpty) return const SizedBox.shrink();

    return TextButton.icon(
      onPressed: () => _showPicker(context, adhoc),
      icon: const Icon(Icons.add),
      label: const Text('手动加入'),
    );
  }

  void _showPicker(BuildContext context, List<Routine> adhoc) {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        children: [
          const Text('选择临时习惯',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ...adhoc.map((r) => ListTile(
                leading: Text(r.effectiveIcon,
                    style: const TextStyle(fontSize: 22)),
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

    if (daysWithData.isEmpty) {
      return Center(
        child: Text(
          '还没有历史记录',
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
    final label = DateFormat('M月d日 (EEE)', 'zh').format(day);
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
                Text(r.effectiveIcon,
                    style: const TextStyle(fontSize: 18)),
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
            child: Text(routine.effectiveIcon,
                style: const TextStyle(fontSize: 20)),
          ),
        ),
        title: Text(
          routine.name,
          style: TextStyle(color: routine.isActive ? null : Colors.grey),
        ),
        subtitle: Text(
          routine.frequencyLabel,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _onMenuSelected(context, value),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'edit',
              child: const Text('编辑'),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Text(routine.isActive ? '暂停' : '恢复'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('删除', style: TextStyle(color: Colors.red)),
            ),
          ],
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个习惯吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteRoutine(routine.id);
              Navigator.pop(ctx);
            },
            child:
                const Text('删除', style: TextStyle(color: Colors.red)),
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

  static const List<String> _dayLabels = ['', '一', '二', '三', '四', '五', '六', '日'];

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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _reminderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? '编辑习惯' : '添加习惯'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '名称',
                hintText: '例如: 喝水',
              ),
            ),
            const SizedBox(height: 12),

            // Reminder
            TextField(
              controller: _reminderController,
              decoration: const InputDecoration(
                labelText: '提醒时间 (可选)',
                hintText: '例如: 09:00',
              ),
            ),
            const SizedBox(height: 12),

            // Frequency
            const Text('频率', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 6),
            DropdownButton<RoutineFrequency>(
              value: _frequency,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: RoutineFrequency.daily, child: Text('每天')),
                DropdownMenuItem(value: RoutineFrequency.weekly, child: Text('每周 (指定星期)')),
                DropdownMenuItem(value: RoutineFrequency.scheduled, child: Text('指定日期 (一次性)')),
                DropdownMenuItem(value: RoutineFrequency.adhoc, child: Text('随时 (手动加入)')),
              ],
              onChanged: (v) => setState(() {
                _frequency = v!;
              }),
            ),

            // Day-of-week picker (for weekly)
            if (_frequency == RoutineFrequency.weekly) ...[
              const SizedBox(height: 8),
              const Text('选择星期', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: List.generate(7, (i) {
                  final day = i + 1; // 1=Mon…7=Sun
                  final selected = _selectedDays.contains(day);
                  return FilterChip(
                    label: Text(_dayLabels[day]),
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
                        ? '未选择日期'
                        : '${_scheduledDate!.year}年${_scheduledDate!.month}月${_scheduledDate!.day}日',
                    style: TextStyle(
                      color: _scheduledDate == null ? Colors.grey : null,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _pickDate,
                    child: const Text('选择日期'),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // Category
            const Text('分类 (可选)', style: TextStyle(fontSize: 13, color: Colors.grey)),
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
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _save,
          child: Text(widget.existing != null ? '保存' : '添加'),
        ),
      ],
    );
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
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入习惯名称')),
      );
      return;
    }
    if (_frequency == RoutineFrequency.scheduled && _scheduledDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择指定日期')),
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
      );
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.existing != null ? '习惯已更新' : '习惯已添加')),
    );
  }
}
