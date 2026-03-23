import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/entry_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/tag_provider.dart';
import '../models/entry.dart';
import '../models/media.dart';
import '../core/services/file_service.dart';
import '../core/config/emotions.dart';
import '../l10n/app_localizations.dart';
import 'package:open_filex/open_filex.dart';

class AddEntryScreen extends StatefulWidget {
  final Entry? existingEntry;
  const AddEntryScreen({Key? key, this.existingEntry}) : super(key: key);

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final FileService _fileService = FileService();

  final List<Media> _mediaItems = [];
  final Set<String> _selectedTagIds = {};
  String? _selectedEmotion;

  @override
  void initState() {
    super.initState();
    _loadExistingEntry();
  }

  Future<void> _loadExistingEntry() async {
    if (widget.existingEntry != null) {
      _textController.text = widget.existingEntry!.content;
      _selectedTagIds.addAll(widget.existingEntry!.tagIds);
      if (widget.existingEntry!.emotion != null) {
        setState(() => _selectedEmotion = widget.existingEntry!.emotion);
      }
      for (final url in widget.existingEntry!.mediaUrls) {
        // Resolve full path for display if it's a relative path
        String displayPath = url;
        if (!url.startsWith('/')) {
           displayPath = await _fileService.getFullPath(url);
        }
        
        setState(() {
          _mediaItems.add(Media(
            id: DateTime.now().millisecondsSinceEpoch.toString() + url,
            entryId: widget.existingEntry!.id,
            type: _getMediaTypeFromUrl(url),
            localPath: displayPath,
          ));
        });
      }
    }
  }

  MediaType _getMediaTypeFromUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.mp4') || lower.contains('.mov')) return MediaType.video;
    if (lower.contains('.aac') || lower.contains('.m4a') || lower.contains('.mp3')) return MediaType.audio;
    return MediaType.image;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final media = Media(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        entryId: '',
        type: MediaType.image,
        localPath: image.path,
      );
      setState(() {
        _mediaItems.add(media);
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      final media = Media(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        entryId: '',
        type: MediaType.image,
        localPath: photo.path,
      );
      setState(() {
        _mediaItems.add(media);
      });
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _mediaItems.removeAt(index);
    });
  }

  void _toggleTag(String tagId) {
    setState(() {
      if (_selectedTagIds.contains(tagId)) {
        _selectedTagIds.remove(tagId);
      } else {
        _selectedTagIds.add(tagId);
      }
    });
  }

  String _moodLabel(BuildContext context, String emoji) {
    final l = AppLocalizations.of(context)!;
    switch (emoji) {
      case '😊': return l.moodHappy;
      case '😢': return l.moodSad;
      case '😡': return l.moodAngry;
      case '😰': return l.moodAnxious;
      case '😴': return l.moodTired;
      case '🤩': return l.moodExcited;
      case '😌': return l.moodCalm;
      case '😤': return l.moodFrustrated;
      case '🥰': return l.moodLoving;
      case '😐': return l.moodNeutral;
      default: return emoji;
    }
  }

  Future<void> _saveEntry() async {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    if (_textController.text.trim().isEmpty && _mediaItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                isZh ? '请添加一些内容' : 'Please add some content')),
      );
      return;
    }

    final entryProvider = context.read<EntryProvider>();
    
    // 1. Persist all media files to internal storage
    final List<String> persistentMediaUrls = [];
    for (final media in _mediaItems) {
      if (media.localPath == null) continue;
      
      // If it's already a relative path (starting with 'media/'), it's already persisted
      if (media.localPath!.startsWith('media/')) {
        persistentMediaUrls.add(media.localPath!);
      } else {
        // Copy to internal storage
        try {
          final relativePath = await _fileService.saveFile(media.localPath!);
          persistentMediaUrls.add(relativePath);
        } catch (e) {
          debugPrint('Error persisting file: $e');
          // Fallback to original path if copy fails (though this is risky)
          persistentMediaUrls.add(media.localPath!);
        }
      }
    }

    if (widget.existingEntry != null) {
      await entryProvider.updateEntry(
        widget.existingEntry!.copyWith(
          content: _textController.text.trim(),
          tagIds: _selectedTagIds.toList(),
          mediaUrls: persistentMediaUrls,
          updatedAt: DateTime.now(),
          emotion: _selectedEmotion,
          clearEmotion: _selectedEmotion == null,
        ),
      );
    } else {
      await entryProvider.addEntry(
        type: EntryType.freeform,
        content: _textController.text.trim(),
        tagIds: _selectedTagIds.toList(),
        mediaUrls: persistentMediaUrls,
        emotion: _selectedEmotion,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.existingEntry != null
                ? (isZh ? '记录已更新！' : 'Memory updated!')
                : (isZh ? '记录已保存！' : 'Memory saved!'))),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingEntry != null
            ? (isZh ? '编辑记录' : 'Edit Memory')
            : (isZh ? '添加记录' : 'Add Memory')),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, size: 28),
            onPressed: _saveEntry,
            tooltip: 'Save',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text input
            TextField(
              controller: _textController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: isZh ? '今天有什么想记录的？' : 'What\'s on your mind?',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Media buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MediaButton(
                  icon: Icons.photo_library,
                  label: isZh ? '相册' : 'Photo',
                  onPressed: _pickImage,
                ),
                _MediaButton(
                  icon: Icons.camera_alt,
                  label: isZh ? '拍照' : 'Camera',
                  onPressed: _takePhoto,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Media preview
            if (_mediaItems.isNotEmpty) ...[
              Text(
                isZh ? '媒体' : 'Media',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _mediaItems.length,
                  itemBuilder: (context, index) {
                    final media = _mediaItems[index];
                    return _MediaPreview(
                      media: media,
                      onRemove: () => _removeMedia(index),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Emotion picker
            Text(
              isZh ? '心情' : 'Mood',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: kDefaultEmotions.length,
                itemBuilder: (context, index) {
                  final emoji = kDefaultEmotions[index];
                  final isSelected = _selectedEmotion == emoji;
                  final label = _moodLabel(context, emoji);
                  return Semantics(
                    label: label,
                    button: true,
                    selected: isSelected,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedEmotion = isSelected ? null : emoji;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected
                              ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                              : null,
                        ),
                        child: Text(emoji, style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Show label only when an emotion is selected
            if (_selectedEmotion != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '$_selectedEmotion  ${_moodLabel(context, _selectedEmotion!)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Tags
            Text(
              isZh ? '标签' : 'Tags',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Consumer<TagProvider>(
              builder: (context, tagProvider, child) {
                final tags = tagProvider.tags;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.map((tag) {
                    final isSelected = _selectedTagIds.contains(tag.id);
                    final colorValue = int.parse(tag.color.substring(1), radix: 16) + 0xFF000000;
                    return FilterChip(
                      label: Text(tag.name),
                      selected: isSelected,
                      onSelected: (_) => _toggleTag(tag.id),
                      backgroundColor: Color(colorValue).withValues(alpha: 0.2),
                      selectedColor: Color(colorValue),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _MediaButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _MediaPreview extends StatelessWidget {
  final Media media;
  final VoidCallback onRemove;

  const _MediaPreview({
    required this.media,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {
              if (media.localPath != null) {
                OpenFilex.open(media.localPath!);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildPreview(),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (media.localPath == null) {
      return Container(
        width: 100,
        height: 100,
        color: Colors.grey,
        child: const Icon(Icons.error),
      );
    }
    
    switch (media.type) {
      case MediaType.image:
        return Image.file(
          File(media.localPath!),
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        );
      case MediaType.video:
        return Container(
          width: 100,
          height: 100,
          color: Colors.black12,
          child: const Icon(Icons.play_circle_outline, size: 40),
        );
      case MediaType.audio:
        return Container(
          width: 100,
          height: 100,
          color: Colors.black12,
          child: const Icon(Icons.audiotrack, size: 40),
        );
      case MediaType.text:
        return Container(
          width: 100,
          height: 100,
          color: Colors.black12,
          child: const Icon(Icons.text_fields, size: 40),
        );
    }
  }
}
