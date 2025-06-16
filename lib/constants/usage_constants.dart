class UsageConstants {
  static const List<String> golonganOptions = [
    "R-1/TR Daya 900 VA",
    "R-1/TR Daya 1.300 VA",
    "R-2/TR Daya 3.500 VA",
    "R-3/TR Daya 6.600 VA",
    "B-2/TR Daya 200 kVA",
    "P-1/TR Untuk Penerangan Jalan Umum"
  ];

  static const List<String> parameterOptions = [
    "Daya Listrik (kWh)",
    "Biaya (Rp)",
  ];

  static const String defaultUnit = "kWh";
  static const int maxDisplayItems = 10;
  static const double minInputValue = 0.1;
  static const double maxInputValue = 10000;
  static const String dateFormat = 'dd/MM/yyyy';
  static const int maxHistoryDays = 365;
}
