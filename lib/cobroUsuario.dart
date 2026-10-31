import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:cobro_app_flutter/pagoUsuario.dart';

class CobrosUsuario extends StatelessWidget {
  final String userId;
  final String uidAuth;

  CobrosUsuario({super.key, required this.userId, required this.uidAuth});
=======
import 'package:hola_mundo/PagoUsuario.dart';

class CobrosUsuario extends StatelessWidget {
  final String userId; // Este debe ser la cédula del cobrador

  CobrosUsuario({required this.userId});
>>>>>>> origin/main

  final CollectionReference creditosRef = FirebaseFirestore.instance.collection(
    'creditos',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFFFEF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C290),
<<<<<<< HEAD
        title: const Text(
          'Mis cobros asignados',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
=======
        title: Text(
          'Cobros de $userId',
        ), // Aquí el cambio para estilo igual que CrearClienteAdmin
        centerTitle: true,
        leading: const BackButton(
          color: Colors.white,
        ), // Botón atrás blanco igual
>>>>>>> origin/main
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            creditosRef
                .where('cedulaCobradorAsignado', isEqualTo: userId)
                .snapshots(),
        builder: (context, snapshot) {
<<<<<<< HEAD
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
=======
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final creditos = snapshot.data!.docs;
>>>>>>> origin/main

          if (creditos.isEmpty) {
            return const Center(
              child: Text(
                'No tienes cobros asignados',
<<<<<<< HEAD
                style: TextStyle(fontSize: 16, color: Colors.black87),
=======
                style: TextStyle(fontSize: 16, color: Colors.black54),
>>>>>>> origin/main
              ),
            );
          }

          return ListView.builder(
<<<<<<< HEAD
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
=======
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
>>>>>>> origin/main
                ),
              );
            },
          );
        },
      ),
    );
  }
}
