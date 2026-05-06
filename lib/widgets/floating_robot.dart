import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ai_persona_provider.dart';
import '../providers/llm_config_notifier.dart';
import '../core/services/entitlement_service.dart';
import '../screens/assistant/assistant_screen.dart';
import '../screens/purchase/paywall_screen.dart';

class FloatingRobotWidget extends StatefulWidget {
  final int currentTabIndex;
  final void Function(int tabIndex)? onSwitchTab;

  const FloatingRobotWidget({
    super.key,
    required this.currentTabIndex,
    this.onSwitchTab,
  });

  @override
  State<FloatingRobotWidget> createState() => _FloatingRobotWidgetState();
}

class _FloatingRobotWidgetState extends State<FloatingRobotWidget>
    with TickerProviderStateMixin {
  late final AnimationController _bobController;
  late final Animation<double> _bobAnimation;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final AnimationController _waveController;
  late final Animation<double> _waveAnimation;

  LlmConfigNotifier? _llmNotifier;

  @override
  void initState() {
    super.initState();
    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);

    _bobAnimation = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _bobController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final notifier = context.read<LlmConfigNotifier>();
    if (_llmNotifier != notifier) {
      _llmNotifier?.removeListener(_onConfigChanged);
      _llmNotifier = notifier;
      _llmNotifier!.addListener(_onConfigChanged);
    }
  }

  void _onConfigChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _llmNotifier?.removeListener(_onConfigChanged);
    _bobController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _onTap() {
    final entitlement = context.read<EntitlementService>();
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final visual = entitlement.buttonVisual;

    switch (visual) {
      case AIButtonVisual.active:
        _waveController.forward(from: 0);
        Navigator.push(
          context,
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => const AssistantScreen(),
          ),
        );
        break;
      case AIButtonVisual.dormant:
        if (entitlement.isRestricted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PaywallScreen()),
          );
        } else {
          final message = isZh
              ? '今日 AI 配额已用完。明天会刷新。'
              : "You've used today's AI quota. It refreshes tomorrow.";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
          );
        }
        break;
      case AIButtonVisual.dormantWarn:
        final message = isZh
            ? '你的 API Key 需要更新。点击前往设置。'
            : 'Your API key needs attention. Tap to go to Settings.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
        );
        widget.onSwitchTab?.call(4);
        break;
      case AIButtonVisual.hidden:
      case AIButtonVisual.pulsing:
        break;
    }
  }

  void _onLongPress() {
    final entitlement = context.read<EntitlementService>();
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx - 180,
        position.dy - 120,
        position.dx + size.width,
        position.dy,
      ),
      items: [
        PopupMenuItem(
          enabled: false,
          height: 24,
          child: Text(
            isZh ? 'AI 助手' : 'AI assistant',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        PopupMenuItem(
          enabled: false,
          height: 20,
          child: Text(
            '${isZh ? "来源" : "Source"}: ${entitlement.aiSourceLabel}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        if (entitlement.remainingAI > 0)
          PopupMenuItem(
            enabled: false,
            height: 20,
            child: Text(
              '${isZh ? "剩余" : "Remaining"}: ${entitlement.remainingAI}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        if (entitlement.isPreviewActive)
          PopupMenuItem(
            enabled: false,
            height: 20,
            child: Text(
              isZh
                  ? '预览剩余 ${entitlement.previewDaysRemaining} 天'
                  : 'Preview: ${entitlement.previewDaysRemaining} days left',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        if (entitlement.currentState == EntitlementState.restricted &&
            !entitlement.hasActiveBYOK)
          PopupMenuItem(
            height: 36,
            child: Text(
              isZh ? '获取 Pro' : 'Get Pro',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600),
            ),
          ),
        if (!entitlement.hasActiveBYOK)
          PopupMenuItem(
            height: 36,
            child: Text(
              isZh ? '使用自己的 Key' : 'Use my own key',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            onTap: () {
              widget.onSwitchTab?.call(4);
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentTabIndex >= 4) return const SizedBox.shrink();

    final entitlement = context.watch<EntitlementService>();
    final visual = entitlement.buttonVisual;
    final canUse = entitlement.canUseAI && visual == AIButtonVisual.active;

    final avatarPath = context.read<AiPersonaProvider>().avatarPath;
    final avatarFile = avatarPath != null ? File(avatarPath) : null;
    final hasAvatar = avatarFile != null && avatarFile.existsSync();

    Widget avatar = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: canUse
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
          : Center(
              child: Text(
                '🤖',
                style: TextStyle(
                    fontSize: 28,
                    color: canUse ? null : Colors.grey[500]),
              ),
            ),
    );

    final showBadge = !canUse &&
        visual != AIButtonVisual.hidden &&
        visual != AIButtonVisual.pulsing;

    final opacity = canUse ? 1.0 : 0.55;
    final animate = canUse;

    Widget robotWidget = GestureDetector(
      onTap: _onTap,
      onLongPress: _onLongPress,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          if (showBadge)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: visual == AIButtonVisual.dormantWarn
                      ? Colors.amber
                      : entitlement.isPreviewActive
                          ? Theme.of(context).colorScheme.primary
                          : Colors.orange,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    visual == AIButtonVisual.dormantWarn ? '⚠' : '!',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return Positioned(
      right: 16,
      bottom: 90,
      child: Opacity(
        opacity: opacity,
        child: animate
            ? AnimatedBuilder(
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
                child: robotWidget,
              )
            : robotWidget,
      ),
    );
  }
}
