import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HistorialPagosUsuario extends StatelessWidget {
  final String userId;

  const HistorialPagosUsuario({Key? key, required this.userId})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFFFEF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C290),
        title: const Text(
          'Historial de Pagos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('abonos')
                .where('userId', isEqualTo: userId)
                .orderBy('fecha', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar los pagos'));
          }

          final pagos = snapshot.data?.docs ?? [];

          if (pagos.isEmpty) {
            return const Center(
              child: Text(
                'No tienes pagos registrados',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            itemCount: pagos.length,
            itemBuilder: (context, index) {
              final pago = pagos[index];
              final data = pago.data() as Map<String, dynamic>;
              final valor = (data['valor'] ?? 0).toDouble();
              final fecha = (data['fecha'] as Timestamp).toDate();
              final clienteId = data['clienteId'] ?? 'Desconocido';

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  leading: const Icon(Icons.payments, color: Color(0xFF00C290)),
                  title: Text(
                    'Pago: \$${valor.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    'Cliente ID: $clienteId\n'
                    'Fecha: ${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
