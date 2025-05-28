import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hola_mundo/cobroUsuario.dart';
import 'package:hola_mundo/crearClienteAdmin.dart';
import 'package:hola_mundo/historialPagoUsuario.dart';
import 'package:hola_mundo/perfilUsuario.dart';
import 'package:hola_mundo/globals.dart';

class MenuUsuario extends StatefulWidget {
  final String userId; // Cambiamos de clienteCedula a userId

  const MenuUsuario({Key? key, required this.userId}) : super(key: key);

  @override
  _MenuUsuarioState createState() => _MenuUsuarioState();
}

class _MenuUsuarioState extends State<MenuUsuario> {
  Map<String, dynamic>? clienteData;

  @override
  void initState() {
    super.initState();
    _cargarDatosCliente();
  }

  Future<void> _cargarDatosCliente() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('clientes')
              .doc(widget.userId) // Ahora usamos el ID directo
              .get();

      if (doc.exists) {
        setState(() {
          clienteData = doc.data();
        });
      }
    } catch (e) {
      print('Error cargando datos: $e');
    }
  }

  Widget buildBoton(BuildContext context, IconData icono, String texto) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3FB),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
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
                builder: (context) => CobrosUsuario(userId: widget.userId),
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
          } else if (texto == 'Notificaciones') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Funcionalidad de Notificaciones pendiente'),
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C290),
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          clienteData != null
              ? 'Hola, ${clienteData!['nombreCompleto']}'
              : 'Hola, Bienvenido De Nuevo.',
          style: const TextStyle(
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
