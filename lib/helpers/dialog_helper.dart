import 'package:flutter/material.dart';
import 'package:emonic/models/usage_model.dart';
import 'package:emonic/constants/colors.dart';
import 'package:emonic/constants/usage_constants.dart';
import 'package:emonic/screens/usage/widgets/form_widgets.dart';

class DialogHelper {
  static Future<UsageModel?> showEditDialog(
    BuildContext context,
    UsageModel usage,
  ) async {
    final TextEditingController nilaiController =
        TextEditingController(text: usage.nilai.toString());
    final TextEditingController catatanController =
        TextEditingController(text: usage.catatan ?? '');

    String selectedGolongan = usage.golongan;
    String selectedParameter = usage.parameter;
    DateTime selectedDate = usage.tanggal;

    return await showDialog<UsageModel>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) => Dialog(
            backgroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogHeader(context),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FormWidgets.buildDropdown(
                            "Golongan",
                            selectedGolongan,
                            UsageConstants.golonganOptions,
                            (value) => setStateDialog(
                                () => selectedGolongan = value ?? ''),
                          ),
                          const SizedBox(height: 16),
                          FormWidgets.buildDropdown(
                            "Parameter",
                            selectedParameter,
                            UsageConstants.parameterOptions,
                            (value) => setStateDialog(
                                () => selectedParameter = value ?? ''),
                          ),
                          const SizedBox(height: 16),
                          FormWidgets.buildTextField(
                            "Nilai",
                            nilaiController,
                            TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          FormWidgets.buildDateField(
                            "Tanggal",
                            selectedDate,
                            () async {
                              final picked =
                                  await _showDatePicker(context, selectedDate);
                              if (picked != null) {
                                setStateDialog(() => selectedDate = picked);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          FormWidgets.buildTextField(
                            "Catatan",
                            catatanController,
                            TextInputType.text,
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildDialogActions(
                    context,
                    () => Navigator.pop(context),
                    () {
                      if (_validateForm(nilaiController.text)) {
                        final updatedUsage = usage.copyWith(
                          golongan: selectedGolongan,
                          parameter: selectedParameter,
                          nilai: double.parse(nilaiController.text),
                          tanggal: selectedDate,
                          catatan: catatanController.text,
                        );
                        Navigator.pop(context, updatedUsage);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<bool> showDeleteDialog(
    BuildContext context,
    UsageModel usage,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.warning, color: AppColors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Konfirmasi Hapus",
                      style: TextStyle(
                        color: AppColors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Apakah Anda yakin ingin menghapus data penggunaan ini?",
                    style: TextStyle(color: AppColors.textGrey),
                  ),
                  const SizedBox(height: 12),
                  _buildUsagePreview(usage),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textGrey,
                  ),
                  child: const Text("Batal"),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.delete,
                      color: AppColors.white, size: 16),
                  label: const Text("Hapus"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.red,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  static Widget _buildDialogHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.edit, color: AppColors.primaryBlue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Edit Penggunaan",
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: AppColors.textGrey, size: 20),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  static Widget _buildDialogActions(
    BuildContext context,
    VoidCallback onCancel,
    VoidCallback onSave,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textGrey,
                side: BorderSide(color: AppColors.textGrey),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Batal"),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save, size: 18),
              label: const Text("Simpan"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildUsagePreview(UsageModel usage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tanggal: ${usage.formattedDate}",
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textGrey,
            ),
          ),
          Text(
            "Nilai: ${usage.formattedValue} kWh",
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textGrey,
            ),
          ),
          if (usage.catatan != null && usage.catatan!.isNotEmpty)
            Text(
              "Catatan: ${usage.catatan}",
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textGrey,
              ),
            ),
        ],
      ),
    );
  }

  static Future<DateTime?> _showDatePicker(
      BuildContext context, DateTime initialDate) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
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
  }

  static bool _validateForm(String nilai) {
    return nilai.isNotEmpty && double.tryParse(nilai) != null;
  }
}
