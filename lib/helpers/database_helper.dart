import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // Cache untuk active target
  Map<String, dynamic>? _cachedActiveTarget;
  DateTime? _activeTargetCacheTime;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'emonic.db');
    // await deleteDatabase(path); // HAPUS BARIS INI!

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Tambahkan untuk handle version upgrade
      readOnly: false,
      singleInstance: true,
    );
  }

  // Tambahkan method untuk handle database upgrade
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      // Handle database schema changes jika diperlukan
      print('Database upgraded from version $oldVersion to $newVersion');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create daily_usage table
    await db.execute('''
      CREATE TABLE daily_usage (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        golongan TEXT NOT NULL,
        parameter TEXT NOT NULL,
        nilai REAL NOT NULL,
        tanggal TEXT NOT NULL,
        catatan TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create targets table
    await db.execute('''
      CREATE TABLE targets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        golongan TEXT NOT NULL,
        parameter TEXT NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        target REAL NOT NULL,
        period TEXT NOT NULL DEFAULT '1 Bulan',
        duration_days INTEGER NOT NULL DEFAULT 30,
        createdAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
        status TEXT DEFAULT 'active' CHECK(status IN ('active', 'completed', 'cancelled', 'paused'))
      )
    ''');

    // Indexes untuk performa
    await db.execute(
        'CREATE INDEX idx_daily_usage_user_tanggal ON daily_usage(userId, tanggal DESC)');
    await db.execute(
        'CREATE INDEX idx_daily_usage_user_parameter ON daily_usage(userId, parameter)');
    await db.execute(
        'CREATE INDEX idx_daily_usage_composite ON daily_usage(userId, parameter, tanggal DESC)');
    await db.execute(
        'CREATE INDEX idx_targets_user_status ON targets(userId, status)');
    await db.execute(
        'CREATE INDEX idx_targets_active ON targets(status, endDate) WHERE status = "active"');
  }

  // ===== DAILY USAGE METHODS =====
  Future<int> insertDailyUsage(Map<String, dynamic> usage) async {
    final db = await database;

    if (!usage.containsKey('userId') ||
        usage['userId'] == null ||
        usage['userId'].toString().isEmpty) {
      throw Exception('userId is required');
    }

    usage['created_at'] = DateTime.now().toIso8601String();
    usage['updated_at'] = DateTime.now().toIso8601String();

    return await db.insert('daily_usage', usage);
  }

  Future<void> insertDailyUsageBatch(
      List<Map<String, dynamic>> usageList) async {
    final db = await database;
    final batch = db.batch();

    for (final usage in usageList) {
      if (!usage.containsKey('userId') || usage['userId'] == null) {
        throw Exception('userId is required for all usage entries');
      }

      usage['created_at'] = DateTime.now().toIso8601String();
      usage['updated_at'] = DateTime.now().toIso8601String();

      batch.insert('daily_usage', usage);
    }

    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getDailyUsage([String? userId]) async {
    final db = await database;

    if (userId != null && userId.isNotEmpty) {
      return await db.query(
        'daily_usage',
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'tanggal DESC, created_at DESC',
      );
    } else {
      return await db.query(
        'daily_usage',
        orderBy: 'tanggal DESC, created_at DESC',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getDailyUsageByDateRange(
    String startDate,
    String endDate, [
    String? userId,
  ]) async {
    final db = await database;

    if (userId != null && userId.isNotEmpty) {
      return await db.query(
        'daily_usage',
        where: 'tanggal BETWEEN ? AND ? AND userId = ?',
        whereArgs: [startDate, endDate, userId],
        orderBy: 'tanggal DESC, created_at DESC',
      );
    } else {
      return await db.query(
        'daily_usage',
        where: 'tanggal BETWEEN ? AND ?',
        whereArgs: [startDate, endDate],
        orderBy: 'tanggal DESC, created_at DESC',
      );
    }
  }

  Future<double> getTotalUsageByDate(String date, [String? userId]) async {
    final db = await database;

    String query;
    List<dynamic> args;

    if (userId != null && userId.isNotEmpty) {
      query = '''SELECT SUM(nilai) as total FROM daily_usage 
                 WHERE tanggal = ? AND parameter = "Daya Listrik (kWh)" AND userId = ?''';
      args = [date, userId];
    } else {
      query = '''SELECT SUM(nilai) as total FROM daily_usage 
                 WHERE tanggal = ? AND parameter = "Daya Listrik (kWh)"''';
      args = [date];
    }

    final result = await db.rawQuery(query, args);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> updateDailyUsage(int id, Map<String, dynamic> usage) async {
    final db = await database;
    usage['updated_at'] = DateTime.now().toIso8601String();

    return await db.update(
      'daily_usage',
      usage,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteDailyUsage(int id) async {
    final db = await database;
    invalidateActiveTargetCache();

    return await db.delete(
      'daily_usage',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getLast7DaysUsage([String? userId]) async {
    final db = await database;
    final sevenDaysAgo = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().subtract(const Duration(days: 7)));

    String query;
    List<dynamic> args;

    if (userId != null && userId.isNotEmpty) {
      query = '''SELECT tanggal, SUM(nilai) as total 
                 FROM daily_usage 
                 WHERE tanggal >= ? AND parameter = ? AND userId = ?
                 GROUP BY tanggal
                 ORDER BY tanggal ASC''';
      args = [sevenDaysAgo, 'Daya Listrik (kWh)', userId];
    } else {
      query = '''SELECT tanggal, SUM(nilai) as total 
                 FROM daily_usage 
                 WHERE tanggal >= ? AND parameter = ?
                 GROUP BY tanggal
                 ORDER BY tanggal ASC''';
      args = [sevenDaysAgo, 'Daya Listrik (kWh)'];
    }

    return await db.rawQuery(query, args);
  }

  Future<Map<String, double>> getDailyTotals(int days, [String? userId]) async {
    final db = await database;
    final startDate = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().subtract(Duration(days: days)));

    String query;
    List<dynamic> args;

    if (userId != null && userId.isNotEmpty) {
      query = '''SELECT tanggal, SUM(nilai) as total 
                 FROM daily_usage 
                 WHERE tanggal >= ? AND parameter = "Daya Listrik (kWh)" AND userId = ?
                 GROUP BY tanggal
                 ORDER BY tanggal ASC''';
      args = [startDate, userId];
    } else {
      query = '''SELECT tanggal, SUM(nilai) as total 
                 FROM daily_usage 
                 WHERE tanggal >= ? AND parameter = "Daya Listrik (kWh)"
                 GROUP BY tanggal
                 ORDER BY tanggal ASC''';
      args = [startDate];
    }

    final result = await db.rawQuery(query, args);

    Map<String, double> dailyTotals = {};
    for (var row in result) {
      dailyTotals[row['tanggal'] as String] = (row['total'] as num).toDouble();
    }

    return dailyTotals;
  }

  // ===== TARGETS METHODS =====
  Future<int> insertTarget(Map<String, dynamic> target) async {
    final db = await database;

    if (!target.containsKey('userId') || target['userId'] == null) {
      throw Exception('userId is required for target');
    }

    target['createdAt'] = DateTime.now().toIso8601String();
    target['updatedAt'] = DateTime.now().toIso8601String();

    if (target['target'] is String) {
      target['target'] = double.tryParse(target['target']) ?? 0.0;
    }

    invalidateActiveTargetCache();
    return await db.insert('targets', target);
  }

  Future<List<Map<String, dynamic>>> getTargetsByUser(String userId) async {
    final db = await database;
    return await db.query(
      'targets',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllTargets() async {
    final db = await database;
    return await db.query('targets', orderBy: 'createdAt DESC');
  }

  Future<Map<String, dynamic>?> getActiveTarget() async {
    // Check cache first
    if (_cachedActiveTarget != null &&
        _activeTargetCacheTime != null &&
        DateTime.now().difference(_activeTargetCacheTime!) <
            _cacheValidDuration) {
      return _cachedActiveTarget;
    }

    final db = await database;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final result = await db.rawQuery(
      '''SELECT * FROM targets 
         WHERE DATE(endDate) >= DATE(?) AND status = "active" 
         ORDER BY createdAt DESC LIMIT 1''',
      [today],
    );

    _cachedActiveTarget = result.isNotEmpty ? result.first : null;
    _activeTargetCacheTime = DateTime.now();

    return _cachedActiveTarget;
  }

  Future<Map<String, dynamic>?> getActiveTargetByUser(String userId) async {
    final db = await database;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final result = await db.rawQuery(
      '''SELECT * FROM targets 
         WHERE DATE(endDate) >= DATE(?) AND status = "active" AND userId = ?
         ORDER BY createdAt DESC LIMIT 1''',
      [today, userId],
    );

    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateTarget(int id, Map<String, dynamic> target) async {
    final db = await database;

    target['updatedAt'] = DateTime.now().toIso8601String();

    if (target['target'] is String) {
      target['target'] = double.tryParse(target['target']) ?? 0.0;
    }

    invalidateActiveTargetCache();

    return await db.update(
      'targets',
      target,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteTarget(int id, [String? userId]) async {
    final db = await database;
    invalidateActiveTargetCache();

    if (userId != null && userId.isNotEmpty) {
      return await db.delete(
        'targets',
        where: 'id = ? AND userId = ?',
        whereArgs: [id, userId],
      );
    } else {
      return await db.delete(
        'targets',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  // ===== CACHE MANAGEMENT =====
  void invalidateActiveTargetCache() {
    _cachedActiveTarget = null;
    _activeTargetCacheTime = null;
  }

  // ===== TRANSACTION SUPPORT =====
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }

  // ===== UTILITY METHODS =====
  Future<List<Map<String, dynamic>>> getUsageInDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
    final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

    return await db.query(
      'daily_usage',
      where: 'userId = ? AND tanggal BETWEEN ? AND ?',
      whereArgs: [userId, startDateStr, endDateStr],
      orderBy: 'tanggal DESC, created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getRecentUsage(
    String userId,
    int limit,
  ) async {
    final db = await database;

    return await db.query(
      'daily_usage',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'tanggal DESC, created_at DESC',
      limit: limit,
    );
  }

  Future<void> clearUserData(String userId) async {
    await transaction((txn) async {
      await txn.delete('daily_usage', where: 'userId = ?', whereArgs: [userId]);
      await txn.delete('targets', where: 'userId = ?', whereArgs: [userId]);
    });

    invalidateActiveTargetCache();
  }

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
      invalidateActiveTargetCache();
    }
  }
}
