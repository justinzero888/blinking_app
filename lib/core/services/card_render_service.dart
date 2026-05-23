import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/card_enums.dart';
import '../../models/card_template.dart';

/// Off-screen rendering service for Keepsake cards.
/// Renders 1080×1440 3:4 portrait PNGs with template engine, auto-font sizing,
/// overlay elements, and decorative motifs.
class CardRenderService {
  static const int _cardWidth = 1080;
  static const int _cardHeight = 1440;
  static const String _defaultFooter = 'Blinking Notes';
  static const int _minFontSize = 9;
  static const int _maxFontSize = 96;
  static const _uuid = Uuid();

  CardRenderService._();

  /// Builds the card widget tree for preview (mounted in RepaintBoundary).
  static Widget buildPreviewWidget({
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
    Map<String, dynamic>? styleOverrides,
  }) {
    final config = _buildConfig(
      template,
      styleOverrides: styleOverrides,
      showMood: showMood,
      showDate: showDate,
      showTags: showTags,
      showFooter: showFooter,
    );
    return _CardRenderWidget(
      template: template,
      config: config,
      content: content,
      imagePath: imagePath,
      emotion: emotion,
      tags: tags,
      date: date,
    );
  }

  /// Renders a card to a PNG file and returns the file path.
  /// Uses an off-screen RepaintBoundary pipeline.
  static Future<String> renderToFile({
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
    Map<String, dynamic>? styleOverrides,
  }) async {
    final widget = buildPreviewWidget(
      template: template,
      content: content,
      imagePath: imagePath,
      emotion: emotion,
      tags: tags,
      date: date,
      showMood: showMood,
      showDate: showDate,
      showTags: showTags,
      showFooter: showFooter,
      styleOverrides: styleOverrides,
    );

    final image = await _renderOffscreen(widget);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) throw Exception('Failed to convert image to PNG bytes');

    final dir = await getApplicationDocumentsDirectory();
    final cardDir = Directory('${dir.path}/cards');
    if (!cardDir.existsSync()) cardDir.createSync(recursive: true);
    final path = '${cardDir.path}/${_uuid.v4()}.png';
    await File(path).writeAsBytes(bytes.buffer.asUint8List());
    return path;
  }

  /// Captures a PNG from a RepaintBoundary key (for preview screen).
  static Future<String?> captureFromKey(GlobalKey boundaryKey) async {
    final boundary =
        boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return null;

    final dir = await getApplicationDocumentsDirectory();
    final cardDir = Directory('${dir.path}/cards');
    if (!cardDir.existsSync()) cardDir.createSync(recursive: true);
    final path = '${cardDir.path}/${_uuid.v4()}.png';
    await File(path).writeAsBytes(bytes.buffer.asUint8List());
    return path;
  }

  // ---- Private rendering ----

  static Future<ui.Image> _renderOffscreen(Widget widget) async {
    WidgetsFlutterBinding.ensureInitialized();

    final renderObject = RenderRepaintBoundary();
    final pipelineOwner = PipelineOwner();
    renderObject.attach(pipelineOwner);

    final element = RenderObjectToWidgetAdapter<RenderBox>(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: widget,
      ),
      container: renderObject,
    ).createElement();
    element.assignOwner(BuildOwner(focusManager: FocusManager()));
    element.mount(null, null);

    renderObject.layout(
      BoxConstraints.tight(Size(_cardWidth.toDouble(), _cardHeight.toDouble())),
    );
    pipelineOwner.flushLayout();
    pipelineOwner.flushPaint();
    element.unmount();

    return renderObject.toImage(pixelRatio: 1.0);
  }

  static _CardConfig _buildConfig(
    CardTemplate template, {
    Map<String, dynamic>? styleOverrides,
    bool? showMood,
    bool? showDate,
    bool? showTags,
    bool? showFooter,
  }) {
    return _CardConfig(
      layout: template.layout,
      bgColor: _parseColor(template.bgColor),
      fontColor: _parseColor(styleOverrides?['font_color'] as String? ?? template.fontColor),
      accentColor: template.accentColor != null
          ? _parseColor(styleOverrides?['accent_color'] as String? ?? template.accentColor!)
          : null,
      textBackdropColor: template.textBackdropColor != null
          ? _tryParseRgba(template.textBackdropColor!)
          : null,
      textAreaOpacity: (styleOverrides?['text_area_opacity'] as num?)?.toDouble() ??
          template.textAreaOpacity,
      footerText: template.footerText ?? _defaultFooter,
      showMood: showMood ?? template.showMood,
      showDate: showDate ?? template.showDate,
      showTags: showTags ?? template.showTags,
      showFooter: showFooter ?? template.showFooter,
      cornerStyle: template.cornerStyle,
      decorationStyle: template.decorationStyle,
    );
  }

  static Color _parseColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  static Color? _tryParseRgba(String rgba) {
    try {
      final match = RegExp(r'rgba\((\d+),\s*(\d+),\s*(\d+),\s*([\d.]+)\)').firstMatch(rgba);
      if (match != null) {
        return Color.fromARGB(
          (double.parse(match.group(4)!) * 255).round(),
          int.parse(match.group(1)!),
          int.parse(match.group(2)!),
          int.parse(match.group(3)!),
        );
      }
    } catch (_) {}
    return null;
  }
}

/// Internal configuration resolved from template + overrides.
class _CardConfig {
  final CardLayout layout;
  final Color bgColor;
  final Color fontColor;
  final Color? accentColor;
  final Color? textBackdropColor;
  final double textAreaOpacity;
  final String footerText;
  final bool showMood;
  final bool showDate;
  final bool showTags;
  final bool showFooter;
  final CardCornerStyle cornerStyle;
  final String? decorationStyle;

  const _CardConfig({
    required this.layout,
    required this.bgColor,
    required this.fontColor,
    this.accentColor,
    this.textBackdropColor,
    required this.textAreaOpacity,
    required this.footerText,
    required this.showMood,
    required this.showDate,
    required this.showTags,
    required this.showFooter,
    required this.cornerStyle,
    this.decorationStyle,
  });
}

/// The full card widget tree rendered at 1080×1440.
class _CardRenderWidget extends StatelessWidget {
  final CardTemplate template;
  final _CardConfig config;
  final String content;
  final String? imagePath;
  final String? emotion;
  final List<String>? tags;
  final DateTime? date;

  const _CardRenderWidget({
    required this.template,
    required this.config,
    required this.content,
    this.imagePath,
    this.emotion,
    this.tags,
    this.date,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CardRenderService._cardWidth.toDouble(),
      height: CardRenderService._cardHeight.toDouble(),
      child: DecoratedBox(
        decoration: _buildBackground(),
        child: _buildLayout(),
      ),
    );
  }

  Decoration _buildBackground() {
    if (config.decorationStyle != null) {
      return _buildDecoratedBackground(config.decorationStyle!);
    }
    return BoxDecoration(color: config.bgColor);
  }

  Decoration _buildDecoratedBackground(String style) {
    switch (style) {
      case 'ink_wash':
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF5F0E8),
              Color(0xFFD8D0C0),
            ],
          ),
        );
      case 'bamboo':
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEDF5EC),
              Color(0xFFD4E6D0),
            ],
          ),
        );
      case 'crescent':
      case 'moonlight':
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1B2838),
              Color(0xFF2D4A5A),
            ],
          ),
        );
      case 'tea':
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF5EDE3),
              Color(0xFFE8D5C0),
            ],
          ),
        );
      case 'landscape':
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFD6E0E8),
              Color(0xFFB8C8D4),
            ],
          ),
        );
      default:
        return BoxDecoration(color: config.bgColor);
    }
  }

  Widget _buildLayout() {
    switch (config.layout) {
      case CardLayout.centered:
        return _buildCenteredLayout();
      case CardLayout.leftAligned:
        return _buildLeftAlignedLayout();
      case CardLayout.twoColumn:
        return _buildTwoColumnLayout();
      case CardLayout.heroImage:
      default:
        return _buildHeroLayout();
    }
  }

  // --- Hero Image Layout ---

  Widget _buildHeroLayout() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (imagePath != null) _buildFullBleedImage(),
        _buildDecorativeMotif(config.decorationStyle),
        Center(child: _buildTextBlock(content)),
        Positioned(
          left: 40,
          right: 40,
          bottom: 60,
          child: _buildOverlayRow(),
        ),
      ],
    );
  }

  // --- Centered Layout ---

  Widget _buildCenteredLayout() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (imagePath != null) _buildFullBleedImage(),
        _buildDecorativeMotif(config.decorationStyle),
        if (config.decorationStyle == 'porcelain') _buildPorcelainBorders(),
        Center(child: _buildTextBlock(content)),
        Positioned(
          left: 40,
          right: 40,
          bottom: 60,
          child: _buildOverlayRow(),
        ),
      ],
    );
  }

  // --- Left-Aligned Layout ---

  Widget _buildLeftAlignedLayout() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Left accent bar
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: Container(
            width: 4,
            color: config.accentColor ?? config.fontColor.withValues(alpha: 0.3),
          ),
        ),
        // Rice paper texture for 素笺
        if (config.decorationStyle == 'rice_paper') _buildRicePaperTexture(),
        // Main content
        Padding(
          padding: const EdgeInsets.only(left: 40, top: 80, right: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildTextBlock(content, align: TextAlign.left)),
              if (imagePath != null) _buildInlineImage(),
            ],
          ),
        ),
        Positioned(
          left: 40,
          right: 40,
          bottom: 60,
          child: Align(
            alignment: Alignment.centerLeft,
            child: _buildOverlayRow(),
          ),
        ),
      ],
    );
  }

  // --- Two-Column Layout ---

  Widget _buildTwoColumnLayout() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Column(
          children: [
            if (imagePath != null)
              SizedBox(
                height: CardRenderService._cardHeight * 0.4,
                child: _buildHeroImage(),
              ),
            Expanded(child: _buildContentArea()),
          ],
        ),
        Positioned(
          left: 40,
          right: 40,
          bottom: 60,
          child: _buildOverlayRow(),
        ),
      ],
    );
  }

  Widget _buildContentArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: _buildTextBlock(content),
    );
  }

  // --- Image helpers ---

  Widget _buildFullBleedImage() {
    return ClipRRect(
      child: Image.file(
        File(imagePath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        color: Colors.black.withValues(alpha: 0.15),
        colorBlendMode: BlendMode.darken,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildHeroImage() {
    return Image.file(
      File(imagePath!),
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  Widget _buildInlineImage() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(imagePath!),
          width: 200,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  // --- Text block ---

  Widget _buildTextBlock(String text, {TextAlign align = TextAlign.center}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final effectiveText = text.trim().isEmpty ? '' : text.trim();
          if (effectiveText.isEmpty) return const SizedBox.shrink();

          final fontSize = _findOptimalFontSize(
            effectiveText,
            constraints.maxWidth,
            constraints.maxHeight,
          );

          final hasBackdrop = config.textBackdropColor != null;

          Widget textWidget = Text(
            effectiveText,
            textAlign: align,
            style: TextStyle(
              fontSize: fontSize,
              color: config.fontColor,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
            maxLines: null,
            overflow: TextOverflow.visible,
          );

          if (hasBackdrop) {
            textWidget = Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: config.textBackdropColor!.withValues(
                  alpha: config.textAreaOpacity,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: textWidget,
            );
          }

          return Center(child: textWidget);
        },
      ),
    );
  }

  double _findOptimalFontSize(String text, double maxWidth, double maxHeight) {
    double low = CardRenderService._minFontSize.toDouble();
    double high = CardRenderService._maxFontSize.toDouble();
    double best = low;

    while (low <= high) {
      final mid = (low + high) / 2;
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(fontSize: mid, height: 1.5),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxWidth);

      if (tp.height <= maxHeight && tp.width <= maxWidth) {
        best = mid;
        low = mid + 0.5;
      } else {
        high = mid - 0.5;
      }
    }
    return best.clamp(CardRenderService._minFontSize.toDouble(), CardRenderService._maxFontSize.toDouble());
  }

  // --- Overlay row ---

  Widget _buildOverlayRow() {
    final items = <Widget>[];

    if (config.showMood && emotion != null && emotion!.isNotEmpty) {
      items.add(Text(emotion!, style: const TextStyle(fontSize: 24)));
      items.add(const SizedBox(width: 8));
    }
    if (config.showDate && date != null) {
      items.add(Text(
        '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}',
        style: TextStyle(fontSize: 18, color: config.fontColor.withValues(alpha: 0.6)),
      ));
      items.add(const SizedBox(width: 8));
    }
    if (config.showTags && tags != null && tags!.isNotEmpty) {
      final displayTags = tags!
          .where((t) => t != 'tag_synthesis' && t != 'tag_private')
          .take(5)
          .toList();
      if (displayTags.isNotEmpty) {
        items.add(Text(
          displayTags.map((t) => '#$t').join(' '),
          style: TextStyle(fontSize: 16, color: config.fontColor.withValues(alpha: 0.5)),
        ));
        items.add(const SizedBox(width: 8));
      }
    }
    if (config.showFooter) {
      items.add(Text(
        config.footerText,
        style: TextStyle(fontSize: 14, color: config.fontColor.withValues(alpha: 0.4)),
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: items,
    );
  }

  // --- Decorative motifs ---

  Widget _buildDecorativeMotif(String? style) {
    if (style == null) return const SizedBox.shrink();
    switch (style) {
      case 'crescent':
        return _buildCrescentMoon();
      case 'bamboo':
        return _buildBambooLeaf();
      case 'seal':
        return _buildSealStamp();
      case 'tea':
        return _buildTeaSteam();
      case 'landscape':
        return _buildMountainSilhouettes();
      case 'porcelain':
        return const SizedBox.shrink(); // Borders handled separately
      case 'ink_wash':
      case 'rice_paper':
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCrescentMoon() {
    return Positioned(
      right: 60,
      top: 60,
      child: CustomPaint(
        size: const Size(120, 120),
        painter: _CrescentPainter(),
      ),
    );
  }

  Widget _buildBambooLeaf() {
    return Positioned(
      right: 40,
      bottom: 120,
      child: CustomPaint(
        size: const Size(160, 100),
        painter: _BambooPainter(config.accentColor ?? const Color(0xFF7A9A6D)),
      ),
    );
  }

  Widget _buildSealStamp() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            border: Border.all(color: config.accentColor ?? const Color(0xFFC43A31), width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              '印',
              style: TextStyle(
                fontSize: 28,
                color: config.accentColor ?? const Color(0xFFC43A31),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeaSteam() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _SteamPainter(config.accentColor ?? const Color(0xFF8FBFB3)),
      ),
    );
  }

  Widget _buildMountainSilhouettes() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: CardRenderService._cardHeight * 0.5,
      child: CustomPaint(
        painter: _MountainPainter(),
      ),
    );
  }

  Widget _buildPorcelainBorders() {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: Container(
        height: 4,
        color: config.accentColor ?? const Color(0xFF2B5F8A),
      ),
    );
  }

  Widget _buildRicePaperTexture() {
    return Positioned.fill(
      child: CustomPaint(painter: _RicePaperPainter()),
    );
  }
}

// --- Decorative motif painters ---

class _CrescentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x14FFFFFF)
      ..style = PaintingStyle.fill;
    final outerPath = Path()..addOval(Rect.fromCircle(center: Offset(size.width * 0.6, size.height * 0.5), radius: 45));
    final innerPath = Path()..addOval(Rect.fromCircle(center: Offset(size.width * 0.75, size.height * 0.35), radius: 45));
    final crescent = Path.combine(PathOperation.difference, outerPath, innerPath);
    canvas.drawPath(crescent, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BambooPainter extends CustomPainter {
  final Color color;
  _BambooPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width, size.height * 0.3)
      ..quadraticBezierTo(size.width * 0.7, size.height * 0.1, size.width * 0.6, 0)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.2, size.width * 0.8, size.height * 0.5)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SteamPainter extends CustomPainter {
  final Color color;
  _SteamPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < 3; i++) {
      final path = Path();
      final x = size.width * (0.3 + i * 0.2);
      path.moveTo(x, size.height * 0.5);
      path.quadraticBezierTo(x - 30, size.height * 0.35, x, size.height * 0.2);
      path.relativeQuadraticBezierTo(30, -50, 0, -70);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paints = [
      Paint()..color = const Color(0xFF6B7B8D).withValues(alpha: 0.12),
      Paint()..color = const Color(0xFF8A9BA8).withValues(alpha: 0.10),
      Paint()..color = const Color(0xFFA0B0B8).withValues(alpha: 0.08),
    ];

    final offsets = [0.0, 30.0, 60.0];
    for (int i = 0; i < 3; i++) {
      final path = Path()
        ..moveTo(0, size.height)
        ..lineTo(size.width * 0.1, size.height * 0.6 - offsets[i])
        ..lineTo(size.width * 0.3, size.height * 0.35 - offsets[i])
        ..lineTo(size.width * 0.5, size.height * 0.55 - offsets[i])
        ..lineTo(size.width * 0.7, size.height * 0.25 - offsets[i])
        ..lineTo(size.width * 0.9, size.height * 0.5 - offsets[i])
        ..lineTo(size.width, size.height * 0.65 - offsets[i])
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(path, paints[i]);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RicePaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x08C43A31)
      ..strokeWidth = 0.5;
    for (double y = 0; y < size.height; y += 8) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
