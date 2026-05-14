import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../core/services/file_service.dart';
import '../models/reflection_style.dart';

/// Holds AI assistant persona settings and notifies listeners on change.
class AiPersonaProvider extends ChangeNotifier {
  String name = 'Kael';
  String personality = '';
  String? avatarPath;
  String styleId = 'kael';

  AiPersonaProvider() {
    _load();
  }

  bool get hasCustomAvatar =>
      avatarPath != null && avatarPath!.isNotEmpty;

  String displayNameFor(bool isZh) {
    final style = ReflectionStyle.byId(styleId);
    return isZh ? style.nameZh : style.name;
  }

  /// Returns the active style's bundled avatar asset path for the given locale.
  /// Falls back to the default asset if the locale-specific variant isn't set.
  String? styleAvatarAssetFor(bool isZh) {
    final style = ReflectionStyle.byId(styleId);
    if (isZh && style.avatarAssetCn != null) return style.avatarAssetCn;
    return style.avatarAsset;
  }

  /// Returns the active style's bundled avatar asset path.
  String? get styleAvatarAsset {
    final style = ReflectionStyle.byId(styleId);
    return style.avatarAsset;
  }

  /// Returns the file-based custom avatar if set, or null.
  /// Callers should then fall back to [styleAvatarAsset] for a bundled asset,
  /// or the emoji if neither is available.
  String? get resolvedAvatarPath {
    if (hasCustomAvatar) return avatarPath;
    return null;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    styleId = prefs.getString('ai_style_id') ?? 'kael';
    if (styleId == 'custom') {
      final jsonStr = prefs.getString('ai_custom_style');
      if (jsonStr != null) {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        final style = ReflectionStyle.fromJson(json);
        name = style.name;
        personality = style.persona(false);
      } else {
        styleId = 'kael';
        name = 'Kael';
        personality = ReflectionStyle.byId('kael').persona(false);
      }
    } else {
      final style = ReflectionStyle.byId(styleId);
      name = prefs.getString('ai_assistant_name') ?? style.name;
      personality = prefs.getString('ai_assistant_personality') ?? style.persona(false);
    }
    avatarPath = prefs.getString('ai_avatar_path');
    notifyListeners();
  }

  Future<void> reload() => _load();

  /// Sets the active reflection style — updates name, personality, and persists.
  Future<void> setStyle(ReflectionStyle style) async {
    final prefs = await SharedPreferences.getInstance();
    styleId = style.id;
    await prefs.setString('ai_style_id', style.id);

    final isZh =
        prefs.getString('language') == 'zh'; // approximate — caller should pass
    name = style.name;
    personality =
        isZh ? style.personaZh : style.personaEn;

    await prefs.setString('ai_assistant_name', name);
    await prefs.setString('ai_assistant_personality', personality);
    notifyListeners();
  }

  /// Activates a custom style by persisting it and updating the persona.
  Future<void> setCustomStyle(Map<String, dynamic> json) async {
    final prefs = await SharedPreferences.getInstance();
    styleId = 'custom';
    await prefs.setString('ai_style_id', 'custom');
    await prefs.setString('ai_custom_style', jsonEncode(json));

    final style = ReflectionStyle.fromJson(json);
    final isZh = prefs.getString('language') == 'zh';
    name = style.name;
    personality = isZh ? style.personaZh : style.personaEn;

    await prefs.setString('ai_assistant_name', name);
    await prefs.setString('ai_assistant_personality', personality);
    notifyListeners();
  }

  /// Removes the custom style and falls back to default.
  Future<void> clearCustomStyle() async {
    if (styleId != 'custom') return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ai_custom_style');
    await setStyle(ReflectionStyle.byId(ReflectionStyle.defaultStyleId));
  }

  Future<void> saveNameAndPersonality(
      String newName, String newPersonality) async {
    name = newName;
    personality = newPersonality;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_assistant_name', name);
    await prefs.setString('ai_assistant_personality', personality);
    notifyListeners();
  }

  Future<void> setAvatarFromPath(String sourcePath) async {
    final savedRelative = await FileService().saveFile(sourcePath);
    final fullPath = await FileService().getFullPath(savedRelative);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_avatar_path', fullPath);
    avatarPath = fullPath;
    notifyListeners();
  }

  Future<void> clearAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ai_avatar_path');
    avatarPath = null;
    notifyListeners();
  }
}
