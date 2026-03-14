import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/entry_provider.dart';
import '../../models/entry.dart';
import '../../core/services/llm_service.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _llmService = LlmService();
  final List<ChatMessage> _messages = [];
  bool _isSending = false;

  static const String _systemPrompt =
      '你是 Blinking 日记应用的 AI 助手，帮助用户回顾每日记录、提供情绪支持和成长建议。'
      '请用温暖、简洁的中文回答。如果用户分享了心情或记录，给出有共鸣的回应。';

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    _messageController.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final history = _messages
          .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text})
          .toList();

      final reply = await _llmService.chat(
        history: history,
        systemPrompt: _systemPrompt,
      );

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(text: reply, isUser: false, timestamp: DateTime.now()));
        });
        _scrollToBottom();
      }
    } on LlmException catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: '⚠️ ${e.message}',
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: '⚠️ 发送失败，请检查网络连接。',
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showReflectionPrompt() {
    final prompts = [
      '今天最让你开心的事是什么？',
      '今天遇到了什么挑战？你是如何应对的？',
      '今天学到了什么新东西？',
      '有什么想对明天的自己说的话吗？',
      '今天有什么值得感恩的事情？',
    ];
    final prompt = prompts[DateTime.now().second % prompts.length];
    setState(() {
      _messages.add(ChatMessage(
        text: '💭 反思时刻\n\n$prompt',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  Future<void> _saveReflection() async {
    if (_messages.isEmpty) return;

    // Build conversation text for summarization
    final conversation = _messages
        .map((m) => '${m.isUser ? "用户" : "AI"}: ${m.text}')
        .join('\n\n');

    final summarizePrompt =
        '请将以下对话总结成一段简洁的反思笔记（100-200字），用第一人称，以"今天"或"这次"开头：\n\n$conversation';

    setState(() => _isSending = true);

    String summary;
    try {
      summary = await _llmService.complete(summarizePrompt);
    } on LlmException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成总结失败: ${e.message}')),
        );
      }
      setState(() => _isSending = false);
      return;
    } catch (_) {
      // Fallback: save raw conversation if LLM unavailable
      summary = _messages
          .where((m) => m.isUser)
          .map((m) => m.text)
          .join('\n');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }

    if (!mounted) return;

    await context.read<EntryProvider>().addEntry(
      type: EntryType.freeform,
      content: summary,
      tagIds: ['tag_reflection'],
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('反思已保存到记录 ✨')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 助手'),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save_alt),
              tooltip: '保存反思',
              onPressed: _isSending ? null : _saveReflection,
            ),
        ],
      ),
      body: Column(
        children: [
          // Quick actions row
          _buildQuickActions(),
          const Divider(height: 1),

          // Message list
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) =>
                        _buildMessageBubble(_messages[index]),
                  ),
          ),

          const Divider(height: 1),

          // Input field
          _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🤖', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            '你好！我是你的 AI 助手',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '可以聊聊今天的心情，或者问我任何事',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          ActionChip(
            avatar: const Icon(Icons.psychology, size: 18, color: Colors.black87),
            label: const Text('反思提示', style: TextStyle(color: Colors.black87)),
            onPressed: _showReflectionPrompt,
          ),
          const SizedBox(width: 8),
          ActionChip(
            avatar: const Icon(Icons.mood, size: 18, color: Colors.black87),
            label: const Text('今日情绪', style: TextStyle(color: Colors.black87)),
            onPressed: () => _sendMessage2('帮我回顾今天的情绪状态并给出建议'),
          ),
          const SizedBox(width: 8),
          ActionChip(
            avatar: const Icon(Icons.lightbulb_outline, size: 18, color: Colors.black87),
            label: const Text('激励一下', style: TextStyle(color: Colors.black87)),
            onPressed: () => _sendMessage2('给我一句温暖的鼓励'),
          ),
        ],
      ),
    );
  }

  void _sendMessage2(String text) {
    _messageController.text = text;
    _sendMessage();
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.text, style: const TextStyle(fontSize: 15)),
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
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: '向 AI 提问…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          _isSending
              ? const SizedBox(
                  width: 40,
                  height: 40,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: Theme.of(context).colorScheme.primary,
                ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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
