import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emonic/blocs/authentication_bloc/authentication_bloc.dart';
import 'package:emonic/screens/settings/privacy_policy_screen.dart';
import 'package:emonic/screens/settings/edit_profile_screen.dart';
import 'package:emonic/screens/settings/change_email_screen.dart';
import 'package:emonic/constants/colors.dart';
import 'package:emonic/screens/settings/help_screen.dart';
import 'package:emonic/screens/settings/change_password_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: const Text(
          'Pengaturan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),

          // Account Settings Section
          _buildSectionHeader('Pengaturan Akun'),
          const SizedBox(height: 8),
          _buildSettingsCard([
            _buildSettingsTile(
              icon: Icons.person_outline,
              title: 'Edit Profil',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
              },
            ),
            const Divider(height: 1, color: AppColors.grey),
            _buildSettingsTile(
              icon: Icons.email_outlined,
              title: 'Ubah Email',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChangeEmailScreen(),
                  ),
                );
              },
            ),
            const Divider(height: 1, color: AppColors.grey),
            _buildSettingsTile(
              icon: Icons.lock_outline,
              title: 'Ubah Password',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChangePasswordScreen(),
                  ),
                );
              },
            ),
          ]),

          const SizedBox(height: 24),

          // Support & Information Section
          _buildSectionHeader('Bantuan & Informasi'),
          const SizedBox(height: 8),
          _buildSettingsCard([
            _buildSettingsTile(
              icon: Icons.help_outline,
              title: 'Bantuan & Dukungan',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpScreen(),
                  ),
                );
              },
            ),
            const Divider(height: 1, color: AppColors.grey),
            _buildSettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Kebijakan Privasi',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyScreen(),
                  ),
                );
              },
            ),
            const Divider(height: 1, color: AppColors.grey),
            _buildSettingsTile(
              icon: Icons.info_outline,
              title: 'Tentang Aplikasi',
              trailing: Text(
                'v1.0.0',
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                _showAboutDialog(context);
              },
            ),
          ]),

          const SizedBox(height: 32),

          // Logout Section
          _buildSettingsCard([
            _buildSettingsTile(
              icon: Icons.logout,
              title: 'Keluar',
              textColor: AppColors.red,
              showArrow: false,
              onTap: () => _showLogoutDialog(context),
            ),
          ]),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold, // Sama seperti home_screen
          color: AppColors.black,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16), // Sama seperti cards di home
        boxShadow: [
          BoxShadow(
            color: AppColors.textGrey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Widget? trailing,
    bool showArrow = true,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: textColor == AppColors.red
              ? AppColors.red.withValues(alpha: 0.1)
              : AppColors.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: textColor ?? AppColors.primaryBlue,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? AppColors.black,
          fontWeight: FontWeight.w500, // Konsisten dengan styling home
          fontSize: 14,
        ),
      ),
      trailing: trailing ??
          (showArrow
              ? Icon(
                  Icons.chevron_right,
                  color: AppColors.textGrey,
                  size: 20,
                )
              : null),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Konsisten dengan cards
        ),
        title: Row(
          children: [
            Icon(
              Icons.logout,
              color: AppColors.red,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Keluar',
              style: TextStyle(
                fontWeight: FontWeight.bold, // Bold seperti header
                color: AppColors.black,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari aplikasi?',
          style: TextStyle(
            color: AppColors.textGrey,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textGrey,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Batal',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AuthenticationBloc>().add(LogoutRequested());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Keluar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.info,
                color: AppColors.primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'EMONIC',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.black,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Energy Monitoring Application',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.black,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                color: AppColors.textGrey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Aplikasi untuk memantau dan mengelola penggunaan energi listrik Anda.',
              style: TextStyle(
                color: AppColors.textGrey,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'OK',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
