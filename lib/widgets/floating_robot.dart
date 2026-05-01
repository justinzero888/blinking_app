import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/ai_persona_provider.dart';
import '../providers/llm_config_notifier.dart';
import '../core/services/llm_service.dart';
import '../core/services/trial_service.dart';
import '../screens/assistant/assistant_screen.dart';

/// Floating animated robot widget overlaid on the main screen.
/// - Visible only on tabs 0 (Calendar), 1 (Moments), 2 (Routine).
/// - Full opacity + bobbing when API key is configured.
/// - 50% opacity + no animation + ! badge when no API key.
class FloatingRobotWidget extends StatefulWidget {
  final int currentTabIndex;

  const FloatingRobotWidget({super.key, required this.currentTabIndex});

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

  bool _hasApiKey = false;
  bool _trialExpired = false;
  LlmConfigNotifier? _llmNotifier;

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
    ]).animate(
        CurvedAnimation(parent: _waveController, curve: Curves.easeInOut));

    _checkApiKey();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final notifier = context.read<LlmConfigNotifier>();
    if (_llmNotifier != notifier) {
      _llmNotifier?.removeListener(_checkApiKey);
      _llmNotifier = notifier;
      _llmNotifier!.addListener(_checkApiKey);
    }
    _checkApiKey();
  }

  Future<void> _checkApiKey() async {
    final hasKey = await LlmService.hasApiKey();
    final prefs = await SharedPreferences.getInstance();
    final trialService = TrialService(prefs);
    final trialActive = trialService.getStatus() == TrialStatus.active;
    final trialExpired = trialService.getStatus() == TrialStatus.expired;
    if (mounted) {
      final keyChanged = hasKey != _hasApiKey;
      final expiredChanged = trialExpired != _trialExpired;
      if (keyChanged || expiredChanged) {
        setState(() {
          _hasApiKey = hasKey || trialActive;
          _trialExpired = trialExpired && !hasKey;
        });
      }
    }
  }

  @override
  void dispose() {
    _llmNotifier?.removeListener(_checkApiKey);
    _controller.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _openAssistant() {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    if (!_hasApiKey) {
      final message = _trialExpired
          ? (isZh
              ? '试用已过期。请在 设置 → AI 服务配置 中添加 API Key 以继续使用 AI 助手。'
              : 'Your trial has ended. Add your API key in Settings → AI Providers to continue.')
          : (isZh
              ? '请前往 设置 → AI 服务配置 添加 API Key 后使用助手'
              : 'Add your API key in Settings → AI Providers to use the assistant');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
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
    // Hide on Keepsakes (3) and Settings (4)
    if (widget.currentTabIndex >= 3) return const SizedBox.shrink();

    final avatarPath = context.watch<AiPersonaProvider>().avatarPath;
    final avatarFile = avatarPath != null ? File(avatarPath) : null;
    final hasAvatar = avatarFile != null && avatarFile.existsSync();

    Widget avatar = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: _hasApiKey
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.grey[300],
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: hasAvatar
          ? ClipOval(child: Image.file(avatarFile, fit: BoxFit.cover))
          : const Center(child: Text('🤖', style: TextStyle(fontSize: 28))),
    );

    // No API key: grey out, add badge, stop animation
    if (!_hasApiKey) {
      return Positioned(
        right: 16,
        bottom: 90,
        child: Opacity(
          opacity: 0.5,
          child: GestureDetector(
            onTap: _openAssistant,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                avatar,
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: _trialExpired ? Colors.grey : Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _trialExpired ? '\u{1F550}' : '!',
                        style: TextStyle(
                          fontSize: _trialExpired ? 12 : 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // API key present: full animated robot
    return Positioned(
      right: 16,
      bottom: 90,
      child: AnimatedBuilder(
        animation: Listenable.merge(
            [_bobAnimation, _pulseAnimation, _waveAnimation]),
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
          child: avatar,
        ),
      ),
    );
  }
}
