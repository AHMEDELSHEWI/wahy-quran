import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/ayah.dart';
import '../models/surah.dart';

/// Singleton access point to the offline Quran SQLite database.
///
/// The database ships pre-built inside the app bundle (assets/db/quran.db)
/// so the app works fully offline from first launch — no network required,
/// no first-run download. On first run we copy it into the app's writable
/// documents directory, since SQLite cannot open a DB directly from the
/// read-only asset bundle on most platforms.
class QuranDatabase {
  QuranDatabase._internal();
  static final QuranDatabase instance = QuranDatabase._internal();

  static Database? _db;
  static const String _dbAssetPath = 'assets/db/quran.db';
  static const String _dbFileName = 'quran.db';

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDirectory.path, _dbFileName);

    final dbFile = File(dbPath);
    if (!await dbFile.exists()) {
      final data = await rootBundle.load(_dbAssetPath);
      final bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await dbFile.writeAsBytes(bytes, flush: true);
    }

    return openDatabase(dbPath, readOnly: false);
  }

  // ---------- Surah queries ----------

  Future<List<Surah>> getAllSurahs() async {
    final db = await database;
    final maps = await db.query('surahs', orderBy: 'id ASC');
    return maps.map((m) => Surah.fromMap(m)).toList();
  }

  Future<Surah?> getSurahById(int id) async {
    final db = await database;
    final maps = await db.query('surahs', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Surah.fromMap(maps.first);
  }

  // ---------- Ayah queries ----------

  Future<List<Ayah>> getAyatBySurah(int surahId) async {
    final db = await database;
    final maps = await db.query(
      'ayat',
      where: 'surah_id = ?',
      whereArgs: [surahId],
      orderBy: 'ayah_number ASC',
    );
    return maps.map((m) => Ayah.fromMap(m)).toList();
  }

  Future<Ayah?> getAyah(int surahId, int ayahNumber) async {
    final db = await database;
    final maps = await db.query(
      'ayat',
      where: 'surah_id = ? AND ayah_number = ?',
      whereArgs: [surahId, ayahNumber],
    );
    if (maps.isEmpty) return null;
    return Ayah.fromMap(maps.first);
  }

  /// Simple substring search across ayah text (diacritic-sensitive).
  /// A production release should add a normalized (no-tashkeel) search
  /// index — left as a follow-up item, see README.
  Future<List<Ayah>> searchAyat(String query) async {
    if (query.trim().isEmpty) return [];
    final db = await database;
    final maps = await db.query(
      'ayat',
      where: 'text_uthmani LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'surah_id ASC, ayah_number ASC',
      limit: 200,
    );
    return maps.map((m) => Ayah.fromMap(m)).toList();
  }

  // ---------- Provenance ----------

  Future<List<Map<String, dynamic>>> getProvenanceInfo() async {
    final db = await database;
    return db.query('data_provenance');
  }
}
