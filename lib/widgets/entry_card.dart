import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../models/entry.dart';
import '../models/tag.dart';
import '../providers/entry_provider.dart';
import '../providers/locale_provider.dart';
import 'tag_chip.dart';
import '../core/services/file_service.dart';
import '../l10n/app_localizations.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';

/// Card widget for displaying an entry in list view
class EntryCard extends StatelessWidget {
  final Entry entry;
  final List<String> tagNames;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final int? carriedOverCount;

  const EntryCard({
    super.key,
    required this.entry,
    this.tagNames = const [],
    this.onTap,
    this.onLongPress,
    this.carriedOverCount,
  });

  @override
  Widget build(BuildContext context) {
    final isList = entry.format == EntryFormat.list;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (carriedOverCount != null && carriedOverCount! > 0)
                _buildCarriedOverBanner(context),
              if (isList) ..._buildListContent(context) else ...[
                _buildHeader(context),
                if (entry.content.isNotEmpty) _buildContent(context),
              ],
              if (tagNames.isNotEmpty) _buildTags(),
              if (entry.mediaUrls.isNotEmpty) _buildMedia(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarriedOverBanner(BuildContext context) {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    final l = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Icon(Icons.replay, size: 14),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              l.carriedOverBanner(carriedOverCount!),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          GestureDetector(
            onTap: () {
              context.read<EntryProvider>().clearCarriedBanner();
            },
            child: const Icon(Icons.close, size: 14),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildListContent(BuildContext context) {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    final items = entry.listItems ?? [];
    final doneCount = items.where((i) => i.isDone).length;
    final totalCount = items.length;

    return [
      _buildListHeader(context),
      if (entry.content.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            entry.content,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ...items.map((item) => _buildListItem(context, item)),
      if (totalCount > 0)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${AppLocalizations.of(context)!.itemsDone(doneCount, totalCount)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ),
    ];
  }

  Widget _buildListHeader(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.checklist, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          DateFormat('HH:mm').format(entry.createdAt),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        const Spacer(),
        if (entry.emotion != null)
          Text(entry.emotion!, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 4),
        if (entry.tagIds.contains('tag_secrets'))
          const Icon(Icons.lock_outline, size: 14, color: Colors.grey),
        if (entry.tagIds.contains('tag_secrets'))
          const SizedBox(width: 4),
        GestureDetector(
          onTap: () {
            final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
            Share.share(entry.content, subject: isZh ? '来自 Blinking' : 'From Blinking');
          },
          child: const Icon(Icons.share, size: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildListItem(BuildContext context, ListItem item) {
    return InkWell(
      onTap: () {
        context.read<EntryProvider>().toggleListItem(entry.id, item.id);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(
              item.isDone ? Icons.check_box : Icons.check_box_outline_blank,
              size: 18,
              color: item.isDone ? Colors.grey : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.text,
                style: TextStyle(
                  decoration: item.isDone ? TextDecoration.lineThrough : null,
                  color: item.isDone ? Colors.grey : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        _buildTypeIcon(),
        const SizedBox(width: 8),
        Text(
          DateFormat('HH:mm').format(entry.createdAt),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
        ),
        const Spacer(),
        if (entry.emotion != null)
          Text(entry.emotion!, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 4),
        if (entry.tagIds.contains('tag_secrets'))
          const Icon(Icons.lock_outline, size: 14, color: Colors.grey),
        if (entry.tagIds.contains('tag_secrets'))
          const SizedBox(width: 4),
        GestureDetector(
          onTap: () {
            final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
            Share.share(entry.content, subject: isZh ? '来自 Blinking' : 'From Blinking');
          },
          child: const Icon(Icons.share, size: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildTypeIcon() {
    IconData icon;
    switch (entry.type) {
      case EntryType.routine:
        icon = Icons.check_circle_outline;
        break;
      case EntryType.freeform:
      default:
        icon = Icons.note;
    }
    return Icon(icon, size: 18, color: Colors.grey);
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        entry.content,
        style: Theme.of(context).textTheme.bodyMedium,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTags() {
    // Convert tag names to Tag objects for display
    final tags = tagNames.map((name) => Tag(
      id: name,
      name: name,
      nameEn: name,
      color: '#007AFF',
      category: 'custom',
      createdAt: DateTime.now(),
    )).toList();
    
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: tags.map((tag) => TagChip(tag: tag, small: true)).toList(),
    );
  }

  Widget _buildMedia() {
    final fileService = FileService();
    
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        height: 60,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: entry.mediaUrls.length,
          itemBuilder: (context, index) {
            final url = entry.mediaUrls[index];
            
            return FutureBuilder<String>(
              future: url.startsWith('/') ? Future.value(url) : fileService.getFullPath(url),
              builder: (context, snapshot) {
                final fullPath = snapshot.data;
                final bool isImage = url.toLowerCase().contains('.jpg') || 
                                   url.toLowerCase().contains('.jpeg') || 
                                   url.toLowerCase().contains('.png');

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () {
                        if (fullPath != null) {
                          OpenFilex.open(fullPath);
                        }
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: (fullPath != null && isImage && File(fullPath).existsSync())
                            ? Image.file(File(fullPath), fit: BoxFit.cover)
                            : Icon(_getMediaIcon(url)),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  IconData _getMediaIcon(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.mp4') || lower.contains('.mov')) return Icons.play_circle_outline;
    if (lower.contains('.aac') || lower.contains('.m4a') || lower.contains('.mp3')) return Icons.audiotrack;
    if (lower.contains('.jpg') || lower.contains('.jpeg') || lower.contains('.png')) return Icons.image;
    return Icons.insert_drive_file;
  }
}
