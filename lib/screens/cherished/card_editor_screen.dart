import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/entry.dart';
import '../../models/card_template.dart';
import '../../models/note_card.dart';
import '../../providers/card_provider.dart';
import '../../providers/locale_provider.dart';
import 'card_preview_screen.dart';

/// Full-screen rich text editor for a NoteCard.
class CardEditorScreen extends StatefulWidget {
  final NoteCard card;
  final CardTemplate? template;
  final List<Entry> entries;

  const CardEditorScreen({
    super.key,
    required this.card,
    this.template,
    required this.entries,
  });

  @override
  State<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends State<CardEditorScreen> {
  late QuillController _quillController;
  final FocusNode _focusNode = FocusNode();
  bool _saving = false;
  int _wordCount = 0;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    Document doc;
    if (widget.card.richContent != null) {
      try {
        doc = Document.fromJson(
            jsonDecode(widget.card.richContent!) as List<dynamic>);
      } catch (_) {
        doc = _docFromPlainText(_initialPlainText());
      }
    } else {
      doc = _docFromPlainText(_initialPlainText());
    }

    _quillController = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
    _wordCount = _countWords(_quillController.document.toPlainText());
    _quillController.addListener(() {
      final count = _countWords(_quillController.document.toPlainText());
      if (count != _wordCount) {
        setState(() {
          _wordCount = count;
        });
      }
    });
  }

  String _initialPlainText() {
    final firstEntry = widget.entries.isNotEmpty ? widget.entries.first : null;
    return widget.card.aiSummary ?? firstEntry?.content ?? '';
  }

  Document _docFromPlainText(String text) {
    final doc = Document();
    if (text.isNotEmpty) {
      doc.insert(0, text);
    }
    return doc;
  }

  int _countWords(String text) {
    final cjk = RegExp(r'[\u4e00-\u9fff\u3400-\u4dbf]');
    int count = cjk.allMatches(text).length;
    final noCjk = text.replaceAll(cjk, ' ');
    count += noCjk.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
    return count;
  }

  String _appBarTitle(bool isZh) {
    final summary = widget.card.aiSummary;
    if (summary != null && summary.isNotEmpty) {
      return summary.substring(0, min(20, summary.length));
    }
    return isZh ? '编辑卡片' : 'Edit Card';
  }

  Future<void> _insertImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;

    final docDir = await getApplicationDocumentsDirectory();
    final destDir = Directory('${docDir.path}/card_images');
    if (!await destDir.exists()) {
      await destDir.create(recursive: true);
    }
    final dest = '${destDir.path}/${const Uuid().v4()}.jpg';
    await File(xfile.path).copy(dest);

    final index = _quillController.selection.baseOffset;
    final safeIndex = index < 0 ? 0 : index;
    _quillController.replaceText(
      safeIndex,
      0,
      BlockEmbed.image(dest),
      null,
    );
  }

  Future<void> _save() async {
    if (_wordCount > 100 || _saving) return;
    setState(() => _saving = true);
    try {
      final deltaJson =
          jsonEncode(_quillController.document.toDelta().toJson());
      final plainText = _quillController.document.toPlainText().trim();
      final cardProvider = context.read<CardProvider>();
      final updatedCard = widget.card.copyWith(
        richContent: deltaJson,
        aiSummary: plainText,
        updatedAt: DateTime.now(),
      );
      await cardProvider.updateCard(updatedCard);
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CardPreviewScreen(
              card: updatedCard,
              template: widget.template,
              entries: widget.entries,
            ),
          ),
        );
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isZh ? '保存失败：$e' : 'Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _quillController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final bool overLimit = _wordCount > 100;
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle(isZh)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save),
            tooltip: isZh ? '保存并预览' : 'Save & Preview',
            onPressed: overLimit || _saving ? null : _save,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: QuillEditor(
              controller: _quillController,
              focusNode: _focusNode,
              scrollController: ScrollController(),
              config: QuillEditorConfig(
                scrollable: true,
                padding: const EdgeInsets.all(16),
                embedBuilders: [_LocalImageEmbedBuilder()],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                isZh ? '$_wordCount / 100 字' : '$_wordCount / 100 words',
                style: TextStyle(
                  fontSize: 12,
                  color: overLimit ? Colors.red : Colors.grey,
                ),
              ),
            ),
          ),
          QuillSimpleToolbar(
            controller: _quillController,
            config: QuillSimpleToolbarConfig(
              showFontFamily: false,
              showFontSize: true,
              showBoldButton: true,
              showItalicButton: true,
              showUnderLineButton: true,
              showStrikeThrough: false,
              showInlineCode: false,
              showColorButton: true,
              showBackgroundColorButton: false,
              showClearFormat: true,
              showAlignmentButtons: false,
              showHeaderStyle: false,
              showListNumbers: false,
              showListBullets: false,
              showListCheck: false,
              showCodeBlock: false,
              showQuote: false,
              showIndent: false,
              showLink: false,
              showUndo: true,
              showRedo: true,
              showSearchButton: false,
              showSubscript: false,
              showSuperscript: false,
              showDividers: true,
              embedButtons: [
                (context, embedContext) => IconButton(
                      icon: const Icon(Icons.image, size: 18),
                      tooltip: isZh ? '插入图片' : 'Insert image',
                      onPressed: _insertImage,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Embed builder that renders local file images inserted into the Quill editor.
class _LocalImageEmbedBuilder extends EmbedBuilder {
  @override
  String get key => BlockEmbed.imageType;

  @override
  bool get expanded => false;

  @override
  WidgetSpan buildWidgetSpan(Widget widget) => WidgetSpan(child: widget);

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final path = embedContext.node.value.data as String;
    final file = File(path);
    if (!file.existsSync()) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Image.file(file, fit: BoxFit.contain),
    );
  }
}
