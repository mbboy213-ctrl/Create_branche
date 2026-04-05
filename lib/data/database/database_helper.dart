import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/sensor_data.dart';
import '../../core/constants/app_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);
    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tableData} (
        id TEXT PRIMARY KEY,
        timestamp TEXT NOT NULL,
        value REAL NOT NULL,
        metric TEXT NOT NULL,
        raw_data TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_timestamp ON ${AppConstants.tableData}(timestamp)
    ''');

    await db.execute('''
      CREATE INDEX idx_metric ON ${AppConstants.tableData}(metric)
    ''');
  }

  Future<void> insertSensorData(SensorData data) async {
    final db = await database;
    await db.insert(
      AppConstants.tableData,
      data.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SensorData>> getAllData({int limit = 1000}) async {
    final db = await database;
    final maps = await db.query(
      AppConstants.tableData,
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return maps.map((m) => SensorData.fromMap(m)).toList();
  }

  Future<List<SensorData>> getDataInRange(DateTime from, DateTime to) async {
    final db = await database;
    final maps = await db.query(
      AppConstants.tableData,
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [from.toIso8601String(), to.toIso8601String()],
      orderBy: 'timestamp ASC',
    );
    return maps.map((m) => SensorData.fromMap(m)).toList();
  }

  Future<List<SensorData>> getDataByMetric(String metric, {int limit = 500}) async {
    final db = await database;
    final maps = await db.query(
      AppConstants.tableData,
      where: 'metric = ?',
      whereArgs: [metric],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return maps.map((m) => SensorData.fromMap(m)).toList();
  }

  Future<Map<String, double>> getMonthlyAverages(String metric) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT strftime('%Y-%m', timestamp) as month, AVG(value) as avg_val
      FROM ${AppConstants.tableData}
      WHERE metric = ?
      GROUP BY month
      ORDER BY month ASC
    ''', [metric]);

    return {for (final row in result) row['month'] as String: (row['avg_val'] as num).toDouble()};
  }

  Future<Map<String, double>> getYearlyAverages(String metric) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT strftime('%Y', timestamp) as year, AVG(value) as avg_val
      FROM ${AppConstants.tableData}
      WHERE metric = ?
      GROUP BY year
      ORDER BY year ASC
    ''', [metric]);

    return {for (final row in result) row['year'] as String: (row['avg_val'] as num).toDouble()};
  }

  Future<int> getDataCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM ${AppConstants.tableData}');
    return (result.first['cnt'] as int?) ?? 0;
  }

  Future<void> deleteOldData(int keepDays) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(Duration(days: keepDays));
    await db.delete(
      AppConstants.tableData,
      where: 'timestamp < ?',
      whereArgs: [cutoff.toIso8601String()],
    );
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(AppConstants.tableData);
  }

  Future<List<SensorData>> getRecentData(int minutes) async {
    final from = DateTime.now().subtract(Duration(minutes: minutes));
    return getDataInRange(from, DateTime.now());
  }
}
