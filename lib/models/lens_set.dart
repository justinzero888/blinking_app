class LensSet {
  final String id;
  final String label;
  final String lens1;
  final String lens2;
  final String lens3;
  final bool isBuiltin;
  final int sortOrder;
  final DateTime createdAt;

  LensSet({
    required this.id,
    required this.label,
    required this.lens1,
    required this.lens2,
    required this.lens3,
    this.isBuiltin = false,
    this.sortOrder = 0,
    required this.createdAt,
  });

  List<String> get lenses => [lens1, lens2, lens3];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'lens_1': lens1,
      'lens_2': lens2,
      'lens_3': lens3,
      'is_builtin': isBuiltin ? 1 : 0,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory LensSet.fromJson(Map<String, dynamic> json) {
    return LensSet(
      id: json['id'] as String,
      label: json['label'] as String,
      lens1: json['lens_1'] as String,
      lens2: json['lens_2'] as String,
      lens3: json['lens_3'] as String,
      isBuiltin: (json['is_builtin'] as int? ?? 0) == 1,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt:
          DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}

class DefaultLensSets {
  static List<LensSet> defaults(bool isZh) => [
    LensSet(
      id: 'lens_builtin_zengzi',
      label: isZh ? '曾子三省' : 'Zengzi\'s Three',
      lens1: isZh ? '为人谋而不忠乎？' : 'Have I been true to others?',
      lens2: isZh ? '与朋友交而不信乎？' : 'Have I been trustworthy with friends?',
      lens3: isZh ? '传不习乎？' : 'Have I practiced what I learned?',
      isBuiltin: true,
      sortOrder: isZh ? 1 : 2,
      createdAt: DateTime(2026, 1, 1),
    ),
    LensSet(
      id: 'lens_builtin_honest_weather',
      label: isZh ? '诚实的天气' : 'Honest Weather',
      lens1: isZh ? '今天的阳光是什么？' : 'What was the sunlight today?',
      lens2: isZh ? '今天的雨是什么？' : 'What was the rain today?',
      lens3: isZh ? '明天的天气会怎样？' : 'What might the weather be tomorrow?',
      isBuiltin: true,
      sortOrder: isZh ? 2 : 1,
      createdAt: DateTime(2026, 1, 1),
    ),
    LensSet(
      id: 'lens_builtin_body_mind_heart',
      label: isZh ? '身·心·灵' : 'Body·Mind·Heart',
      lens1: isZh ? '我的身体需要什么？' : 'What is my body asking for?',
      lens2: isZh ? '我的思绪在盘算什么？' : 'What is my mind turning over?',
      lens3: isZh ? '我的内心想要什么？' : 'What is my heart wanting?',
      isBuiltin: true,
      sortOrder: 3,
      createdAt: DateTime(2026, 1, 1),
    ),
    LensSet(
      id: 'lens_builtin_forward_sideways_back',
      label: isZh ? '前·侧·后' : 'Forward·Sideways·Back',
      lens1: isZh ? '前方有什么在等你？' : 'What lies ahead?',
      lens2: isZh ? '此刻你身边有什么？' : 'What is beside you right now?',
      lens3: isZh ? '身后留下了什么？' : 'What have you left behind?',
      isBuiltin: true,
      sortOrder: 4,
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  static const String defaultActiveSetId = 'lens_builtin_zengzi';
}
