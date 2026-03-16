import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final bgColor = _hexToColor(template.bgColor);
    final fontColor = _hexToColor(template.fontColor);
    final firstEntry = entries.isNotEmpty ? entries.first : null;

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
          // Entry content
          Expanded(
            child: Text(
              card.aiSummary ?? firstEntry?.content ?? '',
              style: _fontStyle(template.fontFamily).copyWith(
                color: fontColor,
                fontSize: 14,
                height: 1.5,
              ),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
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

  /// Render the card widget to a PNG byte list and save to documents directory.
  /// Returns the saved file path.
  static Future<String> renderToImage({
    required NoteCard card,
    required CardTemplate template,
    required List<Entry> entries,
    double width = 320,
    double height = 200,
  }) async {
    // Render via direct canvas drawing (offscreen)
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
        recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

    // Simple fallback: draw background and text directly
    final bgColor = _hexToColor(template.bgColor);
    final fontColor = _hexToColor(template.fontColor);

    final bgPaint = Paint()..color = bgColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, width, height),
        const Radius.circular(12),
      ),
      bgPaint,
    );

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

      // Content text
      final textPainter = TextPainter(
        text: TextSpan(
          text: firstEntry.content,
          style: TextStyle(
            color: fontColor,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 6,
        ellipsis: '...',
      )..layout(maxWidth: width - 32);
      textPainter.paint(canvas, const Offset(16, 56));

      // Footer
      final datePainter = TextPainter(
        text: TextSpan(
          text:
              '${firstEntry.createdAt.year}/${firstEntry.createdAt.month}/${firstEntry.createdAt.day}',
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

    // Save to documents directory
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
