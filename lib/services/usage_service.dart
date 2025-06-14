import 'package:emonic/helpers/database_helper.dart';
import 'package:emonic/models/usage_model.dart';

class UsageService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<List<UsageModel>> getAllUsages() async {
    try {
      final List<Map<String, dynamic>> maps =
          await _databaseHelper.getDailyUsage();
      return maps.map((map) => UsageModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to load usage data: $e');
    }
  }

  Future<void> updateUsage(UsageModel usage) async {
    try {
      if (usage.id == null) {
        throw Exception('Usage ID cannot be null for update');
      }
      await _databaseHelper.updateDailyUsage(usage.id!, usage.toMap());
    } catch (e) {
      throw Exception('Failed to update usage: $e');
    }
  }

  Future<void> deleteUsage(int id) async {
    try {
      await _databaseHelper.deleteDailyUsage(id);
    } catch (e) {
      throw Exception('Failed to delete usage: $e');
    }
  }

  Future<void> createUsage(UsageModel usage) async {
    try {
      await _databaseHelper.insertDailyUsage(usage.toMap());
    } catch (e) {
      throw Exception('Failed to create usage: $e');
    }
  }

  Future<double> getTotalUsageByDate(DateTime date) async {
    try {
      final usages = await getAllUsages();
      double totalKwh = 0.0;

      for (final usage in usages) {
        if (usage.tanggal.year == date.year &&
            usage.tanggal.month == date.month &&
            usage.tanggal.day == date.day) {
          totalKwh += usage.nilaiInKwh;
        }
      }

      return totalKwh;
    } catch (e) {
      throw Exception('Failed to get total usage: $e');
    }
  }

  Future<double> getTotalUsageInKwh(
      {DateTime? dateFilter, String? golonganFilter}) async {
    try {
      final usages = await getAllUsages();
      double totalKwh = 0.0;

      for (final usage in usages) {
        bool includeUsage = true;

        // Filter by date if provided
        if (dateFilter != null) {
          includeUsage = usage.tanggal.year == dateFilter.year &&
              usage.tanggal.month == dateFilter.month &&
              usage.tanggal.day == dateFilter.day;
        }

        // Filter by golongan if provided
        if (golonganFilter != null && golonganFilter.isNotEmpty) {
          includeUsage = includeUsage && usage.golongan == golonganFilter;
        }

        if (includeUsage) {
          totalKwh += usage.nilaiInKwh;
        }
      }

      return totalKwh;
    } catch (e) {
      throw Exception('Failed to calculate total usage: $e');
    }
  }

  Future<double> getWeeklyUsageInKwh({String? golonganFilter}) async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final usages = await getAllUsages();

      double weeklyKwh = 0.0;

      for (final usage in usages) {
        bool includeUsage =
            usage.tanggal.isAfter(weekStart.subtract(const Duration(days: 1)));

        // Filter by golongan if provided
        if (golonganFilter != null && golonganFilter.isNotEmpty) {
          includeUsage = includeUsage && usage.golongan == golonganFilter;
        }

        if (includeUsage) {
          weeklyKwh += usage.nilaiInKwh;
        }
      }

      return weeklyKwh;
    } catch (e) {
      throw Exception('Failed to calculate weekly usage: $e');
    }
  }

  Future<Map<String, double>> getUsageBreakdown(
      {String? golonganFilter}) async {
    try {
      final usages = await getAllUsages();
      Map<String, double> breakdown = {
        'totalKwh': 0.0,
        'totalRupiah': 0.0,
        'avgKwhPerDay': 0.0,
        'avgRupiahPerDay': 0.0,
        'maxKwhPerDay': 0.0,
        'minKwhPerDay': 0.0,
      };

      List<UsageModel> filteredUsages = usages;

      // Filter by golongan if provided
      if (golonganFilter != null && golonganFilter.isNotEmpty) {
        filteredUsages =
            usages.where((usage) => usage.golongan == golonganFilter).toList();
      }

      if (filteredUsages.isEmpty) {
        return breakdown;
      }

      double totalKwh = 0.0;
      double totalRupiah = 0.0;
      double maxKwh = 0.0;
      double minKwh = double.infinity;

      for (final usage in filteredUsages) {
        final kwhValue = usage.nilaiInKwh;
        totalKwh += kwhValue;
        totalRupiah += usage.nilaiInRupiah;

        if (kwhValue > maxKwh) maxKwh = kwhValue;
        if (kwhValue < minKwh) minKwh = kwhValue;
      }

      breakdown['totalKwh'] = totalKwh;
      breakdown['totalRupiah'] = totalRupiah;
      breakdown['maxKwhPerDay'] = maxKwh;
      breakdown['minKwhPerDay'] = minKwh == double.infinity ? 0.0 : minKwh;

      final days = filteredUsages.length;
      if (days > 0) {
        breakdown['avgKwhPerDay'] = totalKwh / days;
        breakdown['avgRupiahPerDay'] = totalRupiah / days;
      }

      return breakdown;
    } catch (e) {
      throw Exception('Failed to calculate usage breakdown: $e');
    }
  }

  // Method untuk mendapatkan usage berdasarkan golongan
  Future<List<UsageModel>> getUsagesByGolongan(String golongan) async {
    try {
      final allUsages = await getAllUsages();
      return allUsages.where((usage) => usage.golongan == golongan).toList();
    } catch (e) {
      throw Exception('Failed to get usages by golongan: $e');
    }
  }

  // Method untuk mendapatkan statistik per golongan
  Future<Map<String, Map<String, double>>> getStatisticsByGolongan() async {
    try {
      final usages = await getAllUsages();
      Map<String, Map<String, double>> statistics = {};

      // Group by golongan
      Map<String, List<UsageModel>> groupedByGolongan = {};
      for (final usage in usages) {
        if (!groupedByGolongan.containsKey(usage.golongan)) {
          groupedByGolongan[usage.golongan] = [];
        }
        groupedByGolongan[usage.golongan]!.add(usage);
      }

      // Calculate statistics for each golongan
      for (final golongan in groupedByGolongan.keys) {
        final golonganUsages = groupedByGolongan[golongan]!;
        double totalKwh = 0.0;
        double totalRupiah = 0.0;

        for (final usage in golonganUsages) {
          totalKwh += usage.nilaiInKwh;
          totalRupiah += usage.nilaiInRupiah;
        }

        statistics[golongan] = {
          'totalKwh': totalKwh,
          'totalRupiah': totalRupiah,
          'avgKwhPerEntry': golonganUsages.isNotEmpty
              ? totalKwh / golonganUsages.length
              : 0.0,
          'avgRupiahPerEntry': golonganUsages.isNotEmpty
              ? totalRupiah / golonganUsages.length
              : 0.0,
          'entryCount': golonganUsages.length.toDouble(),
        };
      }

      return statistics;
    } catch (e) {
      throw Exception('Failed to get statistics by golongan: $e');
    }
  }
}
