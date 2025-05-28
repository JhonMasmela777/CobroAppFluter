import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hola_mundo/PagoUsuario.dart';

class CobrosUsuario extends StatelessWidget {
  final String userId; // Este debe ser la cédula del cobrador

  CobrosUsuario({required this.userId});

  final CollectionReference creditosRef = FirebaseFirestore.instance.collection(
    'creditos',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFFFEF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C290),
        title: Text(
          'Cobros de $userId',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            creditosRef
                .where('cedulaCobradorAsignado', isEqualTo: userId)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final creditos = snapshot.data!.docs;

          if (creditos.isEmpty) {
            return const Center(
              child: Text(
                'No tienes cobros asignados',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }

          return ListView.builder(
            itemCount: creditos.length,
            itemBuilder: (context, index) {
              final credito = creditos[index];
              final data = credito.data() as Map<String, dynamic>;

              final creditoId = credito.id;
              final articulo = data['articulo'] ?? 'Sin nombre';
              final deuda = (data['deuda'] ?? 0).toDouble();
              final estado = data['estado'] ?? 'Sin estado';
              final idCliente = data['idCliente'] ?? '';

              return Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
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
                    vertical: 10,
                  ),
                  leading: const Icon(Icons.attach_money, color: Colors.green),
                  title: Text(
                    'Artículo: $articulo',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    'Deuda: \$${deuda.toStringAsFixed(2)} - Estado: $estado',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C290),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => PagoUsuario(
                                creditoId: creditoId,
                                deudaActual: deuda,
                                clienteId: idCliente,

                                userId: userId, // corregido aquí también
                              ),
                        ),
                      );
                    },
                    child: const Text('Generar Pago'),
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
