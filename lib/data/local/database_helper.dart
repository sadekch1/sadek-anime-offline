import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/anime.dart';
import '../../domain/entities/anime_filter.dart';
import '../../domain/entities/library_entry.dart';
import '../models/anime_mapper.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;
  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    final path = p.join(dir.path, 'anime.db');
    final file = File(path);

    // First launch: copy the pre-packaged database out of the APK assets.
    if (!file.existsSync() || file.lengthSync() == 0) {
      try {
        final data = await rootBundle.load('assets/db/anime.db');
        if (data.lengthInBytes > 0) {
          await file.writeAsBytes(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
            flush: true,
          );
        }
      } catch (_) {/* fall through to an empty DB */}
    }

    return openDatabase(
      path,
      version: 2, // v2: user_lists table (my library)
      onCreate: (db, v) => _createSchema(db),
      onUpgrade: (db, oldV, newV) => _createSchema(db),
      onOpen: (db) => _createSchema(db), // idempotent safety net
    );
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS anime(
        mal_id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        title_en TEXT,
        search TEXT NOT NULL,
        type TEXT, episodes INTEGER, status TEXT,
        year INTEGER, season TEXT, score REAL,
        genres TEXT, studios TEXT, synopsis TEXT,
        image_url TEXT, thumb_url TEXT,
        detailed INTEGER NOT NULL DEFAULT 0,
        title_ar TEXT, synopsis_ar TEXT,
        ar_checked INTEGER NOT NULL DEFAULT 0
      )''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_anime_search ON anime(search)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_anime_score ON anime(score DESC)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_anime_status ON anime(status, score)');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS characters(
        anime_id INTEGER NOT NULL,
        char_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        role TEXT, image_url TEXT,
        PRIMARY KEY(anime_id, char_id)
      )''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_lists(
        mal_id INTEGER PRIMARY KEY,
        status TEXT NOT NULL,
        last_episode INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL DEFAULT 0
      )''');
    await _ensureColumns(db);
  }

  /// Migrates the pre-packaged DB (built without the Arabic columns).
  Future<void> _ensureColumns(Database db) async {
    final cols = (await db.rawQuery('PRAGMA table_info(anime)'))
        .map((r) => r['name'] as String)
        .toSet();
    if (!cols.contains('title_ar')) {
      await db.execute('ALTER TABLE anime ADD COLUMN title_ar TEXT');
    }
    if (!cols.contains('synopsis_ar')) {
      await db.execute('ALTER TABLE anime ADD COLUMN synopsis_ar TEXT');
    }
    if (!cols.contains('ar_checked')) {
      await db.execute(
          'ALTER TABLE anime ADD COLUMN ar_checked INTEGER NOT NULL DEFAULT 0');
    }
  }

  Future<List<Anime>> query({
    String? where,
    List<Object?>? args,
    String? orderBy,
    int? limit,
  }) async {
    final db = await database;
    final rows = await db.query('anime',
        where: where, whereArgs: args, orderBy: orderBy, limit: limit);
    return rows.map(animeFromRow).toList();
  }

  /// Multi-token search: every word must appear in title/synonyms.
  Future<List<Anime>> search(String q, {int limit = 60}) async {
    final tokens = q
        .toLowerCase()
        .replaceAll(RegExp(r'[%_]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return [];
    final db = await database;
    final where = tokens.map((_) => 'search LIKE ?').join(' AND ');
    final rows = await db.rawQuery(
      'SELECT * FROM anime WHERE $where '
      'ORDER BY (search LIKE ?) DESC, score DESC LIMIT ?',
      [...tokens.map((t) => '%$t%'), '${tokens.first}%', limit],
    );
    return rows.map(animeFromRow).toList();
  }

  Future<Anime?> byId(int id) async {
    final r = await query(where: 'mal_id = ?', args: [id], limit: 1);
    return r.isEmpty ? null : r.first;
  }

  Future<void> upsert(Anime a) async {
    final db = await database;
    final row = animeToRow(a);
    final search = row.remove('search'); // keep local synonyms on update
    final n = await db
        .update('anime', row, where: 'mal_id = ?', whereArgs: [a.malId]);
    if (n == 0) {
      row['search'] = search;
      await db.insert('anime', row,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> upsertAll(List<Anime> list) async {
    for (final a in list) {
      await upsert(a);
    }
  }

  Future<List<AnimeCharacter>> characters(int animeId) async {
    final db = await database;
    final rows = await db.query('characters',
        where: 'anime_id = ?', whereArgs: [animeId]);
    return rows
        .map((r) => AnimeCharacter(
              id: r['char_id'] as int,
              name: r['name'] as String,
              role: r['role'] as String?,
              imageUrl: r['image_url'] as String?,
            ))
        .toList();
  }

  Future<void> saveCharacters(int animeId, List<AnimeCharacter> list) async {
    final db = await database;
    final batch = db.batch();
    for (final c in list) {
      batch.insert(
        'characters',
        {
          'anime_id': animeId,
          'char_id': c.id,
          'name': c.name,
          'role': c.role,
          'image_url': c.imageUrl,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> saveArabic(int id, String? title, String? overview) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE anime SET title_ar = ?, synopsis_ar = ?, ar_checked = 1, '
      'search = CASE WHEN ? IS NOT NULL AND instr(search, ?) = 0 '
      "THEN search || ' ' || lower(?) ELSE search END WHERE mal_id = ?",
      [title, overview, title, title, title, id],
    );
  }


  // ---- v2: advanced filter (offline, local SQLite) ----
  // Genres are stored as '|'-separated text, so a genre match is a LIKE
  // on '%|Genre|%' (with the column padded). AND = every genre must match,
  // OR = any genre matches.
  List<String> _filterClauses(AnimeFilter f, List<Object?> args) {
    final where = <String>[];
    if (f.genres.isNotEmpty) {
      final parts = f.genres.map((g) {
        args.add('%|$g|%');
        return "('|' || genres || '|') LIKE ?";
      }).toList();
      where.add(f.genreMatchAll ? '(${parts.join(' AND ')})' : '(${parts.join(' OR ')})');
    }
    if (f.types.isNotEmpty) {
      where.add('type IN (${List.filled(f.types.length, '?').join(',')})');
      args.addAll(f.types);
    }
    if (f.statuses.isNotEmpty) {
      where.add('status IN (${List.filled(f.statuses.length, '?').join(',')})');
      args.addAll(f.statuses);
    }
    if (f.seasons.isNotEmpty) {
      where.add('season IN (${List.filled(f.seasons.length, '?').join(',')})');
      args.addAll(f.seasons);
    }
    final y0 = f.effectiveYearStart;
    if (y0 != null) {
      where.add('year >= ?');
      args.add(y0);
    }
    // Upper bound always applies (titles with no year are kept).
    where.add('(year IS NULL OR year <= ?)');
    args.add(f.yearEnd);
    if (f.minScore > 0) {
      where.add('score >= ?');
      args.add(f.minScore);
    }
    switch (f.episodeLength) {
      case 'short':
        where.add('(episodes IS NOT NULL AND episodes <= 13)');
        break;
      case 'medium':
        where.add('(episodes IS NOT NULL AND episodes > 13 AND episodes <= 26)');
        break;
      case 'long':
        where.add('(episodes IS NOT NULL AND episodes > 26)');
        break;
    }
    return where;
  }

  String _filterOrderBy(AnimeFilter f) {
    switch (f.sort) {
      case 'newest':
        return 'year DESC, score DESC';
      case 'oldest':
        return 'year ASC, score DESC';
      case 'name':
        return 'title ASC';
      case 'score':
      default:
        return 'score DESC';
    }
  }

  Future<List<Anime>> searchFiltered(String q, AnimeFilter f,
      {int limit = 120}) async {
    final db = await database;
    final args = <Object?>[];
    final where = _filterClauses(f, args);
    final tokens = q
        .toLowerCase()
        .replaceAll(RegExp(r'[%_]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    for (final tok in tokens) {
      where.add('search LIKE ?');
      args.add('%$tok%');
    }
    if (f.onlyFavorites) {
      where.add(
          "mal_id IN (SELECT mal_id FROM user_lists WHERE status = 'favorite')");
    }
    if (f.hideWatched) {
      where.add(
          "mal_id NOT IN (SELECT mal_id FROM user_lists WHERE status = 'watched')");
    }
    final sql =
        'SELECT * FROM anime${where.isEmpty ? '' : ' WHERE ${where.join(' AND ')}'} '
        'ORDER BY ${_filterOrderBy(f)} LIMIT ?';
    args.add(limit);
    final rows = await db.rawQuery(sql, args);
    return rows.map(animeFromRow).toList();
  }

  Future<int> countFiltered(String q, AnimeFilter f) async {
    final db = await database;
    final args = <Object?>[];
    final where = _filterClauses(f, args);
    final tokens = q
        .toLowerCase()
        .replaceAll(RegExp(r'[%_]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    for (final tok in tokens) {
      where.add('search LIKE ?');
      args.add('%$tok%');
    }
    if (f.onlyFavorites) {
      where.add(
          "mal_id IN (SELECT mal_id FROM user_lists WHERE status = 'favorite')");
    }
    if (f.hideWatched) {
      where.add(
          "mal_id NOT IN (SELECT mal_id FROM user_lists WHERE status = 'watched')");
    }
    final sql =
        'SELECT COUNT(*) AS c FROM anime${where.isEmpty ? '' : ' WHERE ${where.join(' AND ')}'}';
    final rows = await db.rawQuery(sql, args);
    return (rows.first['c'] as int?) ?? 0;
  }

  // ---- v2: my library ----
  Future<Map<int, LibraryEntry>> getLibrary() async {
    final db = await database;
    final rows = await db.query('user_lists');
    return {
      for (final r in rows)
        (r['mal_id'] as int): LibraryEntry.fromMap(r),
    };
  }

  Future<LibraryEntry?> getLibraryEntry(int malId) async {
    final db = await database;
    final rows = await db.query('user_lists',
        where: 'mal_id = ?', whereArgs: [malId], limit: 1);
    return rows.isEmpty ? null : LibraryEntry.fromMap(rows.first);
  }

  Future<void> setLibraryStatus(int malId, String status) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = await getLibraryEntry(malId);
    await db.insert(
      'user_lists',
      {
        'mal_id': malId,
        'status': status,
        'last_episode': existing?.lastEpisode ?? 0,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> setLastEpisode(int malId, int episode) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = await getLibraryEntry(malId);
    if (existing == null) {
      await db.insert('user_lists', {
        'mal_id': malId,
        'status': 'watching',
        'last_episode': episode,
        'updated_at': now,
      });
    } else {
      await db.update(
        'user_lists',
        {'last_episode': episode, 'updated_at': now},
        where: 'mal_id = ?',
        whereArgs: [malId],
      );
    }
  }

  /// Upsert used by Firebase sync (keeps the incoming updated_at).
  Future<void> upsertLibraryEntry(LibraryEntry e) async {
    final db = await database;
    await db.insert('user_lists', e.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> removeFromLibrary(int malId) async {
    final db = await database;
    await db.delete('user_lists', where: 'mal_id = ?', whereArgs: [malId]);
  }

  Future<Map<String, int>> libraryCounts() async {
    final db = await database;
    final rows = await db
        .rawQuery('SELECT status, COUNT(*) AS c FROM user_lists GROUP BY status');
    final out = <String, int>{
      for (final s in libraryStatuses) s: 0,
    };
    for (final r in rows) {
      out[(r['status'] as String?) ?? ''] = (r['c'] as int?) ?? 0;
    }
    return out;
  }

  Future<List<Anime>> libraryAnime(String status) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT a.* FROM anime a JOIN user_lists u ON u.mal_id = a.mal_id '
      'WHERE u.status = ? ORDER BY u.updated_at DESC',
      [status],
    );
    return rows.map(animeFromRow).toList();
  }

  Future<Map<String, int>> stats() async {
    final db = await database;
    Future<int> count(String sql) async =>
        Sqflite.firstIntValue(await db.rawQuery(sql)) ?? 0;
    return {
      'anime': await count('SELECT COUNT(*) FROM anime'),
      'detailed': await count('SELECT COUNT(*) FROM anime WHERE detailed = 1'),
      'characters': await count('SELECT COUNT(*) FROM characters'),
      'arabic': await count('SELECT COUNT(*) FROM anime WHERE synopsis_ar IS NOT NULL'),
    };
  }
}
