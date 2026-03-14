/// Tag model - for categorizing entries
class Tag {
  final String id;
  final String name;
  final String nameEn; // English name
  final String color; // Hex color string (e.g., "#FF5500")
  final String category; // Custom category
  final DateTime createdAt;

  Tag({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.color,
    this.category = 'custom',
    required this.createdAt,
  });

  Tag copyWith({
    String? id,
    String? name,
    String? nameEn,
    String? color,
    String? category,
    DateTime? createdAt,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      color: color ?? this.color,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameEn': nameEn,
      'color': color,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as String,
      name: json['name'] as String,
      nameEn: json['nameEn'] as String,
      color: json['color'] as String,
      category: json['category'] as String? ?? 'custom',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Default tags for new users
class DefaultTags {
  static List<Tag> get defaults => [
    Tag(id: 'tag_health', name: '健康', nameEn: 'Health', color: '#4CAF50', category: 'health', createdAt: DateTime.now()),
    Tag(id: 'tag_work', name: '工作', nameEn: 'Work', color: '#2196F3', category: 'work', createdAt: DateTime.now()),
    Tag(id: 'tag_learning', name: '学习', nameEn: 'Learning', color: '#9C27B0', category: 'learning', createdAt: DateTime.now()),
    Tag(id: 'tag_family', name: '家庭', nameEn: 'Family', color: '#FF9800', category: 'family', createdAt: DateTime.now()),
    Tag(id: 'tag_life', name: '生活', nameEn: 'Life', color: '#E91E63', category: 'life', createdAt: DateTime.now()),
    Tag(id: 'tag_finance', name: '财务', nameEn: 'Finance', color: '#607D8B', category: 'finance', createdAt: DateTime.now()),
    Tag(id: 'tag_social', name: '社交', nameEn: 'Social', color: '#00BCD4', category: 'social', createdAt: DateTime.now()),
    Tag(id: 'tag_hobby', name: '爱好', nameEn: 'Hobby', color: '#795548', category: 'hobby', createdAt: DateTime.now()),
  ];
}
