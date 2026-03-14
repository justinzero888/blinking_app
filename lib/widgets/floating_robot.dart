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
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _bobAnimation;

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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openAssistant() {
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
      bottom: 90, // above FAB + nav bar
      child: AnimatedBuilder(
        animation: _bobAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _bobAnimation.value),
            child: child,
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
