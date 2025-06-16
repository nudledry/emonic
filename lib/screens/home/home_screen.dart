import 'package:flutter/material.dart';
import 'package:emonic/screens/target/target_pengguna.dart';
import 'package:emonic/screens/usage/daily_usage_screen.dart';
import 'package:emonic/screens/news/berita.dart';
import 'package:emonic/screens/settings/settings_screen.dart';
import 'package:emonic/screens/home/widgets/home_content.dart';
import 'package:emonic/constants/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Tambahkan import ini

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadUserData();
  }

  // Load user data from Firestore
  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Ambil data dari Firestore berdasarkan UID user
        final userDoc = await FirebaseFirestore.instance
            .collection('user')
            .doc(user.uid)
            .get();

        setState(() {
          if (userDoc.exists && userDoc.data() != null) {
            _userName = userDoc.data()!['name'] as String? ??
                user.displayName ??
                user.email?.split('@')[0] ??
                'Pengguna';
          } else {
            _userName =
                user.displayName ?? user.email?.split('@')[0] ?? 'Pengguna';
          }
        });
      } else {
        setState(() {
          _userName = 'Pengguna';
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _userName = 'Pengguna';
      });
    }
  }

  List<Widget> get _screens => [
        const HomeContent(),
        const TargetPenggunaanScreen(),
        BeritaScreen(userName: _userName),
        const SettingsScreen(),
      ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    // Only show app bar for home screen (index 0)
    if (_currentIndex != 0) return null;

    return AppBar(
      backgroundColor: AppColors.primaryBlue,
      elevation: 0,
      title: Row(
        children: [
          Image.asset(
            'assets/logo.png',
            height: 30,
            width: 30,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.energy_savings_leaf,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          const Text(
            'EMONIC',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 36,
            height: 36,
            child: FloatingActionButton(
              mini: true,
              onPressed: () async {
                // Navigate to add usage screen and refresh data when returning
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DailyUsageScreen(),
                  ),
                );

                // Refresh home content if data was added
                if (result == true && mounted) {
                  // Trigger refresh di HomeContent
                  setState(() {});
                }
              },
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.primaryBlue,
              elevation: 2,
              child: const Icon(
                Icons.add,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _onTabTapped,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primaryBlue,
      unselectedItemColor: AppColors.textGrey,
      backgroundColor: Colors.white,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.trending_up),
          label: 'Penggunaan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.language),
          label: 'Berita',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Pengaturan',
        ),
      ],
    );
  }
}
