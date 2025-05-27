import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Detallerpagousuario extends StatelessWidget {
  final String cedula;

  const Detallerpagousuario({Key? key, required this.cedula}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(title: Text('Historial de Pagos - $cedula')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('abonos')
                .where('cedula', isEqualTo: cedula)
                .orderBy('fecha', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar los pagos:\n${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('No hay pagos registrados'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              final double valor = (data['valor'] as num).toDouble();
              final Timestamp fechaTs = data['fecha'] as Timestamp;
              final DateTime fecha = fechaTs.toDate();

              return ListTile(
                leading: const Icon(Icons.payment, color: Colors.green),
                title: Text('Pago: \$${valor.toStringAsFixed(2)}'),
                subtitle: Text('Fecha: ${dateFormat.format(fecha)}'),
              );
            },
          );
        },
      ),
    );
  }
}
