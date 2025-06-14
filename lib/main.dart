import 'package:bloc/bloc.dart';
import 'package:emonic/app.dart';
import 'package:emonic/simple_bloc_observer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:user_repository/user_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final UserRepository userRepository = FirebaseUserRepo();
  Bloc.observer = SimpleBlocObserver();

  runApp(MyApp(userRepository));
}
