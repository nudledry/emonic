import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:emonic/services/home_data_service.dart';
import 'package:emonic/screens/usage/daily_usage_screen.dart';
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
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 8),
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
        Text(
          'Electricity Consumption (Last 7 Days)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
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
          'Total: ${dataService.weeklyUsage.toStringAsFixed(2)} kWh',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlue,
          ),
        ),
        if (dataService.currentTarget != null)
          Text(
            'Target: ${dataService.targetValue.toStringAsFixed(2)} kWh',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textGrey,
            ),
          ),
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
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DailyUsageScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Add Data'),
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
      DateFormat('yyyy-MM-dd').format(date);
      dates.add(DateFormat('MM/dd').format(date));

      // Target line (daily target = weekly target / 7)
      if (dataService.targetValue > 0) {
        double dailyTarget = dataService.targetValue / 7;
        targetSpots.add(FlSpot((6 - i).toDouble(), dailyTarget));
      }
    }

    return ChartData(
      usageSpots: usageSpots,
      targetSpots: targetSpots,
      labels: dates,
    );
  }

  List<FlSpot> _generateUsageSpots() {
    List<FlSpot> usageSpots = [];
    List<String> dates = [];

    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      dates.add(DateFormat('MM/dd').format(date));

      // Filter dan hitung usage hanya untuk parameter "Daya Listrik (kWh)" dan user saat ini
      double dayUsage = 0.0;
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

      for (var usage in dataService.dailyUsageData) {
        // Check if usage belongs to current user (if userId field exists)
        bool belongsToCurrentUser = true;
        if (usage.containsKey('userId') && currentUserId != null) {
          belongsToCurrentUser = usage['userId'] == currentUserId;
        }

        if (usage['tanggal'] == dateStr &&
            usage['parameter'] == 'Daya Listrik (kWh)' &&
            belongsToCurrentUser) {
          double nilai = 0.0;

          // Handle berbagai tipe data untuk nilai
          if (usage['nilai'] is String) {
            nilai = double.tryParse(usage['nilai']) ?? 0.0;
          } else if (usage['nilai'] is num) {
            nilai = usage['nilai'].toDouble();
          }

          dayUsage += nilai;
        }
      }

      usageSpots.add(FlSpot((6 - i).toDouble(), dayUsage));
    }

    return usageSpots;
  }

  FlGridData _buildGridData() {
    double maxUsage = 0.0;

    // Cari nilai maksimum untuk menentukan interval grid
    for (var usage in dataService.dailyUsageData) {
      if (usage['parameter'] == 'Daya Listrik (kWh)') {
        double nilai = 0.0;
        if (usage['nilai'] is String) {
          nilai = double.tryParse(usage['nilai']) ?? 0.0;
        } else if (usage['nilai'] is num) {
          nilai = usage['nilai'].toDouble();
        }
        if (nilai > maxUsage) maxUsage = nilai;
      }
    }

    double interval = maxUsage > 0 ? maxUsage / 5 : 10;

    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: interval,
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
