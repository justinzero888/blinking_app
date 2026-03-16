/// A rendered note card linking entries to a template and folder
class NoteCard {
  final String id;
  final List<String> entryIds;
  final String templateId;
  final String folderId;
  final String? renderedImagePath;
  final String? aiSummary;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NoteCard({
    required this.id,
    required this.entryIds,
    required this.templateId,
    required this.folderId,
    this.renderedImagePath,
    this.aiSummary,
    required this.createdAt,
    required this.updatedAt,
  });

  NoteCard copyWith({
    String? id,
    List<String>? entryIds,
    String? templateId,
    String? folderId,
    String? renderedImagePath,
    bool clearImagePath = false,
    String? aiSummary,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteCard(
      id: id ?? this.id,
      entryIds: entryIds ?? this.entryIds,
      templateId: templateId ?? this.templateId,
      folderId: folderId ?? this.folderId,
      renderedImagePath:
          clearImagePath ? null : (renderedImagePath ?? this.renderedImagePath),
      aiSummary: aiSummary ?? this.aiSummary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'entry_ids': entryIds,
        'template_id': templateId,
        'folder_id': folderId,
        'rendered_image_path': renderedImagePath,
        'ai_summary': aiSummary,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory NoteCard.fromJson(Map<String, dynamic> json) => NoteCard(
        id: json['id'] as String,
        entryIds: List<String>.from(json['entry_ids'] as List? ?? []),
        templateId: json['template_id'] as String,
        folderId: json['folder_id'] as String,
        renderedImagePath: json['rendered_image_path'] as String?,
        aiSummary: json['ai_summary'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}
