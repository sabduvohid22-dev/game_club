import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import '../models/station.dart';
import '../models/receipt.dart';
import '../models/app_settings.dart';
import '../models/debtor.dart';

/// Barcha ma'lumotlar shu telefonda mahalliy (SQLite) saqlanadi.
class DbService {
  DbService._();
  static final DbService instance = DbService._();

  Database? _db;

  // Web uchun xotira (RAM) bazasi
  static final List<Station> _webStations = [];
  static final List<Receipt> _webReceipts = [];
  static final List<Debtor> _webDebtors = [];
  static AppSettings _webSettings = const AppSettings();

  Future<Database?> get db async {
    if (kIsWeb) return null;
    _db ??= await _initDb();
    return _db;
  }

  Future<Database?> _initDb() async {
    if (kIsWeb) return null;

    if (io.Platform.isWindows || io.Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // Yangi xavfsiz yo'lni aniqlash (AppData)
    final appDir = await getApplicationSupportDirectory();
    final dbDir = io.Directory(join(appDir.path, 'databases'));
    if (!await dbDir.exists()) await dbDir.create(recursive: true);
    final path = join(dbDir.path, 'gameclub.db');

    // MIGRATSIYA: Agar loyiha ichida eski baza qolgan bo'lsa, uni ko'chiramiz
    try {
      final oldDbPath = join(io.Directory.current.path, '.dart_tool', 'sqflite_common_ffi', 'databases', 'gameclub.db');
      final oldFile = io.File(oldDbPath);
      if (await oldFile.exists()) {
        final newFile = io.File(path);
        if (!await newFile.exists()) {
          await oldFile.copy(path);
          print("DATABASE MIGRATED TO: $path");
        }
      }
    } catch (e) {
      print("Migration error: $e");
    }

    return openDatabase(
      path,
      version: 5,
      onCreate: (db, version) => _createDb(db, version),
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try { await db.execute('ALTER TABLE debtors ADD COLUMN stationName TEXT'); } catch (_) {}
        }
        if (oldVersion < 3) {
          try { await db.execute('ALTER TABLE stations ADD COLUMN createdOrder INTEGER'); } catch (_) {}
        }
        if (oldVersion < 4) {
          try {
            await db.execute('ALTER TABLE stations ADD COLUMN barAmount REAL');
            await db.execute('ALTER TABLE receipts ADD COLUMN barAmount REAL');
          } catch (_) {}
        }
        if (oldVersion < 5) {
          try {
            final columns = await db.rawQuery('PRAGMA table_info(debtors)');
            if (!columns.any((c) => c['name'] == 'history')) {
              await db.execute('ALTER TABLE debtors ADD COLUMN history TEXT');
            }
          } catch (_) {}
        }
      },
    );
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('CREATE TABLE stations(id TEXT PRIMARY KEY, name TEXT, type TEXT, tariffPerHour INTEGER, status TEXT, mode TEXT, startTime TEXT, endTime TEXT, plannedHours REAL, plannedCost REAL, createdOrder INTEGER, barAmount REAL)');
    await db.execute('CREATE TABLE receipts(id INTEGER PRIMARY KEY AUTOINCREMENT, receiptNumber INTEGER, stationId TEXT, stationName TEXT, stationType TEXT, tariffPerHour INTEGER, startTime TEXT, endTime TEXT, durationSeconds INTEGER, total REAL, barAmount REAL, qrData TEXT)');
    await db.execute('CREATE TABLE settings(id INTEGER PRIMARY KEY CHECK (id = 0), clubName TEXT, clubAddress TEXT, qrDefault TEXT, qrLogoBase64 TEXT)');
    await db.execute('CREATE TABLE debtors(id TEXT PRIMARY KEY, name TEXT, phone TEXT, amount REAL, stationName TEXT, history TEXT, createdAt TEXT, paid INTEGER)');
  }

  // ---------- Stations ----------
  Future<void> upsertStation(Station s, {int? order}) async {
    if (kIsWeb) {
      final idx = _webStations.indexWhere((x) => x.id == s.id);
      final updated = s.copyWith(createdOrder: order ?? s.createdOrder);
      if (idx != -1) {
        _webStations[idx] = updated;
      } else {
        _webStations.add(updated);
      }
      return;
    }
    final database = await db;
    if (database == null) {
      return;
    }
    final map = s.toMap();
    if (order != null) {
      map['createdOrder'] = order;
    }
    await database.insert('stations', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteStation(String id) async {
    if (kIsWeb) {
      _webStations.removeWhere((x) => x.id == id);
      return;
    }
    final database = await db;
    await database?.delete('stations', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Station>> getStations() async {
    if (kIsWeb) return List.from(_webStations..sort((a,b) => (a.createdOrder??0).compareTo(b.createdOrder??0)));
    final database = await db;
    if (database == null) return [];
    final rows = await database.query('stations', orderBy: 'createdOrder ASC');
    return rows.map((r) => Station.fromMap(r)).toList();
  }

  // ---------- Receipts ----------
  Future<void> insertReceipt(Receipt r) async {
    if (kIsWeb) { _webReceipts.add(r); return; }
    final database = await db;
    await database?.insert('receipts', r.toMap()..remove('id'));
  }

  Future<List<Receipt>> getReceipts() async {
    if (kIsWeb) return List.from(_webReceipts.reversed);
    final database = await db;
    if (database == null) return [];
    final rows = await database.query('receipts', orderBy: 'id DESC');
    return rows.map((r) => Receipt.fromMap(r)).toList();
  }

  Future<int> nextReceiptNumber() async {
    if (kIsWeb) return _webReceipts.length + 1;
    final database = await db;
    if (database == null) return 1;
    final result = await database.rawQuery('SELECT MAX(receiptNumber) as m FROM receipts');
    final m = result.first['m'];
    return (m == null ? 0 : m as int) + 1;
  }

  Future<int> todayReceiptCount() async {
    if (kIsWeb) {
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      return _webReceipts.where((r) => r.endTime.toIso8601String().startsWith(todayStr)).length;
    }
    final database = await db;
    if (database == null) return 0;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final rows = await database.query('receipts', where: 'endTime LIKE ?', whereArgs: ['$todayStr%']);
    return rows.length;
  }

  Future<double> todayTotal() async {
    if (kIsWeb) {
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      return _webReceipts
          .where((r) => r.endTime.toIso8601String().startsWith(todayStr))
          .fold<double>(0.0, (sum, r) => sum + r.total);
    }
    final database = await db;
    if (database == null) return 0.0;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final rows = await database.query('receipts', where: 'endTime LIKE ?', whereArgs: ['$todayStr%']);
    return rows.fold<double>(0.0, (sum, r) => sum + (r['total'] as num).toDouble());
  }

  // ---------- Settings ----------
  Future<AppSettings> getSettings() async {
    if (kIsWeb) return _webSettings;
    final database = await db;
    if (database == null) return const AppSettings();
    final rows = await database.query('settings', where: 'id = 0');
    return rows.isEmpty ? const AppSettings() : AppSettings.fromMap(rows.first);
  }

  Future<void> saveSettings(AppSettings s) async {
    if (kIsWeb) { _webSettings = s; return; }
    final database = await db;
    final map = s.toMap()..['id'] = 0;
    await database?.insert('settings', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ---------- Debtors ----------
  Future<void> upsertDebtor(Debtor d) async {
    if (kIsWeb) {
      final idx = _webDebtors.indexWhere((x) => x.id == d.id);
      if (idx != -1) {
        _webDebtors[idx] = d;
      } else {
        _webDebtors.add(d);
      }
      return;
    }
    final database = await db;
    if (database == null) {
      return;
    }
    final map = d.toMap()..['paid'] = d.paid ? 1 : 0;
    await database.insert('debtors', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteDebtor(String id) async {
    if (kIsWeb) {
      _webDebtors.removeWhere((x) => x.id == id);
      return;
    }
    final database = await db;
    await database?.delete('debtors', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Debtor>> getDebtors() async {
    if (kIsWeb) return List.from(_webDebtors.reversed);
    final database = await db;
    if (database == null) return [];
    final rows = await database.query('debtors', orderBy: 'createdAt DESC');
    return rows.map((r) {
      final map = Map<String, dynamic>.from(r);
      map['paid'] = (map['paid'] as int) == 1;
      return Debtor.fromMap(map);
    }).toList();
  }
}
