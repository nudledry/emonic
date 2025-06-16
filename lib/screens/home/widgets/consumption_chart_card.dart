import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:emonic/services/home_data_service.dart';
import 'package:emonic/constants/colors.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConsumptionChartCard extends StatelessWidget {
  final HomeDataService dataService;
  final VoidCallback onRefresh;

  const ConsumptionChartCard({
    super.key,
    required this.dataService,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textGrey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 6),
          _buildSummary(),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: _buildChart(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.insert_chart, color: AppColors.primaryBlue),
        const SizedBox(width: 8),
        Text(
          'Penggunaan Energi Mingguan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.black,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: Icon(Icons.refresh, color: AppColors.primaryBlue),
          onPressed: onRefresh,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total: ${dataService.weeklyUsageInKwh.toStringAsFixed(2)} kWh',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlue,
          ),
        ),
        if (dataService.currentTarget != null) ...[
          Text(
            'Target: ${dataService.targetValue.toStringAsFixed(2)} kWh',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChart(BuildContext context) {
    if (dataService.dailyUsageData.isEmpty) {
      return _buildEmptyChart(context);
    }

    return _buildLineChart();
  }

  Widget _buildEmptyChart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_chart,
            size: 48,
            color: AppColors.textGrey,
          ),
          const SizedBox(height: 8),
          Text(
            'No usage data available',
            style: TextStyle(
              color: AppColors.textGrey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    final chartData = _prepareChartData();

    return LineChart(
      LineChartData(
        gridData: _buildGridData(),
        titlesData: _buildTitlesData(chartData.labels),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 6,
        minY: 0,
        lineBarsData: [
          _buildUsageLine(chartData.usageSpots),
          if (chartData.targetSpots.isNotEmpty)
            _buildTargetLine(chartData.targetSpots),
        ],
      ),
    );
  }

  ChartData _prepareChartData() {
    List<FlSpot> usageSpots = _generateUsageSpots();
    List<FlSpot> targetSpots = [];
    List<String> dates = [];

    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      dates.add(DateFormat('MM/dd').format(date));

      // **UPDATE: Target sudah dalam kWh, jadi perhitungan harian lebih sederhana**
      if (dataService.targetValue > 0) {
        // Hitung target harian berdasarkan durasi target
        double dailyTarget = _calculateDailyTarget();
        targetSpots.add(FlSpot((6 - i).toDouble(), dailyTarget));
      }
    }

    return ChartData(
      usageSpots: usageSpots,
      targetSpots: targetSpots,
      labels: dates,
    );
  }

  double _calculateDailyTarget() {
    if (dataService.currentTarget == null || dataService.targetValue <= 0) {
      return 0.0;
    }

    // Ambil durasi target dalam hari
    final durationDays = dataService.currentTarget!['duration_days'] ?? 7;

    // Hitung target harian
    return dataService.targetValue / durationDays;
  }

  List<FlSpot> _generateUsageSpots() {
    List<FlSpot> usageSpots = [];
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      double dayUsage = 0.0;

      for (var usage in dataService.dailyUsageData) {
        // Check if usage belongs to current user
        bool belongsToCurrentUser = true;
        if (usage.containsKey('userId') && currentUserId != null) {
          belongsToCurrentUser = usage['userId'] == currentUserId;
        }

        if (usage['tanggal'] == dateStr && belongsToCurrentUser) {
          // **UPDATE: Data usage sudah dikonversi saat penyimpanan, langsung ambil nilai**
          double nilaiKwh = _extractUsageValue(usage);
          dayUsage += nilaiKwh;
        }
      }

      usageSpots.add(FlSpot((6 - i).toDouble(), dayUsage));
    }

    return usageSpots;
  }

  double _extractUsageValue(Map<String, dynamic> usage) {
    double nilai = 0.0;

    // Parse nilai yang sudah disimpan dalam kWh
    if (usage['nilai'] is String) {
      nilai = double.tryParse(usage['nilai']) ?? 0.0;
    } else if (usage['nilai'] is num) {
      nilai = usage['nilai'].toDouble();
    }

    return nilai;
  }

  FlGridData _buildGridData() {
    double maxUsage = 0.0;

    // Cari nilai maksimum dari data usage
    for (var usage in dataService.dailyUsageData) {
      double nilaiKwh = _extractUsageValue(usage);
      if (nilaiKwh > maxUsage) maxUsage = nilaiKwh;
    }

    // Bandingkan dengan target harian
    double dailyTarget = _calculateDailyTarget();
    if (dailyTarget > maxUsage) maxUsage = dailyTarget;

    double interval = maxUsage > 0 ? maxUsage / 5 : 10;

    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: interval > 0 ? interval : 1,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: AppColors.grey.withValues(alpha: 0.3),
          strokeWidth: 1,
        );
      },
    );
  }

  FlTitlesData _buildTitlesData(List<String> labels) {
    return FlTitlesData(
      show: true,
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            if (value.toInt() >= 0 && value.toInt() < labels.length) {
              return Text(
                labels[value.toInt()],
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 10,
                ),
              );
            }
            return const Text('');
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, meta) {
            return Text(
              value.toStringAsFixed(1),
              style: TextStyle(
                color: AppColors.textGrey,
                fontSize: 10,
              ),
            );
          },
        ),
      ),
    );
  }

  LineChartBarData _buildUsageLine(List<FlSpot> spots) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: AppColors.primaryBlue,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 4,
            color: AppColors.primaryBlue,
            strokeWidth: 2,
            strokeColor: AppColors.white,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        color: AppColors.primaryBlue.withValues(alpha: 0.1),
      ),
    );
  }

  LineChartBarData _buildTargetLine(List<FlSpot> spots) {
    return LineChartBarData(
      spots: spots,
      isCurved: false,
      color: AppColors.red,
      barWidth: 2,
      isStrokeCapRound: true,
      dashArray: [5, 5],
      dotData: const FlDotData(show: false),
    );
  }
}

class ChartData {
  final List<FlSpot> usageSpots;
  final List<FlSpot> targetSpots;
  final List<String> labels;

  ChartData({
    required this.usageSpots,
    required this.targetSpots,
    required this.labels,
  });
}
