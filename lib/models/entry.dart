/// Entry type enum
enum EntryType {
  routine,
  freeform,
}

/// Entry model - represents a memory entry (freeform or routine)
class Entry {
  final String id;
  final EntryType type;
  final String content;
  final List<String> tagIds;
  final List<String> mediaUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata; // For routine-specific data

  Entry({
    required this.id,
    required this.type,
    required this.content,
    this.tagIds = const [],
    this.mediaUrls = const [],
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  Entry copyWith({
    String? id,
    EntryType? type,
    String? content,
    List<String>? tagIds,
    List<String>? mediaUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Entry(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      tagIds: tagIds ?? this.tagIds,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'content': content,
      'tagIds': tagIds,
      'mediaUrls': mediaUrls,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory Entry.fromJson(Map<String, dynamic> json) {
    return Entry(
      id: json['id'] as String,
      type: EntryType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => EntryType.freeform,
      ),
      content: json['content'] as String,
      tagIds: List<String>.from(json['tagIds'] ?? []),
      mediaUrls: List<String>.from(json['mediaUrls'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}
