import 'package:flutter/material.dart';
import 'package:hola_mundo/baseDatosAdmin.dart';
import 'package:hola_mundo/crearClienteAdmin.dart';
import 'package:hola_mundo/crearUsuario.dart';
import 'package:hola_mundo/gestionarCreditoAdmin.dart';
import 'package:hola_mundo/historialPagoUsuario.dart';
import 'package:hola_mundo/historialPagosAdmin.dart';

class MenuAdmin extends StatelessWidget {
  final String userId; // ← Nuevo parámetro para el ID automático

  const MenuAdmin({
    super.key,
    required this.userId,
  }); // ← Hacemos el parámetro requerido

  // Función para construir botones reutilizables
  Widget buildBoton(BuildContext context, IconData icono, String texto) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Color(0xFFF6F3FB),
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
          if (texto == 'Crear Usuario') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        CrearUsuario(adminId: userId), // ← Pasamos el ID
              ),
            );
          } else if (texto == 'Crear Cliente') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        CrearClienteAdmin(adminId: userId), // ← Pasamos el ID
              ),
            );
          } else if (texto == 'Base De Datos') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BaseDatosAdmin(), // ← Pasamos el ID
              ),
            );
          } else if (texto == 'Gestión De Créditos') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GestionCreditosAdmin(), // ← Pasamos el ID
              ),
            );
          } else if (texto == 'Historial De Pagos') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HistorialPagosAdmin(), // ← Pasamos el ID
              ),
            );
          }
          // Agregar más rutas según necesidad
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFDFFFEF),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: 60, bottom: 20),
            color: Color(0xFF00C290),
            child: Center(
              child: Column(
                children: [
                  Text(
                    'Hola, Bienvenido De Nuevo.',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'ID: $userId', // ← Mostramos el ID (opcional, solo para debug)
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  buildBoton(context, Icons.person_add, 'Crear Usuario'),
                  buildBoton(context, Icons.person_add_alt_1, 'Crear Cliente'),
                  buildBoton(context, Icons.folder, 'Base De Datos'),
                  buildBoton(context, Icons.history, 'Historial De Pagos'),
                  buildBoton(context, Icons.notifications, 'Notificaciones'),
                  buildBoton(
                    context,
                    Icons.account_balance_wallet,
                    'Gestión De Créditos',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
