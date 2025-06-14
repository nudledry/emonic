import 'package:bloc/bloc.dart';
import 'package:emonic/screens/home/home_screen.dart';
import 'package:emonic/screens/target/berhasil_input_screen.dart';
import 'package:emonic/simple_bloc_observer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:user_repository/user_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final userRepository = FirebaseUserRepo();
  Bloc.observer = SimpleBlocObserver();

  runApp(MyApp(userRepository));
}

class MyApp extends StatelessWidget {
  final UserRepository userRepository;

  const MyApp(this.userRepository, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/': (context) => const HomeScreen(),
        '/home': (context) => const HomeScreen(),
        '/berhasil': (context) => const BerhasilInputScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => HomeScreen(initialIndex: args?['index'] ?? 0),
          );
        }
        return null;
      },
    );
  }
}
