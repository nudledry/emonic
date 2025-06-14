// lib/screens/home/views/penggunaan/target_pengguna.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:emonic/screens/home/views/database/database_helper.dart';
import 'package:emonic/screens/home/views/penggunaan/history_target_screen.dart';
import 'package:emonic/screens/home/views/penggunaan/berhasil_input_screen.dart';
import 'package:emonic/constants/colors.dart';

class TargetPenggunaanScreen extends StatefulWidget {
  const TargetPenggunaanScreen({super.key});

  @override
  State<TargetPenggunaanScreen> createState() => _TargetPenggunaanScreenState();
}

class _TargetPenggunaanScreenState extends State<TargetPenggunaanScreen> {
  String? selectedGolongan;
  String? selectedParameter;
  DateTime? startDate;
  DateTime? endDate;
  final targetController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Daftar opsi untuk dropdown
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

  // Fungsi untuk menampilkan date picker
  Future<void> pickDate({required bool isStart}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? DateTime.now() : (startDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
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
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  // Fungsi untuk menyimpan data ke SQLite
  void _saveToSQLite() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (selectedGolongan != null &&
          selectedParameter != null &&
          startDate != null &&
          endDate != null &&
          targetController.text.isNotEmpty) {

        // Dapatkan userId saat ini dari Firebase Authentication
        final userId = FirebaseAuth.instance.currentUser?.uid;

        if (userId == null) {
          // Tampilkan pesan error jika pengguna belum login
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Anda harus login untuk menyimpan target.")),
          );
          return; // Hentikan proses penyimpanan
        }

        try {
          Map<String, dynamic> targetData = {
            'userId': userId, // <--- Tambahkan userId di sini
            'golongan': selectedGolongan,
            'parameter': selectedParameter,
            'startDate': startDate!.toIso8601String(),
            'endDate': endDate!.toIso8601String(),
            'target': targetController.text,
            'createdAt': DateTime.now().toIso8601String(),
          };

          await _databaseHelper.insertTarget(targetData);

          Navigator.pop(context); // Close loading dialog

          // Navigasi ke BerhasilInputScreen setelah berhasil menyimpan
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const BerhasilInputScreen()),
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
        startDate != null &&
        endDate != null &&
        targetController.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: const Text(
          "Target Penggunaan",
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Riwayat Target',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const HistoryTargetScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        Icons.flag,
                        size: 48,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "TARGET PENGGUNAAN",
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
                        "Tetapkan target penggunaan listrik Anda",
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textGrey,
                        ),
                        textAlign: TextAlign.center,
                      ),
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

                        _buildSectionLabel("Parameter Target"),
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

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionLabel("Waktu Mulai"),
                                  const SizedBox(height: 8),
                                  _buildRoundedDateField(
                                    label: "Pilih tanggal mulai",
                                    selectedDate: startDate,
                                    onTap: () => pickDate(isStart: true),
                                  ),
                                ],
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 30),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  "Golongan Rumah Tangga",
                                  style: TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 8),
                                _buildRoundedDropdown(
                                  label: "Golongan Rumah Tangga",
                                  value: selectedGolongan,
                                  items: golonganOptions,
                                  onChanged: (value) =>
                                      setState(() => selectedGolongan = value),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Parameter Target",
                                  style: TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 8),
                                _buildRoundedDropdown(
                                  label: "Parameter Target",
                                  value: selectedParameter,
                                  items: parameterOptions,
                                  onChanged: (value) =>
                                      setState(() => selectedParameter = value),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Waktu Mulai",
                                  style: TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 8),
                                _buildRoundedDateField(
                                  label: "Waktu Mulai",
                                  selectedDate: startDate,
                                  onTap: () => pickDate(isStart: true),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Waktu Akhir",
                                  style: TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 8),
                                _buildRoundedDateField(
                                  label: "Waktu Akhir",
                                  selectedDate: endDate,
                                  onTap: () => pickDate(isStart: false),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Nilai Target",
                                  style: TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 8),
                                _buildRoundedTextField(
                                    label: "Nilai Target",
                                    controller: targetController),
                                const SizedBox(height: 30),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isFormFilled()
                                        ? _saveToSQLite
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16, horizontal: 50),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      backgroundColor: _isFormFilled()
                                          ? const Color.fromARGB(
                                              255, 250, 204, 2)
                                          : Colors.lightBlue[100],
                                      foregroundColor: _isFormFilled()
                                          ? Colors.blue
                                          : Colors.white,
                                      textStyle:
                                          const TextStyle(fontSize: 18),
                                    ),
                                    child: Text(
                                      "Simpan",
                                      style: TextStyle(
                                        color: _isFormFilled()
                                            ? const Color.fromARGB(
                                                255, 255, 255, 255)
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        _buildSectionLabel("Nilai Target"),
                        const SizedBox(height: 8),
                        _buildRoundedTextField(
                          label: "Masukkan nilai target",
                          controller: targetController,
                          icon: Icons.flag,
                        ),
                        const SizedBox(height: 32),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                _isFormFilled() ? _saveToFirestore : null,
                            icon: Icon(
                              Icons.save,
                              color: _isFormFilled()
                                  ? AppColors.white
                                  : AppColors.textGrey,
                            ),
                            label: Text(
                              "Simpan Target",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _isFormFilled()
                                    ? AppColors.white
                                    : AppColors.textGrey,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
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

  // Widget untuk membuat dropdown dengan tampilan yang diinginkan
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

  // Widget untuk membuat input field tanggal dengan tampilan yang diinginkan
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
            ? "${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}"
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

  // Widget untuk membuat input field teks dengan tampilan yang diinginkan
  Widget _buildRoundedTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
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
    );
  }
}
