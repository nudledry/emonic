import 'package:flutter/material.dart';
import 'package:emonic/services/home_data_service.dart';
import 'package:emonic/screens/target/target_pengguna.dart';
import 'package:emonic/constants/colors.dart';

class TargetProgressCard extends StatefulWidget {
  final HomeDataService dataService;

  const TargetProgressCard({
    super.key,
    required this.dataService,
  });

  @override
  State<TargetProgressCard> createState() => _TargetProgressCardState();
}

class _TargetProgressCardState extends State<TargetProgressCard> {
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      await widget.dataService.loadData();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      print('Error loading target data: $e');
    }
  }

  bool get _isOverTarget =>
      widget.dataService.weeklyUsage > widget.dataService.targetValue;
  double get _progressPercentage =>
      (widget.dataService.weeklyUsage / widget.dataService.targetValue)
          .clamp(0.0, 1.0);
  double get _overagePercentage =>
      widget.dataService.weeklyUsage > widget.dataService.targetValue
          ? (widget.dataService.weeklyUsage - widget.dataService.targetValue) /
              widget.dataService.targetValue
          : 0.0;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isOverTarget
            ? AppColors.red.withValues(alpha: 0.1)
            : AppColors.chartBlue,
        borderRadius: BorderRadius.circular(16),
        border:
            _isOverTarget ? Border.all(color: AppColors.red, width: 2) : null,
        boxShadow: _isOverTarget
            ? [
                BoxShadow(
                  color: AppColors.red.withValues(alpha: 0.2),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          if (widget.dataService.currentTarget != null)
            _buildTargetInfo()
          else
            _buildNoTargetState(context),
          if (widget.dataService.currentTarget != null) ...[
            const SizedBox(height: 12),
            _buildProgressBar(context),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.chartBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.red,
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            'Error loading data',
            style: TextStyle(
              color: AppColors.red,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap to retry',
            style: TextStyle(
              color: AppColors.textGrey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Icon(
            _isOverTarget ? Icons.warning : Icons.flag,
            color: _isOverTarget ? AppColors.red : AppColors.primaryBlue,
            key: ValueKey(_isOverTarget),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Target Progress',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _isOverTarget ? AppColors.red : AppColors.black,
          ),
        ),
        const Spacer(),
        if (widget.dataService.currentTarget != null)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _isOverTarget ? AppColors.red : AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isOverTarget) ...[
                  Icon(
                    Icons.warning,
                    size: 12,
                    color: AppColors.white,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  _isOverTarget ? 'OVER TARGET' : 'Active',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTargetInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Golongan Info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primaryBlue.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.category,
                size: 14,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.dataService.currentTarget!['golongan'] ?? 'N/A',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Current vs Target
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textGrey,
            ),
            children: [
              const TextSpan(text: 'Current: '),
              TextSpan(
                text: widget.dataService.weeklyUsage.toStringAsFixed(1),
                style: TextStyle(
                  color: _isOverTarget ? AppColors.red : AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(text: ' / '),
              TextSpan(
                text:
                    '${widget.dataService.targetValue.toStringAsFixed(1)} kWh',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Overage Warning
        if (_isOverTarget) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up,
                  size: 14,
                  color: AppColors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  'Exceeded by ${(widget.dataService.weeklyUsage - widget.dataService.targetValue).toStringAsFixed(1)} kWh',
                  style: TextStyle(
                    color: AppColors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 8),

        // Parameter Info
        Row(
          children: [
            Icon(
              Icons.flash_on,
              size: 14,
              color: AppColors.yellow,
            ),
            const SizedBox(width: 4),
            Text(
              'Parameter: ${widget.dataService.currentTarget!['parameter'] ?? 'N/A'}',
              style: TextStyle(
                color: AppColors.textGrey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - 32;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress',
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${(_progressPercentage * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color:
                        _isOverTarget ? AppColors.red : AppColors.primaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Stack(
              children: [
                // Background bar
                Container(
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Progress bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  height: 8,
                  width: availableWidth * _progressPercentage,
                  decoration: BoxDecoration(
                    color:
                        _isOverTarget ? AppColors.red : AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: _isOverTarget
                        ? [
                            BoxShadow(
                              color: AppColors.red.withValues(alpha: 0.3),
                              spreadRadius: 1,
                              blurRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                ),
                // Overage indicator (if exceeded)
                if (_isOverTarget)
                  Positioned(
                    left: availableWidth * 1.0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      height: 8,
                      width:
                          availableWidth * _overagePercentage.clamp(0.0, 0.3),
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.6),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              AppColors.red.withValues(alpha: 0.8),
                              AppColors.red.withValues(alpha: 0.4),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildNoTargetState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'No active target set',
          style: TextStyle(
            color: AppColors.textGrey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TargetPenggunaanScreen(),
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Set Target'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}
