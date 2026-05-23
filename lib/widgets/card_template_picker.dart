import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/card_template.dart';
import '../providers/card_provider.dart';
import '../providers/locale_provider.dart';

/// Horizontal scrolling picker for Keepsake card templates.
/// Shows 8 built-in template thumbnails with locale-aware names.
class CardTemplatePicker extends StatefulWidget {
  final CardTemplate? selectedTemplate;
  final ValueChanged<CardTemplate> onTemplateSelected;

  const CardTemplatePicker({
    super.key,
    this.selectedTemplate,
    required this.onTemplateSelected,
  });

  @override
  State<CardTemplatePicker> createState() => _CardTemplatePickerState();
}

class _CardTemplatePickerState extends State<CardTemplatePicker> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final templates = context.watch<CardProvider>().templates;

    if (templates.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 110,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: templates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final tpl = templates[index];
          final isSelected = widget.selectedTemplate?.id == tpl.id;
          return _TemplateThumbnail(
            template: tpl,
            isSelected: isSelected,
            isZh: isZh,
            onTap: () => widget.onTemplateSelected(tpl),
          );
        },
      ),
    );
  }
}

class _TemplateThumbnail extends StatelessWidget {
  final CardTemplate template;
  final bool isSelected;
  final bool isZh;
  final VoidCallback onTap;

  const _TemplateThumbnail({
    required this.template,
    required this.isSelected,
    required this.isZh,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(template.bgColor);
    final fontColor = _parseColor(template.fontColor);
    final displayName = template.displayNameFor(isZh);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: fontColor, width: 2.5)
              : Border.all(color: Colors.grey.shade300),
          boxShadow: isSelected
              ? [BoxShadow(color: fontColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(template.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              displayName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: fontColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}
