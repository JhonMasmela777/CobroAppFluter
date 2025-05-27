import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HistorialPagosUsuario extends StatelessWidget {
  final String cedulaUsuario;

  const HistorialPagosUsuario({Key? key, required this.cedulaUsuario})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Pagos'),
        backgroundColor: const Color(0xFF00C290),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('abonos')
                .where(
                  'cedulaUsuario',
                  isEqualTo: cedulaUsuario,
                ) // Filtra por cédula
                .orderBy(
                  'fecha',
                  descending: true,
                ) // Ordena por fecha descendente
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay pagos registrados'));
          }

          final pagosDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: pagosDocs.length,
            itemBuilder: (context, index) {
              final pago = pagosDocs[index].data()! as Map<String, dynamic>;

              final monto = pago['monto'] ?? 'N/A';
              final fechaTimestamp = pago['fecha'];
              String fechaTexto = 'Fecha no disponible';
              if (fechaTimestamp != null && fechaTimestamp is Timestamp) {
                final fecha = fechaTimestamp.toDate();
                fechaTexto = '${fecha.day}/${fecha.month}/${fecha.year}';
              }
              final descripcion = pago['descripcion'] ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.payment, color: Colors.green),
                  title: Text('Monto: \$${monto.toString()}'),
                  subtitle: Text('Fecha: $fechaTexto\n$descripcion'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
