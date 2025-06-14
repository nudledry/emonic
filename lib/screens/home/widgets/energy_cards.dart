import 'package:flutter/material.dart';
import 'package:emonic/services/home_data_service.dart';
import 'package:emonic/constants/colors.dart';

class EnergyCards extends StatelessWidget {
  final HomeDataService dataService;

  const EnergyCards({
    super.key,
    required this.dataService,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildEnergyCard(
            "Today's energy",
            dataService.todayUsage.toStringAsFixed(1),
            'kWh',
            AppColors.orange,
            Icons.lightbulb_outline,
            AppColors.yellow,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildEnergyCard(
            'Yesterday',
            dataService.yesterdayUsage.toStringAsFixed(1),
            'kWh',
            AppColors.progressGrey,
            Icons.receipt_outlined,
            AppColors.textGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildEnergyCard(
    String title,
    String value,
    String unit,
    Color backgroundColor,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.black,
                        ),
                      ),
                      TextSpan(
                        text: ' $unit',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
