import 'package:cobro_app_flutter/notificacionesAdmin.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cobro_app_flutter/baseDatosAdmin.dart';
import 'package:cobro_app_flutter/crearClienteAdmin.dart';
import 'package:cobro_app_flutter/crearUsuario.dart';
import 'package:cobro_app_flutter/gestionarCreditoAdmin.dart';
import 'package:cobro_app_flutter/historialPagoUsuario.dart';
import 'package:cobro_app_flutter/historialPagosAdmin.dart';

class MenuAdmin extends StatefulWidget {
  final String userId;

  const MenuAdmin({super.key, required this.userId});

  @override
  State<MenuAdmin> createState() => _MenuAdminState();
}

class _MenuAdminState extends State<MenuAdmin> {
  late Future<String?> _nombreAdminFuture;

  @override
  void initState() {
    super.initState();
    _nombreAdminFuture = obtenerNombreAdmin();
  }

  Future<String?> obtenerNombreAdmin() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .where('uid', isEqualTo: widget.userId)
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final datos = snapshot.docs.first.data();
      final nombre = (datos['nombre'] ?? '').toString().trim();

      return nombre.isEmpty ? null : nombre;
    } catch (e) {
      debugPrint('Error obteniendo nombre del administrador: $e');
      return null;
    }
  }

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
                builder: (context) => CrearUsuario(adminId: widget.userId),
              ),
            );
          } else if (texto == 'Crear Cliente') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CrearClienteAdmin(adminId: widget.userId),
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
          } else if (texto == 'Recordatorios') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificacionesAdmin(),
              ),
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
                  FutureBuilder<String?>(
                    future: _nombreAdminFuture,
                    builder: (context, snapshot) {
                      final nombre = snapshot.data;

                      return Text(
                        nombre != null
                            ? '¡Hola, $nombre!'
                            : '¡Hola, bienvenido de nuevo!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bienvenido a Cobra Tech',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
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
                  buildBoton(context, Icons.notifications, 'Recordatorios'),
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
