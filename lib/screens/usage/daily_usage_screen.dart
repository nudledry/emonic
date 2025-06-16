import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:emonic/constants/colors.dart';
import 'package:emonic/constants/usage_constants.dart';
import 'package:emonic/models/usage_model.dart';
import 'package:emonic/services/daily_usage_service.dart';
import 'package:emonic/services/auth_service.dart';
import 'package:emonic/screens/usage/widgets/form_validator.dart';

class DailyUsageScreen extends StatefulWidget {
  const DailyUsageScreen({super.key});

  @override
  State<DailyUsageScreen> createState() => _DailyUsageScreenState();
}

class _DailyUsageScreenState extends State<DailyUsageScreen> {
  final DailyUsageService _usageService = DailyUsageService();
  final _formKey = GlobalKey<FormState>();

  String? selectedGolongan;
  String? selectedParameter;
  DateTime? selectedDate;
  final nilaiController = TextEditingController();
  final catatanController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    _loadActiveTarget();
  }

  Future<void> _loadActiveTarget() async {
    if (!AuthService.isUserAuthenticated()) {
      _showErrorAndNavigateBack('Anda harus login untuk mengakses halaman ini');
      return;
    }

    try {
      final activeTarget = await _usageService.getActiveTarget();
      setState(() {
        selectedGolongan = activeTarget?['golongan'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorAndNavigateBack('Gagal memuat data target: $e');
    }
  }

  void _showErrorAndNavigateBack(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.red,
        ),
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  Future<void> _pickDate() async {
    if (!AuthService.isUserAuthenticated()) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _saveToDatabase() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_isFormValid()) return;

    try {
      _showLoadingDialog();

      final usage = UsageModel(
        userId: AuthService.getCurrentUserId(),
        golongan: selectedGolongan!,
        parameter: selectedParameter!,
        nilai: double.parse(nilaiController.text),
        tanggal: selectedDate!,
        catatan: catatanController.text.isEmpty ? null : catatanController.text,
        createdAt: DateTime.now(),
      );

      await _usageService.saveDailyUsage(usage);

      Navigator.pop(context); // Close loading dialog
      Navigator.pop(context); // Close current screen

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Data penggunaan berhasil disimpan"),
          backgroundColor: AppColors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Terjadi kesalahan: $e"),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      ),
    );
  }

  bool _isFormValid() {
    return selectedGolongan != null &&
        selectedParameter != null &&
        selectedDate != null &&
        nilaiController.text.isNotEmpty;
  }

  String get _estimatedConversion {
    if (nilaiController.text.isEmpty ||
        selectedGolongan == null ||
        selectedParameter == null) {
      return '';
    }

    final nilai = double.tryParse(nilaiController.text) ?? 0.0;
    if (nilai <= 0) return '';

    // Create temporary usage model for conversion
    final tempUsage = UsageModel(
      golongan: selectedGolongan!,
      parameter: selectedParameter!,
      nilai: nilai,
      tanggal: DateTime.now(),
      createdAt: DateTime.now(),
    );

    return tempUsage.getEstimatedConversion();
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isUserAuthenticated()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorAndNavigateBack('Sesi login telah berakhir');
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: const Text(
          "Tambah Penggunaan Harian",
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 24),
                  _buildFormCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
        children: [
          Icon(
            Icons.add_chart,
            size: 48,
            color: AppColors.primaryBlue,
          ),
          const SizedBox(height: 12),
          Text(
            "PENGGUNAAN HARIAN",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Catat penggunaan listrik harian Anda",
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
          if (selectedGolongan != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      "Golongan dipilih dari target aktif",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel("Tanggal"),
            const SizedBox(height: 8),
            _buildDateField(),
            const SizedBox(height: 20),
            _buildSectionLabel("Golongan Rumah Tangga"),
            const SizedBox(height: 8),
            _buildDropdownField(
              label: "Pilih Golongan",
              value: selectedGolongan,
              items: UsageConstants.golonganOptions,
              onChanged: (value) => setState(() => selectedGolongan = value),
              icon: Icons.home,
              validator: (value) =>
                  FormValidators.validateRequired(value, 'Golongan'),
            ),
            const SizedBox(height: 20),
            _buildSectionLabel("Parameter"),
            const SizedBox(height: 8),
            _buildDropdownField(
              label: "Pilih Parameter",
              value: selectedParameter,
              items: UsageConstants.parameterOptions,
              onChanged: (value) => setState(() => selectedParameter = value),
              icon: Icons.track_changes,
              validator: (value) =>
                  FormValidators.validateRequired(value, 'Parameter'),
            ),
            const SizedBox(height: 20),
            _buildSectionLabel("Nilai Penggunaan"),
            const SizedBox(height: 8),
            _buildNilaiField(),
            const SizedBox(height: 20),
            _buildSectionLabel("Catatan (Opsional)"),
            const SizedBox(height: 8),
            _buildTextField(
              label: "Tambahkan catatan",
              controller: catatanController,
              icon: Icons.note,
            ),
            const SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.black,
      ),
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      readOnly: true,
      onTap: _pickDate,
      controller: TextEditingController(
        text: selectedDate != null
            ? DateFormat(UsageConstants.dateFormat).format(selectedDate!)
            : "",
      ),
      decoration: _buildInputDecoration(
        label: "Pilih tanggal",
        icon: Icons.calendar_today,
      ),
      validator: (_) => FormValidators.validateDate(selectedDate),
      style: TextStyle(color: AppColors.black),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item, style: TextStyle(color: AppColors.black)),
          );
        }).toList(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.textGrey),
          prefixIcon: Icon(icon, color: AppColors.primaryBlue),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: validator,
        icon: Icon(Icons.arrow_drop_down, color: AppColors.textGrey),
        isExpanded: true,
        dropdownColor: AppColors.white,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    String? suffixText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _buildInputDecoration(
        label: label,
        icon: icon,
        suffixText: suffixText,
      ),
      validator: validator,
      style: TextStyle(color: AppColors.black),
    );
  }

  Widget _buildNilaiField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          label: selectedParameter != null
              ? 'Nilai ${selectedParameter!}'
              : 'Nilai',
          controller: nilaiController,
          icon: Icons.electrical_services,
          keyboardType: TextInputType.number,
          suffixText: selectedParameter == "Biaya (Rp)" ? "Rp" : "kWh",
          validator: (value) => FormValidators.validateNumber(value, 'Nilai'),
        ),
        if (_estimatedConversion.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _estimatedConversion,
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isFormValid() ? _saveToDatabase : null,
        icon: Icon(
          Icons.save,
          color: _isFormValid() ? AppColors.white : AppColors.textGrey,
        ),
        label: Text(
          "Simpan Data",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _isFormValid() ? AppColors.white : AppColors.textGrey,
          ),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor:
              _isFormValid() ? AppColors.primaryBlue : AppColors.grey,
          elevation: _isFormValid() ? 2 : 0,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    String? suffixText,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppColors.textGrey),
      suffixText: suffixText,
      filled: true,
      fillColor: AppColors.backgroundColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.grey.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.grey.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primaryBlue),
      ),
      prefixIcon: Icon(icon, color: AppColors.primaryBlue),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  void dispose() {
    nilaiController.dispose();
    catatanController.dispose();
    super.dispose();
  }
}
