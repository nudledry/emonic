import 'package:flutter/material.dart';
import 'package:emonic/models/usage_model.dart';
import 'package:emonic/constants/colors.dart';

class UsageItemWidget extends StatelessWidget {
  final UsageModel usage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const UsageItemWidget({
    super.key,
    required this.usage,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildStatusIndicator(),
          const SizedBox(width: 12),
          Expanded(child: _buildUsageInfo()),
          _buildUsageValue(),
          const SizedBox(width: 8),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: usage.isToday ? AppColors.green : AppColors.primaryBlue,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildUsageInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              usage.formattedDate,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.black,
                fontSize: 14,
              ),
            ),
            if (usage.isToday) ...[
              const SizedBox(width: 8),
              _buildTodayBadge(),
            ],
          ],
        ),
        const SizedBox(height: 4),
        _buildParameterInfo(),
        if (usage.catatan != null && usage.catatan!.isNotEmpty)
          _buildNoteInfo(),
      ],
    );
  }

  Widget _buildTodayBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Hari Ini',
        style: TextStyle(
          color: AppColors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildParameterInfo() {
    return Row(
      children: [
        Icon(
          usage.parameter == "Biaya (Rp)" ? Icons.attach_money : Icons.flash_on,
          size: 14,
          color: usage.parameter == "Biaya (Rp)"
              ? AppColors.green
              : AppColors.yellow,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            usage.parameter,
            style: TextStyle(
              color: AppColors.textGrey,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildNoteInfo() {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        usage.catatan!,
        style: TextStyle(
          color: AppColors.textGrey,
          fontSize: 11,
          fontStyle: FontStyle.italic,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildUsageValue() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Nilai utama
        Text(
          usage.formattedValue,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.primaryBlue,
          ),
        ),
        // Unit utama
        Text(
          usage.displayUnit,
          style: TextStyle(
            color: AppColors.textGrey,
            fontSize: 10,
          ),
        ),
        // Konversi (jika ada)
        if (usage.parameter == "Biaya (Rp)") ...[
          const SizedBox(height: 2),
          Text(
            '≈ ${usage.nilaiInKwh.toStringAsFixed(2)} kWh',
            style: TextStyle(
              color: AppColors.textGrey,
              fontSize: 9,
              fontStyle: FontStyle.italic,
            ),
          ),
        ] else ...[
          const SizedBox(height: 2),
          Text(
            '≈ ${usage.formattedValueInRupiah}',
            style: TextStyle(
              color: AppColors.textGrey,
              fontSize: 9,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            icon: Icon(
              Icons.edit,
              color: AppColors.primaryBlue,
              size: 18,
            ),
            onPressed: onEdit,
            padding: EdgeInsets.zero,
            tooltip: 'Edit',
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            icon: Icon(
              Icons.delete,
              color: AppColors.red,
              size: 18,
            ),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            tooltip: 'Hapus',
          ),
        ),
      ],
    );
  }
}
