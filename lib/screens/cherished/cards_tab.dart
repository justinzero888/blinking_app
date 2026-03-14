import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/note_card.dart';
import '../../providers/card_provider.dart';
import '../../providers/entry_provider.dart';
import 'card_builder_dialog.dart';

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

    // Filter cards by selected folder
    final displayCards = _selectedFolderId == null
        ? allCards
        : allCards
            .where((c) => c.folderId == _selectedFolderId)
            .toList();

    return Scaffold(
      body: Column(
        children: [
          // Folder chips
          if (folders.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _FolderChip(
                    label: '全部',
                    icon: '📋',
                    isSelected: _selectedFolderId == null,
                    onTap: () => setState(() => _selectedFolderId = null),
                  ),
                  const SizedBox(width: 8),
                  ...folders.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FolderChip(
                        label: f.name,
                        icon: f.icon,
                        isSelected: _selectedFolderId == f.id,
                        onTap: () =>
                            setState(() => _selectedFolderId = f.id),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Cards grid
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
        label: const Text('制作卡片'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎴', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            '还没有卡片',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            '点击下方按钮，将记录制作成精美卡片',
            style: TextStyle(color: Colors.grey),
          ),
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
                return entryProvider.allEntries
                    .firstWhere((e) => e.id == id);
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
        );
      },
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

  void _confirmDelete(
      BuildContext context, NoteCard card, CardProvider cardProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除卡片'),
        content: const Text('确定要删除这张卡片吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              cardProvider.deleteCard(card.id);
              Navigator.pop(ctx);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
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
  final dynamic template; // CardTemplate?
  final List<dynamic> entries;
  final VoidCallback onDelete;

  const _CardTile({
    required this.card,
    required this.template,
    required this.entries,
    required this.onDelete,
  });

  Color _hexToColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(cleaned, radix: 16) ?? 0xFFFFFF;
    return Color(0xFF000000 | value);
  }

  @override
  Widget build(BuildContext context) {
    // If there's a rendered image, show it
    if (card.renderedImagePath != null) {
      final file = File(card.renderedImagePath!);
      if (file.existsSync()) {
        return GestureDetector(
          onLongPress: onDelete,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(file, fit: BoxFit.cover),
          ),
        );
      }
    }

    // Fallback: render widget directly
    if (template != null) {
      final bgColor = _hexToColor(template.bgColor as String);
      final fontColor = _hexToColor(template.fontColor as String);
      final firstEntry = entries.isNotEmpty ? entries.first : null;

      return GestureDetector(
        onLongPress: onDelete,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (firstEntry?.emotion != null)
                Text(firstEntry!.emotion,
                    style: const TextStyle(fontSize: 16)),
              Expanded(
                child: Text(
                  firstEntry?.content ?? '',
                  style: TextStyle(
                      color: fontColor, fontSize: 10, height: 1.4),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'Blinking ✨',
                style: TextStyle(
                    color: fontColor.withValues(alpha: 0.5), fontSize: 9),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onLongPress: onDelete,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: Text('🎴')),
      ),
    );
  }
}
