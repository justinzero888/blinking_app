import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/routine_provider.dart';
import '../../models/routine.dart';
import '../../l10n/app_localizations.dart';

// Helper to convert frequency string to enum
RoutineFrequency _parseFrequency(String text) {
  if (text.contains('每天') || text.toLowerCase().contains('daily')) {
    return RoutineFrequency.daily;
  } else if (text.contains('每周') || text.toLowerCase().contains('week')) {
    return RoutineFrequency.weekly;
  }
  return RoutineFrequency.custom;
}

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
                    '还没有日常习惯', // No routines yet
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showAddRoutineDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('添加习惯'), // Add routine
                  ),
                ],
              ),
            );
          }
          
          // Separate active and inactive routines
          final activeRoutines = routines.where((r) => r.isActive).toList();
          final inactiveRoutines = routines.where((r) => !r.isActive).toList();
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Today's Check-in Section
              _buildTodaySection(context, activeRoutines),
              
              const SizedBox(height: 24),
              
              // Active Routines
              if (activeRoutines.isNotEmpty) ...[
                const Text(
                  '活跃习惯', // Active routines
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...activeRoutines.map((routine) => _buildRoutineCard(context, routine)),
              ],
              
              // Inactive Routines
              if (inactiveRoutines.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  '已暂停', // Paused
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ...inactiveRoutines.map((routine) => _buildRoutineCard(context, routine)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildTodaySection(BuildContext context, List<Routine> activeRoutines) {
    final today = DateTime.now();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.today, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  '今日打卡', // Today's Check-in
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (activeRoutines.isEmpty)
              const Text('暂无活跃习惯', style: TextStyle(color: Colors.grey))
            else
              ...activeRoutines.map((routine) {
                final isCompleted = routine.isCompletedToday;
                return CheckboxListTile(
                  title: Text(routine.name),
                  subtitle: Text(_frequencyToString(routine.frequency)),
                  value: isCompleted,
                  onChanged: (value) {
                    if (value == true) {
                      context.read<RoutineProvider>().completeRoutine(routine.id);
                    } else {
                      // Remove today's completion
                      context.read<RoutineProvider>().unmarkRoutine(routine.id);
                    }
                  },
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineCard(BuildContext context, Routine routine) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          routine.isActive ? Icons.check_circle : Icons.pause_circle,
          color: routine.isActive ? Colors.green : Colors.grey,
        ),
        title: Text(routine.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('频率: ${_frequencyToString(routine.frequency)}'),
            if (routine.reminderTime != null)
              Text('提醒: ${routine.reminderTime}'),
            Text('完成次数: ${routine.completionLog.length}'),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: Text(routine.isActive ? '暂停' : '恢复'),
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
    final frequencyController = TextEditingController(text: '每天');
    final reminderController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('添加习惯'), // Add routine
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '名称', // Name
                  hintText: '例如: 喝水', // e.g., Drink water
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: frequencyController,
                decoration: const InputDecoration(
                  labelText: '频率', // Frequency
                  hintText: '例如: 每天, 每周三次', // e.g., Daily, 3 times/week
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reminderController,
                decoration: const InputDecoration(
                  labelText: '提醒时间 (可选)', // Reminder time (optional)
                  hintText: '例如: 09:00', // e.g., 09:00
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'), // Cancel
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
                name: nameController.text,
                nameEn: nameController.text, // For now, same as Chinese
                frequency: RoutineFrequency.daily, // Default to daily
                reminderTime: reminderController.text.isEmpty ? null : reminderController.text,
              );
              Navigator.pop(dialogContext);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('习惯已添加')),
              );
            },
            child: const Text('添加'), // Add
          ),
        ],
      ),
    );
  }

  void _showEditRoutineDialog(BuildContext context, Routine routine) {
    final nameController = TextEditingController(text: routine.name);
    final frequencyController = TextEditingController(text: _frequencyToString(routine.frequency));
    final reminderController = TextEditingController(text: routine.reminderTime ?? '');
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('编辑习惯'), // Edit routine
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '名称'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: frequencyController,
                decoration: const InputDecoration(labelText: '频率'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reminderController,
                decoration: const InputDecoration(labelText: '提醒时间 (可选)'),
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
                name: nameController.text,
                nameEn: nameController.text,
                frequency: _parseFrequency(frequencyController.text),
                reminderTime: reminderController.text.isEmpty ? null : reminderController.text,
                updatedAt: DateTime.now(),
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
