// lib/screens/home/views/penggunaan/history_target_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:emonic/screens/home/views/database/database_helper.dart';
import 'package:emonic/constants/colors.dart';

class HistoryTargetScreen extends StatefulWidget {
  const HistoryTargetScreen({super.key});

  @override
  State<HistoryTargetScreen> createState() => _HistoryTargetScreenState();
}

class _HistoryTargetScreenState extends State<HistoryTargetScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Map<String, dynamic>> _targets = [];
  String? _currentUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAndTargets();
  }

  Future<void> _loadCurrentUserAndTargets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _currentUserId = FirebaseAuth.instance.currentUser?.uid;

      if (_currentUserId != null) {
        await _loadTargets();
      } else {
        setState(() {
          _targets = [];
        });
        print("User belum login, tidak dapat memuat riwayat target.");
      }
    } catch (e) {
      print("Error loading user and targets: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error memuat data: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTargets() async {
    try {
      if (_currentUserId != null) {
        final targets = await _databaseHelper.getTargetsByUser(_currentUserId!);
        setState(() {
          _targets = targets;
        });
      }
    } catch (e) {
      print("Error loading targets: $e");
      // Jika error karena masalah database, coba reset dan load ulang
      if (e.toString().contains('no such column: userId')) {
        try {
          // Coba ambil semua data tanpa filter userId sebagai fallback
          final db = await _databaseHelper.database;
          final allTargets = await db.query('targets', orderBy: 'createdAt DESC');
          setState(() {
            _targets = allTargets;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Menampilkan semua data (mode kompatibilitas)")),
          );
        } catch (e2) {
          print("Error fallback: $e2");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error memuat data: $e2")),
          );
        }
      }
    }
  }

  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Tanggal Tidak Valid';
    }
    
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      print('Error parsing date: $dateString, Error: $e');
      return 'Tanggal Tidak Valid';
    }
  }

  Future<void> _showEditDialog(BuildContext context, Map<String, dynamic> target) async {
    final TextEditingController targetController =
        TextEditingController(text: target['target']?.toString() ?? '');
    DateTime? startDate = DateTime.tryParse(target['startDate'] ?? '');
    DateTime? endDate = DateTime.tryParse(target['endDate'] ?? '');

    String selectedGolongan = target['golongan'] ?? '';
    String selectedParameter = target['parameter'] ?? '';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: Text(
              "Edit Target",
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: AppColors.white,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            content: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 400.0,
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.white,
                          labelText: "Golongan",
                          labelStyle: TextStyle(color: AppColors.textGrey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: AppColors.primaryBlue),
                          ),
                        ),
                        value: selectedGolongan.isNotEmpty ? selectedGolongan : null,
                        onChanged: (String? newValue) {
                          setStateDialog(() {
                            selectedGolongan = newValue ?? '';
                          });
                        },
                        items: [
                          "R-1/TR Daya 900 VA",
                          "R-1/TR Daya 1.300 VA",
                          "R-2/TR Daya 3.500 VA",
                          "R-3/TR Daya 6.600 VA",
                          "B-2/TR Daya 200 kVA",
                          "P-1/TR Untuk Penerangan Jalan Umum"
                        ].map((golongan) {
                          return DropdownMenuItem<String>(
                            value: golongan,
                            child: Text(
                              golongan,
                              style: TextStyle(color: AppColors.black),
                            ),
                          );
                        }).toList(),
                        style: TextStyle(color: AppColors.black),
                        icon: Icon(Icons.arrow_drop_down,
                            color: AppColors.textGrey),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 400.0,
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.white,
                          labelText: "Parameter",
                          labelStyle: TextStyle(color: AppColors.textGrey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: AppColors.primaryBlue),
                          ),
                        ),
                        value: selectedParameter.isNotEmpty ? selectedParameter : null,
                        onChanged: (String? newValue) {
                          setStateDialog(() {
                            selectedParameter = newValue ?? '';
                          });
                        },
                        items: [
                          "Daya Listrik (kWh)",
                          "Biaya (Rp)",
                        ].map((parameter) {
                          return DropdownMenuItem<String>(
                            value: parameter,
                            child: Text(
                              parameter,
                              style: TextStyle(color: AppColors.black),
                            ),
                          );
                        }).toList(),
                        style: TextStyle(color: AppColors.black),
                        icon: Icon(Icons.arrow_drop_down,
                            color: AppColors.textGrey),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: targetController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: AppColors.black),
                      decoration: InputDecoration(
                        labelText: "Nilai Target",
                        labelStyle: TextStyle(color: AppColors.textGrey),
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primaryBlue),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.grey),
                      ),
                      child: ListTile(
                        title: Text(
                          "Waktu Mulai: ${startDate != null ? formatDate(Timestamp.fromDate(startDate!)) : 'Pilih tanggal'}",
                          style: TextStyle(color: AppColors.black),
                        ),
                        trailing: Icon(Icons.calendar_today,
                            color: AppColors.primaryBlue),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setStateDialog(() => startDate = picked);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.grey),
                      ),
                      child: ListTile(
                        title: Text(
                          "Waktu Akhir: ${endDate != null ? formatDate(Timestamp.fromDate(endDate!)) : 'Pilih tanggal'}",
                          style: TextStyle(color: AppColors.black),
                        ),
                        trailing: Icon(Icons.calendar_today,
                            color: AppColors.primaryBlue),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: endDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setStateDialog(() => endDate = picked);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textGrey,
                ),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (startDate == null || endDate == null || targetController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Semua field harus diisi!")),
                    );
                    return;
                  }

                  try {
                    Map<String, dynamic> updatedTarget = {
                      'golongan': selectedGolongan,
                      'parameter': selectedParameter,
                      'target': targetController.text,
                      'startDate': startDate!.toIso8601String(),
                      'endDate': endDate!.toIso8601String(),
                      'createdAt': target['createdAt'] ?? DateTime.now().toIso8601String(),
                      'userId': target['userId'] ?? _currentUserId ?? 'default_user_id',
                    };

                    await _databaseHelper.updateTarget(target['id'], updatedTarget);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Target berhasil diperbarui")),
                    );
                    _loadTargets();
                  } catch (e) {
                    print("Error updating target: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error memperbarui target: $e")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Simpan"),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteTarget(int id) async {
    try {
      if (_currentUserId != null) {
        await _databaseHelper.deleteTarget(id, _currentUserId!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Target berhasil dihapus")),
        );
        _loadTargets();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tidak dapat menghapus target: Pengguna tidak valid.")),
        );
      }
    } catch (e) {
      print("Error deleting target: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error menghapus target: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text("Riwayat Target"),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCurrentUserAndTargets,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUserId == null
              ? const Center(child: Text("Silakan login untuk melihat riwayat target Anda."))
              : _targets.isEmpty
                  ? const Center(child: Text("Belum ada data target untuk Anda."))
                  : ListView.builder(
                      itemCount: _targets.length,
                      itemBuilder: (context, index) {
                        final target = _targets[index];

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: Colors.blue[50],
                          child: ListTile(
                            title: Text(target['golongan'] ?? 'N/A'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Parameter: ${target['parameter'] ?? 'N/A'}"),
                                Text("Target: ${target['target'] ?? 'N/A'}"),
                                Text(
                                  "Periode: ${formatDate(target['startDate'])} - ${formatDate(target['endDate'])}",
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  color: Colors.green,
                                  onPressed: () {
                                    _showEditDialog(context, target);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  color: Colors.red,
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text("Konfirmasi Hapus"),
                                          content: const Text("Apakah Anda yakin ingin menghapus target ini?"),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(),
                                              child: const Text("Batal"),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                _deleteTarget(target['id']);
                                              },
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                              child: const Text("Hapus", style: TextStyle(color: Colors.white)),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
