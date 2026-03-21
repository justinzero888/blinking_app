import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/entry.dart';
import '../../models/card_template.dart';
import '../../models/card_folder.dart';
import '../../models/note_card.dart';
import '../../providers/card_provider.dart';
import '../../providers/entry_provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/services/llm_service.dart';

/// Full-screen dialog for creating or editing a note card from entries.
class CardBuilderDialog extends StatefulWidget {
  final Entry? initialEntry;
  final NoteCard? existingCard; // non-null = edit mode

  const CardBuilderDialog({super.key, this.initialEntry, this.existingCard});

  @override
  State<CardBuilderDialog> createState() => _CardBuilderDialogState();
}

class _CardBuilderDialogState extends State<CardBuilderDialog> {
  final List<Entry> _selectedEntries = [];
  CardTemplate? _selectedTemplate;
  CardFolder? _selectedFolder;
  bool _building = false;

  // AI merge
  bool _useAiMerge = false;
  String? _aiSummary;
  bool _generatingAi = false;
  final _aiController = TextEditingController();

  final _llmService = LlmService();

  bool get _isEditMode => widget.existingCard != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initDefaults());
  }

  void _initDefaults() {
    final cardProvider = context.read<CardProvider>();
    final entryProvider = context.read<EntryProvider>();

    if (_isEditMode) {
      final card = widget.existingCard!;
      // Pre-fill entries
      for (final id in card.entryIds) {
        try {
          final e = entryProvider.allEntries.firstWhere((e) => e.id == id);
          _selectedEntries.add(e);
        } catch (_) {}
      }
      // Pre-fill template
      final tpl = cardProvider.getTemplateById(card.templateId);
      // Pre-fill folder
      CardFolder? folder;
      try {
        folder = cardProvider.folders.firstWhere((f) => f.id == card.folderId);
      } catch (_) {}
      // Pre-fill AI summary
      if (card.aiSummary != null) {
        _useAiMerge = true;
        _aiSummary = card.aiSummary;
        _aiController.text = card.aiSummary!;
      }
      setState(() {
        _selectedTemplate = tpl;
        _selectedFolder = folder;
      });
    } else {
      if (widget.initialEntry != null) {
        _selectedEntries.add(widget.initialEntry!);
      }
      if (cardProvider.templates.isNotEmpty) {
        setState(() => _selectedTemplate = cardProvider.templates.first);
      }
      if (cardProvider.folders.isNotEmpty) {
        setState(() => _selectedFolder = cardProvider.folders.first);
      }
    }
  }

  @override
  void dispose() {
    _aiController.dispose();
    super.dispose();
  }

  Color _hexToColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(cleaned, radix: 16) ?? 0xFFFFFF;
    return Color(0xFF000000 | value);
  }

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final cardProvider = context.watch<CardProvider>();
    final entryProvider = context.watch<EntryProvider>();
    final templates = cardProvider.templates;
    final folders = cardProvider.folders;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode
            ? (isZh ? '编辑卡片' : 'Edit Card')
            : (isZh ? '制作记忆卡片' : 'Create Card')),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Selected entries
          Text(
              isZh
                  ? '已选记录 (${_selectedEntries.length})'
                  : 'Selected (${_selectedEntries.length})',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._selectedEntries.map((entry) => Card(
                child: ListTile(
                  leading: Text(entry.emotion ?? '📝'),
                  title: Text(
                    entry.content.length > 50
                        ? '${entry.content.substring(0, 50)}...'
                        : entry.content,
                    style: const TextStyle(fontSize: 13),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.red, size: 20),
                    onPressed: () =>
                        setState(() => _selectedEntries.remove(entry)),
                  ),
                ),
              )),
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: Text(isZh ? '添加更多笔记' : 'Add more entries'),
            onPressed: () => _showEntryPicker(entryProvider),
          ),
          const Divider(height: 24),

          // AI merge toggle
          if (_selectedEntries.isNotEmpty) ...[
            Row(
              children: [
                Text(isZh ? '内容模式' : 'Content mode',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                ChoiceChip(
                  label: Text(isZh ? '原文' : 'Original'),
                  selected: !_useAiMerge,
                  onSelected: (_) => setState(() {
                    _useAiMerge = false;
                    _aiSummary = null;
                    _aiController.clear();
                  }),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(isZh ? 'AI 生成' : 'AI Generate'),
                  selected: _useAiMerge,
                  onSelected: (_) => setState(() => _useAiMerge = true),
                ),
              ],
            ),
            if (_useAiMerge) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _aiController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: isZh
                      ? 'AI 生成的内容将显示在这里，你可以直接编辑'
                      : 'AI-generated content will appear here. You can edit it.',
                  border: const OutlineInputBorder(),
                  suffixIcon: _generatingAi
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : IconButton(
                          icon: const Icon(Icons.auto_awesome),
                          tooltip: isZh ? '用 AI 生成' : 'Generate with AI',
                          onPressed: _generateAiSummary,
                        ),
                ),
                onChanged: (v) => setState(() { _aiSummary = v; }),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  isZh
                      ? '${_countWords(_aiController.text)} / 100 字'
                      : '${_countWords(_aiController.text)} / 100 words',
                  style: TextStyle(
                    fontSize: 12,
                    color: _countWords(_aiController.text) > 100
                        ? Colors.red
                        : Colors.grey,
                  ),
                ),
              ),
            ],
            const Divider(height: 24),
          ],

          // Template picker
          Row(
            children: [
              Text(isZh ? '选择模板' : 'Select template',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.edit, size: 16),
                label: Text(isZh ? '编辑模板' : 'Edit template'),
                onPressed: _selectedTemplate != null
                    ? () => _showTemplateEditor(_selectedTemplate!)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: templates.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final tpl = templates[index];
                final isSelected = _selectedTemplate?.id == tpl.id;
                Widget bg;
                if (tpl.customImagePath != null &&
                    File(tpl.customImagePath!).existsSync()) {
                  bg = Image.file(File(tpl.customImagePath!),
                      fit: BoxFit.cover,
                      width: 80,
                      height: 100);
                } else {
                  bg = Container(
                      width: 80,
                      height: 100,
                      color: _hexToColor(tpl.bgColor));
                }
                return GestureDetector(
                  onTap: () => setState(() => _selectedTemplate = tpl),
                  child: Stack(
                    children: [
                      ClipRRect(
                          borderRadius: BorderRadius.circular(8), child: bg),
                      if (isSelected)
                        Container(
                          width: 80,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color:
                                    Theme.of(context).colorScheme.primary,
                                width: 2.5),
                          ),
                        ),
                      Positioned(
                        bottom: 4,
                        left: 0,
                        right: 0,
                        child: Text(
                          tpl.name,
                          style: TextStyle(
                              fontSize: 9,
                              color: _hexToColor(tpl.fontColor)),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Folder picker
          Text(isZh ? '选择文件夹' : 'Select folder',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (folders.isNotEmpty)
            DropdownButtonFormField<CardFolder>(
              value: _selectedFolder,
              items: folders
                  .map((f) => DropdownMenuItem(
                        value: f,
                        child: Row(children: [
                          Text(f.icon),
                          const SizedBox(width: 8),
                          Text(f.name)
                        ]),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedFolder = val),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          const SizedBox(height: 24),

          // Generate button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canBuild() ? (_building ? null : _buildCard) : null,
              style:
                  ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              child: _building
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(
                      _isEditMode
                          ? (isZh ? '保存卡片' : 'Save Card')
                          : (isZh ? '生成卡片' : 'Create Card'),
                      style: const TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  int _countWords(String text) {
    final cjk = RegExp(r'[\u4e00-\u9fff\u3400-\u4dbf]');
    int count = cjk.allMatches(text).length;
    final noCjk = text.replaceAll(cjk, ' ');
    count += noCjk.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
    return count;
  }

  bool _canBuild() =>
      _selectedEntries.isNotEmpty &&
      _selectedTemplate != null &&
      _selectedFolder != null;

  Future<void> _generateAiSummary() async {
    if (_selectedEntries.isEmpty) return;
    setState(() => _generatingAi = true);
    try {
      final combined = _selectedEntries
          .map((e) => e.content)
          .where((c) => c.isNotEmpty)
          .join('\n---\n');
      final prompt =
          '将以下日记片段合并为一段简洁优美的文字（不超过100个字）：\n$combined';
      final result = await _llmService.complete(prompt);
      setState(() {
        _aiSummary = result;
        _aiController.text = result;
      });
    } catch (e) {
      if (mounted) {
        final isZhErr = context.read<LocaleProvider>().locale.languageCode == 'zh';
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(isZhErr ? 'AI 生成失败: $e' : 'AI generation failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _generatingAi = false);
    }
  }

  void _showEntryPicker(EntryProvider entryProvider) {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    final available = entryProvider.allEntries
        .where((e) => !_selectedEntries.any((s) => s.id == e.id))
        .toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isZh ? '没有更多可添加的记录' : 'No more entries to add')));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isZh ? '选择笔记' : 'Select Entry'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: available.length,
            itemBuilder: (context, index) {
              final entry = available[index];
              return ListTile(
                leading: Text(entry.emotion ?? '📝'),
                title: Text(
                  entry.content.length > 40
                      ? '${entry.content.substring(0, 40)}...'
                      : entry.content,
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: Text(
                    '${entry.createdAt.year}/${entry.createdAt.month}/${entry.createdAt.day}',
                    style: const TextStyle(fontSize: 11)),
                onTap: () {
                  setState(() => _selectedEntries.add(entry));
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isZh ? '取消' : 'Cancel')),
        ],
      ),
    );
  }

  Future<void> _buildCard() async {
    if (!_canBuild()) return;
    setState(() => _building = true);

    final finalAiSummary = _useAiMerge
        ? (_aiController.text.trim().isNotEmpty
            ? _aiController.text.trim()
            : _aiSummary)
        : null;

    try {
      final cardProvider = context.read<CardProvider>();

      if (_isEditMode) {
        final updated = widget.existingCard!.copyWith(
          entryIds: _selectedEntries.map((e) => e.id).toList(),
          templateId: _selectedTemplate!.id,
          folderId: _selectedFolder!.id,
          aiSummary: finalAiSummary,
          updatedAt: DateTime.now(),
        );
        await cardProvider.updateCard(updated);
      } else {
        await cardProvider.addCard(
          entryIds: _selectedEntries.map((e) => e.id).toList(),
          templateId: _selectedTemplate!.id,
          folderId: _selectedFolder!.id,
          aiSummary: finalAiSummary,
        );
      }

      if (mounted) {
        final isZhDone = context.read<LocaleProvider>().locale.languageCode == 'zh';
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_isEditMode
                  ? (isZhDone ? '卡片已更新！' : 'Card updated!')
                  : (isZhDone ? '卡片已生成！' : 'Card created!'))),
        );
      }
    } catch (e) {
      if (mounted) {
        final isZhErr = context.read<LocaleProvider>().locale.languageCode == 'zh';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isZhErr ? '操作失败：$e' : 'Operation failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _building = false);
    }
  }

  void _showTemplateEditor(CardTemplate template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _TemplateEditorSheet(
        template: template,
        onSave: (updated) async {
          final cp = context.read<CardProvider>();
          if (updated.isBuiltIn) {
            // Copy-on-edit: create a user copy
            final copy = await cp.copyBuiltInTemplate(updated);
            if (mounted) setState(() => _selectedTemplate = copy);
          } else {
            await cp.updateTemplate(updated);
            if (mounted) setState(() => _selectedTemplate = updated);
          }
        },
      ),
    );
  }
}

/// Bottom sheet for editing a template's name, colors, and background image.
class _TemplateEditorSheet extends StatefulWidget {
  final CardTemplate template;
  final Future<void> Function(CardTemplate updated) onSave;

  const _TemplateEditorSheet({required this.template, required this.onSave});

  @override
  State<_TemplateEditorSheet> createState() => _TemplateEditorSheetState();
}

class _TemplateEditorSheetState extends State<_TemplateEditorSheet> {
  late TextEditingController _nameController;
  late String _bgColor;
  String? _customImagePath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template.name);
    _bgColor = widget.template.bgColor;
    _customImagePath = widget.template.customImagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;

    // Copy image to app documents directory
    final docDir = await getApplicationDocumentsDirectory();
    final destDir = Directory('${docDir.path}/template_images');
    if (!await destDir.exists()) await destDir.create(recursive: true);
    final dest = '${destDir.path}/${const Uuid().v4()}.jpg';
    await File(xfile.path).copy(dest);

    setState(() => _customImagePath = dest);
  }

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.template.isBuiltIn
                ? (isZh ? '编辑模板（将创建副本）' : 'Edit template (a copy will be created)')
                : (isZh ? '编辑模板' : 'Edit template'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
                labelText: isZh ? '模板名称' : 'Template name',
                border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          // Background: color swatch or image thumbnail
          Row(
            children: [
              Text(isZh ? '背景：' : 'Background:'),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  // Simple color picker: cycle through palette
                  const colors = [
                    '#FFE4E1',
                    '#1A237E',
                    '#FF6F00',
                    '#FAFAFA',
                    '#1B5E20',
                    '#E3F2FD',
                    '#F3E5F5',
                    '#FFF9C4',
                    '#E0F2F1'
                  ];
                  final idx = colors.indexOf(_bgColor);
                  setState(() => _bgColor = colors[(idx + 1) % colors.length]);
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Color(0xFF000000 |
                        (int.tryParse(
                                _bgColor.replaceFirst('#', ''),
                                radix: 16) ??
                            0xFFFFFF)),
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Icons.image, size: 18),
                label: Text(_customImagePath != null
                    ? (isZh ? '已选择图片' : 'Image selected')
                    : (isZh ? '上传图片' : 'Upload image')),
                onPressed: _pickImage,
              ),
              if (_customImagePath != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: Colors.red),
                  onPressed: () => setState(() => _customImagePath = null),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(isZh ? '保存' : 'Save'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final updated = widget.template.copyWith(
      name: _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : widget.template.name,
      bgColor: _bgColor,
      customImagePath: _customImagePath,
    );
    await widget.onSave(updated);
    if (mounted) Navigator.pop(context);
  }
}
