/// A card template defining visual style for note cards
class CardTemplate {
  final String id;
  final String name;
  final String icon;
  final String fontFamily; // 'default', 'serif', 'mono'
  final String fontColor;  // hex e.g. '#222222'
  final String bgColor;    // hex background color
  final bool isBuiltIn;
  final DateTime createdAt;

  const CardTemplate({
    required this.id,
    required this.name,
    required this.icon,
    this.fontFamily = 'default',
    required this.fontColor,
    required this.bgColor,
    this.isBuiltIn = false,
    required this.createdAt,
  });

  CardTemplate copyWith({
    String? id,
    String? name,
    String? icon,
    String? fontFamily,
    String? fontColor,
    String? bgColor,
    bool? isBuiltIn,
    DateTime? createdAt,
  }) {
    return CardTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      fontFamily: fontFamily ?? this.fontFamily,
      fontColor: fontColor ?? this.fontColor,
      bgColor: bgColor ?? this.bgColor,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'font_family': fontFamily,
        'font_color': fontColor,
        'bg_color': bgColor,
        'is_built_in': isBuiltIn ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory CardTemplate.fromJson(Map<String, dynamic> json) => CardTemplate(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String,
        fontFamily: json['font_family'] as String? ?? 'default',
        fontColor: json['font_color'] as String? ?? '#222222',
        bgColor: json['bg_color'] as String? ?? '#FFFFFF',
        isBuiltIn: (json['is_built_in'] as int? ?? 0) == 1,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
