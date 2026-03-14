import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../providers/entry_provider.dart';
import '../providers/tag_provider.dart';
import '../models/entry.dart';
import '../models/media.dart';
import '../core/services/file_service.dart';
import '../core/config/emotions.dart';
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
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FileService _fileService = FileService();
  
  final List<Media> _mediaItems = [];
  final Set<String> _selectedTagIds = {};
  bool _isRecording = false;
  String? _audioPath;
  bool _recorderInitialized = false;
  String? _selectedEmotion;

  @override
  void initState() {
    super.initState();
    _initRecorder();
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

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      return;
    }
    
    await _recorder.openRecorder();
    setState(() {
      _recorderInitialized = true;
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _recorder.closeRecorder();
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

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      final media = Media(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        entryId: '',
        type: MediaType.video,
        localPath: video.path,
      );
      setState(() {
        _mediaItems.add(media);
      });
    }
  }

  Future<void> _recordVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
    if (video != null) {
      final media = Media(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        entryId: '',
        type: MediaType.video,
        localPath: video.path,
      );
      setState(() {
        _mediaItems.add(media);
      });
    }
  }

  Future<void> _toggleRecording() async {
    if (!_recorderInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission not granted')),
      );
      return;
    }

    if (_isRecording) {
      // Stop recording
      final path = await _recorder.stopRecorder();
      if (path != null) {
        final media = Media(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          entryId: '',
          type: MediaType.audio,
          localPath: path,
        );
        setState(() {
          _mediaItems.add(media);
          _isRecording = false;
        });
      }
    } else {
      // Start recording
      final tempDir = Directory.systemTemp;
      final path = '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';
      await _recorder.startRecorder(toFile: path);
      setState(() {
        _isRecording = true;
        _audioPath = path;
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

  Future<void> _saveEntry() async {
    if (_textController.text.trim().isEmpty && _mediaItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some content')),
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
        SnackBar(content: Text(widget.existingEntry != null ? 'Memory updated!' : 'Memory saved!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingEntry != null ? 'Edit Memory' : 'Add Memory'),
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
              decoration: const InputDecoration(
                hintText: 'What\'s on your mind?',
                border: OutlineInputBorder(),
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
                  label: 'Photo',
                  onPressed: _pickImage,
                ),
                _MediaButton(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onPressed: _takePhoto,
                ),
                _MediaButton(
                  icon: Icons.video_library,
                  label: 'Video',
                  onPressed: _pickVideo,
                ),
                _MediaButton(
                  icon: Icons.videocam,
                  label: 'Record',
                  onPressed: _recordVideo,
                ),
                _MediaButton(
                  icon: _isRecording ? Icons.stop : Icons.mic,
                  label: _isRecording ? 'Stop' : 'Audio',
                  onPressed: _toggleRecording,
                  color: _isRecording ? Colors.red : null,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Media preview
            if (_mediaItems.isNotEmpty) ...[
              const Text(
                'Media',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
            const Text(
              '心情',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                  return GestureDetector(
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
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Tags
            const Text(
              'Tags',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
  final Color? color;

  const _MediaButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: color),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: color,
      ),
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
