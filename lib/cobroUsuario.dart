import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cobro_app_flutter/pagoUsuario.dart';

class CobrosUsuario extends StatelessWidget {
  final String userId;
  final String uidAuth;

  CobrosUsuario({super.key, required this.userId, required this.uidAuth});

  final CollectionReference creditosRef = FirebaseFirestore.instance.collection(
    'creditos',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFFFEF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C290),
        title: const Text(
          'Mis cobros asignados',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            creditosRef
                .where('cedulaCobradorAsignado', isEqualTo: userId)
                .snapshots(),
        builder: (context, snapshot) {
          debugPrint('USER ID RECIBIDO: $userId');

          if (snapshot.hasError) {
            debugPrint('ERROR FIRESTORE: ${snapshot.error}');

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error al consultar los cobros:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final creditos = snapshot.data?.docs ?? [];

          debugPrint('CANTIDAD DE CRÉDITOS: ${creditos.length}');

          if (creditos.isEmpty) {
            return const Center(
              child: Text(
                'No tienes cobros asignados',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: creditos.length,
            itemBuilder: (context, index) {
              final documento = creditos[index];

              final credito = documento.data() as Map<String, dynamic>;

              final articulo =
                  credito['articulo']?.toString() ?? 'Sin artículo';

              final num deudaNumero = (credito['deuda'] as num?) ?? 0;

              final double deudaActual = deudaNumero.toDouble();

              final estado = credito['estado']?.toString() ?? 'Sin estado';

              final clienteId = credito['idCliente']?.toString() ?? '';

              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFDFFFEF),
                    child: Icon(Icons.receipt_long, color: Color(0xFF00A878)),
                  ),
                  title: Text(
                    articulo,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Deuda: \$${deudaActual.toStringAsFixed(0)}\n'
                      'Estado: $estado',
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Color(0xFF00A878),
                  ),
                  onTap: () {
                    if (clienteId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Este crédito no tiene un cliente asociado.',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => PagoUsuario(
                              creditoId: documento.id,
                              deudaActual: deudaActual,
                              clienteId: clienteId,
                              userId: userId,
                            ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
