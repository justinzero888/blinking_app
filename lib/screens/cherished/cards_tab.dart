import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/entry.dart';
import '../../models/note_card.dart';
import '../../models/card_template.dart';
import '../../providers/card_provider.dart';
import '../../providers/entry_provider.dart';
import '../../providers/locale_provider.dart';
import 'card_builder_dialog.dart';
import 'card_editor_screen.dart';

/// 卡片 tab — folder chips + card grid + FAB to build new cards
class CardsTab extends StatefulWidget {
  const CardsTab({super.key});

  @override
  State<CardsTab> createState() => _CardsTabState();
}

class _CardsTabState extends State<CardsTab> {
  String? _selectedFolderId;

  @override
  Widget build(BuildContext context) {
    final cardProvider = context.watch<CardProvider>();
    final folders = cardProvider.folders;
    final allCards = cardProvider.cards;
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';

    final displayCards = _selectedFolderId == null
        ? allCards
        : allCards.where((c) => c.folderId == _selectedFolderId).toList();

    return Scaffold(
      body: Column(
        children: [
          if (folders.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _FolderChip(
                    label: isZh ? '全部' : 'All',
                    icon: '📋',
                    isSelected: _selectedFolderId == null,
                    onTap: () => setState(() => _selectedFolderId = null),
                  ),
                  const SizedBox(width: 8),
                  ...folders.map((f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FolderChip(
                          label: f.name,
                          icon: f.icon,
                          isSelected: _selectedFolderId == f.id,
                          onTap: () =>
                              setState(() => _selectedFolderId = f.id),
                        ),
                      )),
                ],
              ),
            ),
          Expanded(
            child: displayCards.isEmpty
                ? _buildEmptyState(context)
                : _buildCardGrid(context, displayCards, cardProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCardBuilder(context),
        icon: const Icon(Icons.add),
        label: Text(isZh ? '制作卡片' : 'New Card'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎴', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(isZh ? '还没有卡片' : 'No cards yet',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
              isZh
                  ? '点击下方按钮，将记录制作成精美卡片'
                  : 'Tap the button below to create a card from your entries',
              style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCardGrid(
      BuildContext context, List<NoteCard> cards, CardProvider cardProvider) {
    final entryProvider = context.read<EntryProvider>();

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        final template = cardProvider.getTemplateById(card.templateId);
        final entries = card.entryIds
            .map((id) {
              try {
                return entryProvider.allEntries.firstWhere((e) => e.id == id);
              } catch (_) {
                return null;
              }
            })
            .where((e) => e != null)
            .cast<dynamic>()
            .toList();

        return _CardTile(
          card: card,
          template: template,
          entries: entries,
          onDelete: () => _confirmDelete(context, card, cardProvider),
          onEdit: () => _openCardEditor(context, card),
          onShare: () => _shareCard(card),
          onTap: () => _openCardViewer(context, card, template, entries),
        );
      },
    );
  }

  void _openCardViewer(BuildContext context, NoteCard card,
      CardTemplate? template, List<dynamic> entries) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CardEditorScreen(
          card: card,
          template: template,
          entries: entries.cast<Entry>(),
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void _openCardBuilder(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CardBuilderDialog(),
        fullscreenDialog: true,
      ),
    );
  }

  void _openCardEditor(BuildContext context, NoteCard card) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CardBuilderDialog(existingCard: card),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _shareCard(NoteCard card) async {
    final content = card.aiSummary ?? '';
    final shareText = content.isNotEmpty
        ? '$content\n\n— 来自 Blinking ✨'
        : '来自 Blinking ✨';

    if (card.renderedImagePath != null &&
        File(card.renderedImagePath!).existsSync()) {
      await Share.shareXFiles(
        [XFile(card.renderedImagePath!)],
        text: shareText,
      );
    } else {
      await Share.share(shareText);
    }
  }

  void _confirmDelete(
      BuildContext context, NoteCard card, CardProvider cardProvider) {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isZh ? '删除卡片' : 'Delete Card'),
        content: Text(isZh ? '确定要删除这张卡片吗？' : 'Delete this card?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isZh ? '取消' : 'Cancel')),
          TextButton(
            onPressed: () {
              cardProvider.deleteCard(card.id);
              Navigator.pop(ctx);
            },
            child: Text(isZh ? '删除' : 'Delete',
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _FolderChip extends StatelessWidget {
  final String label;
  final String icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FolderChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
    );
  }
}

class _CardTile extends StatelessWidget {
  final NoteCard card;
  final CardTemplate? template;
  final List<dynamic> entries;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onShare;
  final VoidCallback onTap;

  const _CardTile({
    required this.card,
    required this.template,
    required this.entries,
    required this.onDelete,
    required this.onEdit,
    required this.onShare,
    required this.onTap,
  });

  Color _hexToColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(cleaned, radix: 16) ?? 0xFFFFFF;
    return Color(0xFF000000 | value);
  }

  void _showMenu(BuildContext context) {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(isZh ? '编辑' : 'Edit'),
              onTap: () {
                Navigator.pop(context);
                onEdit();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: Text(isZh ? '分享' : 'Share'),
              onTap: () {
                Navigator.pop(context);
                onShare();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(isZh ? '删除' : 'Delete',
                  style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (card.renderedImagePath != null) {
      final file = File(card.renderedImagePath!);
      if (file.existsSync()) {
        return GestureDetector(
          onTap: onTap,
          onLongPress: () => _showMenu(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(file, fit: BoxFit.cover),
          ),
        );
      }
    }

    if (template != null) {
      final bgColor = _hexToColor(template!.bgColor);
      final fontColor = _hexToColor(template!.fontColor);
      final firstEntry = entries.isNotEmpty ? entries.first : null;
      final displayText = card.aiSummary ??
          (firstEntry?.content as String? ?? '');

      Widget background;
      if (template!.customImagePath != null &&
          File(template!.customImagePath!).existsSync()) {
        background = Image.file(File(template!.customImagePath!),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity);
      } else {
        background = Container(
            decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8)));
      }

      return GestureDetector(
        onTap: onTap,
        onLongPress: () => _showMenu(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              background,
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (firstEntry?.emotion != null)
                      Text(firstEntry!.emotion as String,
                          style: const TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(
                        displayText,
                        style: TextStyle(
                            color: fontColor, fontSize: 10, height: 1.4),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('Blinking ✨',
                        style: TextStyle(
                            color: fontColor.withValues(alpha: 0.5),
                            fontSize: 9)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showMenu(context),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
        child: const Center(child: Text('🎴')),
      ),
    );
  }
}

