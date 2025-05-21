import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../data/models/photo_progress_entry.dart';

class PhotoProgressRepository {
  static const _dataFile = 'photo_progress.json';

  Future<String> _getDataFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, _dataFile);
  }

  Future<List<PhotoProgressEntry>> loadEntries() async {
    try {
      final filePath = await _getDataFilePath();
      final file = File(filePath);
      if (!file.existsSync()) return [];

      final jsonStr = await file.readAsString();
      final List decoded = json.decode(jsonStr);
      return decoded.map((e) => PhotoProgressEntry.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveEntries(List<PhotoProgressEntry> entries) async {
    final filePath = await _getDataFilePath();
    final file = File(filePath);
    final jsonStr = json.encode(entries.map((e) => e.toJson()).toList());
    await file.writeAsString(jsonStr);
  }

  Future<String> saveImageFile(File imageFile) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(dir.path, 'photo_progress'));
    if (!folder.existsSync()) folder.createSync(recursive: true);

    final filename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedPath = p.join(folder.path, filename);
    final newFile = await imageFile.copy(savedPath);
    return newFile.path;
  }

  Future<void> deleteEntry(PhotoProgressEntry entry) async {
    final file = File(entry.path);
    if (await file.exists()) {
      await file.delete();
    }

    final entries = await loadEntries();
    entries.removeWhere((e) => e.path == entry.path);
    await saveEntries(entries);
  }
}