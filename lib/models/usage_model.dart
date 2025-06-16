import 'package:emonic/constants/tarif_listrik.dart';

class UsageModel {
  final int? id;
  final String? userId;
  final String golongan;
  final String parameter;
  final double nilai;
  final DateTime tanggal;
  final String? catatan;
  final DateTime createdAt;

  UsageModel({
    this.id,
    this.userId,
    required this.golongan,
    required this.parameter,
    required this.nilai,
    required this.tanggal,
    this.catatan,
    required this.createdAt,
  });

  factory UsageModel.fromMap(Map<String, dynamic> map) {
    return UsageModel(
      id: map['id'],
      userId: map['userId']?.toString(),
      golongan: map['golongan']?.toString() ?? '',
      parameter: map['parameter']?.toString() ?? '',
      nilai: (map['nilai'] ?? 0.0).toDouble(),
      tanggal:
          DateTime.tryParse(map['tanggal']?.toString() ?? '') ?? DateTime.now(),
      catatan: map['catatan']?.toString(),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'golongan': golongan,
      'parameter': parameter,
      'nilai': nilai,
      'tanggal': tanggal.toIso8601String().split('T')[0],
      'catatan': catatan,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Konversi nilai ke kWh
  double get nilaiInKwh {
    if (parameter == "Biaya (Rp)") {
      return TarifListrik.convertBiayaToKwh(nilai, golongan);
    }
    return nilai;
  }

  // Konversi nilai ke Rupiah
  double get nilaiInRupiah {
    if (parameter == "Daya Listrik (kWh)") {
      return TarifListrik.convertKwhToBiaya(nilai, golongan);
    }
    return nilai;
  }

  String get formattedValue {
    if (parameter == "Biaya (Rp)") {
      return TarifListrik.formatRupiah(nilai);
    }
    return nilai.toStringAsFixed(2);
  }

  String get formattedValueWithUnit {
    if (parameter == "Biaya (Rp)") {
      return '${TarifListrik.formatRupiah(nilai)} (${nilaiInKwh.toStringAsFixed(2)} kWh)';
    }
    return '${nilai.toStringAsFixed(2)} kWh (${TarifListrik.formatRupiah(nilaiInRupiah)})';
  }

  String get displayUnit {
    return parameter == "Biaya (Rp)" ? "Rp" : "kWh";
  }

  // Helper method untuk format Rupiah yang lebih pendek
  String get formattedValueInRupiah {
    final rupiah = nilaiInRupiah;
    if (rupiah >= 1000000) {
      return 'Rp ${(rupiah / 1000000).toStringAsFixed(1)}M';
    } else if (rupiah >= 1000) {
      return 'Rp ${(rupiah / 1000).toStringAsFixed(1)}K';
    }
    return TarifListrik.formatRupiah(rupiah);
  }

  // Helper method untuk estimasi konversi
  String getEstimatedConversion() {
    if (parameter == "Biaya (Rp)") {
      return '≈ ${nilaiInKwh.toStringAsFixed(2)} kWh';
    } else {
      return '≈ ${TarifListrik.formatRupiah(nilaiInRupiah)}';
    }
  }

  // Helper method untuk cek apakah nilai besar
  bool get isHighValue {
    return nilaiInKwh > 100;
  }

  // Helper method untuk level kategori
  String get usageCategory {
    final kwhValue = nilaiInKwh;
    if (kwhValue <= 50) return 'Low';
    if (kwhValue <= 100) return 'Normal';
    if (kwhValue <= 200) return 'High';
    return 'Very High';
  }

  UsageModel copyWith({
    int? id,
    String? userId,
    String? golongan,
    String? parameter,
    double? nilai,
    DateTime? tanggal,
    String? catatan,
    DateTime? createdAt,
  }) {
    return UsageModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      golongan: golongan ?? this.golongan,
      parameter: parameter ?? this.parameter,
      nilai: nilai ?? this.nilai,
      tanggal: tanggal ?? this.tanggal,
      catatan: catatan ?? this.catatan,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isToday {
    final now = DateTime.now();
    return tanggal.year == now.year &&
        tanggal.month == now.month &&
        tanggal.day == now.day;
  }

  String get formattedDate {
    return "${tanggal.day.toString().padLeft(2, '0')}/${tanggal.month.toString().padLeft(2, '0')}/${tanggal.year}";
  }
}
