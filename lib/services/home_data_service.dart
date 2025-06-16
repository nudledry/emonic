import 'package:emonic/helpers/database_helper.dart';
import 'package:emonic/models/usage_model.dart';
import 'package:emonic/services/usage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HomeDataService {
  final UsageService _usageService = UsageService();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  List<Map<String, dynamic>> dailyUsageData = [];
  Map<String, dynamic>? currentTarget;
  double todayUsage = 0.0;
  double yesterdayUsage = 0.0;
  double weeklyUsage = 0.0;
  double targetValue = 0.0;
  double progressPercentage = 0.0;

  double get weeklyUsageInKwh {
    double totalKwh = 0.0;

    for (final data in dailyUsageData) {
      final usage = UsageModel.fromMap(data);
      totalKwh += usage.nilaiInKwh;
    }

    return totalKwh;
  }

  Future<void> loadData() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        print('User not authenticated, loading limited data');
        return;
      }

      // Load daily usage data from SQLite for current user only
      final usageData = await _databaseHelper.getDailyUsage(userId);

      // Load current target from SQLite for current user
      final targetData = await _databaseHelper.getActiveTarget();

      // Verify target belongs to current user
      if (targetData != null && targetData['userId'] != userId) {
        print('Active target does not belong to current user');
        // Set targetData to null if it doesn't belong to current user
        _processTargetData(null);
      } else {
        _processTargetData(targetData);
      }

      // Calculate usage metrics
      _calculateUsageMetrics(usageData);

      dailyUsageData = usageData;
    } catch (e) {
      print('Error loading data: $e');

      // Fallback for backward compatibility
      try {
        final usageData = await _databaseHelper.getDailyUsage();
        final targetData = await _databaseHelper.getActiveTarget();

        _calculateUsageMetrics(usageData);
        _processTargetData(targetData);

        dailyUsageData = usageData;
      } catch (e2) {
        print('Error in fallback data loading: $e2');
      }
    }
  }

  void _calculateUsageMetrics(List<Map<String, dynamic>> usageData) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final yesterday = DateFormat('yyyy-MM-dd').format(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));

    double todayTotal = 0.0;
    double yesterdayTotal = 0.0;
    double weeklyTotal = 0.0;

    for (var usage in usageData) {
      // Filter hanya parameter "Daya Listrik (kWh)"
      if (usage['parameter'] != 'Daya Listrik (kWh)') continue;

      final usageDate = DateTime.parse(usage['tanggal']);
      double nilai = 0.0;

      // Handle berbagai tipe data untuk nilai
      if (usage['nilai'] is String) {
        nilai = double.tryParse(usage['nilai']) ?? 0.0;
      } else if (usage['nilai'] is num) {
        nilai = usage['nilai'].toDouble();
      }

      if (usage['tanggal'] == today) {
        todayTotal += nilai;
      }
      if (usage['tanggal'] == yesterday) {
        yesterdayTotal += nilai;
      }
      if (usageDate.isAfter(weekAgo)) {
        weeklyTotal += nilai;
      }
    }

    todayUsage = todayTotal;
    yesterdayUsage = yesterdayTotal;
    weeklyUsage = weeklyTotal;
  }

  void _processTargetData(Map<String, dynamic>? targetData) {
    double target = 0.0;

    print('DEBUG: Target data received: $targetData');

    if (targetData != null) {
      // Handle berbagai format target
      if (targetData['target'] is String) {
        target = double.tryParse(targetData['target']) ?? 0.0;
      } else if (targetData['target'] is num) {
        target = targetData['target'].toDouble();
      }

      print('DEBUG: Parsed target value: $target');
    } else {
      print('DEBUG: No target data found');
    }

    currentTarget = targetData;
    targetValue = target;
  }

  Future<void> loadWeeklyUsage() async {
    try {
      weeklyUsage = await _usageService.getWeeklyUsageInKwh();
    } catch (e) {
      print('Error loading weekly usage: $e');
    }
  }

  Future<Map<String, double>> getUsageStatistics() async {
    try {
      return await _usageService.getUsageBreakdown();
    } catch (e) {
      print('Error getting usage statistics: $e');
      return {};
    }
  }

  // Method untuk refresh data
  Future<void> refreshData() async {
    await loadData();
    await loadWeeklyUsage();
  }

  // Method untuk mendapatkan usage hari ini dalam kWh
  Future<double> getTodayUsageInKwh() async {
    try {
      final today = DateTime.now();
      return await _usageService.getTotalUsageByDate(today);
    } catch (e) {
      print('Error getting today usage: $e');
      return 0.0;
    }
  }

  // Method untuk mendapatkan perbandingan dengan kemarin
  double get usageComparisonWithYesterday {
    if (yesterdayUsage == 0) return 0.0;
    return ((todayUsage - yesterdayUsage) / yesterdayUsage) * 100;
  }

  // Method untuk status target
  bool get isOverTarget => weeklyUsage > targetValue && targetValue > 0;

  String get targetStatus {
    if (currentTarget == null) return 'No Target Set';
    if (isOverTarget) return 'Over Target';
    if (weeklyUsage >= targetValue * 0.8) return 'Near Target';
    return 'On Track';
  }

  // Method untuk mendapatkan target berdasarkan user
  Future<void> loadUserTarget([String? specificUserId]) async {
    try {
      final userId = specificUserId ?? _currentUserId;
      if (userId == null) {
        print('No user ID available for loading target');
        return;
      }

      final targets = await _databaseHelper.getTargetsByUser(userId);

      if (targets.isNotEmpty) {
        // Ambil target yang masih aktif
        final activeTarget = targets.firstWhere(
          (target) {
            final endDate = DateTime.parse(target['endDate']);
            return endDate.isAfter(DateTime.now()) ||
                endDate.isAtSameMomentAs(DateTime.now());
          },
          orElse: () => targets.first,
        );

        currentTarget = activeTarget;
        targetValue =
            double.tryParse(activeTarget['target']?.toString() ?? '0') ?? 0.0;

        // Recalculate progress
        if (targetValue > 0) {
          progressPercentage = (weeklyUsage / targetValue).clamp(0.0, 1.0);
        }
      }
    } catch (e) {
      print('Error loading user target: $e');
    }
  }

  // Method untuk mendapatkan statistik penggunaan mingguan
  Future<List<Map<String, dynamic>>> getWeeklyUsageStats() async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 7));

      final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
      final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

      return await _databaseHelper.getDailyUsageByDateRange(
          startDateStr, endDateStr);
    } catch (e) {
      print('Error getting weekly usage stats: $e');
      return [];
    }
  }

  // Method untuk mendapatkan rata-rata penggunaan harian
  double get averageDailyUsage {
    if (dailyUsageData.isEmpty) return 0.0;

    final totalDays = dailyUsageData.length;
    return weeklyUsage / totalDays;
  }

  // Method untuk prediksi penggunaan bulanan
  double get predictedMonthlyUsage {
    return averageDailyUsage * 30;
  }

  // Method untuk mendapatkan trend penggunaan
  String get usageTrend {
    if (todayUsage > yesterdayUsage) {
      return 'increasing';
    } else if (todayUsage < yesterdayUsage) {
      return 'decreasing';
    } else {
      return 'stable';
    }
  }

  // Method untuk mendapatkan efisiensi target
  double get targetEfficiency {
    if (targetValue == 0) return 0.0;
    return (targetValue - weeklyUsage) / targetValue * 100;
  }
}
