import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'emonic.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      readOnly: false,
      singleInstance: true,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create daily_usage table dengan userId column
    await db.execute('''
      CREATE TABLE daily_usage (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        golongan TEXT NOT NULL,
        parameter TEXT NOT NULL,
        nilai REAL NOT NULL,
        tanggal TEXT NOT NULL,
        catatan TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Create targets table dengan struktur lengkap
    await db.execute('''
      CREATE TABLE targets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        golongan TEXT NOT NULL,
        parameter TEXT NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        target TEXT NOT NULL,
        period TEXT NOT NULL DEFAULT '1 Bulan',
        duration_days INTEGER NOT NULL DEFAULT 30,
        createdAt TEXT NOT NULL,
        status TEXT DEFAULT 'active' CHECK(status IN ('active', 'completed', 'cancelled'))
      )
    ''');

    // Add indexes untuk performa optimal
    await db.execute(
        'CREATE INDEX idx_daily_usage_user_tanggal ON daily_usage(userId, tanggal)');
    await db.execute(
        'CREATE INDEX idx_daily_usage_parameter ON daily_usage(parameter)');
    await db.execute(
        'CREATE INDEX idx_daily_usage_golongan ON daily_usage(golongan)');
    await db.execute(
        'CREATE INDEX idx_targets_user_date ON targets(userId, endDate)');
    await db.execute('CREATE INDEX idx_targets_status ON targets(status)');

    print('Database created successfully with version $version');
  }

  // ===== DAILY USAGE METHODS =====
  Future<int> insertDailyUsage(Map<String, dynamic> usage) async {
    try {
      final db = await database;
      // Ensure userId is included in the data
      if (!usage.containsKey('userId')) {
        throw Exception('userId is required for daily usage entry');
      }
      return await db.insert('daily_usage', usage);
    } catch (e) {
      print('Error inserting daily usage: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getDailyUsage([String? userId]) async {
    try {
      final db = await database;

      if (userId != null) {
        // Filter by userId if provided
        return await db.query(
          'daily_usage',
          where: 'userId = ?',
          whereArgs: [userId],
          orderBy: 'tanggal DESC, created_at DESC',
        );
      } else {
        // Return all data (for backward compatibility)
        return await db.query(
          'daily_usage',
          orderBy: 'tanggal DESC, created_at DESC',
        );
      }
    } catch (e) {
      print('Error getting daily usage: $e');

      // Handle case where userId column doesn't exist (backward compatibility)
      if (e.toString().contains('no such column: userId')) {
        try {
          final db = await database;
          return await db.query(
            'daily_usage',
            orderBy: 'tanggal DESC, created_at DESC',
          );
        } catch (e2) {
          print('Error in fallback query: $e2');
          return [];
        }
      }
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getDailyUsageByDateRange(
      String startDate, String endDate,
      [String? userId]) async {
    try {
      final db = await database;

      if (userId != null) {
        return await db.query(
          'daily_usage',
          where: 'tanggal >= ? AND tanggal <= ? AND userId = ?',
          whereArgs: [startDate, endDate, userId],
          orderBy: 'tanggal DESC',
        );
      } else {
        return await db.query(
          'daily_usage',
          where: 'tanggal >= ? AND tanggal <= ?',
          whereArgs: [startDate, endDate],
          orderBy: 'tanggal DESC',
        );
      }
    } catch (e) {
      print('Error getting daily usage by date range: $e');

      // Handle backward compatibility
      if (e.toString().contains('no such column: userId')) {
        try {
          final db = await database;
          return await db.query(
            'daily_usage',
            where: 'tanggal >= ? AND tanggal <= ?',
            whereArgs: [startDate, endDate],
            orderBy: 'tanggal DESC',
          );
        } catch (e2) {
          print('Error in fallback query: $e2');
          return [];
        }
      }
      return [];
    }
  }

  Future<double> getTotalUsageByDate(String date, [String? userId]) async {
    try {
      final db = await database;

      if (userId != null) {
        final result = await db.rawQuery(
            'SELECT SUM(nilai) as total FROM daily_usage WHERE tanggal = ? AND parameter = "Daya Listrik (kWh)" AND userId = ?',
            [date, userId]);
        return (result.first['total'] as double?) ?? 0.0;
      } else {
        final result = await db.rawQuery(
            'SELECT SUM(nilai) as total FROM daily_usage WHERE tanggal = ? AND parameter = "Daya Listrik (kWh)"',
            [date]);
        return (result.first['total'] as double?) ?? 0.0;
      }
    } catch (e) {
      print('Error getting total usage by date: $e');
      return 0.0;
    }
  }

  Future<int> updateDailyUsage(int id, Map<String, dynamic> usage) async {
    try {
      final db = await database;
      return await db.update(
        'daily_usage',
        usage,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error updating daily usage: $e');
      rethrow;
    }
  }

  Future<int> deleteDailyUsage(int id) async {
    try {
      final db = await database;
      return await db.delete(
        'daily_usage',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error deleting daily usage: $e');
      rethrow;
    }
  }

  // Query optimized dengan filtering
  Future<List<Map<String, dynamic>>> getDailyUsageOptimized({
    String? golongan,
    String? parameter,
    String? startDate,
    String? endDate,
    int? limit,
  }) async {
    try {
      final db = await database;

      List<String> conditions = [];
      List<dynamic> args = [];

      if (golongan != null) {
        conditions.add('golongan = ?');
        args.add(golongan);
      }

      if (parameter != null) {
        conditions.add('parameter = ?');
        args.add(parameter);
      }

      if (startDate != null && endDate != null) {
        conditions.add('tanggal BETWEEN ? AND ?');
        args.addAll([startDate, endDate]);
      }

      String whereClause =
          conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
      String limitClause = limit != null ? 'LIMIT $limit' : '';

      return await db.rawQuery('''
        SELECT * FROM daily_usage 
        $whereClause 
        ORDER BY tanggal DESC, created_at DESC 
        $limitClause
      ''', args);
    } catch (e) {
      print('Error in optimized daily usage query: $e');
      return [];
    }
  }

  // Method untuk mendapatkan usage data 7 hari terakhir (optimized untuk chart)
  Future<List<Map<String, dynamic>>> getLast7DaysUsage() async {
    try {
      final db = await database;
      final sevenDaysAgo = DateFormat('yyyy-MM-dd')
          .format(DateTime.now().subtract(const Duration(days: 7)));

      return await db.query(
        'daily_usage',
        where: 'tanggal >= ? AND parameter = ?',
        whereArgs: [sevenDaysAgo, 'Daya Listrik (kWh)'],
        orderBy: 'tanggal ASC',
      );
    } catch (e) {
      print('Error getting last 7 days usage: $e');
      return [];
    }
  }

  // Method untuk mendapatkan total usage per hari (optimized)
  Future<Map<String, double>> getDailyTotals(int days) async {
    try {
      final db = await database;
      final startDate = DateFormat('yyyy-MM-dd')
          .format(DateTime.now().subtract(Duration(days: days)));

      final result = await db.rawQuery('''
        SELECT tanggal, SUM(nilai) as total 
        FROM daily_usage 
        WHERE tanggal >= ? AND parameter = "Daya Listrik (kWh)"
        GROUP BY tanggal
        ORDER BY tanggal ASC
      ''', [startDate]);

      Map<String, double> dailyTotals = {};
      for (var row in result) {
        dailyTotals[row['tanggal'] as String] =
            (row['total'] as num).toDouble();
      }

      return dailyTotals;
    } catch (e) {
      print('Error getting daily totals: $e');
      return {};
    }
  }

  // ===== TARGETS METHODS =====

  Future<int> insertTarget(Map<String, dynamic> target) async {
    try {
      final db = await database;
      return await db.insert('targets', target);
    } catch (e) {
      print('Error inserting target: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTargetsByUser(String userId) async {
    try {
      final db = await database;
      return await db.query(
        'targets',
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'createdAt DESC',
      );
    } catch (e) {
      print('Error getting targets by user: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllTargets() async {
    try {
      final db = await database;
      return await db.query('targets', orderBy: 'createdAt DESC');
    } catch (e) {
      print('Error getting all targets: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getActiveTarget() async {
    try {
      final db = await database;
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Cek apakah kolom status ada
      final tableInfo = await db.rawQuery("PRAGMA table_info(targets)");
      final hasStatusColumn =
          tableInfo.any((column) => column['name'] == 'status');

      List<Map<String, dynamic>> result;

      if (hasStatusColumn) {
        // Jika kolom status ada, gunakan query dengan status
        result = await db.rawQuery(
          'SELECT * FROM targets WHERE DATE(endDate) >= DATE(?) AND status = "active" ORDER BY createdAt DESC LIMIT 1',
          [today],
        );
      } else {
        // Jika kolom status tidak ada, gunakan query tanpa status
        result = await db.rawQuery(
          'SELECT * FROM targets WHERE DATE(endDate) >= DATE(?) ORDER BY createdAt DESC LIMIT 1',
          [today],
        );
      }

      print('DEBUG: Active target query result: $result');
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      print('Error getting active target: $e');
      return null;
    }
  }

  Future<int> updateTarget(int id, Map<String, dynamic> target) async {
    try {
      final db = await database;
      return await db.update(
        'targets',
        target,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error updating target: $e');
      rethrow;
    }
  }

  Future<int> deleteTarget(int id, [String? userId]) async {
    try {
      final db = await database;

      if (userId != null) {
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
    } catch (e) {
      print('Error deleting target: $e');
      rethrow;
    }
  }

  // ===== UTILITY METHODS =====

  Future<Map<String, int>> getDatabaseStats() async {
    try {
      final db = await database;

      final dailyUsageCount =
          await db.rawQuery('SELECT COUNT(*) as count FROM daily_usage');
      final targetsCount =
          await db.rawQuery('SELECT COUNT(*) as count FROM targets');

      return {
        'daily_usage': dailyUsageCount.first['count'] as int,
        'targets': targetsCount.first['count'] as int,
      };
    } catch (e) {
      print('Error getting database stats: $e');
      return {
        'daily_usage': 0,
        'targets': 0,
      };
    }
  }

  Future<void> clearAllData() async {
    try {
      final db = await database;
      await db.delete('daily_usage');
      await db.delete('targets');
      print('All data cleared from database');
    } catch (e) {
      print('Error clearing all data: $e');
      rethrow;
    }
  }

  Future<void> close() async {
    try {
      final db = _database;
      if (db != null) {
        await db.close();
        _database = null;
      }
      print('Database closed successfully');
    } catch (e) {
      print('Error closing database: $e');
    }
  }

  // ===== DEBUG METHOD =====

  Future<void> resetDatabase() async {
    try {
      String path = join(await getDatabasesPath(), 'emonic.db');
      await deleteDatabase(path);
      _database = null;
      print('Database reset successfully');
    } catch (e) {
      print('Error resetting database: $e');
    }
  }
}
