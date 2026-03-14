import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/routine_provider.dart';
import '../../models/routine.dart';
import '../../l10n/app_localizations.dart';

// Helper to convert frequency enum to string
String _frequencyToString(RoutineFrequency frequency) {
  switch (frequency) {
    case RoutineFrequency.daily:
      return '每天';
    case RoutineFrequency.weekly:
      return '每周';
    case RoutineFrequency.custom:
      return '自定义';
  }
}

class RoutineScreen extends StatelessWidget {
  const RoutineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.routine),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddRoutineDialog(context),
          ),
        ],
      ),
      body: Consumer<RoutineProvider>(
        builder: (context, routineProvider, child) {
          final routines = routineProvider.routines;

          if (routines.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    '还没有日常习惯',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showAddRoutineDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('添加习惯'),
                  ),
                ],
              ),
            );
          }

          // Active routines split into pending / completed today
          final activeRoutines = routines.where((r) => r.isActive).toList();
          final pendingToday = activeRoutines.where((r) => !r.isCompletedToday).toList();
          final completedToday = activeRoutines.where((r) => r.isCompletedToday).toList();
          final pausedRoutines = routines.where((r) => !r.isActive).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Pending routines
              if (pendingToday.isNotEmpty) ...[
                const Text(
                  '今日待完成',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...pendingToday.map((r) => _buildRoutineItem(context, r, completed: false)),
                const SizedBox(height: 16),
              ],

              // Completed today
              if (completedToday.isNotEmpty) ...[
                const Text(
                  '已完成',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                ...completedToday.map((r) => _buildRoutineItem(context, r, completed: true)),
                const SizedBox(height: 16),
              ],

              // Paused routines
              if (pausedRoutines.isNotEmpty) ...[
                const Text(
                  '已暂停',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                ...pausedRoutines.map((r) => _buildRoutineItem(context, r, completed: false)),
              ],

              // Empty active state
              if (activeRoutines.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    '暂无活跃习惯，点击右上角 + 添加',
                    style: TextStyle(color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRoutineItem(BuildContext context, Routine routine, {required bool completed}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: GestureDetector(
          onTap: () {
            if (routine.isActive) {
              if (completed) {
                context.read<RoutineProvider>().unmarkRoutine(routine.id);
              } else {
                context.read<RoutineProvider>().completeRoutine(routine.id);
              }
            }
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: completed
                  ? Colors.green.withValues(alpha: 0.15)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: completed
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
            decoration: completed ? TextDecoration.lineThrough : null,
            color: completed ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _frequencyToString(routine.frequency),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            if (routine.isCounter && routine.targetCount != null)
              Text(
                '${routine.currentCount} / ${routine.targetCount} ${routine.unit ?? ""}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            if (routine.isActive)
              PopupMenuItem(
                child: const Text('暂停'),
                onTap: () {
                  Future.delayed(Duration.zero, () {
                    context.read<RoutineProvider>().toggleActive(routine.id);
                  });
                },
              )
            else
              PopupMenuItem(
                child: const Text('恢复'),
                onTap: () {
                  Future.delayed(Duration.zero, () {
                    context.read<RoutineProvider>().toggleActive(routine.id);
                  });
                },
              ),
            PopupMenuItem(
              child: const Text('编辑'),
              onTap: () {
                Future.delayed(Duration.zero, () {
                  _showEditRoutineDialog(context, routine);
                });
              },
            ),
            PopupMenuItem(
              child: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () {
                Future.delayed(Duration.zero, () {
                  _confirmDelete(context, routine.id);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddRoutineDialog(BuildContext context) {
    final nameController = TextEditingController();
    final reminderController = TextEditingController();
    RoutineCategory? selectedCategory;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('添加习惯'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '名称',
                    hintText: '例如: 喝水',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reminderController,
                  decoration: const InputDecoration(
                    labelText: '提醒时间 (可选)',
                    hintText: '例如: 09:00',
                  ),
                ),
                const SizedBox(height: 12),
                const Text('分类 (可选)', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: RoutineCategory.values.map((cat) {
                    final isSelected = selectedCategory == cat;
                    return GestureDetector(
                      onTap: () => setDialogState(() {
                        selectedCategory = isSelected ? null : cat;
                      }),
                      child: Chip(
                        avatar: Text(kCategoryIcon[cat]!, style: const TextStyle(fontSize: 14)),
                        label: Text(cat.name, style: const TextStyle(fontSize: 12)),
                        backgroundColor: isSelected
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
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请输入习惯名称')),
                  );
                  return;
                }

                context.read<RoutineProvider>().addRoutine(
                  name: nameController.text.trim(),
                  nameEn: nameController.text.trim(),
                  frequency: RoutineFrequency.daily,
                  reminderTime: reminderController.text.isEmpty ? null : reminderController.text,
                  category: selectedCategory,
                );
                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('习惯已添加')),
                );
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRoutineDialog(BuildContext context, Routine routine) {
    final nameController = TextEditingController(text: routine.name);
    final reminderController = TextEditingController(text: routine.reminderTime ?? '');
    RoutineCategory? selectedCategory = routine.category;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('编辑习惯'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '名称'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reminderController,
                  decoration: const InputDecoration(labelText: '提醒时间 (可选)'),
                ),
                const SizedBox(height: 12),
                const Text('分类', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: RoutineCategory.values.map((cat) {
                    final isSelected = selectedCategory == cat;
                    return GestureDetector(
                      onTap: () => setDialogState(() {
                        selectedCategory = isSelected ? null : cat;
                      }),
                      child: Chip(
                        avatar: Text(kCategoryIcon[cat]!, style: const TextStyle(fontSize: 14)),
                        label: Text(cat.name, style: const TextStyle(fontSize: 12)),
                        backgroundColor: isSelected
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
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final updatedRoutine = routine.copyWith(
                  name: nameController.text.trim(),
                  nameEn: nameController.text.trim(),
                  reminderTime: reminderController.text.isEmpty ? null : reminderController.text,
                  updatedAt: DateTime.now(),
                  category: selectedCategory,
                  clearCategory: selectedCategory == null,
                );

                context.read<RoutineProvider>().updateRoutine(updatedRoutine);
                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('习惯已更新')),
                );
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个习惯吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              context.read<RoutineProvider>().deleteRoutine(id);
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('习惯已删除')),
              );
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
