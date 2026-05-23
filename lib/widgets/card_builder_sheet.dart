import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/card_template.dart';
import '../models/note_card.dart';
import '../providers/card_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/llm_config_notifier.dart';
import '../core/services/card_render_service.dart';
import 'card_template_picker.dart';

/// Bottom sheet for building a Keepsake card.
/// Template picker, content editor, AI Rewrite, toggle overlays, Save.
class CardBuilderSheet extends StatefulWidget {
  final String? entryId;
  final String initialContent;
  final String? initialEmotion;
  final List<String>? initialTags;
  final String? initialPhotoPath;
  final DateTime? entryDate;
  final Future<String> Function({
    required CardTemplate template,
    required String content,
    String? imagePath,
    String? emotion,
    List<String>? tags,
    DateTime? date,
    bool? showMood,
    bool? showDate,
    bool? showTags,
    bool? showFooter,
  })? _renderFn;

  const CardBuilderSheet({
    super.key,
    this.entryId,
    required this.initialContent,
    this.initialEmotion,
    this.initialTags,
    this.initialPhotoPath,
    this.entryDate,
    @visibleForTesting Future<String> Function({
      required CardTemplate template,
      required String content,
      String? imagePath,
      String? emotion,
      List<String>? tags,
      DateTime? date,
      bool? showMood,
      bool? showDate,
      bool? showTags,
      bool? showFooter,
    })? renderFn,
  }) : _renderFn = renderFn;

  /// Show the builder as a modal bottom sheet. Returns the created NoteCard, or null if cancelled.
  static Future<NoteCard?> show(
    BuildContext context, {
    String? entryId,
    required String initialContent,
    String? initialEmotion,
    List<String>? initialTags,
    String? initialPhotoPath,
    DateTime? entryDate,
    @visibleForTesting Future<String> Function({
      required CardTemplate template,
      required String content,
      String? imagePath,
      String? emotion,
      List<String>? tags,
      DateTime? date,
      bool? showMood,
      bool? showDate,
      bool? showTags,
      bool? showFooter,
    })? renderFn,
  }) {
    return showModalBottomSheet<NoteCard>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CardBuilderSheet(
        entryId: entryId,
        initialContent: initialContent,
        initialEmotion: initialEmotion,
        initialTags: initialTags,
        initialPhotoPath: initialPhotoPath,
        entryDate: entryDate,
        renderFn: renderFn,
      ),
    );
  }

  @override
  State<CardBuilderSheet> createState() => _CardBuilderSheetState();
}

class _CardBuilderSheetState extends State<CardBuilderSheet> {
  late TextEditingController _contentController;
  late CardTemplate _selectedTemplate;
  bool _showMood = true;
  bool _showDate = true;
  bool _showTags = true;
  bool _showFooter = true;
  bool _isSaving = false;
  bool _isRewriting = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.initialContent);
    final templates = context.read<CardProvider>().templates;
    _selectedTemplate = templates.isNotEmpty ? templates.first : _fallbackTemplate();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  CardTemplate _fallbackTemplate() {
    final now = DateTime.now();
    return CardTemplate(
      id: 'tpl_fallback', name: 'Default', icon: '📄',
      fontColor: '#2C2C2C', bgColor: '#F5F0E8',
      isBuiltIn: true, createdAt: now,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final cardProvider = context.read<CardProvider>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                // Title
                Text(
                  isZh ? '保存为纪念' : 'Save as Keepsake',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                // Body
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // Template picker
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          isZh ? '选择模板' : 'Choose Template',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                      CardTemplatePicker(
                        selectedTemplate: _selectedTemplate,
                        onTemplateSelected: (tpl) {
                          setState(() => _selectedTemplate = tpl);
                        },
                      ),
                      const SizedBox(height: 16),
                      // Content editor
                      Text(
                        isZh ? '内容' : 'Content',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _contentController,
                        maxLines: 8,
                        minLines: 4,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          hintText: isZh ? '你的文字...' : 'Your words...',
                        ),
                      ),
                      const SizedBox(height: 8),
                      // AI Rewrite button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isRewriting ? null : _handleAiRewrite,
                          icon: _isRewriting
                              ? const SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.auto_awesome, size: 18),
                          label: Text(_isRewriting
                              ? (isZh ? '润色中...' : 'Rewriting...')
                              : (isZh ? 'AI 润色' : 'AI Rewrite')),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Toggle row
                      Text(
                        isZh ? '显示元素' : 'Show Elements',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      SwitchListTile(
                        dense: true,
                        title: Text(isZh ? '心情' : 'Mood'),
                        value: _showMood,
                        onChanged: (v) => setState(() => _showMood = v),
                      ),
                      SwitchListTile(
                        dense: true,
                        title: Text(isZh ? '日期' : 'Date'),
                        value: _showDate,
                        onChanged: (v) => setState(() => _showDate = v),
                      ),
                      SwitchListTile(
                        dense: true,
                        title: Text(isZh ? '标签' : 'Tags'),
                        value: _showTags,
                        onChanged: (v) => setState(() => _showTags = v),
                      ),
                      SwitchListTile(
                        dense: true,
                        title: Text(isZh ? '水印' : 'Footer'),
                        value: _showFooter,
                        onChanged: (v) => setState(() => _showFooter = v),
                      ),
                      const SizedBox(height: 20),
                      // Save button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white,
                                  ),
                                )
                              : Text(isZh ? '保存纪念' : 'Save Keepsake',
                                  style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleAiRewrite() async {
    setState(() => _isRewriting = true);
    try {
      final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
      final llmService = context.read<LlmConfigNotifier>();
      // TODO: Wire real LlmService call when available
      // For now, append a note that AI Rewrite will be available soon
      await Future.delayed(const Duration(seconds: 1));
    } finally {
      if (mounted) setState(() => _isRewriting = false);
    }
  }

  Future<void> _handleSave() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isZh ? '请输入内容' : 'Please enter some content')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final cardProvider = context.read<CardProvider>();

      // Render the PNG
      final renderFn = widget._renderFn ?? CardRenderService.renderToFile;
      final renderedPath = await renderFn(
        template: _selectedTemplate,
        content: content,
        imagePath: widget.initialPhotoPath,
        emotion: widget.initialEmotion,
        tags: widget.initialTags,
        date: widget.entryDate,
        showMood: _showMood,
        showDate: _showDate,
        showTags: _showTags,
        showFooter: _showFooter,
      );

      // Persist to DB
      final card = await cardProvider.addCard(
        entryIds: widget.entryId != null ? [widget.entryId!] : [],
        templateId: _selectedTemplate.id,
        folderId: 'folder_default',
        renderedImagePath: renderedPath,
        cardContent: content,
        emotion: widget.initialEmotion,
        displayTags: widget.initialTags,
        showMood: _showMood,
        showDate: _showDate,
        showTags: _showTags,
        showFooter: _showFooter,
      );

      if (mounted) {
        final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isZh ? '纪念已保存' : 'Keepsake saved')),
        );
        Navigator.of(context).pop(card);
      }
    } catch (e) {
      if (mounted) {
        final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isZh ? '保存失败: $e' : 'Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
