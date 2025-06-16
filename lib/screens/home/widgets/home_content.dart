import 'package:flutter/material.dart';
import 'package:emonic/screens/home/widgets/energy_cards.dart';
import 'package:emonic/screens/home/widgets/target_progress_card.dart';
import 'package:emonic/screens/home/widgets/consumption_chart_card.dart';
import 'package:emonic/screens/usage/widgets/usage_data_list.dart';
import 'package:emonic/services/home_data_service.dart';
import 'package:emonic/constants/colors.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final HomeDataService _dataService = HomeDataService();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      await _dataService.loadData();
      // Pastikan weekly usage juga diload dengan konversi
      await _dataService.loadWeeklyUsage();

      print('DEBUG: Data service loaded successfully');
      print('DEBUG: Current target: ${_dataService.currentTarget}');
      print('DEBUG: Target value: ${_dataService.targetValue}');
      print('DEBUG: Today usage (kWh): ${_dataService.todayUsage}');
      print('DEBUG: Weekly usage (kWh): ${_dataService.weeklyUsage}');
      print(
          'DEBUG: Weekly usage from getter (kWh): ${_dataService.weeklyUsageInKwh}');
    } catch (e) {
      print('ERROR: Failed to load data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryBlue,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TargetProgressCard(dataService: _dataService),
              const SizedBox(height: 16),
              EnergyCards(dataService: _dataService),
              const SizedBox(height: 16),
              ConsumptionChartCard(
                dataService: _dataService,
                onRefresh: _loadData,
              ),
              const SizedBox(height: 16),
              UsageDataList(
                dataService: _dataService,
                onDataChanged: _loadData,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
