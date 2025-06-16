import 'package:emonic/helpers/database_helper.dart';
import 'package:emonic/constants/tarif_listrik.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HomeDataService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Map<String, dynamic>? currentTarget;
  double weeklyUsage = 0.0;
  double monthlyUsage = 0.0;
  List<Map<String, dynamic>> recentUsage = [];

  // Add new fields for daily usage tracking
  double _todayUsage = 0.0;
  double _yesterdayUsage = 0.0;
  List<Map<String, dynamic>> _dailyUsageData = [];

  // Add field to track current user
  String? _currentUserId;

  // Method to verify and get current user ID
  String? _getCurrentUserId() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('Warning: No user authenticated');
        return null;
      }

      // If this is the first call or user has changed, update current user ID
      if (_currentUserId != user.uid) {
        _currentUserId = user.uid;
      }

      return _currentUserId;
    } catch (e) {
      print('Error getting current user ID: $e');
      return null;
    }
  }

  // Method to verify if data belongs to current user
  bool _verifyDataOwnership(Map<String, dynamic> data) {
    final currentUserId = _getCurrentUserId();
    if (currentUserId == null) return false;

    final dataUserId = data['userId'] as String?;

    if (dataUserId == null || dataUserId != currentUserId) {
      print(
          'Warning: Data ownership mismatch. Expected: $currentUserId, Found: $dataUserId');
      return false;
    }

    return true;
  }

  // Method to filter data by current user
  List<Map<String, dynamic>> _filterDataByCurrentUser(
      List<Map<String, dynamic>> data) {
    final currentUserId = _getCurrentUserId();
    if (currentUserId == null) return [];

    return data.where((item) {
      final dataUserId = item['userId'] as String?;
      return dataUserId != null && dataUserId == currentUserId;
    }).toList();
  }

  // Existing getter with null safety
  double get targetValue {
    if (currentTarget == null) return 0.0;

    // Verify target ownership before returning value
    if (!_verifyDataOwnership(currentTarget!)) {
      print('Warning: Target data ownership verification failed');
      return 0.0;
    }

    return double.tryParse(currentTarget!['target']?.toString() ?? '0') ?? 0.0;
  }

  // Add missing getters with verification
  double get todayUsage => _todayUsage;
  double get yesterdayUsage => _yesterdayUsage;
  double get weeklyUsageInKwh => weeklyUsage;
  List<Map<String, dynamic>> get dailyUsageData => _dailyUsageData;

  // Fungsi baru untuk mendapatkan target value dalam kWh
  double get targetValueInKwh {
    if (currentTarget == null) return 0.0;

    final targetValue = this.targetValue;
    final parameter = currentTarget!['parameter'] as String?;
    final golongan = currentTarget!['golongan'] as String?;

    // Jika parameter adalah "Daya Listrik (kWh)", nilai sudah dalam kWh
    if (parameter == "Daya Listrik (kWh)") {
      return targetValue;
    }

    // Jika parameter adalah "Biaya (Rp)" dan golongan tidak null, konversi ke kWh
    if (parameter == "Biaya (Rp)" && golongan != null) {
      return TarifListrik.convertBiayaToKwh(targetValue, golongan);
    }

    // Default: anggap sudah dalam kWh (untuk backward compatibility)
    return targetValue;
  }

  // Fungsi untuk mendapatkan target value dalam format Rupiah
  double get targetValueInRupiah {
    if (currentTarget == null) return 0.0;

    final targetValue = this.targetValue;
    final parameter = currentTarget!['parameter'] as String?;
    final golongan = currentTarget!['golongan'] as String?;

    // Jika parameter adalah "Biaya (Rp)", nilai sudah dalam Rupiah
    if (parameter == "Biaya (Rp)") {
      return targetValue;
    }

    // Jika parameter adalah "Daya Listrik (kWh)" dan golongan tidak null, konversi ke Rupiah
    if (parameter == "Daya Listrik (kWh)" && golongan != null) {
      return TarifListrik.convertKwhToBiaya(targetValue, golongan);
    }

    // Default: konversi dari kWh ke Rupiah menggunakan tarif default
    if (golongan != null) {
      return TarifListrik.convertKwhToBiaya(targetValue, golongan);
    }

    return TarifListrik.convertKwhToBiaya(targetValue, "R-1/TR Daya 900 VA");
  }

  // Fungsi untuk mengecek apakah target terlampaui
  bool get isOverTarget => weeklyUsage > targetValueInKwh;

  // Fungsi untuk mendapatkan persentase progress
  double get progressPercentage => targetValueInKwh > 0
      ? (weeklyUsage / targetValueInKwh).clamp(0.0, 1.0)
      : 0.0;

  // Fungsi untuk mendapatkan persentase kelebihan
  double get overagePercentage =>
      weeklyUsage > targetValueInKwh && targetValueInKwh > 0
          ? (weeklyUsage - targetValueInKwh) / targetValueInKwh
          : 0.0;

  // Fungsi untuk mendapatkan nilai kelebihan dalam kWh
  double get overageAmount =>
      weeklyUsage > targetValueInKwh ? weeklyUsage - targetValueInKwh : 0.0;

  // Fungsi untuk mendapatkan sisa target dalam kWh
  double get remainingTargetAmount =>
      targetValueInKwh > weeklyUsage ? targetValueInKwh - weeklyUsage : 0.0;

  // Add missing loadWeeklyUsage method with verification
  Future<void> loadWeeklyUsage() async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        print('Warning: Cannot load weekly usage - user not authenticated');
        weeklyUsage = 0.0;
        return;
      }

      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      // Get weekly usage with user verification
      final weeklyUsageData =
          await _databaseHelper.getUsageInDateRange(userId, weekAgo, now);

      // Filter and verify data ownership
      final verifiedData = _filterDataByCurrentUser(weeklyUsageData);

      weeklyUsage = verifiedData.fold(0.0, (sum, usage) {
        final parameter = usage['parameter'] as String?;
        final golongan = usage['golongan'] as String?;
        final nilai = usage['nilai'] as double? ?? 0.0;

        // Konversi ke kWh jika diperlukan
        if (parameter == "Daya Listrik (kWh)") {
          return sum + nilai;
        } else if (parameter == "Biaya (Rp)" && golongan != null) {
          return sum + TarifListrik.convertBiayaToKwh(nilai, golongan);
        }
        return sum + nilai;
      });
    } catch (e) {
      print('Error loading weekly usage: $e');
      weeklyUsage = 0.0;
    }
  }

  // Helper method to convert usage data to kWh
  double _convertToKwh(Map<String, dynamic> usage) {
    final parameter = usage['parameter'] as String?;
    final golongan = usage['golongan'] as String?;
    final nilai = usage['nilai'] as double? ?? 0.0;

    if (parameter == "Daya Listrik (kWh)") {
      return nilai;
    } else if (parameter == "Biaya (Rp)" && golongan != null) {
      return TarifListrik.convertBiayaToKwh(nilai, golongan);
    }
    return nilai;
  }

  // Enhanced loadData method with verification and error handling
  Future<void> loadData() async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        print('Warning: Cannot load data - user not authenticated');
        return;
      }

      // Load current target with verification
      final targetData = await _databaseHelper.getActiveTarget();
      if (targetData != null && _verifyDataOwnership(targetData)) {
        currentTarget = targetData;
      } else {
        currentTarget = null;
        print('Info: No active target found or ownership verification failed');
      }

      // Load usage data
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final monthAgo = DateTime(now.year, now.month - 1, now.day);
      final today = DateFormat('yyyy-MM-dd').format(now);
      final yesterday = DateFormat('yyyy-MM-dd')
          .format(now.subtract(const Duration(days: 1)));

      // Get today's usage with verification
      try {
        final todayUsageData = await _databaseHelper.getDailyUsageByDateRange(
            today, today, userId);
        final verifiedTodayData = _filterDataByCurrentUser(todayUsageData);
        _todayUsage = verifiedTodayData.fold(
            0.0, (sum, usage) => sum + _convertToKwh(usage));
      } catch (e) {
        print('Error loading today usage: $e');
        _todayUsage = 0.0;
      }

      // Get yesterday's usage with verification
      try {
        final yesterdayUsageData = await _databaseHelper
            .getDailyUsageByDateRange(yesterday, yesterday, userId);
        final verifiedYesterdayData =
            _filterDataByCurrentUser(yesterdayUsageData);
        _yesterdayUsage = verifiedYesterdayData.fold(
            0.0, (sum, usage) => sum + _convertToKwh(usage));
      } catch (e) {
        print('Error loading yesterday usage: $e');
        _yesterdayUsage = 0.0;
      }

      // Get weekly usage with verification
      try {
        final weeklyUsageData =
            await _databaseHelper.getUsageInDateRange(userId, weekAgo, now);
        final verifiedWeeklyData = _filterDataByCurrentUser(weeklyUsageData);
        weeklyUsage = verifiedWeeklyData.fold(
            0.0, (sum, usage) => sum + _convertToKwh(usage));
      } catch (e) {
        print('Error loading weekly usage: $e');
        weeklyUsage = 0.0;
      }

      // Get monthly usage with verification
      try {
        final monthlyUsageData =
            await _databaseHelper.getUsageInDateRange(userId, monthAgo, now);
        final verifiedMonthlyData = _filterDataByCurrentUser(monthlyUsageData);
        monthlyUsage = verifiedMonthlyData.fold(
            0.0, (sum, usage) => sum + _convertToKwh(usage));
      } catch (e) {
        print('Error loading monthly usage: $e');
        monthlyUsage = 0.0;
      }

      // Get recent usage with verification (last 5 entries)
      try {
        final recentUsageData = await _databaseHelper.getRecentUsage(userId, 5);
        recentUsage = _filterDataByCurrentUser(recentUsageData);
      } catch (e) {
        print('Error loading recent usage: $e');
        recentUsage = [];
      }

      // Get daily usage data with verification (last 30 days for charts/lists)
      try {
        final thirtyDaysAgo = now.subtract(const Duration(days: 30));
        final dailyUsageData = await _databaseHelper.getUsageInDateRange(
            userId, thirtyDaysAgo, now);
        _dailyUsageData = _filterDataByCurrentUser(dailyUsageData);
      } catch (e) {
        print('Error loading daily usage data: $e');
        _dailyUsageData = [];
      }

      print('Data loaded successfully for user: $userId');
    } catch (e) {
      print('Error loading home data: $e');
    }
  }

  // Enhanced refreshData method with verification
  Future<void> refreshData() async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        print('Warning: Cannot refresh data - user not authenticated');
        return;
      }

      print('Refreshing data for user: $userId');

      // Reload all data
      await loadData();

      print('Data refreshed successfully for user: $userId');
    } catch (e) {
      print('Error refreshing home data: $e');
    }
  }

  // Method to check if current user is still authenticated
  bool isUserAuthenticated() {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      return userId != null && userId == _currentUserId;
    } catch (e) {
      return false;
    }
  }

  // Method to handle user logout
  void handleUserLogout() {
    _currentUserId = null;
  }

  // Method to safely initialize data for authenticated users
  Future<void> initializeForCurrentUser() async {
    try {
      final userId = _getCurrentUserId();
      if (userId != null) {
        await loadData();
      } else {
        print('Info: No user authenticated, using default empty data');
      }
    } catch (e) {
      print('Error initializing data: $e');
    }
  }
}
