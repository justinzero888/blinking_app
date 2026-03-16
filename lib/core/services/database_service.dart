import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/models.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'blinking.db');

    return await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE entries ADD COLUMN metadata_json TEXT');
      await db.execute('ALTER TABLE routines ADD COLUMN description TEXT');
      await db.execute('ALTER TABLE routines ADD COLUMN description_en TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE entries ADD COLUMN emotion TEXT');
      await db.execute('ALTER TABLE routines ADD COLUMN category TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS card_folders (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          icon TEXT NOT NULL,
          is_default INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS templates (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          icon TEXT NOT NULL,
          font_family TEXT NOT NULL DEFAULT 'default',
          font_color TEXT NOT NULL DEFAULT '#222222',
          bg_color TEXT NOT NULL DEFAULT '#FFFFFF',
          is_built_in INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS note_cards (
          id TEXT PRIMARY KEY,
          template_id TEXT NOT NULL,
          folder_id TEXT NOT NULL,
          rendered_image_path TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS note_card_entries (
          card_id TEXT NOT NULL,
          entry_id TEXT NOT NULL,
          PRIMARY KEY (card_id, entry_id)
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE routines ADD COLUMN scheduled_days_of_week TEXT');
      await db.execute('ALTER TABLE routines ADD COLUMN scheduled_date TEXT');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Entries table
    await db.execute('''
      CREATE TABLE entries (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        content TEXT,
        media_json TEXT,
        metadata_json TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        emotion TEXT
      )
    ''');

    // Tags table
    await db.execute('''
      CREATE TABLE tags (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        name_en TEXT,
        color TEXT NOT NULL,
        category TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Entry Tags (Many-to-Many)
    await db.execute('''
      CREATE TABLE entry_tags (
        entry_id TEXT NOT NULL,
        tag_id TEXT NOT NULL,
        PRIMARY KEY (entry_id, tag_id),
        FOREIGN KEY (entry_id) REFERENCES entries (id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
      )
    ''');

    // Routines table
    await db.execute('''
      CREATE TABLE routines (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        name_en TEXT,
        icon TEXT,
        description TEXT,
        description_en TEXT,
        frequency TEXT NOT NULL,
        reminder_time TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        target_count INTEGER,
        current_count INTEGER DEFAULT 0,
        is_counter INTEGER NOT NULL DEFAULT 0,
        unit TEXT,
        category TEXT,
        scheduled_days_of_week TEXT,
        scheduled_date TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Completion log table
    await db.execute('''
      CREATE TABLE completions (
        id TEXT PRIMARY KEY,
        routine_id TEXT NOT NULL,
        completed_at TEXT NOT NULL,
        count INTEGER,
        notes TEXT,
        FOREIGN KEY (routine_id) REFERENCES routines (id) ON DELETE CASCADE
      )
    ''');

    // Card folders table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS card_folders (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Templates table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS templates (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        font_family TEXT NOT NULL DEFAULT 'default',
        font_color TEXT NOT NULL DEFAULT '#222222',
        bg_color TEXT NOT NULL DEFAULT '#FFFFFF',
        is_built_in INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Note cards table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS note_cards (
        id TEXT PRIMARY KEY,
        template_id TEXT NOT NULL,
        folder_id TEXT NOT NULL,
        rendered_image_path TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Note card entries (many-to-many)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS note_card_entries (
        card_id TEXT NOT NULL,
        entry_id TEXT NOT NULL,
        PRIMARY KEY (card_id, entry_id)
      )
    ''');
  }

  /// Perform data migration from SharedPreferences to SQLite if needed
  Future<void> migrateFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final bool migrated = prefs.getBool('sqlite_migrated') ?? false;
    if (migrated) return;

    final db = await database;

    // Migrate Tags
    final tagsJson = prefs.getString('blinking_tags');
    if (tagsJson != null) {
      final List<dynamic> tagsList = json.decode(tagsJson);
      for (final tagMap in tagsList) {
        final tag = Tag.fromJson(tagMap as Map<String, dynamic>);
        await db.insert('tags', {
          'id': tag.id,
          'name': tag.name,
          'name_en': tag.nameEn,
          'color': tag.color,
          'category': tag.category,
          'created_at': tag.createdAt.toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }

    // Migrate Routines & Completions
    final routinesJson = prefs.getString('blinking_routines');
    if (routinesJson != null) {
      final List<dynamic> routinesList = json.decode(routinesJson);
      for (final routineMap in routinesList) {
        final routine = Routine.fromJson(routineMap as Map<String, dynamic>);
        await db.insert('routines', {
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
          await db.insert('completions', {
            'id': completion.id,
            'routine_id': routine.id,
            'completed_at': completion.completedAt.toIso8601String(),
            'count': completion.count,
            'notes': completion.notes,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    }

    // Migrate Entries & EntryTags
    final entriesJson = prefs.getString('blinking_entries');
    if (entriesJson != null) {
      final List<dynamic> entriesList = json.decode(entriesJson);
      for (final entryMap in entriesList) {
        final entry = Entry.fromJson(entryMap as Map<String, dynamic>);
        await db.insert('entries', {
          'id': entry.id,
          'type': entry.type.toString().split('.').last,
          'content': entry.content,
          'media_json': json.encode(entry.mediaUrls),
          'metadata_json': entry.metadata != null ? json.encode(entry.metadata) : null,
          'created_at': entry.createdAt.toIso8601String(),
          'updated_at': entry.updatedAt.toIso8601String(),
          'emotion': entry.emotion,
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        for (final tagId in entry.tagIds) {
          await db.insert('entry_tags', {
            'entry_id': entry.id,
            'tag_id': tagId,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }
    }

    await prefs.setBool('sqlite_migrated', true);
  }

  // ============ HELPER METHODS ============

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
