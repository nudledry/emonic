// lib/screens/home/views/penggunaan/history_target_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:emonic/helpers/database_helper.dart';
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error memuat data: $e"),
            backgroundColor: AppColors.red,
          ),
        );
      }
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
      if (e.toString().contains('no such column: userId')) {
        try {
          final db = await _databaseHelper.database;
          final allTargets =
              await db.query('targets', orderBy: 'createdAt DESC');
          setState(() {
            _targets = allTargets;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    const Text("Menampilkan semua data (mode kompatibilitas)"),
                backgroundColor: AppColors.yellow,
              ),
            );
          }
        } catch (e2) {
          print("Error fallback: $e2");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error memuat data: $e2"),
                backgroundColor: AppColors.red,
              ),
            );
          }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: const Text(
          "Riwayat Target",
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCurrentUserAndTargets,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryBlue,
                ),
              )
            : _currentUserId == null
                ? _buildLoginPrompt()
                : _targets.isEmpty
                    ? _buildEmptyState()
                    : _buildTargetList(),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.login,
                size: 64,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(height: 16),
              Text(
                "Login Diperlukan",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Silakan login untuk melihat riwayat target Anda.",
                style: TextStyle(
                  color: AppColors.textGrey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 64,
                color: AppColors.textGrey,
              ),
              const SizedBox(height: 16),
              Text(
                "Belum Ada Target",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Belum ada data target untuk Anda. Mulai buat target penggunaan listrik Anda.",
                style: TextStyle(
                  color: AppColors.textGrey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.add),
                label: const Text('Buat Target'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTargetList() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.chartBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.flag, color: AppColors.primaryBlue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Target",
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textGrey,
                        ),
                      ),
                      Text(
                        "${_targets.length} target tersimpan",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Target List
          Expanded(
            child: ListView.separated(
              itemCount: _targets.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final target = _targets[index];
                return _buildTargetCard(target);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetCard(Map<String, dynamic> target) {
    return Container(
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
          // Card Header
          Container(
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.home,
                    color: AppColors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    target['golongan'] ?? 'N/A',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                ),
                _buildActionButtons(target),
              ],
            ),
          ),

          // Card Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(Icons.track_changes, "Parameter",
                    target['parameter'] ?? 'N/A'),
                const SizedBox(height: 8),
                _buildInfoRow(
                    Icons.flag, "Target", "${target['target'] ?? 'N/A'} kWh"),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.calendar_today,
                  "Periode",
                  "${formatDate(target['startDate'])} - ${formatDate(target['endDate'])}",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textGrey),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textGrey,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> target) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.edit, color: AppColors.primaryBlue),
          onPressed: () => _showEditDialog(context, target),
          tooltip: 'Edit',
        ),
        IconButton(
          icon: Icon(Icons.delete, color: AppColors.red),
          onPressed: () => _showDeleteDialog(target),
          tooltip: 'Hapus',
        ),
      ],
    );
  }

  void _showDeleteDialog(Map<String, dynamic> target) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Konfirmasi Hapus",
            style: TextStyle(
              color: AppColors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Apakah Anda yakin ingin menghapus target ini?",
            style: TextStyle(color: AppColors.textGrey),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textGrey,
              ),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteTarget(target['id']);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Hapus"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditDialog(
      BuildContext context, Map<String, dynamic> target) async {
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
            backgroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              "Edit Target",
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildEditDropdown(
                      "Golongan",
                      selectedGolongan,
                      [
                        "R-1/TR Daya 900 VA",
                        "R-1/TR Daya 1.300 VA",
                        "R-2/TR Daya 3.500 VA",
                        "R-3/TR Daya 6.600 VA",
                        "B-2/TR Daya 200 kVA",
                        "P-1/TR Untuk Penerangan Jalan Umum"
                      ],
                      (value) =>
                          setStateDialog(() => selectedGolongan = value ?? ''),
                    ),
                    const SizedBox(height: 16),
                    _buildEditDropdown(
                      "Parameter",
                      selectedParameter,
                      ["Daya Listrik (kWh)", "Biaya (Rp)"],
                      (value) =>
                          setStateDialog(() => selectedParameter = value ?? ''),
                    ),
                    const SizedBox(height: 16),
                    _buildEditTextField("Nilai Target", targetController),
                    const SizedBox(height: 16),
                    _buildEditDateField(
                      "Waktu Mulai",
                      startDate,
                      () async {
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
                    const SizedBox(height: 16),
                    _buildEditDateField(
                      "Waktu Akhir",
                      endDate,
                      () async {
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
                onPressed: () => _updateTarget(
                  target,
                  selectedGolongan,
                  selectedParameter,
                  targetController.text,
                  startDate,
                  endDate,
                ),
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

  Widget _buildEditDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textGrey),
        filled: true,
        fillColor: AppColors.backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.grey.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryBlue),
        ),
      ),
      value: value.isNotEmpty ? value : null,
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
      style: TextStyle(color: AppColors.black),
      dropdownColor: AppColors.white,
    );
  }

  Widget _buildEditTextField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: TextStyle(color: AppColors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textGrey),
        filled: true,
        fillColor: AppColors.backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.grey.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryBlue),
        ),
      ),
    );
  }

  Widget _buildEditDateField(String label, DateTime? date, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        title: Text(
          "$label: ${date != null ? formatDate(date.toIso8601String()) : 'Pilih tanggal'}",
          style: TextStyle(color: AppColors.black),
        ),
        trailing: Icon(Icons.calendar_today, color: AppColors.primaryBlue),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _updateTarget(
    Map<String, dynamic> target,
    String golongan,
    String parameter,
    String targetValue,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    if (startDate == null || endDate == null || targetValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Semua field harus diisi!"),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    try {
      Map<String, dynamic> updatedTarget = {
        'golongan': golongan,
        'parameter': parameter,
        'target': targetValue,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'createdAt': target['createdAt'] ?? DateTime.now().toIso8601String(),
        'userId': target['userId'] ?? _currentUserId ?? 'default_user_id',
      };

      await _databaseHelper.updateTarget(target['id'], updatedTarget);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Target berhasil diperbarui"),
          backgroundColor: AppColors.green,
        ),
      );
      _loadTargets();
    } catch (e) {
      print("Error updating target: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error memperbarui target: $e"),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  Future<void> _deleteTarget(int id) async {
    try {
      if (_currentUserId != null) {
        await _databaseHelper.deleteTarget(id, _currentUserId!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Target berhasil dihapus"),
            backgroundColor: AppColors.green,
          ),
        );
        _loadTargets();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                "Tidak dapat menghapus target: Pengguna tidak valid."),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } catch (e) {
      print("Error deleting target: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error menghapus target: $e"),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }
}
