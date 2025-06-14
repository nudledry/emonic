class TarifListrik {
  static const Map<String, double> tarifPerKwh = {
    "R-1/TR Daya 900 VA": 1352.0, // Rp per kWh
    "R-1/TR Daya 1.300 VA": 1352.0,
    "R-2/TR Daya 3.500 VA": 1444.7,
    "R-3/TR Daya 6.600 VA": 1699.53,
    "B-2/TR Daya 200 kVA": 1467.28,
    "P-1/TR Untuk Penerangan Jalan Umum": 1050.0,
  };

  static double getTarifByGolongan(String golongan) {
    return tarifPerKwh[golongan] ?? 1352.0; // Default tarif R-1
  }

  static double convertBiayaToKwh(double biaya, String golongan) {
    final tarif = getTarifByGolongan(golongan);
    return biaya / tarif;
  }

  static double convertKwhToBiaya(double kwh, String golongan) {
    final tarif = getTarifByGolongan(golongan);
    return kwh * tarif;
  }

  static String formatRupiah(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]}.',
        )}';
  }
}
