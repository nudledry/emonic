import 'package:flutter/material.dart';
import 'package:emonic/services/home_data_service.dart';
import 'package:emonic/constants/colors.dart';

class UsageSummaryCard extends StatelessWidget {
  final HomeDataService dataService;

  const UsageSummaryCard({
    super.key,
    required this.dataService,
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
          _buildSubtitle(),
          const SizedBox(height: 8),
          _buildProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.flash_on, color: AppColors.red),
        const SizedBox(width: 8),
        Text(
          '${dataService.weeklyUsage.toStringAsFixed(3)} kWh',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.black,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.orange,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${(dataService.progressPercentage * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'Weekly Electricity Usage',
      style: TextStyle(
        color: AppColors.textGrey,
        fontSize: 12,
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return LinearProgressIndicator(
      value: dataService.progressPercentage,
      backgroundColor: AppColors.progressGrey,
      valueColor: AlwaysStoppedAnimation<Color>(
        dataService.progressPercentage > 0.8
            ? AppColors.red
            : AppColors.primaryBlue,
      ),
      minHeight: 5,
      borderRadius: BorderRadius.circular(2.5),
    );
  }
}
