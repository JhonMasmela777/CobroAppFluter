import 'package:flutter/material.dart';
import 'package:hola_mundo/inicio.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CobraTech',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Inicio()),
        );
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF00C2A8),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.show_chart, size: 80, color: Colors.black),
              SizedBox(height: 20),
              Text(
                'CobraTech',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Acceder extends StatelessWidget {
  const Acceder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pantalla Acceder')),
      body: const Center(
        child: Text(
          'Bienvenido a la pantalla Acceder',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
