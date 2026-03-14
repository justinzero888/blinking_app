import 'package:flutter/foundation.dart';
import '../models/entry.dart';
import '../repositories/entry_repository.dart';

/// Provider for managing entries (freeform and routine records)
/// Uses EntryRepository for data access
class EntryProvider extends ChangeNotifier {
  final EntryRepository _repository;
  
  List<Entry> _entries = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String? _filterTagId;
  String _filterType = 'all'; // 'all', 'freeform', 'routine'

  EntryProvider(this._repository);

  // Getters
  List<Entry> get allEntries => _entries;
  List<Entry> get entries {
    var filtered = _entries;

    // Filter by type
    if (_filterType != 'all') {
      final filterTypeEnum = _filterType == 'freeform' ? EntryType.freeform : EntryType.routine;
      filtered = filtered.where((e) => e.type == filterTypeEnum).toList();
    }

    // Filter by tag
    if (_filterTagId != null) {
      filtered = filtered.where((e) => e.tagIds.contains(_filterTagId)).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((e) => e.content.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get filterTagId => _filterTagId;
  String get filterType => _filterType;

  /// Load all entries from storage
  Future<void> loadEntries() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _entries = await _repository.getAll();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Add a new entry
  Future<void> addEntry({
    required EntryType type,
    required String content,
    List<String> tagIds = const [],
    List<String> mediaUrls = const [],
    Map<String, dynamic>? metadata,
  }) async {
    _error = null;
    
    try {
      final entry = await _repository.create(
        type: type,
        content: content,
        tagIds: tagIds,
        mediaUrls: mediaUrls,
        metadata: metadata,
      );
      _entries.insert(0, entry); // Add to beginning
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Update an entry
  Future<void> updateEntry(Entry entry) async {
    _error = null;
    
    try {
      final updated = await _repository.update(entry);
      if (updated != null) {
        final index = _entries.indexWhere((e) => e.id == entry.id);
        if (index != -1) {
          _entries[index] = updated;
          notifyListeners();
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Delete an entry
  Future<void> deleteEntry(String id) async {
    _error = null;
    
    try {
      await _repository.delete(id);
      _entries.removeWhere((e) => e.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Set filter by tag
  void setFilterTag(String? tagId) {
    _filterTagId = tagId;
    notifyListeners();
  }

  /// Set filter by type
  void setFilterType(String type) {
    _filterType = type;
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _filterTagId = null;
    _filterType = 'all';
    notifyListeners();
  }

  /// Get entries for a specific date
  List<Entry> getEntriesForDate(DateTime date) {
    return _entries.where((e) =>
        e.createdAt.year == date.year &&
        e.createdAt.month == date.month &&
        e.createdAt.day == date.day).toList();
  }

  /// Get today's entries
  List<Entry> get todayEntries => getEntriesForDate(DateTime.now());

  /// Get this week's entries
  List<Entry> get thisWeekEntries {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return _entries.where((e) =>
        e.createdAt.isAfter(startOfWeek.subtract(const Duration(days: 1)))).toList();
  }

  /// Get this month's entries
  List<Entry> get thisMonthEntries {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return _entries.where((e) =>
        e.createdAt.isAfter(startOfMonth.subtract(const Duration(days: 1)))).toList();
  }

  /// Get dates that have entries (for calendar markers)
  Set<DateTime> getDatesWithEntries() {
    return _entries.map((e) => DateTime(
      e.createdAt.year,
      e.createdAt.month,
      e.createdAt.day,
    )).toSet();
  }

  /// Search entries
  Future<List<Entry>> search(String query) async {
    return _repository.search(query);
  }
}
