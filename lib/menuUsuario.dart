import 'package:flutter/material.dart';

class MenuUsuario extends StatelessWidget {
  const MenuUsuario({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0FFF1), // verde muy claro
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C28B), // verde fuerte
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Hola, Bienvenido De Nuevo.',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          children: [
            _buildMenuButton(Icons.calendar_today, 'Cobros Del Día'),
            const SizedBox(height: 15),
            _buildMenuButton(Icons.history, 'Historial De Pagos'),
            const SizedBox(height: 15),
            _buildMenuButton(Icons.notifications, 'Notificaciones'),
            const SizedBox(height: 15),
            _buildMenuButton(Icons.person, 'Mi Perfil'),
            const SizedBox(height: 15),
            _buildMenuButton(Icons.person_add, 'Crear Cliente'),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(IconData icon, String title) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        onTap: () {
          // Acción al tocar
        },
      ),
    );
  }
}
