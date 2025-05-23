import 'package:flutter/material.dart';
import 'package:hola_mundo/crearClienteAdmin.dart';
import 'package:hola_mundo/perfilUsuario.dart';

class MenuUsuario extends StatelessWidget {
  const MenuUsuario({super.key});

  Widget buildBoton(BuildContext context, IconData icono, String texto) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Color(0xFFF6F3FB), // mismo color que en MenuAdmin
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: ListTile(
        leading: Icon(icono, color: Colors.blue, size: 30),
        title: Text(
          texto,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        onTap: () {
          if (texto == 'Crear Cliente') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CrearClienteAdmin()),
            );
          } else if (texto == 'Mi Perfil') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PerfilUsuario()),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFFFEF), // igual al MenuAdmin
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C290), // igual al MenuAdmin
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Hola, Bienvenido De Nuevo.',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            buildBoton(context, Icons.calendar_today, 'Cobros Del Día'),
            buildBoton(context, Icons.history, 'Historial De Pagos'),
            buildBoton(context, Icons.notifications, 'Notificaciones'),
            buildBoton(context, Icons.person, 'Mi Perfil'),
            buildBoton(context, Icons.person_add, 'Crear Cliente'),
          ],
        ),
      ),
    );
  }
}
