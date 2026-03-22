import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/ai_persona_provider.dart';
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

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // LLM Provider settings (persisted via SharedPreferences)
  final List<Map<String, String>> _llmProviders = [
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
    {
      'name': 'Open Router',
      'model': 'qwen/qwen3.5-flash-02-23',
      'apiKey': '',
      'baseUrl': 'https://openrouter.ai/api/v1',
    },
  ];

  int _selectedLlmIndex = 0;

  String _aiName = 'AI 助手';
  String _aiPersonality = '';

  @override
  void initState() {
    super.initState();
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
          ...List.generate(_llmProviders.length, (index) {
            final provider = _llmProviders[index];
            final isSelected = _selectedLlmIndex == index;
            return ListTile(
              leading: Radio<int>(
                value: index,
                groupValue: _selectedLlmIndex,
                onChanged: (value) {
                  setState(() => _selectedLlmIndex = value!);
                  _saveLlmSettings();
                },
              ),
              title: Text(provider['name']!),
              subtitle: Text(
                '${isZh ? "模型" : "Model"}: ${provider['model']}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _showEditLlmDialog(context, index, isZh),
              ),
              selected: isSelected,
              onTap: () {
                setState(() => _selectedLlmIndex = index);
                _saveLlmSettings();
              },
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
                    leading: const Icon(Icons.add, color: Colors.blue),
                    title: Text(isZh ? '添加标签' : 'Add Tag'),
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
            subtitle: Text(isZh ? '版本 1.1.0-beta.1' : 'Version 1.1.0-beta.1'),
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

  Widget _buildTagTile(
    BuildContext context, Tag tag, TagProvider provider, bool isZh,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.hexColor(tag.color),
        radius: 12,
      ),
      title: Text(tag.name),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () => _showEditTagDialog(context, tag, provider, isZh),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
            onPressed: () => _confirmDeleteTag(context, tag, provider, isZh),
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

  // ============ DATA PORTABILITY ============

  Future<void> _handleBackup(BuildContext context, bool isZh) async {
    try {
      final exportService = context.read<ExportService>();
      final path = await exportService.exportAll();
      await exportService.shareFile(
        path,
        subject: isZh ? 'Blinking 全量备份' : 'Blinking Full Backup',
        text: isZh ? '这是我的 Blinking App 备份文件。' : 'This is my Blinking App backup file.',
      );
    } catch (e) {
      _showError(context, isZh, e.toString());
    }
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
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        final storage = context.read<StorageService>();
        await storage.restoreFromBackup(file);

        if (!mounted) return;
        context.read<EntryProvider>().loadEntries();
        context.read<RoutineProvider>().loadRoutines();
        context.read<TagProvider>().loadTags();

        Navigator.pop(context); // Close loading

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isZh ? '数据恢复成功！' : 'Data restored successfully!')),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showError(context, isZh, e.toString());
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

  void _showError(BuildContext context, bool isZh, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isZh ? '操作失败: $error' : 'Operation failed: $error'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
