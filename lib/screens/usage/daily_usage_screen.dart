import 'package:flutter/material.dart';
import 'package:emonic/helpers/database_helper.dart';
import 'package:emonic/constants/colors.dart';
import 'package:intl/intl.dart';
import 'package:emonic/constants/tarif_listrik.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DailyUsageScreen extends StatefulWidget {
  const DailyUsageScreen({super.key});

  @override
  State<DailyUsageScreen> createState() => _DailyUsageScreenState();
}

class _DailyUsageScreenState extends State<DailyUsageScreen> {
  String? selectedGolongan;
  String? selectedParameter;
  DateTime? selectedDate;
  final nilaiController = TextEditingController();
  final catatanController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;

  // Daftar opsi untuk dropdown (sama dengan target)
  List<String> golonganOptions = [
    "R-1/TR Daya 900 VA",
    "R-1/TR Daya 1.300 VA",
    "R-2/TR Daya 3.500 VA",
    "R-3/TR Daya 6.600 VA",
    "B-2/TR Daya 200 kVA",
    "P-1/TR Untuk Penerangan Jalan Umum"
  ];

  List<String> parameterOptions = [
    "Daya Listrik (kWh)",
    "Biaya (Rp)",
  ];

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    _loadActiveTarget();
  }

  // Fungsi untuk memuat target yang sedang aktif
  Future<void> _loadActiveTarget() async {
    try {
      final activeTarget = await DatabaseHelper().getActiveTarget();

      if (activeTarget != null) {
        setState(() {
          selectedGolongan = activeTarget['golongan'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading active target: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fungsi untuk menampilkan date picker
  Future<void> pickDate() async {
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
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // Fungsi untuk menyimpan data ke SQLite
  void _saveToDatabase() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (selectedGolongan != null &&
          selectedParameter != null &&
          selectedDate != null &&
          nilaiController.text.isNotEmpty) {
        // Check if user is authenticated
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  "Anda harus login untuk menyimpan data penggunaan"),
              backgroundColor: AppColors.red,
            ),
          );
          return;
        }

        try {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryBlue,
              ),
            ),
          );

          await DatabaseHelper().insertDailyUsage({
            'userId': userId, // Add userId to the data
            'golongan': selectedGolongan!,
            'parameter': selectedParameter!,
            'nilai': double.parse(nilaiController.text),
            'tanggal': DateFormat('yyyy-MM-dd').format(selectedDate!),
            'catatan': catatanController.text,
            'created_at': DateTime.now().toIso8601String(),
          });

          Navigator.pop(context); // Close loading dialog
          Navigator.pop(context); // Close input screen

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
    }
  }

  // Fungsi untuk memeriksa apakah semua field telah terisi
  bool _isFormFilled() {
    return selectedGolongan != null &&
        selectedParameter != null &&
        selectedDate != null &&
        nilaiController.text.isNotEmpty;
  }

  String get _estimatedConversion {
    if (nilaiController.text.isEmpty ||
        selectedGolongan == null ||
        selectedParameter == null) return '';

    final nilai = double.tryParse(nilaiController.text) ?? 0.0;
    if (nilai <= 0) return '';

    if (selectedParameter == "Biaya (Rp)") {
      final kwh = TarifListrik.convertBiayaToKwh(nilai, selectedGolongan!);
      return '≈ ${kwh.toStringAsFixed(2)} kWh';
    } else {
      final rupiah = TarifListrik.convertKwhToBiaya(nilai, selectedGolongan!);
      return '≈ ${TarifListrik.formatRupiah(rupiah)}';
    }
  }

  @override
  Widget build(BuildContext context) {
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
              child: CircularProgressIndicator(
                color: AppColors.primaryBlue,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header Card
                  Container(
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
                        // Tampilkan info jika golongan diambil dari target aktif
                        if (selectedGolongan != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primaryBlue.withValues(alpha: 0.1),
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
                  ),
                  const SizedBox(height: 24),

                  // Form Card
                  Container(
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
                        children: <Widget>[
                          _buildSectionLabel("Tanggal"),
                          const SizedBox(height: 8),
                          _buildRoundedDateField(
                            label: "Pilih tanggal",
                            selectedDate: selectedDate,
                            onTap: pickDate,
                          ),
                          const SizedBox(height: 20),

                          _buildSectionLabel("Golongan Rumah Tangga"),
                          const SizedBox(height: 8),
                          _buildRoundedDropdown(
                            label: "Pilih Golongan",
                            value: selectedGolongan,
                            items: golonganOptions,
                            onChanged: (value) =>
                                setState(() => selectedGolongan = value),
                            icon: Icons.home,
                          ),
                          const SizedBox(height: 20),

                          _buildSectionLabel("Parameter"),
                          const SizedBox(height: 8),
                          _buildRoundedDropdown(
                            label: "Pilih Parameter",
                            value: selectedParameter,
                            items: parameterOptions,
                            onChanged: (value) =>
                                setState(() => selectedParameter = value),
                            icon: Icons.track_changes,
                          ),
                          const SizedBox(height: 20),

                          _buildSectionLabel("Nilai Penggunaan"),
                          const SizedBox(height: 8),
                          _buildNilaiField(),
                          const SizedBox(height: 20),

                          _buildSectionLabel("Catatan (Opsional)"),
                          const SizedBox(height: 8),
                          _buildRoundedTextField(
                            label: "Tambahkan catatan",
                            controller: catatanController,
                            icon: Icons.note,
                            isOptional: true,
                          ),
                          const SizedBox(height: 32),

                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed:
                                  _isFormFilled() ? _saveToDatabase : null,
                              icon: Icon(
                                Icons.save,
                                color: _isFormFilled()
                                    ? AppColors.white
                                    : AppColors.textGrey,
                              ),
                              label: Text(
                                "Simpan Data",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _isFormFilled()
                                      ? AppColors.white
                                      : AppColors.textGrey,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: _isFormFilled()
                                    ? AppColors.primaryBlue
                                    : AppColors.grey,
                                elevation: _isFormFilled() ? 2 : 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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

  Widget _buildRoundedDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: TextStyle(color: AppColors.black),
            ),
          );
        }).toList(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.textGrey),
          prefixIcon: Icon(icon, color: AppColors.primaryBlue),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        style: TextStyle(color: AppColors.black),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Field ini harus dipilih';
          }
          return null;
        },
        icon: Icon(Icons.arrow_drop_down, color: AppColors.textGrey),
        isExpanded: true,
        dropdownColor: AppColors.white,
      ),
    );
  }

  Widget _buildRoundedDateField({
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
  }) {
    return TextFormField(
      readOnly: true,
      onTap: onTap,
      controller: TextEditingController(
        text: selectedDate != null
            ? DateFormat('dd/MM/yyyy').format(selectedDate)
            : "",
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textGrey),
        filled: true,
        fillColor: AppColors.backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.grey.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.grey.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryBlue),
        ),
        prefixIcon: Icon(Icons.calendar_today, color: AppColors.primaryBlue),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: (value) {
        if (selectedDate == null) {
          return 'Tanggal harus dipilih';
        }
        return null;
      },
      style: TextStyle(color: AppColors.black),
    );
  }

  Widget _buildRoundedTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isOptional = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isOptional ? TextInputType.text : TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textGrey),
        filled: true,
        fillColor: AppColors.backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.grey.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.grey.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryBlue),
        ),
        prefixIcon: Icon(icon, color: AppColors.primaryBlue),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: isOptional
          ? null
          : (value) {
              if (value == null || value.isEmpty) {
                return 'Field ini tidak boleh kosong';
              }
              if (double.tryParse(value) == null) {
                return 'Masukkan nilai yang valid';
              }
              return null;
            },
      style: TextStyle(color: AppColors.black),
    );
  }

  Widget _buildNilaiField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: nilaiController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: selectedParameter != null
                ? 'Nilai ${selectedParameter!}'
                : 'Nilai',
            suffixText: selectedParameter == "Biaya (Rp)" ? "Rp" : "kWh",
            filled: true,
            fillColor: AppColors.backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.grey.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.grey.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryBlue),
            ),
            prefixIcon:
                Icon(Icons.electrical_services, color: AppColors.primaryBlue),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          onChanged: (value) {
            setState(() {}); // Trigger rebuild untuk update konversi
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Field ini tidak boleh kosong';
            }
            if (double.tryParse(value) == null) {
              return 'Masukkan nilai yang valid';
            }
            return null;
          },
          style: TextStyle(color: AppColors.black),
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
}
