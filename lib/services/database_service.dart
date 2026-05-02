import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

import '../models/download_task.dart';
import '../models/media_item.dart';
import '../models/playlist.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('volta.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return openDatabase(
      path,
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE media_items (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  artist TEXT,
  type TEXT NOT NULL,
  file_path TEXT NOT NULL UNIQUE,
  duration_ms INTEGER NOT NULL DEFAULT 0,
  thumbnail_path TEXT,
  added_at INTEGER NOT NULL,
  file_size_bytes INTEGER NOT NULL DEFAULT 0,
  source_url TEXT
)
''');
    await db.execute('''
CREATE TABLE playlists (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  is_smart INTEGER NOT NULL DEFAULT 0
)
''');
    await db.execute('''
CREATE TABLE playlist_items (
  playlist_id TEXT NOT NULL,
  media_item_id TEXT NOT NULL,
  position INTEGER NOT NULL,
  PRIMARY KEY (playlist_id, media_item_id),
  FOREIGN KEY (playlist_id) REFERENCES playlists(id) ON DELETE CASCADE,
  FOREIGN KEY (media_item_id) REFERENCES media_items(id) ON DELETE CASCADE
)
''');
    await db.execute('''
CREATE TABLE download_tasks (
  id TEXT PRIMARY KEY,
  url TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'queued',
  progress REAL NOT NULL DEFAULT 0.0,
  format TEXT NOT NULL DEFAULT 'best',
  file_path TEXT,
  error_message TEXT,
  created_at INTEGER NOT NULL
)
''');
    await db.execute('''
CREATE TABLE search_history (
  id TEXT PRIMARY KEY,
  url TEXT NOT NULL UNIQUE,
  searched_at INTEGER NOT NULL
)
''');
    await _createFts(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createFts(db);
    }
  }

  Future<void> _createFts(Database db) async {
    try {
      await db.execute('''
CREATE VIRTUAL TABLE IF NOT EXISTS media_fts USING fts5(
  title, artist,
  content=media_items,
  content_rowid=rowid
)
''');
      await db.execute('''
CREATE TRIGGER IF NOT EXISTS media_items_ai AFTER INSERT ON media_items BEGIN
  INSERT INTO media_fts(rowid, title, artist) VALUES (new.rowid, new.title, new.artist);
END
''');
      await db.execute('''
CREATE TRIGGER IF NOT EXISTS media_items_ad AFTER DELETE ON media_items BEGIN
  INSERT INTO media_fts(media_fts, rowid, title, artist) VALUES('delete', old.rowid, old.title, old.artist);
END
''');
    } on DatabaseException catch (error) {
      debugPrint('FTS5 unavailable, falling back to FTS4: $error');
      await _createFts4Fallback(db);
    }

    await db.execute('''
INSERT INTO media_fts(rowid, title, artist)
SELECT rowid, title, artist FROM media_items
WHERE rowid NOT IN (SELECT rowid FROM media_fts)
''');
  }

  Future<void> _createFts4Fallback(Database db) async {
    await db.execute('DROP TRIGGER IF EXISTS media_items_ai');
    await db.execute('DROP TRIGGER IF EXISTS media_items_ad');
    await db.execute('DROP TABLE IF EXISTS media_fts');
    await db.execute('''
CREATE VIRTUAL TABLE IF NOT EXISTS media_fts USING fts4(title, artist)
''');
    await db.execute('''
CREATE TRIGGER IF NOT EXISTS media_items_ai AFTER INSERT ON media_items BEGIN
  INSERT INTO media_fts(rowid, title, artist) VALUES (new.rowid, new.title, new.artist);
END
''');
    await db.execute('''
CREATE TRIGGER IF NOT EXISTS media_items_ad AFTER DELETE ON media_items BEGIN
  DELETE FROM media_fts WHERE rowid = old.rowid;
END
''');
  }

  Future<void> addSearchHistory(String url) async {
    final db = await instance.database;
    await db.insert(
      'search_history',
      {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'url': url,
        'searched_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getSearchHistory() async {
    final db = await instance.database;
    return await db.query('search_history',
        orderBy: 'searched_at DESC', limit: 20);
  }

  Future<void> clearSearchHistory() async {
    final db = await instance.database;
    await db.delete('search_history');
  }

  Future<void> upsertDownloadTask(DownloadTask task) async {
    final db = await instance.database;
    await db.insert(
      'download_tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DownloadTask>> getDownloadTasks() async {
    final db = await instance.database;
    final rows = await db.query('download_tasks', orderBy: 'created_at DESC');
    return rows.map(DownloadTask.fromMap).toList();
  }

  Future<void> upsertMediaItem(MediaItem item) async {
    final db = await instance.database;
    await db.insert(
      'media_items',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MediaItem>> getMediaItems() async {
    final db = await instance.database;
    final rows = await db.query('media_items', orderBy: 'added_at DESC');
    return rows.map(MediaItem.fromMap).toList();
  }

  Future<List<MediaItem>> searchMedia(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return getMediaItems();

    final db = await instance.database;
    try {
      final rows = await db.rawQuery(
        '''
SELECT media_items.* FROM media_fts
JOIN media_items ON media_items.rowid = media_fts.rowid
WHERE media_fts MATCH ?
ORDER BY media_items.added_at DESC
''',
        ['$trimmed*'],
      );
      return rows.map(MediaItem.fromMap).toList();
    } on DatabaseException catch (error) {
      debugPrint('FTS search failed, falling back to LIKE search: $error');
      final rows = await db.query(
        'media_items',
        where: 'title LIKE ? OR artist LIKE ?',
        whereArgs: ['%$trimmed%', '%$trimmed%'],
        orderBy: 'added_at DESC',
      );
      return rows.map(MediaItem.fromMap).toList();
    }
  }

  Future<void> deleteMediaItem(String id) async {
    final db = await instance.database;
    await db.delete('media_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deletePlaylist(String id) async {
    final db = await instance.database;
    await db.delete('playlists', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> upsertPlaylist(Playlist playlist) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.insert(
        'playlists',
        {
          'id': playlist.id,
          'name': playlist.name,
          'created_at': playlist.createdAt.millisecondsSinceEpoch,
          'is_smart': playlist.isSmart ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.delete(
        'playlist_items',
        where: 'playlist_id = ?',
        whereArgs: [playlist.id],
      );
      for (var index = 0; index < playlist.mediaItemIds.length; index++) {
        await txn.insert('playlist_items', {
          'playlist_id': playlist.id,
          'media_item_id': playlist.mediaItemIds[index],
          'position': index,
        });
      }
    });
  }

  Future<List<Playlist>> getPlaylists() async {
    final db = await instance.database;
    final rows = await db.query('playlists', orderBy: 'created_at DESC');
    final playlists = <Playlist>[];
    for (final row in rows) {
      final itemRows = await db.query(
        'playlist_items',
        columns: ['media_item_id'],
        where: 'playlist_id = ?',
        whereArgs: [row['id']],
        orderBy: 'position ASC',
      );
      playlists.add(
        Playlist.fromMap(
          row,
          itemRows.map((item) => item['media_item_id'] as String).toList(),
        ),
      );
    }
    return playlists;
  }

  Future<void> addMediaToPlaylist(String playlistId, String mediaItemId) async {
    final db = await instance.database;
    final count = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM playlist_items WHERE playlist_id = ?',
            [playlistId],
          ),
        ) ??
        0;
    await db.insert(
      'playlist_items',
      {
        'playlist_id': playlistId,
        'media_item_id': mediaItemId,
        'position': count,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<MediaItem>> getPlaylistItems(String playlistId) async {
    final db = await instance.database;
    final rows = await db.rawQuery(
      '''
SELECT media_items.* FROM playlist_items
JOIN media_items ON media_items.id = playlist_items.media_item_id
WHERE playlist_items.playlist_id = ?
ORDER BY playlist_items.position ASC
''',
      [playlistId],
    );
    return rows.map(MediaItem.fromMap).toList();
  }
}
