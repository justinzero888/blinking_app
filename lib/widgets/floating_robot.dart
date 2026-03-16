import 'package:flutter/material.dart';
import '../screens/assistant/assistant_screen.dart';

/// Floating animated robot widget overlaid on the main screen.
/// Bobs up and down on an idle animation; tapping opens AssistantScreen.
class FloatingRobotWidget extends StatefulWidget {
  const FloatingRobotWidget({super.key});

  @override
  State<FloatingRobotWidget> createState() => _FloatingRobotWidgetState();
}

class _FloatingRobotWidgetState extends State<FloatingRobotWidget>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _bobAnimation;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final AnimationController _waveController;
  late final Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _bobAnimation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _waveAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.3, end: -0.3), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.3, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _waveController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _openAssistant() {
    _waveController.forward(from: 0);
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const AssistantScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 90,
      child: AnimatedBuilder(
        animation: Listenable.merge([_bobAnimation, _pulseAnimation, _waveAnimation]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _bobAnimation.value),
            child: Transform.rotate(
              angle: _waveAnimation.value,
              child: Transform.scale(
                scale: _pulseAnimation.value,
                child: child,
              ),
            ),
          );
        },
        child: GestureDetector(
          onTap: _openAssistant,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text('🤖', style: TextStyle(fontSize: 28)),
            ),
          ),
        ),
      ),
    );
  }
}
