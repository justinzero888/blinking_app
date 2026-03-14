import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/entry_provider.dart';
import '../../providers/routine_provider.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadDailySummary();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _loadDailySummary() {
    // Generate daily summary on load
    final entryProvider = context.read<EntryProvider>();
    final routineProvider = context.read<RoutineProvider>();
    
    final today = DateTime.now();
    final todayEntries = entryProvider.entries.where((e) =>
      e.createdAt.year == today.year &&
      e.createdAt.month == today.month &&
      e.createdAt.day == today.day
    ).length;
    
    final completedRoutines = routineProvider.schedules.where((s) =>
      s.scheduledDate.year == today.year &&
      s.scheduledDate.month == today.month &&
      s.scheduledDate.day == today.day &&
      s.completedAt != null
    ).length;
    
    final totalRoutines = routineProvider.routines.where((r) => r.isActive).length;
    
    setState(() {
      _messages.add(ChatMessage(
        text: '📊 今日总结\n\n'
              '✅ 完成日常: $completedRoutines/$totalRoutines\n'
              '📝 记录条数: $todayEntries\n\n'
              '${_getEncouragement(completedRoutines, totalRoutines)}',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  String _getEncouragement(int completed, int total) {
    if (total == 0) return '今天还没有设置日常任务哦！';
    final percentage = (completed / total * 100).round();
    
    if (percentage == 100) return '🎉 太棒了！今天所有任务都完成了！';
    if (percentage >= 80) return '👏 做得很好！继续保持！';
    if (percentage >= 50) return '💪 不错！继续努力！';
    return '📌 还有一些任务待完成，加油！';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI助手'), // AI Assistant
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'weekly',
                child: Text('生成周报'), // Generate weekly report
              ),
              const PopupMenuItem(
                value: 'monthly',
                child: Text('生成月报'), // Generate monthly report
              ),
              const PopupMenuItem(
                value: 'reflection',
                child: Text('反思提示'), // Reflection prompt
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Actions
          _buildQuickActions(),
          
          const Divider(height: 1),
          
          // Chat Messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          
          const Divider(height: 1),
          
          // Input Field
          _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildActionChip('今日总结', Icons.today, () => _loadDailySummary()),
            const SizedBox(width: 8),
            _buildActionChip('周报', Icons.calendar_view_week, () => _generateWeeklyReport()),
            const SizedBox(width: 8),
            _buildActionChip('月报', Icons.calendar_month, () => _generateMonthlyReport()),
            const SizedBox(width: 8),
            _buildActionChip('反思', Icons.psychology, () => _showReflectionPrompt()),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip(String label, IconData icon, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: message.isUser 
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: '向AI提问...', // Ask AI...
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
            color: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'weekly':
        _generateWeeklyReport();
        break;
      case 'monthly':
        _generateMonthlyReport();
        break;
      case 'reflection':
        _showReflectionPrompt();
        break;
    }
  }

  void _generateWeeklyReport() {
    final entryProvider = context.read<EntryProvider>();
    final routineProvider = context.read<RoutineProvider>();
    
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    final weekEntries = entryProvider.entries.where((e) =>
      e.createdAt.isAfter(weekStart)
    ).length;
    
    final weekCompletions = routineProvider.schedules.where((s) =>
      s.scheduledDate.isAfter(weekStart) && s.completedAt != null
    ).length;
    
    setState(() {
      _messages.add(ChatMessage(
        text: '📅 本周总结 (${_formatDate(weekStart)} - ${_formatDate(now)})\n\n'
              '✅ 完成日常: $weekCompletions 次\n'
              '📝 新增记录: $weekEntries 条\n\n'
              '本周表现不错！继续保持这个节奏！',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  void _generateMonthlyReport() {
    final entryProvider = context.read<EntryProvider>();
    final routineProvider = context.read<RoutineProvider>();
    
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    
    final monthEntries = entryProvider.entries.where((e) =>
      e.createdAt.isAfter(monthStart)
    ).length;
    
    final monthCompletions = routineProvider.schedules.where((s) =>
      s.scheduledDate.isAfter(monthStart) && s.completedAt != null
    ).length;
    
    setState(() {
      _messages.add(ChatMessage(
        text: '📊 本月总结 (${now.month}月)\n\n'
              '✅ 完成日常: $monthCompletions 次\n'
              '📝 新增记录: $monthEntries 条\n\n'
              '这个月的坚持值得肯定！',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  void _showReflectionPrompt() {
    final prompts = [
      '今天最让你开心的事是什么？',
      '今天遇到了什么挑战？你是如何应对的？',
      '今天学到了什么新东西？',
      '有什么想对明天的自己说的话吗？',
      '今天有什么值得感恩的事情？',
    ];
    
    final randomPrompt = prompts[DateTime.now().second % prompts.length];
    
    setState(() {
      _messages.add(ChatMessage(
        text: '💭 反思时刻\n\n$randomPrompt',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    final userMessage = _messageController.text;
    
    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      
      // Simulate AI response
      _messages.add(ChatMessage(
        text: '收到您的消息！AI功能将在后续版本中完善。',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    
    _messageController.clear();
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
