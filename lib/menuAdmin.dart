import 'package:flutter/material.dart';
import 'package:cobro_app_flutter/baseDatosAdmin.dart';
import 'package:cobro_app_flutter/crearClienteAdmin.dart';
import 'package:cobro_app_flutter/crearUsuario.dart';
import 'package:cobro_app_flutter/gestionarCreditoAdmin.dart';
import 'package:cobro_app_flutter/historialPagoUsuario.dart';
import 'package:cobro_app_flutter/historialPagosAdmin.dart';

class MenuAdmin extends StatelessWidget {
  final String userId;

  const MenuAdmin({super.key, required this.userId});

  Widget buildBoton(BuildContext context, IconData icono, String texto) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3FB),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: ListTile(
        leading: Icon(icono, color: Colors.blue, size: 30),
        title: Text(
          texto,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        onTap: () {
          if (texto == 'Crear Usuario') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CrearUsuario(adminId: userId),
              ),
            );
          } else if (texto == 'Crear Cliente') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CrearClienteAdmin(adminId: userId),
              ),
            );
          } else if (texto == 'Base De Datos') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BaseDatosAdmin()),
            );
          } else if (texto == 'Gestión De Créditos') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => GestionCreditosAdmin()),
            );
          } else if (texto == 'Historial De Pagos') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HistorialPagosAdmin()),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFFFEF),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 20),
            color: const Color(0xFF00C290),
            child: Center(
              child: Column(
                children: [
                  const Text(
                    'Hola, Bienvenido De Nuevo.',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ID: $userId',
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
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
