import 'package:flutter/material.dart';
import 'package:emonic/screens/home/views/penggunaan/history_target_screen.dart';
import 'package:emonic/constants/colors.dart'; // Import colors

class BerhasilInputScreen extends StatefulWidget {
  const BerhasilInputScreen({super.key});

  @override
  State<BerhasilInputScreen> createState() => _BerhasilInputScreenState();
}

class _BerhasilInputScreenState extends State<BerhasilInputScreen> {
  @override
  void initState() {
    super.initState();
    // Tunggu beberapa detik sebelum navigasi ke history screen
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        // Navigasi langsung ke history dengan push (bukan replace)
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HistoryTargetScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: const Text(
          'Status Input',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.green,
                  child: const Icon(
                    Icons.check,
                    color: AppColors.white,
                    size: 60,
                  ),
                ),
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: Transform.rotate(
                    angle: -0.2,
                    child: const Icon(
                      Icons.bolt,
                      color: AppColors.yellow,
                      size: 30,
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Transform.rotate(
                    angle: 0.2,
                    child: const Icon(
                      Icons.bolt,
                      color: AppColors.yellow,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "Berhasil Input Harian",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Data penggunaan listrik berhasil disimpan",
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
