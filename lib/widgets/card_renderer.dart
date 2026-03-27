import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:path_provider/path_provider.dart';
import '../models/note_card.dart';
import '../models/card_template.dart';
import '../models/entry.dart';

/// Renders a note card visually using a template's colors and entry content.
class CardRenderer extends StatelessWidget {
  final NoteCard card;
  final CardTemplate template;
  final List<Entry> entries;
  final double width;
  final double height;

  const CardRenderer({
    super.key,
    required this.card,
    required this.template,
    required this.entries,
    this.width = 320,
    this.height = 200,
  });

  /// Extract plain text from richContent Delta JSON, falling back to aiSummary or entry content.
  static String _extractPlainText(
      String? richContent, String? aiSummary, Entry? firstEntry) {
    if (richContent != null) {
      try {
        final doc = Document.fromJson(jsonDecode(richContent) as List);
        return doc.toPlainText().trim();
      } catch (_) {}
    }
    return aiSummary ?? firstEntry?.content ?? '';
  }

  static Color _hexToColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(cleaned, radix: 16) ?? 0xFFFFFF;
    return Color(0xFF000000 | value);
  }

  static TextStyle _fontStyle(String fontFamily) {
    switch (fontFamily) {
      case 'serif':
        return const TextStyle(fontFamily: 'serif');
      case 'mono':
        return const TextStyle(fontFamily: 'monospace');
      default:
        return const TextStyle();
    }
  }

  /// Returns the largest font size where [text] fits within [maxHeight]
  /// when laid out at [maxWidth]. Short text → large font; long text → small font.
  static double _autoFontSize(
    String text,
    double maxWidth,
    double maxHeight, {
    double maxSize = 96.0,
    double minSize = 9.0,
  }) {
    double fontSize = maxSize;
    while (fontSize > minSize) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(fontSize: fontSize, height: 1.5),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxWidth);
      if (painter.height <= maxHeight) return fontSize;
      fontSize -= 1.0;
    }
    return minSize;
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _hexToColor(template.bgColor);
    final fontColor = _hexToColor(template.fontColor);
    final firstEntry = entries.isNotEmpty ? entries.first : null;
    final content = _extractPlainText(card.richContent, card.aiSummary, firstEntry);
    final textAreaWidth = width * 0.88;
    final textAreaHeight = height * 0.8;
    final fontSize = _autoFontSize(content, textAreaWidth, textAreaHeight);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: template.customImagePath == null ? bgColor : null,
        image: template.customImagePath != null
            ? DecorationImage(
                image: FileImage(File(template.customImagePath!)),
                fit: BoxFit.cover,
              )
            : null,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emotion emoji from first entry
          if (firstEntry?.emotion != null)
            Text(
              firstEntry!.emotion!,
              style: const TextStyle(fontSize: 28),
            ),
          const SizedBox(height: 8),
          // Entry content — fills height×0.8 / width×0.88 text area
          SizedBox(
            width: textAreaWidth,
            height: textAreaHeight,
            child: Text(
              content,
              style: _fontStyle(template.fontFamily).copyWith(
                color: fontColor,
                fontSize: fontSize,
                height: 1.5,
              ),
              overflow: TextOverflow.clip,
            ),
          ),
          // Footer: date + branding
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                firstEntry != null
                    ? '${firstEntry.createdAt.year}/${firstEntry.createdAt.month}/${firstEntry.createdAt.day}'
                    : '',
                style: TextStyle(
                  color: fontColor.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
              Text(
                'Blinking ✨',
                style: TextStyle(
                  color: fontColor.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Render the card widget to a PNG and save to documents directory.
  /// Returns the saved file path.
  static Future<String> renderToImage({
    required NoteCard card,
    required CardTemplate template,
    required List<Entry> entries,
    double width = 320,
    double height = 200,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
        recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

    final bgColor = _hexToColor(template.bgColor);
    final fontColor = _hexToColor(template.fontColor);

    final roundedRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, height),
      const Radius.circular(12),
    );

    // Draw background: custom image or solid color
    canvas.save();
    canvas.clipRRect(roundedRect);
    if (template.customImagePath != null) {
      final imgFile = File(template.customImagePath!);
      if (imgFile.existsSync()) {
        final bytes = await imgFile.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final img = frame.image;
        canvas.drawImageRect(
          img,
          Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
          Rect.fromLTWH(0, 0, width, height),
          Paint()..filterQuality = FilterQuality.high,
        );
        // Semi-transparent overlay so text stays readable over the image
        canvas.drawRect(
          Rect.fromLTWH(0, 0, width, height),
          Paint()..color = Colors.black.withValues(alpha: 0.25),
        );
      } else {
        canvas.drawRect(Rect.fromLTWH(0, 0, width, height), Paint()..color = bgColor);
      }
    } else {
      canvas.drawRect(Rect.fromLTWH(0, 0, width, height), Paint()..color = bgColor);
    }
    canvas.restore();

    final firstEntry = entries.isNotEmpty ? entries.first : null;
    if (firstEntry != null) {
      // Emotion emoji
      if (firstEntry.emotion != null) {
        final emojiPainter = TextPainter(
          text: TextSpan(
            text: firstEntry.emotion,
            style: const TextStyle(fontSize: 28),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: width - 32);
        emojiPainter.paint(canvas, const Offset(16, 16));
      }

      // Auto-size: largest font that fills the text area (height×0.8, width×0.88)
      final content = _extractPlainText(card.richContent, card.aiSummary, firstEntry);
      final textAreaWidth = width * 0.88;
      final fontSize = _autoFontSize(content, textAreaWidth, height * 0.8);
      final textPainter = TextPainter(
        text: TextSpan(
          text: content,
          style: TextStyle(color: fontColor, fontSize: fontSize, height: 1.5),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: textAreaWidth);
      textPainter.paint(canvas, const Offset(16, 56));

      // Footer
      final datePainter = TextPainter(
        text: TextSpan(
          text: '${firstEntry.createdAt.year}/${firstEntry.createdAt.month}/${firstEntry.createdAt.day}',
          style: TextStyle(
            color: fontColor.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: width / 2);
      datePainter.paint(canvas, Offset(16, height - 28));

      final brandPainter = TextPainter(
        text: TextSpan(
          text: 'Blinking ✨',
          style: TextStyle(
            color: fontColor.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: width / 2);
      brandPainter.paint(
          canvas, Offset(width - brandPainter.width - 16, height - 28));
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    final docDir = await getApplicationDocumentsDirectory();
    final cardsDir = Directory('${docDir.path}/cards');
    if (!await cardsDir.exists()) {
      await cardsDir.create(recursive: true);
    }
    final filePath = '${cardsDir.path}/${card.id}.png';
    await File(filePath).writeAsBytes(pngBytes);
    return filePath;
  }
}
