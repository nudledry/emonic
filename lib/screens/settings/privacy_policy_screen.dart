import 'package:flutter/material.dart';
import 'package:emonic/constants/colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Kebijakan Privasi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kebijakan Privasi EMONIC',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Terakhir diperbarui: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 24),
                _buildSection(
                  'Pengumpulan Data',
                  'Kami mengumpulkan informasi berikut:\n'
                      '• Data konsumsi energi dan pola penggunaan\n'
                      '• Informasi profil pengguna (nama, email)\n'
                      '• Informasi perangkat dan sistem operasi\n'
                      '• Statistik penggunaan aplikasi',
                ),
                _buildSection(
                  'Penggunaan Data',
                  'Data Anda digunakan untuk:\n'
                      '• Memantau dan menganalisis konsumsi energi\n'
                      '• Memberikan rekomendasi yang dipersonalisasi\n'
                      '• Meningkatkan layanan dan fitur aplikasi\n'
                      '• Mengirim notifikasi penting terkait penggunaan',
                ),
                _buildSection(
                  'Keamanan Data',
                  'Kami menerapkan langkah-langkah keamanan tingkat tinggi untuk melindungi informasi pribadi Anda. '
                      'Data Anda dienkripsi dengan protokol SSL dan disimpan dengan aman di server yang terlindungi.',
                ),
                _buildSection(
                  'Layanan Pihak Ketiga',
                  'Kami dapat menggunakan layanan pihak ketiga untuk:\n'
                      '• Memproses pembayaran dengan standar PCI DSS\n'
                      '• Menganalisis penggunaan aplikasi (Google Analytics)\n'
                      '• Mengirim notifikasi push (Firebase Cloud Messaging)\n'
                      '• Penyimpanan cloud yang aman',
                ),
                _buildSection(
                  'Hak Anda',
                  'Sesuai dengan peraturan perlindungan data, Anda memiliki hak untuk:\n'
                      '• Mengakses dan melihat data pribadi Anda\n'
                      '• Meminta penghapusan data (right to erasure)\n'
                      '• Menolak pengumpulan data tertentu\n'
                      '• Memperbarui atau mengoreksi informasi Anda\n'
                      '• Meminta portabilitas data',
                ),
                _buildContactSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.security,
                  color: AppColors.primaryBlue,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.contact_support,
                color: AppColors.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Hubungi Kami',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Jika Anda memiliki pertanyaan tentang kebijakan privasi ini atau ingin menggunakan hak-hak Anda, silakan hubungi kami:',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.black,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildContactItem(Icons.email, 'Email: support@emonic.com'),
          const SizedBox(height: 8),
          _buildContactItem(Icons.phone, 'Telepon: +62 21 1234 5678'),
          const SizedBox(height: 8),
          _buildContactItem(
              Icons.schedule, 'Jam Kerja: Senin-Jumat, 09:00-17:00 WIB'),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.primaryBlue,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.black,
            ),
          ),
        ),
      ],
    );
  }
}
