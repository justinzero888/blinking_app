import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/entry.dart';
import '../../models/note_card.dart';
import '../../models/card_template.dart';
import '../../providers/card_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/card_renderer.dart';

/// Shows a rendered PNG preview of a card before saving and sharing.
class CardPreviewScreen extends StatefulWidget {
  final NoteCard card;
  final CardTemplate? template;
  final List<Entry> entries;

  const CardPreviewScreen({
    super.key,
    required this.card,
    this.template,
    required this.entries,
  });

  @override
  State<CardPreviewScreen> createState() => _CardPreviewScreenState();
}

class _CardPreviewScreenState extends State<CardPreviewScreen> {
  bool _rendering = true;
  String? _imagePath;
  String? _error;

  @override
  void initState() {
    super.initState();
    _render();
  }

  Future<void> _render() async {
    final tpl = widget.template;
    if (tpl == null) {
      setState(() {
        _error = 'No template selected';
        _rendering = false;
      });
      return;
    }
    try {
      final path = await CardRenderer.renderToImage(
        card: widget.card,
        template: tpl,
        entries: widget.entries,
        width: 640,
        height: 400,
      );
      if (mounted) {
        setState(() {
          _imagePath = path;
          _rendering = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _rendering = false;
        });
      }
    }
  }

  Future<void> _save() async {
    final path = _imagePath;
    if (path == null) return;
    final cardProvider = context.read<CardProvider>();
    await cardProvider.updateCard(
      widget.card.copyWith(renderedImagePath: path, updatedAt: DateTime.now()),
    );
    if (mounted) {
      final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isZh ? '卡片已保存' : 'Card saved')),
      );
      Navigator.pop(context); // return to editor
    }
  }

  Future<void> _share() async {
    final path = _imagePath;
    if (path == null) return;
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    final suffix = isZh ? '来自 Blinking ✨' : 'From Blinking ✨';
    final text = (widget.card.aiSummary?.isNotEmpty == true)
        ? '${widget.card.aiSummary}\n\n— $suffix'
        : suffix;
    await Share.shareXFiles(
      [XFile(path)],
      text: text,
      subject: isZh ? '记忆卡片' : 'Memory Card',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        title: Text(isZh ? '预览' : 'Preview'),
        actions: [
          if (_imagePath != null) ...[
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: isZh ? '分享图片' : 'Share Image',
              onPressed: _share,
            ),
            IconButton(
              icon: const Icon(Icons.save_alt),
              tooltip: isZh ? '保存' : 'Save',
              onPressed: _save,
            ),
          ],
        ],
      ),
      body: Center(
        child: _rendering
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    isZh ? '正在渲染...' : 'Rendering...',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              )
            : _error != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_imagePath!),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}
