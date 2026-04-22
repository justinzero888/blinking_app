import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/file_service.dart';
import '../../models/entry.dart';
import '../../providers/locale_provider.dart';
import '../../providers/tag_provider.dart';
import '../../widgets/tag_chip.dart';
import '../add_entry_screen.dart';

class EntryDetailScreen extends StatelessWidget {
  final Entry entry;

  const EntryDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final tagProvider = context.watch<TagProvider>();
    final tags = tagProvider.tags.where((t) => entry.tagIds.contains(t.id)).toList();

    final dateStr = isZh
        ? DateFormat('yyyy年M月d日 HH:mm').format(entry.createdAt)
        : DateFormat('MMM d, y  HH:mm').format(entry.createdAt);

    return Scaffold(
      appBar: AppBar(
        title: Text(dateStr),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: isZh ? '编辑' : 'Edit',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEntryScreen(existingEntry: entry),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: isZh ? '分享' : 'Share',
            onPressed: () => Share.share(
              entry.content,
              subject: isZh ? '来自 Blinking' : 'From Blinking',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.emotion != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(entry.emotion!, style: const TextStyle(fontSize: 32)),
              ),
            SelectableText(
              entry.content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: tags.map((t) => TagChip(tag: t, small: true)).toList(),
              ),
            ],
            if (entry.mediaUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              _MediaGrid(mediaUrls: entry.mediaUrls),
            ],
          ],
        ),
      ),
    );
  }
}

class _MediaGrid extends StatelessWidget {
  final List<String> mediaUrls;
  const _MediaGrid({required this.mediaUrls});

  @override
  Widget build(BuildContext context) {
    final fileService = FileService();
    return Column(
      children: mediaUrls.map((url) {
        final isImage = url.toLowerCase().endsWith('.jpg') ||
            url.toLowerCase().endsWith('.jpeg') ||
            url.toLowerCase().endsWith('.png');
        return FutureBuilder<String>(
          future: url.startsWith('/') ? Future.value(url) : fileService.getFullPath(url),
          builder: (context, snapshot) {
            final fullPath = snapshot.data;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: fullPath != null ? () => OpenFilex.open(fullPath) : null,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: (fullPath != null && isImage && File(fullPath).existsSync())
                      ? Image.file(File(fullPath), fit: BoxFit.contain, width: double.infinity)
                      : Container(
                          height: 120,
                          color: Colors.grey[300],
                          child: const Icon(Icons.insert_drive_file, size: 48),
                        ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}
