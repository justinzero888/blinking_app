import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path_pkg;
import '../config/constants.dart';
import '../../models/entry.dart';
import '../../models/tag.dart';
import '../../models/routine.dart';
import '../utils/csv_utils.dart';
import 'storage_service.dart';

class ExportData {
  // ... (ExportData class remains mostly the same, but let's ensure we have full content)
  final String version;
  final DateTime exportedAt;
  final String? userId;
  final List<Map<String, dynamic>> entries;
  final List<Map<String, dynamic>> tags;
  final List<Map<String, dynamic>> routines;

  ExportData({
    required this.version,
    required this.exportedAt,
    this.userId,
    required this.entries,
    required this.tags,
    required this.routines,
  });

  factory ExportData.fromEntriesAndTagsAndRoutines({
    required List<Entry> entries,
    required List<Tag> tags,
    required List<Routine> routines,
    String? userId,
  }) {
    return ExportData(
      version: AppConstants.exportVersion,
      exportedAt: DateTime.now(),
      userId: userId,
      entries: entries.map((e) => e.toJson()).toList(),
      tags: tags.map((t) => t.toJson()).toList(),
      routines: routines.map((r) => r.toJson()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'exportedAt': exportedAt.toIso8601String(),
      'userId': userId,
      'entries': entries,
      'tags': tags,
      'routines': routines,
    };
  }

  factory ExportData.fromJson(Map<String, dynamic> json) {
    return ExportData(
      version: (json['version'] ?? '1.0') as String,
      exportedAt: DateTime.parse((json['exportedAt'] ?? DateTime.now().toIso8601String()) as String),
      userId: json['userId'] as String?,
      entries: (json['entries'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
      tags: (json['tags'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
      routines: (json['routines'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
    );
  }
}

class ExportService {
  final StorageService _storage;

  ExportService(this._storage);

  /// Export all data (JSON + Media) to a ZIP file
  Future<String> exportAll({DateTime? startDate, DateTime? endDate}) async {
    final entries = await _storage.getEntries();
    final tags = await _storage.getTags();
    final routines = await _storage.getRoutines();

    List<Entry> filteredEntries = entries;
    if (startDate != null || endDate != null) {
      filteredEntries = entries.where((e) {
        if (startDate != null && e.createdAt.isBefore(startDate)) return false;
        if (endDate != null && e.createdAt.isAfter(endDate)) return false;
        return true;
      }).toList();
    }

    final exportData = ExportData.fromEntriesAndTagsAndRoutines(
      entries: filteredEntries,
      tags: tags,
      routines: routines,
    );

    final archive = Archive();
    
    // 1. Add data.json
    final jsonStr = const JsonEncoder.withIndent('  ').convert(exportData.toJson());
    final jsonBytes = utf8.encode(jsonStr);
    archive.addFile(ArchiveFile('data.json', jsonBytes.length, jsonBytes));
    
    // 2. Add manifest.json
    final manifest = {
      'exportedAt': exportData.exportedAt.toIso8601String(),
      'version': exportData.version,
      'entriesCount': filteredEntries.length,
      'tagsCount': tags.length,
      'routinesCount': routines.length,
      'hasMedia': true,
    };
    final manifestBytes = utf8.encode(jsonEncode(manifest));
    archive.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));

    // 3. Add Media Files
    final docDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(path_pkg.join(docDir.path, 'media'));
    
    if (await mediaDir.exists()) {
      final List<FileSystemEntity> entities = await mediaDir.list(recursive: true).toList();
      for (final entity in entities) {
        if (entity is File) {
          final relativePath = path_pkg.relative(entity.path, from: docDir.path);
          final bytes = await entity.readAsBytes();
          archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
        }
      }
    }

    // Save ZIP
    final zipData = ZipEncoder().encode(archive);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = path_pkg.join(docDir.path, 'blinking_backup_$timestamp.zip');
    final file = File(filePath);
    await file.writeAsBytes(zipData!);

    return filePath;
  }

  /// Export data as CSV (returns file path)
  Future<String> exportCsv({bool exportEntries = true, bool exportRoutines = true}) async {
    final docDir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final archive = Archive();

    if (exportEntries) {
      final entries = await _storage.getEntries();
      final csvData = entries.map((e) {
        final map = e.toJson();
        // Flatten simple fields for CSV readability
        map['tagIds'] = e.tagIds.join('|');
        map['mediaUrls'] = e.mediaUrls.join('|');
        return map;
      }).toList();
      final csvString = CsvUtils.mapListToCsv(csvData);
      final csvBytes = utf8.encode(csvString);
      archive.addFile(ArchiveFile('entries.csv', csvBytes.length, csvBytes));
    }

    if (exportRoutines) {
      final routines = await _storage.getRoutines();
      final csvData = routines.map((r) {
        final map = r.toJson();
        // Skip completionLog for flat routine CSV, maybe add separate one?
        map.remove('completionLog');
        return map;
      }).toList();
      final csvString = CsvUtils.mapListToCsv(csvData);
      final csvBytes = utf8.encode(csvString);
      archive.addFile(ArchiveFile('routines.csv', csvBytes.length, csvBytes));
    }

    final zipData = ZipEncoder().encode(archive);
    final filePath = path_pkg.join(docDir.path, 'blinking_export_csv_$timestamp.zip');
    final file = File(filePath);
    await file.writeAsBytes(zipData!);
    
    return filePath;
  }

  /// Export only JSON data as a file
  Future<String> exportJsonFile() async {
    final entries = await _storage.getEntries();
    final tags = await _storage.getTags();
    final routines = await _storage.getRoutines();

    final exportData = ExportData.fromEntriesAndTagsAndRoutines(
      entries: entries,
      tags: tags,
      routines: routines,
    );

    final jsonStr = const JsonEncoder.withIndent('  ').convert(exportData.toJson());
    final docDir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = path_pkg.join(docDir.path, 'blinking_data_$timestamp.json');
    final file = File(filePath);
    await file.writeAsString(jsonStr);

    return filePath;
  }

  /// Share a file using the system share sheet
  Future<void> shareFile(String filePath, {String? subject, String? text}) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: subject,
      text: text,
    );
  }

  /// Import data from JSON
  Future<void> importFromJson(String jsonStr) async {
    final Map<String, dynamic> data = jsonDecode(jsonStr);
    final exportData = ExportData.fromJson(data);

    // Filter out duplicates if needed, but saveData usually handles conflict replace
    final tags = exportData.tags.map((t) => Tag.fromJson(t)).toList();
    for (final tag in tags) await _storage.addTag(tag);

    final routines = exportData.routines.map((r) => Routine.fromJson(r)).toList();
    for (final routine in routines) await _storage.addRoutine(routine);

    final entries = exportData.entries.map((e) => Entry.fromJson(e)).toList();
    for (final entry in entries) await _storage.addEntry(entry);
  }
}