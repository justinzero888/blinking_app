import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path_pkg;
import 'package:uuid/uuid.dart';

/// Service to handle persistent file storage in the app's internal directory.
class FileService {
  static final FileService _instance = FileService._internal();
  factory FileService() => _instance;
  FileService._internal();

  final _uuid = const Uuid();

  /// Save a file to the app's internal documents directory.
  /// Returns the relative path (usually just the filename) within the documents directory.
  Future<String> saveFile(String sourcePath) async {
    final File sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw Exception('Source file does not exist: $sourcePath');
    }

    final directory = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(path_pkg.join(directory.path, 'media'));
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }

    final String extension = path_pkg.extension(sourcePath);
    final String fileName = '${_uuid.v4()}$extension';
    final String targetPath = path_pkg.join(mediaDir.path, fileName);

    await sourceFile.copy(targetPath);
    
    // Return the relative path from the documents directory
    return path_pkg.join('media', fileName);
  }

  /// Get the full absolute path from a relative path.
  Future<String> getFullPath(String relativePath) async {
    final directory = await getApplicationDocumentsDirectory();
    return path_pkg.join(directory.path, relativePath);
  }

  /// Delete a file given its relative path.
  Future<void> deleteFile(String relativePath) async {
    final fullPath = await getFullPath(relativePath);
    final file = File(fullPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Check if a relative path points to a file that exists.
  Future<bool> fileExists(String relativePath) async {
    final fullPath = await getFullPath(relativePath);
    return await File(fullPath).exists();
  }
}
