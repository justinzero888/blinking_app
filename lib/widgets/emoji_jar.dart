import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/jar_provider.dart';
import '../core/services/llm_service.dart';

/// A stylised glass jar widget showing the day's emotions as emoji.
class EmojiJarWidget extends StatelessWidget {
  final DateTime date;
  final double size;

  const EmojiJarWidget({super.key, required this.date, this.size = 160});

  @override
  Widget build(BuildContext context) {
    final emotions = context.watch<JarProvider>().getDayEmotions(date);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size * 1.1,
          child: CustomPaint(
            painter: _JarPainter(),
            child: ClipPath(
              clipper: _JarClipper(),
              child: Container(
                padding: EdgeInsets.fromLTRB(
                    size * 0.1, size * 0.18, size * 0.1, size * 0.08),
                child: emotions.isEmpty
                    ? Center(
                        child: Text(
                          '空',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: size * 0.18,
                          ),
                        ),
                      )
                    : Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 2,
                        runSpacing: 2,
                        children: emotions
                            .map(
                              (e) => Text(
                                e,
                                style: TextStyle(fontSize: size * 0.12),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          icon: const Text('✨', style: TextStyle(fontSize: 14)),
          label: const Text('问问 AI', style: TextStyle(fontSize: 13)),
          onPressed: emotions.isEmpty
              ? null
              : () => _openAIBottomSheet(context, emotions),
        ),
      ],
    );
  }

  void _openAIBottomSheet(BuildContext context, List<String> emotions) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _AiBottomSheet(emotions: emotions),
    );
  }
}

class _AiBottomSheet extends StatefulWidget {
  final List<String> emotions;
  const _AiBottomSheet({required this.emotions});

  @override
  State<_AiBottomSheet> createState() => _AiBottomSheetState();
}

class _AiBottomSheetState extends State<_AiBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _llm = LlmService();
  bool _loading = false;
  String _result = '';
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _activeTab = _tabController.index;
          _result = '';
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _buildPrompt(int tabIndex) {
    final emojiStr = widget.emotions.join(' ');
    switch (tabIndex) {
      case 0:
        return '我今天的情绪有：$emojiStr。请给我一句温暖的鼓励话语（不超过50字）。';
      case 1:
        return '我今天的情绪有：$emojiStr。请给我一句创意灵感或思考方向（不超过50字）。';
      case 2:
        return '我今天的情绪有：$emojiStr。请给我一句增强行动力的动力语句（不超过50字）。';
      default:
        return '';
    }
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _result = '';
    });
    try {
      final text = await _llm.complete(_buildPrompt(_activeTab));
      setState(() => _result = text);
    } catch (e) {
      setState(() => _result = '生成失败：${e.toString().replaceFirst('LlmException: ', '')}');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: 320,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '鼓励'),
                Tab(text: '灵感'),
                Tab(text: '动力'),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (_loading)
                      const Expanded(
                          child: Center(child: CircularProgressIndicator()))
                    else if (_result.isNotEmpty)
                      Expanded(
                        child: Center(
                          child: Text(
                            _result,
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      const Expanded(
                        child: Center(
                          child: Text(
                            '点击下方按钮，让 AI 为你生成',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ElevatedButton(
                      onPressed: _loading ? null : _generate,
                      child: const Text('生成'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints a mason jar silhouette with amber tint and shimmer.
class _JarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Lid / neck area (top 15% of height)
    final neckTop = h * 0.0;
    final neckBottom = h * 0.15;
    final neckLeft = w * 0.25;
    final neckRight = w * 0.75;

    // Jar body (trapezoid — wider at top, narrower at bottom)
    final bodyTopLeft = w * 0.12;
    final bodyTopRight = w * 0.88;
    final bodyBottom = h * 1.0;
    final bodyBottomLeft = w * 0.18;
    final bodyBottomRight = w * 0.82;
    final bodyTop = neckBottom;

    final jarPath = Path()
      ..moveTo(neckLeft, neckTop)
      ..lineTo(neckRight, neckTop)
      ..lineTo(neckRight, neckBottom)
      ..lineTo(bodyTopRight, bodyTop)
      ..lineTo(bodyBottomRight, bodyBottom)
      ..lineTo(bodyBottomLeft, bodyBottom)
      ..lineTo(bodyTopLeft, bodyTop)
      ..lineTo(neckLeft, neckBottom)
      ..close();

    // Fill: semi-transparent amber
    final fillPaint = Paint()
      ..color = const Color(0xFFFFE082).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawPath(jarPath, fillPaint);

    // Shimmer overlay (left edge highlight)
    final shimmerRect = Rect.fromLTRB(0, neckTop, w, bodyBottom);
    final shimmerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.35),
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.3, 1.0],
      ).createShader(shimmerRect);
    canvas.drawPath(jarPath, shimmerPaint);

    // Outline
    final outlinePaint = Paint()
      ..color = const Color(0xFFFFB300).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(jarPath, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Clips the emoji wrap to the jar body shape.
class _JarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final neckBottom = h * 0.15;
    final bodyTopLeft = w * 0.12;
    final bodyTopRight = w * 0.88;
    final bodyBottom = h * 1.0;
    final bodyBottomLeft = w * 0.18;
    final bodyBottomRight = w * 0.82;

    return Path()
      ..moveTo(w * 0.25, 0)
      ..lineTo(w * 0.75, 0)
      ..lineTo(w * 0.75, neckBottom)
      ..lineTo(bodyTopRight, neckBottom)
      ..lineTo(bodyBottomRight, bodyBottom)
      ..lineTo(bodyBottomLeft, bodyBottom)
      ..lineTo(bodyTopLeft, neckBottom)
      ..lineTo(w * 0.25, neckBottom)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
