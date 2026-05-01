import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/ai_persona_provider.dart';
import '../../providers/llm_config_notifier.dart';
import '../../providers/tag_provider.dart';
import '../../providers/locale_provider.dart';
import '../legal_doc_screen.dart';
import '../../core/constants/legal_content.dart';
import '../../providers/entry_provider.dart';
import '../../providers/routine_provider.dart';
import '../../models/tag.dart';
import '../../core/config/theme.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/export_service.dart';
import '../../core/services/trial_service.dart';

enum _BackupRange { all, lastMonth, last3Months, last6Months, custom }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // LLM Provider settings (persisted via SharedPreferences)
  // OpenRouter is first — lowest friction for new users (free trial key)
  final List<Map<String, String>> _llmProviders = [
    {
      'name': 'Open Router',
      'model': 'qwen/qwen3.5-flash-02-23',
      'apiKey': '',
      'baseUrl': 'https://openrouter.ai/api/v1',
    },
    {
      'name': 'OpenAI',
      'model': 'gpt-4o',
      'apiKey': '',
      'baseUrl': 'https://api.openai.com/v1',
    },
    {
      'name': 'Claude (Anthropic)',
      'model': 'claude-3.5-sonnet',
      'apiKey': '',
      'baseUrl': 'https://api.anthropic.com/v1',
    },
    {
      'name': 'Gemini (Google)',
      'model': 'gemini-pro',
      'apiKey': '',
      'baseUrl': 'https://generativelanguage.googleapis.com/v1',
    },
  ];

  int _selectedLlmIndex = 0;

  String _aiName = 'AI 助手';
  String _aiPersonality = '';

  TrialService? _trialService;
  bool _isStartingTrial = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      _trialService = TrialService(prefs);
      if (mounted) setState(() {});
    });
    _loadLlmSettings();
    _loadAiSettings();
  }

  Future<void> _loadAiSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _aiName = prefs.getString('ai_assistant_name') ?? 'AI 助手';
        _aiPersonality = prefs.getString('ai_assistant_personality') ?? '';
      });
    }
  }

  Future<void> _saveAiSettings() async {
    await context
        .read<AiPersonaProvider>()
        .saveNameAndPersonality(_aiName, _aiPersonality);
    if (mounted) {
      final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isZh ? 'AI 设置已保存' : 'AI settings saved')),
      );
    }
  }

  Future<void> _pickAiAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    try {
      await context.read<AiPersonaProvider>().setAvatarFromPath(picked.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('头像保存失败: $e')),
        );
      }
    }
  }

  Future<void> _clearAiAvatar() async {
    await context.read<AiPersonaProvider>().clearAvatar();
  }

  Future<void> _loadLlmSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('llm_providers');
    if (jsonStr != null && mounted) {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      final saved = decoded
          .map((m) => (m as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, v.toString())))
          .toList();

      // Merge: start from saved list (preserves user API keys), then append
      // any default providers whose name isn't already present.
      final savedNames = saved.map((p) => p['name']).toSet();
      final merged = [...saved];
      for (final def in _llmProviders) {
        if (!savedNames.contains(def['name'])) {
          merged.add(Map<String, String>.from(def));
        }
      }

      setState(() {
        _llmProviders
          ..clear()
          ..addAll(merged);
        final idx = prefs.getInt('llm_selected_index') ?? 0;
        _selectedLlmIndex = idx < _llmProviders.length ? idx : 0;
      });
    }
  }

  Future<void> _saveLlmSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('llm_providers', jsonEncode(_llmProviders));
    await prefs.setInt('llm_selected_index', _selectedLlmIndex);
    if (mounted) {
      context.read<LlmConfigNotifier>().notify();
    }
  }

  List<Map<String, String>> get _displayProviders {
    final ts = _trialService;
    if (ts != null && ts.getStatus() == TrialStatus.active) {
      return [ts.buildTrialProvider(), ..._llmProviders];
    }
    return _llmProviders;
  }

  Future<void> _startTrial() async {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    if (_trialService == null) return;
    setState(() => _isStartingTrial = true);
    try {
      await _trialService!.startTrial();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isZh
                ? '试用已开始！享受 7 天免费 AI 助手。'
                : 'Trial started! Enjoy 7 days of free AI.'),
          ),
        );
        context.read<LlmConfigNotifier>().notify();
        setState(() {});
      }
    } on TrialException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.code == 'trial_already_used'
                ? (isZh ? '此设备已使用过免费试用。' : 'This device has already used its free trial.')
                : (isZh ? '启动试用失败，请重试。' : 'Failed to start trial. Please try again.')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isZh ? '启动失败，请检查网络连接。' : 'Failed to start trial. Check your network.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isStartingTrial = false);
    }
  }

  Widget _buildTrialBanner(bool isZh) {
    final ts = _trialService;
    final trialStatus = ts != null ? ts.getStatus() : TrialStatus.none;

    switch (trialStatus) {
      case TrialStatus.none:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.purple.shade400],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('🎉', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isZh ? '免费试用 AI \u2014 7 天' : 'Try AI for Free \u2014 7 Days',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            isZh ? '无需设置，立即开始聊天。' : 'No setup needed. Start chatting now.',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isStartingTrial ? null : _startTrial,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue.shade700,
                    ),
                    child: _isStartingTrial
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            isZh ? '开始免费试用 \u2192' : 'Start Free Trial \u2192',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );

      case TrialStatus.active:
        final daysLeft = ts?.trialDaysLeft ?? 0;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border.all(color: Colors.green.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text('\u2705', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isZh
                                  ? '试用中 \u2014 剩余 $daysLeft 天'
                                  : 'Trial Active \u2014 $daysLeft ${daysLeft == 1 ? 'day' : 'days'} remaining',
                              style: TextStyle(
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        isZh
                            ? '每天 20 次请求 · 您可以随时添加自己的 Key'
                            : '20 requests/day \u00b7 You can add your own key anytime',
                        style: TextStyle(color: Colors.green.shade700, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

      case TrialStatus.expired:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              border: Border.all(color: Colors.orange.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('\u23F0', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isZh ? '试用已过期' : 'Trial Expired',
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            isZh
                                ? '在下方添加您自己的 API Key 以继续使用 AI 助手。'
                                : 'Add your own API key below to continue using the AI assistant.',
                            style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => launchUrl(
                      Uri.parse('https://openrouter.ai/keys'),
                      mode: LaunchMode.externalApplication,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange.shade800,
                    ),
                    child: Text(
                      isZh ? '免费获取 Key \u2192' : 'Get a free key \u2192',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final isZh = locale.languageCode == 'zh';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isZh ? '设置' : 'Settings',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        children: [
          // AI / LLM Provider Settings
          _buildSectionHeader(isZh ? 'AI 服务配置' : 'AI Provider'),
          _buildTrialBanner(isZh),
          ...List.generate(_displayProviders.length, (index) {
            final trialActive = _trialService?.getStatus() == TrialStatus.active;
            final isTrial = trialActive && index == 0;
            final provider = _displayProviders[index];
            final userIndex = trialActive ? index - 1 : index;
            final isSelected = !isTrial && _selectedLlmIndex == userIndex;
            final hasKey = (provider['apiKey'] ?? '').isNotEmpty;
            return Container(
              color: (isSelected && hasKey)
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
                  : null,
              child: ListTile(
                leading: isTrial
                    ? const Icon(Icons.card_giftcard, color: Colors.green)
                    : Radio<int>(
                        value: userIndex,
                        groupValue: _selectedLlmIndex,
                        onChanged: (value) {
                          setState(() => _selectedLlmIndex = value!);
                          _saveLlmSettings();
                        },
                      ),
                title: Row(
                  children: [
                    Text(provider['name']!),
                    if (isTrial) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isZh ? '试用' : 'Trial',
                          style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ] else if (isSelected && hasKey) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isZh ? '使用中' : 'Active',
                          style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  isTrial
                      ? (() {
                          final days = _trialService?.trialDaysLeft ?? 0;
                          if (isZh) {
                            return '剩余 $days 天 \u00b7 每天 20 次请求';
                          }
                          return '$days ${days == 1 ? 'day' : 'days'} remaining \u00b7 20 requests/day';
                        })()
                      : (hasKey
                          ? '${isZh ? "模型" : "Model"}: ${provider['model']}'
                          : isZh
                              ? '模型: ${provider['model']} \u00b7 未配置 Key'
                              : 'Model: ${provider['model']} \u00b7 No key set'),
                ),
                trailing: isTrial
                    ? IconButton(
                        icon: const Icon(Icons.info_outline, size: 20),
                        onPressed: () => _showTrialInfoDialog(context, isZh),
                      )
                    : IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showEditLlmDialog(context, userIndex, isZh),
                      ),
                selected: isSelected,
                onTap: isTrial
                    ? null
                    : () {
                        setState(() => _selectedLlmIndex = userIndex);
                        _saveLlmSettings();
                      },
              ),
            );
          }),
          ListTile(
            leading: const Icon(Icons.add, color: Colors.blue),
            title: Text(isZh ? '添加 AI 服务' : 'Add AI Provider'),
            onTap: () => _showAddLlmDialog(context, isZh),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                border: Border.all(color: Colors.amber.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.amber.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isZh
                          ? 'AI 功能需要您自行提供 API Key。您需自行承担：\n'
                            '• API Key 的安全保管\n'
                            '• 使用 AI 服务产生的 Token 费用\n'
                            '• 发送给 AI 提供商的数据隐私（受该提供商条款约束）\n'
                            'Blinking 不收集任何您的数据，AI 请求由您的设备直接发送至 AI 提供商。'
                          : 'The AI feature requires your own API key. You are responsible for:\n'
                            '• Keeping your API key secure\n'
                            '• Any token costs charged by your AI provider\n'
                            '• Data privacy with your AI provider (governed by their terms)\n'
                            'Blinking does not collect your data. AI requests are sent directly from your device to the AI provider.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),

          // AI Personalization
          _buildSectionHeader(isZh ? 'AI 个性化' : 'AI Personalization'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar picker
                  Consumer<AiPersonaProvider>(
                    builder: (context, persona, _) {
                      final avatarPath = persona.avatarPath;
                      final hasAvatar = avatarPath != null &&
                          File(avatarPath).existsSync();
                      return Row(
                        children: [
                          GestureDetector(
                            onTap: _pickAiAvatar,
                            child: CircleAvatar(
                              radius: 32,
                              backgroundImage: hasAvatar
                                  ? FileImage(File(avatarPath))
                                  : null,
                              child: !hasAvatar
                                  ? const Text('🤖',
                                      style: TextStyle(fontSize: 28))
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.image, size: 16),
                                label: Text(
                                    isZh ? '更换头像' : 'Change Avatar',
                                    style: const TextStyle(fontSize: 13)),
                                onPressed: _pickAiAvatar,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              if (hasAvatar)
                                TextButton.icon(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 16, color: Colors.red),
                                  label: Text(
                                      isZh ? '移除头像' : 'Remove',
                                      style: const TextStyle(
                                          fontSize: 13, color: Colors.red)),
                                  onPressed: _clearAiAvatar,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: isZh ? '助手名称' : 'Assistant Name',
                      hintText: 'AI 助手',
                    ),
                    controller: TextEditingController(text: _aiName),
                    onChanged: (v) => _aiName = v,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      labelText: isZh ? '性格描述' : 'Personality',
                      hintText: isZh
                          ? '例如: 温柔、幽默、鼓励型'
                          : 'e.g. warm, funny, motivating',
                    ),
                    controller: TextEditingController(text: _aiPersonality),
                    onChanged: (v) => _aiPersonality = v,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveAiSettings,
                      child: Text(isZh ? '保存 AI 设置' : 'Save AI Settings'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),

          // Tags Management
          _buildSectionHeader(isZh ? '标签管理' : 'Tag Management'),
          Consumer<TagProvider>(
            builder: (context, tagProvider, _) {
              return Column(
                children: [
                  ...tagProvider.tags.map(
                    (tag) => _buildTagTile(context, tag, tagProvider, isZh),
                  ),
                  ListTile(
                    leading: Icon(Icons.add,
                        color: Theme.of(context).colorScheme.primary),
                    title: Text(
                      isZh ? '添加标签' : 'Add Tag',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    onTap: () => _showAddTagDialog(context, tagProvider, isZh),
                  ),
                ],
              );
            },
          ),
          const Divider(),

          // Language & General Settings
          _buildSectionHeader(isZh ? '通用设置' : 'General'),
          Consumer<LocaleProvider>(
            builder: (context, localeProvider, _) {
              return ListTile(
                leading: const Icon(Icons.language),
                title: Text(isZh ? '语言' : 'Language'),
                subtitle: Text(isZh ? '中文' : 'English'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLanguageDialog(context, localeProvider),
              );
            },
          ),
          const Divider(),

          // Data Portability
          _buildSectionHeader(isZh ? '数据备份与迁移' : 'Data Portability'),
          ListTile(
            leading: const Icon(Icons.archive_outlined),
            title: Text(isZh ? '完整备份 (ZIP)' : 'Full Backup (ZIP)'),
            subtitle: Text(isZh ? '包含所有数据和多媒体文件' : 'All data and media files'),
            onTap: () => _handleBackup(context, isZh),
          ),
          ListTile(
            leading: const Icon(Icons.table_chart_outlined),
            title: Text(isZh ? '导出为 CSV' : 'Export to CSV'),
            subtitle: Text(isZh ? '适用于 Excel 统计' : 'Compatible with Excel'),
            onTap: () => _handleExportCsv(context, isZh),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: Text(isZh ? '导出为 JSON' : 'Export to JSON'),
            subtitle: Text(isZh ? '仅导出结构化数据' : 'Structured data only'),
            onTap: () => _handleExportJson(context, isZh),
          ),
          ListTile(
            leading: const Icon(Icons.restore_outlined),
            title: Text(isZh ? '恢复数据' : 'Restore Data'),
            subtitle: Text(isZh ? '从备份文件导入' : 'Import from backup file'),
            onTap: () => _handleRestore(context, isZh),
          ),
          ListTile(
            leading: const Icon(Icons.fitness_center_outlined),
            title: Text(isZh ? '导出习惯数据' : 'Export Habits'),
            subtitle: Text(isZh ? '导出所有习惯为 JSON 文件' : 'Export all habits as JSON'),
            onTap: () => _handleExportHabits(context, isZh),
          ),
          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: Text(isZh ? '导入习惯数据' : 'Import Habits'),
            subtitle: Text(isZh ? '从 JSON 文件导入习惯' : 'Import habits from JSON file'),
            onTap: () => _handleImportHabits(context, isZh),
          ),
          const Divider(),

          // About
          _buildSectionHeader(isZh ? '关于' : 'About'),
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: Text(isZh ? '发送反馈' : 'Send Feedback'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _sendFeedback(context, isZh),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(isZh ? '隐私政策' : 'Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LegalDocScreen(
                  title: isZh ? '隐私政策' : 'Privacy Policy',
                  content: isZh ? kPrivacyPolicyContentZh : kPrivacyPolicyContent,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: Text(isZh ? '服务条款' : 'Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LegalDocScreen(
                  title: isZh ? '服务条款' : 'Terms of Service',
                  content: isZh ? kTermsOfServiceContentZh : kTermsOfServiceContent,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Blinking (记忆闪烁)'),
            subtitle: Text(isZh ? '版本 1.1.0-beta.5' : 'Version 1.1.0-beta.5'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  // ============ TAG MANAGEMENT ============

  static const _systemTagIds = {'tag_reflection', 'tag_secrets'};

  Widget _buildTagTile(
    BuildContext context, Tag tag, TagProvider provider, bool isZh,
  ) {
    final isSystem = _systemTagIds.contains(tag.id);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.hexColor(tag.color),
        radius: 12,
      ),
      title: Text(tag.displayName(isZh)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isSystem)
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showEditTagDialog(context, tag, provider, isZh),
            ),
          if (!isSystem)
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => _confirmDeleteTag(context, tag, provider, isZh),
            ),
          if (isSystem)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.lock_outline, size: 16, color: Colors.grey[400]),
            ),
        ],
      ),
    );
  }

  void _showAddTagDialog(
    BuildContext context, TagProvider provider, bool isZh,
  ) {
    final nameController = TextEditingController();
    String selectedColor = '#007AFF';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isZh ? '添加标签' : 'Add Tag'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: isZh ? '标签名称' : 'Tag Name',
                  hintText: isZh ? '例如：工作、学习' : 'e.g. Work, Study',
                ),
              ),
              const SizedBox(height: 16),
              Text(isZh ? '选择颜色' : 'Pick Color'),
              const SizedBox(height: 8),
              _buildColorPicker(selectedColor, (color) {
                setState(() => selectedColor = color);
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isZh ? '取消' : 'Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  provider.addTag(
                    name: nameController.text,
                    nameEn: nameController.text,
                    color: selectedColor,
                  );
                  Navigator.pop(context);
                }
              },
              child: Text(isZh ? '添加' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTagDialog(
    BuildContext context, Tag tag, TagProvider provider, bool isZh,
  ) {
    final nameController = TextEditingController(text: tag.name);
    String selectedColor = tag.color;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isZh ? '编辑标签' : 'Edit Tag'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: isZh ? '标签名称' : 'Tag Name',
                ),
              ),
              const SizedBox(height: 16),
              _buildColorPicker(selectedColor, (color) {
                setState(() => selectedColor = color);
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isZh ? '取消' : 'Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  provider.updateTag(tag.copyWith(
                    name: nameController.text,
                    color: selectedColor,
                  ));
                  Navigator.pop(context);
                }
              },
              child: Text(isZh ? '保存' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteTag(
    BuildContext context, Tag tag, TagProvider provider, bool isZh,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isZh ? '删除标签' : 'Delete Tag'),
        content: Text(
          isZh ? '确定要删除 "${tag.name}" 吗？' : 'Delete "${tag.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isZh ? '取消' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteTag(tag.id);
              Navigator.pop(context);
            },
            child: Text(
              isZh ? '删除' : 'Delete',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker(String selectedColor, Function(String) onSelect) {
    return Wrap(
      spacing: 8,
      children: [
        '#007AFF', '#34C759', '#FF9500', '#FF3B30',
        '#AF52DE', '#5856D6', '#FF2D55', '#00C7BE',
      ].map((color) => GestureDetector(
        onTap: () => onSelect(color),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.hexColor(color),
            shape: BoxShape.circle,
            border: selectedColor == color
                ? Border.all(color: Colors.black, width: 2)
                : null,
          ),
        ),
      )).toList(),
    );
  }

  // ============ LANGUAGE ============

  void _showLanguageDialog(BuildContext context, LocaleProvider localeProvider) {
    final isZh = localeProvider.locale.languageCode == 'zh';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isZh ? '选择语言' : 'Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('中文'),
              trailing: isZh
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                localeProvider.setLocale(const Locale('zh'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('English'),
              trailing: !isZh
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                localeProvider.setLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============ LLM PROVIDER MANAGEMENT ============

  void _showEditLlmDialog(BuildContext context, int index, bool isZh) {
    final provider = _llmProviders[index];
    final nameController = TextEditingController(text: provider['name']);
    final modelController = TextEditingController(text: provider['model']);
    final apiKeyController = TextEditingController(text: provider['apiKey']);
    final baseUrlController = TextEditingController(text: provider['baseUrl']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isZh ? '编辑 AI 服务' : 'Edit AI Provider'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: isZh ? '服务名称' : 'Provider Name',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: modelController,
                decoration: InputDecoration(
                  labelText: isZh ? '模型名称' : 'Model Name',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  hintText: 'sk-...',
                ),
                obscureText: true,
              ),
              if ((provider['baseUrl'] ?? '').contains('openrouter'))
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: GestureDetector(
                    onTap: () => launchUrl(
                      Uri.parse('https://openrouter.ai/keys'),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Text(
                      isZh ? '🔑 免费获取 API Key →' : '🔑 Get a free API key →',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: baseUrlController,
                decoration: const InputDecoration(
                  labelText: 'Base URL',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isZh ? '取消' : 'Cancel'),
          ),
          if (_llmProviders.length > 1)
            TextButton(
              onPressed: () {
                setState(() {
                  _llmProviders.removeAt(index);
                  if (_selectedLlmIndex >= _llmProviders.length) {
                    _selectedLlmIndex = _llmProviders.length - 1;
                  }
                });
                _saveLlmSettings();
                Navigator.pop(context);
              },
              child: Text(
                isZh ? '删除' : 'Delete',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          TextButton(
            onPressed: () {
              setState(() {
                _llmProviders[index] = {
                  'name': nameController.text,
                  'model': modelController.text,
                  'apiKey': apiKeyController.text,
                  'baseUrl': baseUrlController.text,
                };
              });
              _saveLlmSettings();
              Navigator.pop(context);
            },
            child: Text(isZh ? '保存' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _showAddLlmDialog(BuildContext context, bool isZh) {
    final nameController = TextEditingController();
    final modelController = TextEditingController();
    final apiKeyController = TextEditingController();
    final baseUrlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isZh ? '添加 AI 服务' : 'Add AI Provider'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: isZh ? '服务名称' : 'Provider Name',
                  hintText: isZh ? '例如：DeepSeek' : 'e.g. DeepSeek',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: modelController,
                decoration: InputDecoration(
                  labelText: isZh ? '模型名称' : 'Model Name',
                  hintText: 'e.g. deepseek-chat',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  hintText: 'sk-...',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: baseUrlController,
                decoration: const InputDecoration(
                  labelText: 'Base URL',
                  hintText: 'https://api.example.com/v1',
                ),
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
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  _llmProviders.add({
                    'name': nameController.text,
                    'model': modelController.text,
                    'apiKey': apiKeyController.text,
                    'baseUrl': baseUrlController.text,
                  });
                });
                _saveLlmSettings();
                Navigator.pop(context);
              }
            },
            child: Text(isZh ? '添加' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _showTrialInfoDialog(BuildContext context, bool isZh) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isZh ? '试用详情' : 'Trial Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isZh ? '模型：qwen/qwen3.5-flash' : 'Model: qwen/qwen3.5-flash'),
            const SizedBox(height: 8),
            Text(isZh ? '由 Blinking 试用后端代理' : 'Proxied by Blinking trial backend'),
            const SizedBox(height: 8),
            Text(
              isZh ? '每天最多 20 次请求，共 7 天试用期。' : 'Up to 20 requests/day for 7 days.',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Text(
              isZh ? '试用服务商不可编辑。' : 'Trial provider cannot be edited.',
              style: TextStyle(color: Colors.red[400], fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isZh ? '关闭' : 'Close'),
          ),
        ],
      ),
    );
  }

  // ============ DATA PORTABILITY ============

  String _rangeLabel(_BackupRange r, bool isZh) {
    switch (r) {
      case _BackupRange.all:
        return isZh ? '全部数据' : 'All data';
      case _BackupRange.lastMonth:
        return isZh ? '最近1个月' : 'Last month';
      case _BackupRange.last3Months:
        return isZh ? '最近3个月' : 'Last 3 months';
      case _BackupRange.last6Months:
        return isZh ? '最近6个月' : 'Last 6 months';
      case _BackupRange.custom:
        return isZh ? '自定义' : 'Custom';
    }
  }

  Future<void> _handleBackup(BuildContext context, bool isZh) async {
    var phase = 0;
    var range = _BackupRange.all;
    DateTime? customFrom;
    DateTime? customTo;
    var progress = 0.0;
    var estimateText = '';
    final estimator = _BackupEstimator();

    (DateTime?, DateTime?) resolveRange() {
      final now = DateTime.now();
      switch (range) {
        case _BackupRange.lastMonth:
          return (now.subtract(const Duration(days: 30)), null);
        case _BackupRange.last3Months:
          return (now.subtract(const Duration(days: 90)), null);
        case _BackupRange.last6Months:
          return (now.subtract(const Duration(days: 180)), null);
        case _BackupRange.custom:
          return (customFrom, customTo);
        case _BackupRange.all:
          return (null, null);
      }
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) {
          if (phase == 0) {
            return AlertDialog(
              title: Text(isZh ? '选择备份范围' : 'Select Backup Range'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final r in _BackupRange.values)
                          if (r != _BackupRange.custom)
                            ChoiceChip(
                              label: Text(_rangeLabel(r, isZh)),
                              selected: range == r,
                              onSelected: (_) =>
                                  setDialogState(() => range = r),
                            ),
                        ChoiceChip(
                          label: Text(isZh ? '自定义' : 'Custom'),
                          selected: range == _BackupRange.custom,
                          onSelected: (_) => setDialogState(
                              () => range = _BackupRange.custom),
                        ),
                      ],
                    ),
                    if (range == _BackupRange.custom) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text(customFrom != null
                                  ? '${customFrom!.year}-${customFrom!.month.toString().padLeft(2, '0')}-${customFrom!.day.toString().padLeft(2, '0')}'
                                  : (isZh ? '开始日期' : 'From')),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: customFrom ??
                                      DateTime.now()
                                          .subtract(const Duration(days: 30)),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setDialogState(() => customFrom = picked);
                                }
                              },
                            ),
                          ),
                          const Text('→'),
                          Expanded(
                            child: TextButton.icon(
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text(customTo != null
                                  ? '${customTo!.year}-${customTo!.month.toString().padLeft(2, '0')}-${customTo!.day.toString().padLeft(2, '0')}'
                                  : (isZh ? '结束日期' : 'To')),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: customTo ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setDialogState(() => customTo = picked);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(isZh ? '取消' : 'Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    setDialogState(() => phase = 1);
                    final exportService = context.read<ExportService>();
                    try {
                      final (startDate, endDate) = resolveRange();
                      final path = await exportService.exportAll(
                        startDate: startDate,
                        endDate: endDate,
                        onProgress: (p) {
                          if (dialogContext.mounted) {
                            setDialogState(() {
                              progress = p;
                              estimateText = estimator.estimate(p, isZh);
                            });
                          }
                        },
                      );
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                      await exportService.shareFile(
                        path,
                        subject:
                            isZh ? 'Blinking 全量备份' : 'Blinking Full Backup',
                        text: isZh
                            ? '这是我的 Blinking App 备份文件。'
                            : 'This is my Blinking App backup file.',
                      );
                      // Delete the ZIP after sharing — no reason to keep a copy on device
                      try { await File(path).delete(); } catch (_) {}
                    } catch (e) {
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                      if (context.mounted) _showError(context, isZh, e.toString());
                    }
                  },
                  child: Text(isZh ? '开始备份' : 'Start Backup'),
                ),
              ],
            );
          }

          // Phase 2: progress
          return PopScope(
            canPop: false,
            child: AlertDialog(
              title: Text(isZh ? '正在备份...' : 'Backing up...'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                      value: progress > 0 ? progress : null),
                  const SizedBox(height: 12),
                  Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  if (estimateText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(estimateText,
                        style: const TextStyle(color: Colors.grey)),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        isZh ? '请勿关闭应用' : 'Do not close the app',
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleExportCsv(BuildContext context, bool isZh) async {
    try {
      final exportService = context.read<ExportService>();
      final path = await exportService.exportCsv();
      await exportService.shareFile(
        path,
        subject: isZh ? 'Blinking 习惯与条目导出 (CSV)' : 'Blinking Habit & Entries Export (CSV)',
      );
    } catch (e) {
      _showError(context, isZh, e.toString());
    }
  }

  Future<void> _handleExportJson(BuildContext context, bool isZh) async {
    try {
      final exportService = context.read<ExportService>();
      final path = await exportService.exportJsonFile();
      await exportService.shareFile(
        path,
        subject: isZh ? 'Blinking 数据导出 (JSON)' : 'Blinking Data Export (JSON)',
      );
    } catch (e) {
      _showError(context, isZh, e.toString());
    }
  }

  Future<void> _handleRestore(BuildContext context, bool isZh) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip', 'json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);

        if (!mounted) return;

        var phase = 0;
        double progress = 0.0;
        String estimateText = '';
        final estimator = _BackupEstimator();

        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => StatefulBuilder(
            builder: (_, setDialogState) {
              if (phase == 0) {
                return AlertDialog(
                  title: Text(isZh ? '恢复数据' : 'Restore Data'),
                  content: Text(isZh
                      ? '从此备份恢复数据将替换您当前的所有数据。'
                      : 'Restore data from this backup? This will replace all your current data.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(isZh ? '取消' : 'Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        setDialogState(() => phase = 1);
                        await _performRestore(
                          context,
                          dialogContext,
                          file,
                          isZh,
                          (p) {
                            if (dialogContext.mounted) {
                              setDialogState(() {
                                progress = p;
                                estimateText = estimator.estimate(p, isZh);
                              });
                            }
                          },
                        );
                      },
                      child: Text(isZh ? '恢复' : 'Restore'),
                    ),
                  ],
                );
              }

              // Phase 1: progress
              return PopScope(
                canPop: false,
                child: AlertDialog(
                  title: Text(isZh ? '正在恢复...' : 'Restoring...'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LinearProgressIndicator(
                          value: progress > 0 ? progress : null),
                      const SizedBox(height: 12),
                      Text(
                        '${(progress * 100).round()}%',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      if (estimateText.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(estimateText,
                            style: const TextStyle(color: Colors.grey)),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              size: 16, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            isZh ? '请勿关闭应用' : 'Do not close the app',
                            style: const TextStyle(color: Colors.orange),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) _showError(context, isZh, e.toString());
    }
  }

  Future<void> _performRestore(
    BuildContext context,
    BuildContext dialogContext,
    File file,
    bool isZh,
    void Function(double)? onProgress,
  ) async {
    try {
      final storage = context.read<StorageService>();
      await storage.restoreFromBackup(file, onProgress: onProgress);

      if (!dialogContext.mounted) return;
      Navigator.pop(dialogContext);

      if (!context.mounted) return;
      context.read<EntryProvider>().loadEntries();
      context.read<RoutineProvider>().loadRoutines();
      context.read<TagProvider>().loadTags();
      await context.read<AiPersonaProvider>().reload();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isZh ? '数据恢复成功！' : 'Data restored successfully!')),
      );
    } catch (e) {
      if (dialogContext.mounted) Navigator.pop(dialogContext);
      if (context.mounted) _showError(context, isZh, e.toString());
    }
  }

  Future<void> _handleExportHabits(BuildContext context, bool isZh) async {
    try {
      final provider = context.read<RoutineProvider>();
      final json = provider.exportRoutinesJson();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/habits_export.json');
      await file.writeAsString(json);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: isZh ? '习惯数据导出' : 'Habits Export',
      );
    } catch (e) {
      if (mounted) _showError(context, isZh, e.toString());
    }
  }

  Future<void> _handleImportHabits(BuildContext context, bool isZh) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final json = await file.readAsString();

      if (!mounted) return;
      final provider = context.read<RoutineProvider>();
      final counts = await provider.importRoutinesJson(json);

      if (mounted) {
        final msg = isZh
            ? '导入完成：${counts.imported} 条已导入，${counts.skipped} 条已跳过'
            : 'Import complete: ${counts.imported} imported, ${counts.skipped} skipped';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) _showError(context, isZh, e.toString());
    }
  }

  Future<void> _sendFeedback(BuildContext context, bool isZh) async {
    const email = 'blinkingfeedback@gmail.com';
    const version = '1.1.0-beta.5'; // TODO: keep in sync with pubspec.yaml
    final subject = Uri.encodeComponent('Blinking App Feedback - v$version');
    final body = Uri.encodeComponent(
      'What happened:\n\n\nSteps to reproduce:\n\n\nExpected behavior:\n\n\nDevice & OS:\n\n',
    );
    final uri = Uri.parse('mailto:$email?subject=$subject&body=$body');

    try {
      await launchUrl(uri);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isZh
                ? '无法打开邮件应用，请发送邮件至 $email'
                : 'No mail app found. Please email $email',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _showError(BuildContext context, bool isZh, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isZh ? '操作失败: $error' : 'Operation failed: $error'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

class _BackupEstimator {
  final _start = DateTime.now();
  final _samples = <({double progress, int elapsed})>[];

  String estimate(double progress, bool isZh) {
    final elapsedMs = DateTime.now().difference(_start).inMilliseconds;
    _samples.add((progress: progress, elapsed: elapsedMs));
    if (_samples.length > 5) _samples.removeAt(0);

    if (progress < 0.15 || _samples.length < 2) return '';

    final oldest = _samples.first;
    final newest = _samples.last;
    final progressDelta = newest.progress - oldest.progress;
    final timeDelta = newest.elapsed - oldest.elapsed;
    if (progressDelta <= 0 || timeDelta <= 0) return '';

    final msPerProgress = timeDelta / progressDelta;
    final remainingMs = msPerProgress * (1.0 - progress);
    final remainingSec = (remainingMs / 1000).round();

    if (remainingSec < 10) {
      return isZh ? '不到10秒' : 'Less than 10 seconds';
    } else if (remainingSec < 60) {
      final rounded = ((remainingSec / 10).round() * 10).clamp(10, 50);
      return isZh ? '约$rounded秒' : 'About $rounded seconds';
    } else {
      final mins = (remainingSec / 60).ceil();
      return isZh ? '约$mins分钟' : 'About $mins minute${mins > 1 ? 's' : ''}';
    }
  }
}
