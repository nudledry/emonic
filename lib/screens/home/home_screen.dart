import 'package:flutter/material.dart';
import 'package:emonic/screens/target/target_pengguna.dart';
import 'package:emonic/screens/usage/daily_usage_screen.dart';
import 'package:emonic/screens/news/berita.dart';
import 'package:emonic/screens/settings/settings_screen.dart';
import 'package:emonic/screens/home/widgets/home_content.dart';
import 'package:emonic/constants/colors.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _screens = [
    const HomeContent(),
    const TargetPenggunaanScreen(),
    BeritaScreen(),
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DailyUsageScreen(),
                  ),
                );
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
