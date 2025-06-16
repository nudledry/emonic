import 'package:flutter/material.dart';
import 'package:emonic/services/home_data_service.dart';
import 'package:emonic/screens/usage/daily_usage_screen.dart';
import 'package:emonic/services/usage_service.dart';
import 'package:emonic/models/usage_model.dart';
import 'package:emonic/constants/colors.dart';
import 'package:emonic/constants/usage_constants.dart';
import 'package:emonic/screens/usage/widgets/usage_item_widget.dart';
import 'package:emonic/helpers/dialog_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UsageDataList extends StatefulWidget {
  final HomeDataService dataService;
  final VoidCallback? onDataChanged;

  const UsageDataList({
    super.key,
    required this.dataService,
    this.onDataChanged,
  });

  @override
  State<UsageDataList> createState() => _UsageDataListState();
}

class _UsageDataListState extends State<UsageDataList> {
  final UsageService _usageService = UsageService();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 80),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
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
          if (widget.dataService.dailyUsageData.isEmpty)
            _buildEmptyState(context)
          else
            _buildUsageList(context),
          if (widget.dataService.dailyUsageData.length >
              UsageConstants.maxDisplayItems)
            _buildViewAllButton(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.list_alt, color: AppColors.primaryBlue),
          const SizedBox(width: 8),
          Text(
            'Riwayat Penggunaan',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.black,
            ),
          ),
          const Spacer(),
          Text(
            '${widget.dataService.dailyUsageData.length} data',
            style: TextStyle(
              color: AppColors.textGrey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: AppColors.textGrey,
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada data penggunaan',
              style: TextStyle(
                color: AppColors.textGrey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _navigateToAddUsage(context),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageList(BuildContext context) {
    final itemCount = widget.dataService.dailyUsageData.length >
            UsageConstants.maxDisplayItems
        ? UsageConstants.maxDisplayItems
        : widget.dataService.dailyUsageData.length;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (context, index) => Divider(
        color: Colors.grey.withValues(alpha: 0.3),
        height: 1,
      ),
      itemBuilder: (context, index) {
        final usage =
            UsageModel.fromMap(widget.dataService.dailyUsageData[index]);
        return UsageItemWidget(
          usage: usage,
          onEdit: () => _handleEdit(context, usage),
          onDelete: () => _handleDelete(context, usage),
        );
      },
    );
  }

  Widget _buildViewAllButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: TextButton(
          onPressed: () => _showAllDataSnackBar(context),
          child: Text(
            'Lihat Semua (${widget.dataService.dailyUsageData.length} data)',
            style: TextStyle(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToAddUsage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DailyUsageScreen(),
      ),
    ).then((_) {
      // Refresh data when returning from add usage screen
      _refreshData();
    });
  }

  void _showAllDataSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Total ${widget.dataService.dailyUsageData.length} data tersedia'),
        backgroundColor: AppColors.primaryBlue,
      ),
    );
  }

  Future<void> _handleEdit(BuildContext context, UsageModel usage) async {
    try {
      final updatedUsage = await DialogHelper.showEditDialog(context, usage);
      if (updatedUsage != null) {
        await _showLoadingDialog(context);
        await _usageService.updateUsage(updatedUsage);
        if (mounted) Navigator.pop(context); // Close loading dialog

        if (mounted) {
          _showSuccessSnackBar(context, "Data penggunaan berhasil diperbarui");
          _refreshData();
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading dialog if open
      if (mounted) {
        _showErrorSnackBar(context, "Error memperbarui data: $e");
      }
    }
  }

  Future<void> _handleDelete(BuildContext context, UsageModel usage) async {
    try {
      final shouldDelete = await DialogHelper.showDeleteDialog(context, usage);
      if (shouldDelete) {
        await _showLoadingDialog(context);
        await _usageService.deleteUsage(usage.id!);
        if (mounted) Navigator.pop(context); // Close loading dialog

        if (mounted) {
          _showSuccessSnackBar(context, "Data penggunaan berhasil dihapus");
          _refreshData();
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading dialog if open
      if (mounted) {
        _showErrorSnackBar(context, "Error menghapus data: $e");
      }
    }
  }

  Future<void> _showLoadingDialog(BuildContext context) async {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryBlue,
          ),
        ),
      );
    }
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.green,
        ),
      );
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  Future<void> _refreshData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  const Text("Silakan login untuk melihat data penggunaan"),
              backgroundColor: AppColors.orange,
            ),
          );
        }
        return;
      }

      await widget.dataService.refreshData();
      if (mounted) {
        setState(() {
          // Trigger rebuild
        });

        // Call the callback if provided
        widget.onDataChanged?.call();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(context, "Error memuat data: $e");
      }
    }
  }
}
