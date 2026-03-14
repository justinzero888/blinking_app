import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/card_folder.dart';
import '../models/card_template.dart';
import '../models/note_card.dart';
import '../core/services/storage_service.dart';

/// Provider for card folders, templates and note cards
class CardProvider extends ChangeNotifier {
  final StorageService _storage;
  final _uuid = const Uuid();

  List<CardFolder> _folders = [];
  List<CardTemplate> _templates = [];
  List<NoteCard> _cards = [];
  bool _isLoading = false;

  CardProvider(this._storage);

  // Getters
  List<CardFolder> get folders => _folders;
  List<CardTemplate> get templates => _templates;
  List<NoteCard> get cards => _cards;
  bool get isLoading => _isLoading;

  /// Load all data from storage
  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _folders = await _storage.getCardFolders();
      _templates = await _storage.getTemplates();
      _cards = await _storage.getNoteCards();
    } catch (e) {
      debugPrint('CardProvider.load error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  // ---- Note Cards ----

  Future<NoteCard> addCard({
    required List<String> entryIds,
    required String templateId,
    required String folderId,
    String? renderedImagePath,
  }) async {
    final now = DateTime.now();
    final card = NoteCard(
      id: _uuid.v4(),
      entryIds: entryIds,
      templateId: templateId,
      folderId: folderId,
      renderedImagePath: renderedImagePath,
      createdAt: now,
      updatedAt: now,
    );
    await _storage.addNoteCard(card);
    _cards.insert(0, card);
    notifyListeners();
    return card;
  }

  Future<void> deleteCard(String id) async {
    await _storage.deleteNoteCard(id);
    _cards.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  List<NoteCard> getCardsInFolder(String folderId) {
    return _cards.where((c) => c.folderId == folderId).toList();
  }

  // ---- Folders ----

  Future<void> addFolder(String name, String icon) async {
    final folder = CardFolder(
      id: _uuid.v4(),
      name: name,
      icon: icon,
      createdAt: DateTime.now(),
    );
    await _storage.addCardFolder(folder);
    _folders.add(folder);
    notifyListeners();
  }

  Future<void> updateFolder(CardFolder folder) async {
    await _storage.updateCardFolder(folder);
    final index = _folders.indexWhere((f) => f.id == folder.id);
    if (index != -1) {
      _folders[index] = folder;
      notifyListeners();
    }
  }

  Future<void> deleteFolder(String id) async {
    await _storage.deleteCardFolder(id);
    _folders.removeWhere((f) => f.id == id);
    notifyListeners();
  }

  // ---- Templates ----

  Future<void> addTemplate(CardTemplate template) async {
    await _storage.addTemplate(template);
    _templates.add(template);
    notifyListeners();
  }

  Future<void> updateTemplate(CardTemplate template) async {
    if (template.isBuiltIn) return; // Cannot modify built-in templates
    await _storage.updateTemplate(template);
    final index = _templates.indexWhere((t) => t.id == template.id);
    if (index != -1) {
      _templates[index] = template;
      notifyListeners();
    }
  }

  Future<void> deleteTemplate(String id) async {
    final template = _templates.firstWhere((t) => t.id == id,
        orElse: () => throw Exception('Template not found'));
    if (template.isBuiltIn) return; // Cannot delete built-in templates
    await _storage.deleteTemplate(id);
    _templates.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  /// Get template by id, returns null if not found
  CardTemplate? getTemplateById(String id) {
    try {
      return _templates.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
