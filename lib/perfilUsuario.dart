import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

<<<<<<< HEAD
class PerfilUsuario extends StatefulWidget {
  final String userId;

  const PerfilUsuario({super.key, required this.userId});

  @override
  State<PerfilUsuario> createState() => _PerfilUsuarioState();
}

class _PerfilUsuarioState extends State<PerfilUsuario> {
  late Future<Map<String, dynamic>?> perfilFuture;

  @override
  void initState() {
    super.initState();
    perfilFuture = obtenerPerfil();
  }

  Future<Map<String, dynamic>?> obtenerPerfil() async {
    final usuariosRef = FirebaseFirestore.instance.collection('usuarios');

    // Primera búsqueda: comprobar si el UID es el ID del documento.
    final documento = await usuariosRef.doc(widget.userId).get();

    if (documento.exists) {
      return documento.data();
    }

    // Segunda búsqueda: buscar por el campo uid.
    final resultadoUid =
        await usuariosRef.where('uid', isEqualTo: widget.userId).limit(1).get();

    if (resultadoUid.docs.isNotEmpty) {
      return resultadoUid.docs.first.data();
    }

    // Tercera búsqueda: compatibilidad con el campo userId.
    final resultadoUserId =
        await usuariosRef
            .where('userId', isEqualTo: widget.userId)
            .limit(1)
            .get();

    if (resultadoUserId.docs.isNotEmpty) {
      return resultadoUserId.docs.first.data();
    }

    return null;
  }

  String obtenerValor(Map<String, dynamic> usuario, List<String> campos) {
    for (final campo in campos) {
      final valor = usuario[campo];

      if (valor != null && valor.toString().trim().isNotEmpty) {
        return valor.toString().trim();
      }
    }

    return 'No registrado';
  }
=======
class PerfilUsuario extends StatelessWidget {
  final String userId; // Recibe el userId

  const PerfilUsuario({
    super.key,
    required this.userId,
  }); // constructor recibe userId
>>>>>>> origin/main

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0FFF1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C290),
        leading: const BackButton(color: Colors.white),
        title: const Text('Mi Perfil'),
        centerTitle: true,
        elevation: 2,
      ),
<<<<<<< HEAD
      body: FutureBuilder<Map<String, dynamic>?>(
        future: perfilFuture,
=======

      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance
                .collection('usuarios')
                .doc(userId) // usar userId recibido
                .get(),
>>>>>>> origin/main
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
<<<<<<< HEAD

          if (snapshot.hasError) {
            return const Center(child: Text('Error al consultar el perfil'));
          }

          if (!snapshot.hasData || snapshot.data == null) {
=======
          if (!snapshot.hasData || !snapshot.data!.exists) {
>>>>>>> origin/main
            return const Center(child: Text('Usuario no encontrado'));
          }

          final usuario = snapshot.data!;

<<<<<<< HEAD
          final nombre = obtenerValor(usuario, ['nombreCompleto', 'nombre']);

=======
>>>>>>> origin/main
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Color(0xFF00C28B),
                  child: Icon(Icons.person, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Text(
<<<<<<< HEAD
                  nombre,
                  textAlign: TextAlign.center,
=======
                  usuario['nombre'],
>>>>>>> origin/main
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF007A52),
                  ),
                ),
                const SizedBox(height: 30),
                InfoRow(
                  icon: Icons.badge,
                  label: 'Cédula',
<<<<<<< HEAD
                  value: obtenerValor(usuario, ['cedula']),
=======
                  value: usuario['cedula'],
>>>>>>> origin/main
                ),
                InfoRow(
                  icon: Icons.email,
                  label: 'Email',
<<<<<<< HEAD
                  value: obtenerValor(usuario, ['email', 'correo']),
=======
                  value: usuario['email'],
>>>>>>> origin/main
                ),
                InfoRow(
                  icon: Icons.phone,
                  label: 'Teléfono',
<<<<<<< HEAD
                  value: obtenerValor(usuario, ['telefono']),
=======
                  value: usuario['telefono'],
>>>>>>> origin/main
                ),
                InfoRow(
                  icon: Icons.security,
                  label: 'Rol',
<<<<<<< HEAD
                  value: obtenerValor(usuario, ['rol']),
=======
                  value: usuario['rol'],
>>>>>>> origin/main
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00C28B), size: 28),
          const SizedBox(width: 15),
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Color(0xFF007A52),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 17, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
