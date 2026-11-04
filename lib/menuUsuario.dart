import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:cobro_app_flutter/cobroUsuario.dart';
import 'package:cobro_app_flutter/crearClienteAdmin.dart';
import 'package:cobro_app_flutter/historialPagoUsuario.dart';
import 'package:cobro_app_flutter/perfilUsuario.dart';

class MenuUsuario extends StatefulWidget {
  final String userId;

  const MenuUsuario({Key? key, required this.userId}) : super(key: key);

  @override
  _MenuUsuarioState createState() => _MenuUsuarioState();
}

class _MenuUsuarioState extends State<MenuUsuario> {
  Map<String, dynamic>? usuarioData;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  // Cargar perfil mediante el UID de Firebase Authentication.
  Future<void> _cargarDatosUsuario() async {
    try {
      final usuariosRef = FirebaseFirestore.instance.collection('usuarios');

      Map<String, dynamic>? datos;

      // Primera búsqueda: UID.
      final resultadoUid =
          await usuariosRef
              .where('uid', isEqualTo: widget.userId)
              .limit(1)
              .get();

      if (resultadoUid.docs.isNotEmpty) {
        datos = resultadoUid.docs.first.data();
      }

      // Segunda búsqueda: userId.
      if (datos == null) {
        final resultadoUserId =
            await usuariosRef
                .where('userId', isEqualTo: widget.userId)
                .limit(1)
                .get();

        if (resultadoUserId.docs.isNotEmpty) {
          datos = resultadoUserId.docs.first.data();
        }
      }

      // Tercera búsqueda: ID del documento.
      if (datos == null) {
        final documento = await usuariosRef.doc(widget.userId).get();

        if (documento.exists) {
          datos = documento.data();
        }
      }

      if (!mounted) return;

      setState(() {
        usuarioData = datos;
      });

      if (datos == null) {
        debugPrint('No se encontró el perfil del usuario.');
      }
    } catch (e) {
      debugPrint('Error cargando los datos del usuario: $e');
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
          if (texto == 'Crear Cliente') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CrearClienteAdmin(adminId: widget.userId),
              ),
            );
          } else if (texto == 'Mi Perfil') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PerfilUsuario(userId: widget.userId),
              ),
            );
          } else if (texto == 'Cobros Del Día') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => CobrosUsuario(
                      userId: widget.userId,
                      uidAuth: widget.userId,
                    ),
              ),
            );
          } else if (texto == 'Historial De Pagos') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => HistorialPagosUsuario(userId: widget.userId),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String nombre = (usuarioData?['nombreCompleto'] ?? '').toString().trim();

    if (nombre.isEmpty) {
      nombre = (usuarioData?['nombre'] ?? '').toString().trim();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFDFFFEF),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 20),
              color: const Color(0xFF00C290),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      nombre.isNotEmpty
                          ? '¡Hola, $nombre!'
                          : '¡Hola, bienvenido de nuevo!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
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

            const SizedBox(height: 20),

            buildBoton(context, Icons.calendar_today, 'Cobros Del Día'),
            buildBoton(context, Icons.history, 'Historial De Pagos'),
            buildBoton(context, Icons.person_add, 'Crear Cliente'),
            buildBoton(context, Icons.person, 'Mi Perfil'),
          ],
        ),
      ),
    );
  }
}
