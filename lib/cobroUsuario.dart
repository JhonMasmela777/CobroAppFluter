import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cobro_app_flutter/rutaCobroUsuario.dart';

class CobrosUsuario extends StatelessWidget {
  final String userId;

  CobrosUsuario({super.key, required this.userId, required String uidAuth});

  final CollectionReference creditosRef = FirebaseFirestore.instance.collection(
    'creditos',
  );

  @override
  Widget build(BuildContext context) {
    final ahora = DateTime.now();

    final inicioHoy = DateTime(ahora.year, ahora.month, ahora.day);

    final inicioManana = inicioHoy.add(const Duration(days: 1));

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RutaCobroUsuario(userId: userId),
            ),
          );
        },
        backgroundColor: const Color(0xFF00C290),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.route),
        label: const Text('Generar ruta de cobro'),
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

          debugPrint('CANTIDAD DE CRÉDITOS ASIGNADOS: ${creditos.length}');

          if (creditos.isEmpty) {
            return const Center(
              child: Text(
                'No tienes cobros asignados',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
            );
          }

          // Consultar los abonos registrados durante el día.
          return StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('abonos')
                    .where(
                      'fecha',
                      isGreaterThanOrEqualTo: Timestamp.fromDate(inicioHoy),
                    )
                    .where(
                      'fecha',
                      isLessThan: Timestamp.fromDate(inicioManana),
                    )
                    .snapshots(),
            builder: (context, abonosSnapshot) {
              if (abonosSnapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Error al consultar los abonos:\n'
                      '${abonosSnapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (abonosSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Identificar los clientes que ya abonaron hoy
              // con el cobrador que inició sesión.
              final Set<String> clientesConAbonoHoy = {};

              for (final abonoDoc in abonosSnapshot.data!.docs) {
                final abono = abonoDoc.data() as Map<String, dynamic>;

                final cobradorAbono = abono['userId']?.toString() ?? '';

                final clienteAbono = abono['clienteId']?.toString() ?? '';

                if (cobradorAbono == userId && clienteAbono.isNotEmpty) {
                  clientesConAbonoHoy.add(clienteAbono);
                }
              }

              // Excluir todos los créditos de esos clientes.
              final creditosVisibles =
                  creditos.where((documento) {
                    final credito = documento.data() as Map<String, dynamic>;

                    final clienteId = credito['idCliente']?.toString() ?? '';

                    return clienteId.isNotEmpty &&
                        !clientesConAbonoHoy.contains(clienteId);
                  }).toList();

              debugPrint('CRÉDITOS VISIBLES: ${creditosVisibles.length}');

              if (creditosVisibles.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No tienes cobros asignados pendientes '
                      'de gestionar en este momento.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: creditosVisibles.length,
                itemBuilder: (context, index) {
                  final documento = creditosVisibles[index];

                  final credito = documento.data() as Map<String, dynamic>;

                  final articulo =
                      credito['articulo']?.toString() ?? 'Sin artículo';

                  final num deudaNumero = (credito['deuda'] as num?) ?? 0;

                  final double deudaActual = deudaNumero.toDouble();

                  final estado = credito['estado']?.toString() ?? 'Sin estado';

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
                        child: Icon(
                          Icons.receipt_long,
                          color: Color(0xFF00A878),
                        ),
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
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
