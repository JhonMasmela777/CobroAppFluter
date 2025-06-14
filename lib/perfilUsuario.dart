import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PerfilUsuario extends StatelessWidget {
  final String userId; // Recibe el userId

  const PerfilUsuario({
    super.key,
    required this.userId,
  }); // constructor recibe userId

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

      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance
                .collection('usuarios')
                .doc(userId) // usar userId recibido
                .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Usuario no encontrado'));
          }

          final usuario = snapshot.data!;

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
                  usuario['nombre'],
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
                  value: usuario['cedula'],
                ),
                InfoRow(
                  icon: Icons.email,
                  label: 'Email',
                  value: usuario['email'],
                ),
                InfoRow(
                  icon: Icons.phone,
                  label: 'Teléfono',
                  value: usuario['telefono'],
                ),
                InfoRow(
                  icon: Icons.security,
                  label: 'Rol',
                  value: usuario['rol'],
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
