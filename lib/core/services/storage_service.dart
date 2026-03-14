import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path_pkg;
import 'package:path_provider/path_provider.dart';
import '../../models/entry.dart';
import '../../models/tag.dart';
import '../../models/routine.dart';
import 'database_service.dart';

/// Local storage service using SQLite (via DatabaseService)
/// Preserves legacy SharedPreferences for settings and migration flags.
class StorageService {
  late SharedPreferences _prefs;
  final DatabaseService _dbService = DatabaseService();
  bool _initialized = false;

  /// Initialize storage
  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    
    // Initialize Database
    await _dbService.database;
    
    // Migrate data if first run
    await _dbService.migrateFromSharedPreferences();

    _initialized = true;

    // Initialize default tags if none exist
    final tags = await getTags();
    if (tags.isEmpty) {
      for (final tag in _getDefaultTags()) {
        await addTag(tag);
      }
    }

    // Initialize default routines if none exist
    final routines = await getRoutines();
    if (routines.isEmpty) {
      for (final routine in _getDefaultRoutines()) {
        await addRoutine(routine);
      }
    }
  }

  /// Get default tags
  List<Tag> _getDefaultTags() {
    return [
      Tag(id: 'tag_work', name: '工作', nameEn: 'Work', color: '#34C759', category: 'custom', createdAt: DateTime.now()),
      Tag(id: 'tag_life', name: '生活', nameEn: 'Life', color: '#007AFF', category: 'custom', createdAt: DateTime.now()),
      Tag(id: 'tag_health', name: '健康', nameEn: 'Health', color: '#FF9500', category: 'health', createdAt: DateTime.now()),
      Tag(id: 'tag_learning', name: '学习', nameEn: 'Learning', color: '#5856D6', category: 'learning', createdAt: DateTime.now()),
      Tag(id: 'tag_family_menu', name: '家庭菜单', nameEn: 'Family Menu', color: '#FF2D55', category: 'custom', createdAt: DateTime.now()),
      Tag(id: 'tag_sleep', name: '睡眠', nameEn: 'Sleep', color: '#5AC8FA', category: 'sleeping', createdAt: DateTime.now()),
    ];
  }

  /// Get default routines
  List<Routine> _getDefaultRoutines() {
    return [
      Routine(id: 'routine_vitamin', name: '维生素', nameEn: 'Vitamin', icon: '💊', frequency: RoutineFrequency.daily, reminderTime: '08:00', isActive: true, targetCount: 1, currentCount: 0, isCounter: false, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      Routine(id: 'routine_steps', name: '5000步', nameEn: '5000 Steps', icon: '🚶', frequency: RoutineFrequency.daily, reminderTime: '21:00', isActive: true, targetCount: 5000, currentCount: 0, isCounter: true, unit: '步', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      Routine(id: 'routine_water', name: '喝水', nameEn: 'Water', icon: '💧', frequency: RoutineFrequency.daily, reminderTime: '21:00', isActive: true, targetCount: 1500, currentCount: 0, isCounter: true, unit: 'ml', createdAt: DateTime.now(), updatedAt: DateTime.now()),
    ];
  }

  // ============ ENTRIES ============

  Future<List<Entry>> getEntries() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query('entries', orderBy: 'created_at DESC');
    
    // When querying entries, we also need to join their tags
    final List<Entry> entries = [];
    for (final map in maps) {
      final List<Map<String, dynamic>> tagMaps = await db.query(
        'entry_tags',
        where: 'entry_id = ?',
        whereArgs: [map['id']],
      );
      final tagIds = tagMaps.map((t) => t['tag_id'] as String).toList();
      
      final entryMap = Map<String, dynamic>.from(map);
      entryMap['tagIds'] = tagIds;
      entryMap['type'] = map['type']; // Enum parsing in fromJson handles this
      entryMap['mediaUrls'] = json.decode(map['media_json'] as String);
      entryMap['metadata'] = map['metadata_json'] != null ? json.decode(map['metadata_json'] as String) : null;
      entryMap['createdAt'] = map['created_at'];
      entryMap['updatedAt'] = map['updated_at'];
      
      entries.add(Entry.fromJson(entryMap));
    }
    return entries;
  }

  Future<void> saveEntries(List<Entry> entries) async {
    // This method is less efficient in SQLite, but kept for legacy support.
    // Better to use addEntry / updateEntry.
    for (final entry in entries) {
      await addEntry(entry);
    }
  }

  Future<void> addEntry(Entry entry) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      await txn.insert('entries', {
        'id': entry.id,
        'type': entry.type.toString().split('.').last,
        'content': entry.content,
        'media_json': json.encode(entry.mediaUrls),
        'metadata_json': entry.metadata != null ? json.encode(entry.metadata) : null,
        'created_at': entry.createdAt.toIso8601String(),
        'updated_at': entry.updatedAt.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // Save tags
      for (final tagId in entry.tagIds) {
        await txn.insert('entry_tags', {
          'entry_id': entry.id,
          'tag_id': tagId,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  Future<void> updateEntry(Entry entry) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      await txn.update('entries', {
        'type': entry.type.toString().split('.').last,
        'content': entry.content,
        'media_json': json.encode(entry.mediaUrls),
        'metadata_json': entry.metadata != null ? json.encode(entry.metadata) : null,
        'updated_at': entry.updatedAt.toIso8601String(),
      }, where: 'id = ?', whereArgs: [entry.id]);

      // Refresh tags
      await txn.delete('entry_tags', where: 'entry_id = ?', whereArgs: [entry.id]);
      for (final tagId in entry.tagIds) {
        await txn.insert('entry_tags', {
          'entry_id': entry.id,
          'tag_id': tagId,
        });
      }
    });
  }

  Future<void> deleteEntry(String id) async {
    final db = await _dbService.database;
    await db.delete('entries', where: 'id = ?', whereArgs: [id]);
  }

  // ============ TAGS ============

  Future<List<Tag>> getTags() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query('tags', orderBy: 'name ASC');
    return maps.map((m) {
      final map = Map<String, dynamic>.from(m);
      map['createdAt'] = m['created_at'];
      map['nameEn'] = m['name_en'];
      return Tag.fromJson(map);
    }).toList();
  }

  Future<void> saveTags(List<Tag> tags) async {
    for (final tag in tags) {
      await addTag(tag);
    }
  }

  Future<void> addTag(Tag tag) async {
    final db = await _dbService.database;
    await db.insert('tags', {
      'id': tag.id,
      'name': tag.name,
      'name_en': tag.nameEn,
      'color': tag.color,
      'category': tag.category,
      'created_at': tag.createdAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateTag(Tag tag) async {
    final db = await _dbService.database;
    await db.update('tags', {
      'name': tag.name,
      'name_en': tag.nameEn,
      'color': tag.color,
      'category': tag.category,
    }, where: 'id = ?', whereArgs: [tag.id]);
  }

  Future<void> deleteTag(String id) async {
    final db = await _dbService.database;
    await db.delete('tags', where: 'id = ?', whereArgs: [id]);
  }

  // ============ ROUTINES ============

  Future<List<Routine>> getRoutines() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query('routines', orderBy: 'created_at ASC');
    
    final List<Routine> routines = [];
    for (final map in maps) {
      final List<Map<String, dynamic>> completionMaps = await db.query(
        'completions',
        where: 'routine_id = ?',
        whereArgs: [map['id']],
      );
      
      final routineMap = Map<String, dynamic>.from(map);
      routineMap['isActive'] = map['is_active'] == 1;
      routineMap['isCounter'] = map['is_counter'] == 1;
      routineMap['frequency'] = map['frequency'];
      routineMap['createdAt'] = map['created_at'];
      routineMap['updatedAt'] = map['updated_at'];
      routineMap['nameEn'] = map['name_en'];
      routineMap['description'] = map['description'];
      routineMap['descriptionEn'] = map['description_en'];
      routineMap['reminderTime'] = map['reminder_time'];
      routineMap['targetCount'] = map['target_count'];
      routineMap['currentCount'] = map['current_count'];
      routineMap['completionLog'] = completionMaps.map((c) => {
        'id': c['id'],
        'routineId': c['routine_id'],
        'completedAt': c['completed_at'],
        'count': c['count'],
        'notes': c['notes'],
      }).toList();
      
      routines.add(Routine.fromJson(routineMap));
    }
    return routines;
  }

  Future<void> saveRoutines(List<Routine> routines) async {
    for (final routine in routines) {
      await addRoutine(routine);
    }
  }

  Future<void> addRoutine(Routine routine) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      await txn.insert('routines', {
        'id': routine.id,
        'name': routine.name,
        'name_en': routine.nameEn,
        'icon': routine.icon,
        'description': routine.description,
        'description_en': routine.descriptionEn,
        'frequency': routine.frequency.toString().split('.').last,
        'reminder_time': routine.reminderTime,
        'is_active': routine.isActive ? 1 : 0,
        'target_count': routine.targetCount,
        'current_count': routine.currentCount,
        'is_counter': routine.isCounter ? 1 : 0,
        'unit': routine.unit,
        'created_at': routine.createdAt.toIso8601String(),
        'updated_at': routine.updatedAt.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      for (final completion in routine.completionLog) {
        await txn.insert('completions', {
          'id': completion.id,
          'routine_id': routine.id,
          'completed_at': completion.completedAt.toIso8601String(),
          'count': completion.count,
          'notes': completion.notes,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> updateRoutine(Routine routine) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      await txn.update('routines', {
        'name': routine.name,
        'name_en': routine.nameEn,
        'icon': routine.icon,
        'description': routine.description,
        'description_en': routine.descriptionEn,
        'frequency': routine.frequency.toString().split('.').last,
        'reminder_time': routine.reminderTime,
        'is_active': routine.isActive ? 1 : 0,
        'target_count': routine.targetCount,
        'current_count': routine.currentCount,
        'is_counter': routine.isCounter ? 1 : 0,
        'unit': routine.unit,
        'updated_at': routine.updatedAt.toIso8601String(),
      }, where: 'id = ?', whereArgs: [routine.id]);

      // Refresh completions
      await txn.delete('completions', where: 'routine_id = ?', whereArgs: [routine.id]);
      for (final completion in routine.completionLog) {
        await txn.insert('completions', {
          'id': completion.id,
          'routine_id': routine.id,
          'completed_at': completion.completedAt.toIso8601String(),
          'count': completion.count,
          'notes': completion.notes,
        });
      }
    });
  }

  Future<void> deleteRoutine(String id) async {
    final db = await _dbService.database;
    await db.delete('routines', where: 'id = ?', whereArgs: [id]);
  }

  // ============ SETTINGS (STILL IN PREFS) ============

  Future<Map<String, dynamic>> getSettings() async {
    final jsonString = _prefs.getString('blinking_settings');
    if (jsonString == null) {
      return {
        'language': 'zh',
        'theme': 'light',
      };
    }
    return json.decode(jsonString) as Map<String, dynamic>;
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final jsonString = json.encode(settings);
    await _prefs.setString('blinking_settings', jsonString);
  }

  Future<String> getLanguage() async {
    final settings = await getSettings();
    return settings['language'] as String? ?? 'zh';
  }

  Future<void> setLanguage(String language) async {
    final settings = await getSettings();
    settings['language'] = language;
    await saveSettings(settings);
  }

  Future<String> getTheme() async {
    final settings = await getSettings();
    return settings['theme'] as String? ?? 'light';
  }

  Future<void> setTheme(String theme) async {
    final settings = await getSettings();
    settings['theme'] = theme;
    await saveSettings(settings);
  }

  // ============ EXPORT / IMPORT ============

  Future<Map<String, dynamic>> exportData() async {
    final entries = await getEntries();
    final tags = await getTags();
    final routines = await getRoutines();
    final settings = await getSettings();

    return {
      'version': '2.0 (SQLite)',
      'exportedAt': DateTime.now().toIso8601String(),
      'entries': entries.map((e) => e.toJson()).toList(),
      'tags': tags.map((t) => t.toJson()).toList(),
      'routines': routines.map((r) => r.toJson()).toList(),
      'settings': settings,
    };
  }

  Future<void> importData(Map<String, dynamic> data) async {
    if (data.containsKey('tags')) {
      final tags = (data['tags'] as List<dynamic>)
          .map((t) => Tag.fromJson(t as Map<String, dynamic>))
          .toList();
      for (final tag in tags) await addTag(tag);
    }

    if (data.containsKey('routines')) {
      final routines = (data['routines'] as List<dynamic>)
          .map((r) => Routine.fromJson(r as Map<String, dynamic>))
          .toList();
      for (final routine in routines) await addRoutine(routine);
    }

    if (data.containsKey('entries')) {
      final entries = (data['entries'] as List<dynamic>)
          .map((e) => Entry.fromJson(e as Map<String, dynamic>))
          .toList();
      for (final entry in entries) await addEntry(entry);
    }

    if (data.containsKey('settings')) {
      await saveSettings(data['settings'] as Map<String, dynamic>);
    }
  }

  /// RESTORE FROM BACKUP (.json or .zip)
  Future<void> restoreFromBackup(File backupFile) async {
    final String extension = backupFile.path.split('.').last.toLowerCase();

    if (extension == 'json') {
      final String content = await backupFile.readAsString();
      final Map<String, dynamic> data = json.decode(content);
      await importData(data);
    } else if (extension == 'zip') {
      final bytes = await backupFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Find and process data.json first
      final dataFile = archive.findFile('data.json');
      if (dataFile != null) {
        final dataStr = utf8.decode(dataFile.content as List<int>);
        final data = json.decode(dataStr) as Map<String, dynamic>;
        await importData(data);
      }

      // Process media files
      final docDir = await getApplicationDocumentsDirectory();
      for (final file in archive) {
        if (file.isFile && file.name.startsWith('media/')) {
          final targetFile = File(path_pkg.join(docDir.path, file.name));
          if (!await targetFile.parent.exists()) {
            await targetFile.parent.create(recursive: true);
          }
          await targetFile.writeAsBytes(file.content as List<int>);
        }
      }
    } else {
      throw Exception('Unsupported backup format: $extension');
    }
  }

  Future<void> clearAll() async {
    final db = await _dbService.database;
    await db.delete('entries');
    await db.delete('tags');
    await db.delete('entry_tags');
    await db.delete('routines');
    await db.delete('completions');
    await _prefs.remove('sqlite_migrated');
  }
}