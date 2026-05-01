import 'package:uuid/uuid.dart';
import '../models/entry.dart';
import '../core/services/storage_service.dart';

/// Repository for Entry data access
/// Acts as a bridge between Providers and StorageService
class EntryRepository {
  final StorageService _storage;
  final _uuid = const Uuid();

  EntryRepository(this._storage);

  /// Get all entries, sorted by newest first
  Future<List<Entry>> getAll() async {
    final entries = await _storage.getEntries();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  /// Get entries for a specific date
  Future<List<Entry>> getByDate(DateTime date) async {
    final entries = await getAll();
    return entries.where((e) =>
        e.createdAt.year == date.year &&
        e.createdAt.month == date.month &&
        e.createdAt.day == date.day).toList();
  }

  /// Get entries for a date range
  Future<List<Entry>> getByDateRange(DateTime start, DateTime end) async {
    final entries = await getAll();
    return entries.where((e) =>
        e.createdAt.isAfter(start.subtract(const Duration(days: 1))) &&
        e.createdAt.isBefore(end.add(const Duration(days: 1)))).toList();
  }

  /// Get entries by tag ID
  Future<List<Entry>> getByTag(String tagId) async {
    final entries = await getAll();
    return entries.where((e) => e.tagIds.contains(tagId)).toList();
  }

  /// Get entries by type (freeform or routine)
  Future<List<Entry>> getByType(EntryType type) async {
    final entries = await getAll();
    return entries.where((e) => e.type == type).toList();
  }

  /// Search entries by content
  Future<List<Entry>> search(String query) async {
    final entries = await getAll();
    final lowerQuery = query.toLowerCase();
    return entries.where((e) =>
        e.content.toLowerCase().contains(lowerQuery)).toList();
  }

  /// Get a single entry by ID
  Future<Entry?> getById(String id) async {
    final entries = await getAll();
    try {
      return entries.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Create a new entry
  Future<Entry> create({
    required EntryType type,
    required String content,
    List<String> tagIds = const [],
    List<String> mediaUrls = const [],
    Map<String, dynamic>? metadata,
    String? emotion,
    EntryFormat format = EntryFormat.note,
    List<ListItem>? listItems,
    bool listCarriedForward = false,
  }) async {
    final now = DateTime.now();
    final entry = Entry(
      id: _uuid.v4(),
      type: type,
      content: content,
      tagIds: tagIds,
      mediaUrls: mediaUrls,
      createdAt: now,
      updatedAt: now,
      metadata: metadata,
      emotion: emotion,
      format: format,
      listItems: listItems,
      listCarriedForward: listCarriedForward,
    );
    await _storage.addEntry(entry);
    return entry;
  }

  /// Update an existing entry
  Future<Entry?> update(Entry entry) async {
    final updated = entry.copyWith(updatedAt: DateTime.now());
    await _storage.updateEntry(updated);
    return updated;
  }

  /// Delete an entry
  Future<void> delete(String id) async {
    await _storage.deleteEntry(id);
  }

  /// Get today's entries
  Future<List<Entry>> getTodayEntries() async {
    return getByDate(DateTime.now());
  }

  /// Get this week's entries
  Future<List<Entry>> getThisWeekEntries() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return getByDateRange(startOfWeek, now);
  }

  /// Get this month's entries
  Future<List<Entry>> getThisMonthEntries() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return getByDateRange(startOfMonth, now);
  }

  Future<void> toggleListItem(String entryId, String itemId) async {
    await _storage.toggleListItem(entryId, itemId);
  }

  Future<int> checkAndCarryForward() async {
    final allEntries = await getAll();
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    int totalCarried = 0;

    for (final entry in allEntries) {
      if (entry.format != EntryFormat.list) continue;
      if (entry.listCarriedForward) continue;
      final entryDate = DateTime(entry.createdAt.year, entry.createdAt.month, entry.createdAt.day);
      if (!entryDate.isBefore(todayDate)) continue;
      final unchecked = (entry.listItems ?? []).where((item) => !item.isDone).toList();
      if (unchecked.isEmpty) continue;

      final carriedItems = unchecked.asMap().entries.map((e) =>
        e.value.copyWith(isDone: false, sortOrder: e.key)
      ).toList();

      await create(
        type: EntryType.freeform,
        content: entry.content,
        format: EntryFormat.list,
        listItems: carriedItems,
        listCarriedForward: false,
      );
      await _storage.markListCarriedForward(entry.id);
      totalCarried += carriedItems.length;
    }
    return totalCarried;
  }
}
