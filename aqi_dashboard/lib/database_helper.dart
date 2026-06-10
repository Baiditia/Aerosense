import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'models/aqi_history.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;

  final _store = intMapStoreFactory.store('aqi_history');

  Future<Database> get database async {
    if (_database != null) return _database!;

    if (kIsWeb) {
      _database = await databaseFactoryWeb.openDatabase('aqi_history.db');
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final dbPath = join(dir.path, 'aqi_history.db');

      _database = await databaseFactoryIo.openDatabase(dbPath);
    }

    return _database!;
  }

  Future<bool> saveIfNew(AqiHistoryRecord record) async {
    final db = await database;

    final finder = Finder(
      filter: Filter.and([Filter.equals('location', record.location)]),
      sortOrders: [SortOrder('recordedAt', false)],
      limit: 1,
    );

    final existing = await _store.findFirst(db, finder: finder);

    if (existing != null) {
      final data = existing.value;

      final lastDate = DateTime.parse(data['recordedAt'] as String);

      final sameDay =
          lastDate.year == record.recordedAt.year &&
          lastDate.month == record.recordedAt.month &&
          lastDate.day == record.recordedAt.day;

      if (sameDay) {
        await _store.record(existing.key).update(db, record.toMap());
        return true;
      }
    }

    await _store.add(db, record.toMap());

    return true;
  }

  Future<Map<String, List<AqiHistoryRecord>>> getAllHistory({
    int days = 30,
  }) async {
    final db = await database;

    final cutoff = DateTime.now().subtract(Duration(days: days));

    final finder = Finder(
      filter: Filter.greaterThan('recordedAt', cutoff.toIso8601String()),
      sortOrders: [SortOrder('recordedAt', false)],
    );

    final records = await _store.find(db, finder: finder);

    final Map<String, List<AqiHistoryRecord>> grouped = {};

    for (final r in records) {
      final item = AqiHistoryRecord.fromMap(r.value);

      grouped.putIfAbsent(item.location, () => []);

      grouped[item.location]!.add(item);
    }

    return grouped;
  }

  Future<List<AqiHistoryRecord>> getHistoryByLocation(
    String location, {
    int days = 30,
  }) async {
    final db = await database;

    final cutoff = DateTime.now().subtract(Duration(days: days));

    final finder = Finder(
      filter: Filter.and([
        Filter.equals('location', location),
        Filter.greaterThan('recordedAt', cutoff.toIso8601String()),
      ]),
      sortOrders: [SortOrder('recordedAt', false)],
    );

    final records = await _store.find(db, finder: finder);

    return records.map((e) => AqiHistoryRecord.fromMap(e.value)).toList();
  }

  Future<void> deleteHistoryForLocation(String location) async {
    final db = await database;

    await _store.delete(
      db,
      finder: Finder(filter: Filter.equals('location', location)),
    );
  }

  Future<void> deleteOldRecords({int keepDays = 60}) async {
    final db = await database;

    final cutoff = DateTime.now().subtract(Duration(days: keepDays));

    await _store.delete(
      db,
      finder: Finder(
        filter: Filter.lessThan('recordedAt', cutoff.toIso8601String()),
      ),
    );
  }
}
