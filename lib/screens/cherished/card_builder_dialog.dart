import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/entry.dart';
import '../../models/card_template.dart';
import '../../models/card_folder.dart';
import '../../providers/card_provider.dart';
import '../../providers/entry_provider.dart';
import '../../widgets/card_renderer.dart';

/// Full-screen dialog for creating a note card from entries
class CardBuilderDialog extends StatefulWidget {
  final Entry? initialEntry;

  const CardBuilderDialog({super.key, this.initialEntry});

  @override
  State<CardBuilderDialog> createState() => _CardBuilderDialogState();
}

class _CardBuilderDialogState extends State<CardBuilderDialog> {
  final List<Entry> _selectedEntries = [];
  CardTemplate? _selectedTemplate;
  CardFolder? _selectedFolder;
  bool _building = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialEntry != null) {
      _selectedEntries.add(widget.initialEntry!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cardProvider = context.read<CardProvider>();
      if (cardProvider.templates.isNotEmpty) {
        setState(() => _selectedTemplate = cardProvider.templates.first);
      }
      if (cardProvider.folders.isNotEmpty) {
        setState(() => _selectedFolder = cardProvider.folders.first);
      }
    });
  }

  Color _hexToColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(cleaned, radix: 16) ?? 0xFFFFFF;
    return Color(0xFF000000 | value);
  }

  @override
  Widget build(BuildContext context) {
    final cardProvider = context.watch<CardProvider>();
    final entryProvider = context.watch<EntryProvider>();
    final templates = cardProvider.templates;
    final folders = cardProvider.folders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('制作记忆卡片'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Selected entries section
          Text('已选记录 (${_selectedEntries.length})',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._selectedEntries.map(
            (entry) => Card(
              child: ListTile(
                leading: Text(entry.emotion ?? '📝'),
                title: Text(
                  entry.content.length > 50
                      ? '${entry.content.substring(0, 50)}...'
                      : entry.content,
                  style: const TextStyle(fontSize: 13),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      color: Colors.red, size: 20),
                  onPressed: () =>
                      setState(() => _selectedEntries.remove(entry)),
                ),
              ),
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('添加更多笔记'),
            onPressed: () => _showEntryPicker(entryProvider),
          ),
          const Divider(height: 24),

          // Template picker
          const Text('选择模板', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: templates.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final tpl = templates[index];
                final isSelected = _selectedTemplate?.id == tpl.id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTemplate = tpl),
                  child: Container(
                    width: 80,
                    decoration: BoxDecoration(
                      color: _hexToColor(tpl.bgColor),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(tpl.icon, style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(
                          tpl.name,
                          style: TextStyle(
                            fontSize: 10,
                            color: _hexToColor(tpl.fontColor),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Folder picker
          const Text('选择文件夹', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (folders.isNotEmpty)
            DropdownButtonFormField<CardFolder>(
              value: _selectedFolder,
              items: folders
                  .map((f) => DropdownMenuItem(
                        value: f,
                        child: Row(
                          children: [
                            Text(f.icon),
                            const SizedBox(width: 8),
                            Text(f.name),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedFolder = val),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          const SizedBox(height: 24),

          // Preview
          if (_selectedTemplate != null && _selectedEntries.isNotEmpty) ...[
            const Text('预览', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Center(
              child: _CardPreview(
                template: _selectedTemplate!,
                entries: _selectedEntries,
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Generate button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canBuild() ? (_building ? null : _buildCard) : null,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              child: _building
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('生成卡片', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  bool _canBuild() =>
      _selectedEntries.isNotEmpty &&
      _selectedTemplate != null &&
      _selectedFolder != null;

  void _showEntryPicker(EntryProvider entryProvider) {
    final available = entryProvider.allEntries
        .where((e) => !_selectedEntries.any((s) => s.id == e.id))
        .toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有更多可添加的记录')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('选择笔记'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: available.length,
            itemBuilder: (context, index) {
              final entry = available[index];
              return ListTile(
                leading: Text(entry.emotion ?? '📝'),
                title: Text(
                  entry.content.length > 40
                      ? '${entry.content.substring(0, 40)}...'
                      : entry.content,
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: Text(
                  '${entry.createdAt.year}/${entry.createdAt.month}/${entry.createdAt.day}',
                  style: const TextStyle(fontSize: 11),
                ),
                onTap: () {
                  setState(() => _selectedEntries.add(entry));
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  Future<void> _buildCard() async {
    if (!_canBuild()) return;
    setState(() => _building = true);

    try {
      final cardProvider = context.read<CardProvider>();

      // Add the card
      final card = await cardProvider.addCard(
        entryIds: _selectedEntries.map((e) => e.id).toList(),
        templateId: _selectedTemplate!.id,
        folderId: _selectedFolder!.id,
      );

      // Try to render to image in background
      try {
        final imagePath = await CardRenderer.renderToImage(
          card: card,
          template: _selectedTemplate!,
          entries: _selectedEntries,
        );
        debugPrint('Card image saved: $imagePath');
      } catch (e) {
        debugPrint('Card image render failed (non-fatal): $e');
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('卡片已生成！')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _building = false);
    }
  }
}

/// A lightweight preview widget that renders the card style without NoteCard model
class _CardPreview extends StatelessWidget {
  final CardTemplate template;
  final List<Entry> entries;

  const _CardPreview({required this.template, required this.entries});

  Color _hexToColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(cleaned, radix: 16) ?? 0xFFFFFF;
    return Color(0xFF000000 | value);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _hexToColor(template.bgColor);
    final fontColor = _hexToColor(template.fontColor);
    final firstEntry = entries.isNotEmpty ? entries.first : null;

    return Container(
      width: 280,
      height: 175,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (firstEntry?.emotion != null)
            Text(firstEntry!.emotion!, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              firstEntry?.content ?? '',
              style: TextStyle(color: fontColor, fontSize: 13, height: 1.5),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                firstEntry != null
                    ? '${firstEntry.createdAt.year}/${firstEntry.createdAt.month}/${firstEntry.createdAt.day}'
                    : '',
                style: TextStyle(
                    color: fontColor.withValues(alpha: 0.6), fontSize: 10),
              ),
              Text(
                'Blinking ✨',
                style: TextStyle(
                    color: fontColor.withValues(alpha: 0.5), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
