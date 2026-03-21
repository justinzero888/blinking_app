import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/file_service.dart';

/// Holds AI assistant persona settings and notifies listeners on change.
/// Persisted to SharedPreferences. Consumed by FloatingRobotWidget,
/// AssistantScreen, and SettingsScreen.
class AiPersonaProvider extends ChangeNotifier {
  String name = 'AI 助手';
  String personality = '';
  String? avatarPath;

  AiPersonaProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    name = prefs.getString('ai_assistant_name') ?? 'AI 助手';
    personality = prefs.getString('ai_assistant_personality') ?? '';
    avatarPath = prefs.getString('ai_avatar_path');
    notifyListeners();
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
