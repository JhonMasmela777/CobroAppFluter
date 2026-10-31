import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:cobro_app_flutter/inicio.dart';
import 'package:cobro_app_flutter/login_view.dart';
import 'package:cobro_app_flutter/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/launch',
      routes: {
        '/launch': (context) => const SplashScreen(),
        '/acceder': (context) => const Inicio(),
        '/login': (context) => const LoginView(),
      },
    );
  }
}
