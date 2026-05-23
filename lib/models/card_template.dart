import 'card_enums.dart';

/// A card template defining visual style for note cards
class CardTemplate {
  final String id;
  final String name;
  final String? nameEn;
  final String icon;
  final String fontFamily; // 'default', 'serif', 'mono'
  final String fontColor; // hex e.g. '#222222'
  final String bgColor; // hex background color
  final bool isBuiltIn;
  final String? customImagePath;
  final String? sourceTemplateId; // set on copies of built-in templates
  final DateTime createdAt;

  // v1.2.0 new fields
  final CardLayout layout;
  final String? accentColor; // #hex
  final double textAreaOpacity; // 0.0–1.0
  final String? textBackdropColor; // #hex
  final String? footerText; // "Blinking Notes" or custom
  final bool showMood;
  final bool showDate;
  final bool showTags;
  final bool showFooter;
  final CardCornerStyle cornerStyle;
  final String? decorationStyle; // ink_wash, bamboo, crescent, porcelain, tea, seal, landscape

  const CardTemplate({
    required this.id,
    required this.name,
    this.nameEn,
    required this.icon,
    this.fontFamily = 'default',
    required this.fontColor,
    required this.bgColor,
    this.isBuiltIn = false,
    this.customImagePath,
    this.sourceTemplateId,
    required this.createdAt,
    this.layout = CardLayout.heroImage,
    this.accentColor,
    this.textAreaOpacity = 0.85,
    this.textBackdropColor,
    this.footerText = 'Blinking Notes',
    this.showMood = true,
    this.showDate = true,
    this.showTags = true,
    this.showFooter = true,
    this.cornerStyle = CardCornerStyle.rounded,
    this.decorationStyle,
  });

  /// Returns a locale-aware display name.
  /// Uses nameEn for English, name for Chinese.
  String displayNameFor(bool isZh) {
    if (!isZh && nameEn != null) return nameEn!;
    return name;
  }

  CardTemplate copyWith({
    String? id,
    String? name,
    String? nameEn,
    bool clearNameEn = false,
    String? icon,
    String? fontFamily,
    String? fontColor,
    String? bgColor,
    bool? isBuiltIn,
    String? customImagePath,
    bool clearCustomImage = false,
    String? sourceTemplateId,
    DateTime? createdAt,
    CardLayout? layout,
    String? accentColor,
    bool clearAccentColor = false,
    double? textAreaOpacity,
    String? textBackdropColor,
    bool clearTextBackdropColor = false,
    String? footerText,
    bool clearFooterText = false,
    bool? showMood,
    bool? showDate,
    bool? showTags,
    bool? showFooter,
    CardCornerStyle? cornerStyle,
    String? decorationStyle,
    bool clearDecorationStyle = false,
  }) {
    return CardTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      nameEn: clearNameEn ? null : (nameEn ?? this.nameEn),
      icon: icon ?? this.icon,
      fontFamily: fontFamily ?? this.fontFamily,
      fontColor: fontColor ?? this.fontColor,
      bgColor: bgColor ?? this.bgColor,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      customImagePath:
          clearCustomImage ? null : (customImagePath ?? this.customImagePath),
      sourceTemplateId: sourceTemplateId ?? this.sourceTemplateId,
      createdAt: createdAt ?? this.createdAt,
      layout: layout ?? this.layout,
      accentColor:
          clearAccentColor ? null : (accentColor ?? this.accentColor),
      textAreaOpacity: textAreaOpacity ?? this.textAreaOpacity,
      textBackdropColor: clearTextBackdropColor
          ? null
          : (textBackdropColor ?? this.textBackdropColor),
      footerText: clearFooterText ? null : (footerText ?? this.footerText),
      showMood: showMood ?? this.showMood,
      showDate: showDate ?? this.showDate,
      showTags: showTags ?? this.showTags,
      showFooter: showFooter ?? this.showFooter,
      cornerStyle: cornerStyle ?? this.cornerStyle,
      decorationStyle: clearDecorationStyle
          ? null
          : (decorationStyle ?? this.decorationStyle),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'name_en': nameEn,
        'icon': icon,
        'font_family': fontFamily,
        'font_color': fontColor,
        'bg_color': bgColor,
        'is_built_in': isBuiltIn ? 1 : 0,
        'custom_image_path': customImagePath,
        'source_template_id': sourceTemplateId,
        'created_at': createdAt.toIso8601String(),
        'layout': layout.value,
        'accent_color': accentColor,
        'text_area_opacity': textAreaOpacity,
        'text_backdrop_color': textBackdropColor,
        'footer_text': footerText,
        'show_mood': showMood ? 1 : 0,
        'show_date': showDate ? 1 : 0,
        'show_tags': showTags ? 1 : 0,
        'show_footer': showFooter ? 1 : 0,
        'corner_style': cornerStyle.value,
        'decoration_style': decorationStyle,
      };

  factory CardTemplate.fromJson(Map<String, dynamic> json) => CardTemplate(
        id: json['id'] as String,
        name: json['name'] as String,
        nameEn: json['name_en'] as String?,
        icon: json['icon'] as String,
        fontFamily: json['font_family'] as String? ?? 'default',
        fontColor: json['font_color'] as String? ?? '#222222',
        bgColor: json['bg_color'] as String? ?? '#FFFFFF',
        isBuiltIn: (json['is_built_in'] as int? ?? 0) == 1,
        customImagePath: json['custom_image_path'] as String?,
        sourceTemplateId: json['source_template_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        layout: json['layout'] != null
            ? CardLayoutExtension.fromString(json['layout'] as String)
            : CardLayout.heroImage,
        accentColor: json['accent_color'] as String?,
        textAreaOpacity: (json['text_area_opacity'] as num?)?.toDouble() ?? 0.85,
        textBackdropColor: json['text_backdrop_color'] as String?,
        footerText: json['footer_text'] as String? ?? 'Blinking Notes',
        showMood: (json['show_mood'] as int? ?? 1) == 1,
        showDate: (json['show_date'] as int? ?? 1) == 1,
        showTags: (json['show_tags'] as int? ?? 1) == 1,
        showFooter: (json['show_footer'] as int? ?? 1) == 1,
        cornerStyle: json['corner_style'] != null
            ? CardCornerStyleExtension.fromString(json['corner_style'] as String)
            : CardCornerStyle.rounded,
        decorationStyle: json['decoration_style'] as String?,
      );
}
