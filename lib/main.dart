import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hola_mundo/inicio.dart';
import 'package:hola_mundo/login_view.dart';
import 'package:hola_mundo/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/launch', // 👈 Esta será la primera pantalla
      routes: {
        '/launch': (_) => const SplashScreen(), // 👈 Tu pantalla de bienvenida
        '/acceder': (_) => const Inicio(), // Navegación desde el splash
        '/login': (_) => const LoginView(),
      },
    ),
  );
}
