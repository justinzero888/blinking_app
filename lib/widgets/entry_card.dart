import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/entry.dart';
import '../models/tag.dart';
import 'tag_chip.dart';
import '../core/services/file_service.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';

/// Card widget for displaying an entry in list view
class EntryCard extends StatelessWidget {
  final Entry entry;
  final List<String> tagNames; // Tag names passed from provider
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const EntryCard({
    super.key,
    required this.entry,
    this.tagNames = const [],
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
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
              _buildHeader(context),
              if (entry.content.isNotEmpty) _buildContent(context),
              if (tagNames.isNotEmpty) _buildTags(),
              if (entry.mediaUrls.isNotEmpty) _buildMedia(),
            ],
          ),
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
