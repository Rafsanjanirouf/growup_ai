import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// SQLite-based local database — single source of truth for scan records.
/// Firestore is used only as a backup / cross-device sync mechanism.
class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  Database? _db;

  static const _dbName    = 'growup_local.db';
  static const _dbVersion = 10;         // bumped: added is_synced to outfit and hairstyle
  static const _scanTable  = 'scan_records';
  static const _outfitTable = 'outfit_history';
  static const _hairStyleTable = 'hairstyle_history';
  static const _configTable = 'app_config';
  static const _chatTable = 'chat_messages';
  static const _chatSessionsTable = 'chat_sessions';

  // ── Open / init ─────────────────────────────────────────────────────────────

  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path   = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // v1 → v2: add config table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $_configTable (
              key   TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 3) {
          // v2 → v3: add week_index column
          await db.execute('ALTER TABLE $_scanTable ADD COLUMN week_index INTEGER NOT NULL DEFAULT 0');
        }
        if (oldVersion < 4) {
          // v3 → v4: add chat_messages table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $_chatTable (
              id        TEXT PRIMARY KEY,
              text      TEXT NOT NULL,
              is_user   INTEGER NOT NULL,
              timestamp TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 5) {
          // v4 → v5: add chat_sessions table and session_id to messages
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $_chatSessionsTable (
              id         TEXT PRIMARY KEY,
              title      TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
          // If the table already existed, add the column.
          // Note: if the user just upgraded from 3->5, the table is already created above without session_id,
          // so we alter it here to add session_id.
          await db.execute('ALTER TABLE $_chatTable ADD COLUMN session_id TEXT NOT NULL DEFAULT ""');
        }
        if (oldVersion < 6) {
          // v5 → v6: add user_id column
          await db.execute('ALTER TABLE $_scanTable ADD COLUMN user_id TEXT NOT NULL DEFAULT ""');
        }
        if (oldVersion < 7) {
          // v6 → v7: add outfit_history table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $_outfitTable (
              id         TEXT PRIMARY KEY,
              user_id    TEXT NOT NULL,
              date       TEXT NOT NULL,
              image_path TEXT,
              full_data  TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 8) {
          // v7 → v8: add hairstyle_history table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $_hairStyleTable (
              id         TEXT PRIMARY KEY,
              user_id    TEXT NOT NULL,
              date       TEXT NOT NULL,
              image_path TEXT,
              full_data  TEXT NOT NULL,
              generated_image_b64 TEXT
            )
          ''');
        }
        if (oldVersion < 9) {
          // v8 → v9: add generated_image_b64 column to hairstyle_history
          try {
            await db.execute('ALTER TABLE $_hairStyleTable ADD COLUMN generated_image_b64 TEXT');
          } catch (e) {
            // Ignore if column already exists (in case of fresh install)
            debugPrint('Error adding column or column already exists: $e');
          }
        }
        if (oldVersion < 10) {
          // v9 → v10: add is_synced column
          try {
            await db.execute('ALTER TABLE $_outfitTable ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 0');
            await db.execute('ALTER TABLE $_hairStyleTable ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 0');
          } catch (e) {
            debugPrint('Error adding is_synced columns: $e');
          }
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE $_scanTable (
        id            TEXT PRIMARY KEY,
        user_id       TEXT NOT NULL,
        date          TEXT NOT NULL,
        aura_score    REAL NOT NULL,
        jawline_score REAL NOT NULL,
        skin_score    REAL NOT NULL,
        eye_score     REAL NOT NULL,
        posture_score REAL NOT NULL,
        rating        TEXT NOT NULL,
        highlights    TEXT NOT NULL,
        image_url     TEXT,
        is_synced     INTEGER NOT NULL DEFAULT 0,
        full_data     TEXT,
        week_index    INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE $_configTable (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE $_chatTable (
        id         TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        text       TEXT NOT NULL,
        is_user    INTEGER NOT NULL,
        timestamp  TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE $_chatSessionsTable (
        id         TEXT PRIMARY KEY,
        title      TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE $_outfitTable (
        id         TEXT PRIMARY KEY,
        user_id    TEXT NOT NULL,
        date       TEXT NOT NULL,
        image_path TEXT,
        full_data  TEXT NOT NULL,
        is_synced  INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE $_hairStyleTable (
        id         TEXT PRIMARY KEY,
        user_id    TEXT NOT NULL,
        date       TEXT NOT NULL,
        image_path TEXT,
        full_data  TEXT NOT NULL,
        generated_image_b64 TEXT,
        is_synced  INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // ── WRITE ────────────────────────────────────────────────────────────────────

  /// Insert a scan record. `isSynced = false` by default (pending Firestore push).
  Future<void> insertScan({
    required String id,
    required String userId,
    required DateTime date,
    required double auraScore,
    required double jawlineScore,
    required double skinScore,
    required double eyeScore,
    required double postureScore,
    required String rating,
    required List<String> highlights,
    String? imageUrl,
    bool isSynced = false,
    int weekIndex = 0,
    /// Full Gemini JSON for Firestore sync (optional)
    Map<String, dynamic>? fullData,
  }) async {
    final database = await db;
    await database.insert(
      _scanTable,
      {
        'id':            id,
        'user_id':       userId,
        'date':          date.toIso8601String(),
        'aura_score':    auraScore,
        'jawline_score': jawlineScore,
        'skin_score':    skinScore,
        'eye_score':     eyeScore,
        'posture_score': postureScore,
        'rating':        rating,
        'highlights':    jsonEncode(highlights),
        'image_url':     imageUrl,
        'is_synced':     isSynced ? 1 : 0,
        'week_index':    weekIndex,
        'full_data':     fullData != null ? jsonEncode(fullData) : null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Mark a record as synced to Firestore.
  Future<void> markSynced(String scanId) async {
    final database = await db;
    await database.update(
      _scanTable,
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [scanId],
    );
  }

  /// Update the image URL for a scan record.
  Future<void> updateImageUrl(String scanId, String imageUrl) async {
    final database = await db;
    await database.update(
      _scanTable,
      {'image_url': imageUrl},
      where: 'id = ?',
      whereArgs: [scanId],
    );
  }

  // ── OUTFIT HISTORY ───────────────────────────────────────────────────────────

  Future<void> insertOutfitScan({
    required String id,
    required String userId,
    required DateTime date,
    String? imagePath,
    required Map<String, dynamic> fullData,
    bool isSynced = false,
  }) async {
    final database = await db;
    await database.insert(
      _outfitTable,
      {
        'id': id,
        'user_id': userId,
        'date': date.toIso8601String(),
        'image_path': imagePath,
        'full_data': jsonEncode(fullData),
        'is_synced': isSynced ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllOutfitScans(String userId) async {
    final database = await db;
    return database.query(
      _outfitTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
  }

  Future<void> deleteOutfitScan(String id) async {
    final database = await db;
    await database.delete(
      _outfitTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedOutfitScans(String userId) async {
    final database = await db;
    return database.query(
      _outfitTable,
      where: 'is_synced = ? AND user_id = ?',
      whereArgs: [0, userId],
    );
  }

  Future<void> markOutfitSynced(String id) async {
    final database = await db;
    await database.update(
      _outfitTable,
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateOutfitImagePath(String id, String imagePath) async {
    final database = await db;
    await database.update(
      _outfitTable,
      {'image_path': imagePath},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── HAIRSTYLE HISTORY ───────────────────────────────────────────────────────────

  Future<void> insertHairStyleScan({
    required String id,
    required String userId,
    required DateTime date,
    String? imagePath,
    required Map<String, dynamic> fullData,
    String? generatedImageB64,
    bool isSynced = false,
  }) async {
    final database = await db;
    await database.insert(
      _hairStyleTable,
      {
        'id': id,
        'user_id': userId,
        'date': date.toIso8601String(),
        'image_path': imagePath,
        'full_data': jsonEncode(fullData),
        'generated_image_b64': generatedImageB64,
        'is_synced': isSynced ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllHairStyleScans(String userId) async {
    final database = await db;
    return database.query(
      _hairStyleTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
  }

  Future<void> deleteHairStyleScan(String id) async {
    final database = await db;
    await database.delete(
      _hairStyleTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedHairStyleScans(String userId) async {
    final database = await db;
    return database.query(
      _hairStyleTable,
      where: 'is_synced = ? AND user_id = ?',
      whereArgs: [0, userId],
    );
  }

  Future<void> markHairStyleSynced(String id) async {
    final database = await db;
    await database.update(
      _hairStyleTable,
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateHairStyleImagePath(String id, String imagePath) async {
    final database = await db;
    await database.update(
      _hairStyleTable,
      {'image_path': imagePath},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── CONFIG (key-value store) ─────────────────────────────────────────────────

  /// Read a config value by key. Returns null if not set.
  Future<String?> getConfig(String key) async {
    final database = await db;
    final rows = await database.query(
      _configTable,
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  /// Write (upsert) a config value.
  Future<void> setConfig(String key, String value) async {
    final database = await db;
    await database.insert(
      _configTable,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Delete a config entry.
  Future<void> deleteConfig(String key) async {
    final database = await db;
    await database.delete(
      _configTable,
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  // ── CHAT SESSIONS & MESSAGES ─────────────────────────────────────────────────

  Future<void> createChatSession({
    required String id,
    required String title,
    required DateTime updatedAt,
  }) async {
    final database = await db;
    await database.insert(
      _chatSessionsTable,
      {
        'id': id,
        'title': title,
        'updated_at': updatedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateChatSessionDate(String id, DateTime updatedAt) async {
    final database = await db;
    await database.update(
      _chatSessionsTable,
      {'updated_at': updatedAt.toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getChatSessions() async {
    final database = await db;
    return database.query(
      _chatSessionsTable,
      orderBy: 'updated_at DESC',
    );
  }

  Future<void> deleteChatSession(String id) async {
    final database = await db;
    await database.transaction((txn) async {
      await txn.delete(_chatTable, where: 'session_id = ?', whereArgs: [id]);
      await txn.delete(_chatSessionsTable, where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> insertChatMessage({
    required String id,
    required String sessionId,
    required String text,
    required bool isUser,
    required DateTime timestamp,
  }) async {
    final database = await db;
    await database.insert(
      _chatTable,
      {
        'id': id,
        'session_id': sessionId,
        'text': text,
        'is_user': isUser ? 1 : 0,
        'timestamp': timestamp.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getChatMessages(String sessionId) async {
    final database = await db;
    return database.query(
      _chatTable,
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );
  }

  Future<void> clearAllData() async {
    final database = await db;
    await database.transaction((txn) async {
      await txn.delete(_scanTable);
      await txn.delete(_configTable);
      await txn.delete(_chatTable);
      await txn.delete(_chatSessionsTable);
    });
  }

  // ── READ ─────────────────────────────────────────────────────────────────────

  /// Returns all scans for the user, newest first. Auto-migrates orphan records.
  Future<List<Map<String, dynamic>>> getAllScans(String userId) async {
    final database = await db;
    // Auto-migrate old scans that have no user_id to the current user
    if (userId.isNotEmpty) {
      await database.update(
        _scanTable,
        {'user_id': userId},
        where: 'user_id = ?',
        whereArgs: [''],
      );
    }

    return database.query(
      _scanTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
  }

  /// Returns scans that have NOT been pushed to Firestore yet for the user.
  Future<List<Map<String, dynamic>>> getUnsyncedScans(String userId) async {
    final database = await db;
    return database.query(
      _scanTable,
      where: 'is_synced = ? AND user_id = ?',
      whereArgs: [0, userId],
    );
  }

  /// Check if a scan with the given ID already exists locally.
  Future<bool> exists(String scanId) async {
    final database = await db;
    final rows = await database.query(
      _scanTable,
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [scanId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  // ── PARSE helpers ─────────────────────────────────────────────────────────────

  static List<String> parseHighlights(dynamic raw) {
    if (raw == null) return [];
    if (raw is String) {
      final decoded = jsonDecode(raw);
      if (decoded is List) return List<String>.from(decoded);
    }
    return [];
  }

  static Map<String, dynamic>? parseFullData(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }
    return null;
  }
}
