import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

String _formatearMiles(dynamic valor) {
  final numero = (valor as num?)?.round() ?? 0;
  final texto = numero.abs().toString();
  final buffer = StringBuffer();

  for (int i = 0; i < texto.length; i++) {
    if (i > 0 && (texto.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(texto[i]);
  }

  return '${numero < 0 ? '-' : ''}${buffer.toString()}';
}

String _obtenerNombre(Map<String, dynamic>? data, String fallback) {
  if (data == null) return fallback;

  final nombre =
      data['nombreCompleto'] ??
      data['nombre'] ??
      data['nombres'] ??
      data['razonSocial'];

  final resultado = nombre?.toString().trim() ?? '';

  return resultado.isNotEmpty ? resultado : fallback;
}

class DetallePagoUsuario extends StatelessWidget {
  final String clienteId;
  final String userId;

  const DetallePagoUsuario({
    Key? key,
    required this.clienteId,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFFFEF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C290),
        leading: const BackButton(color: Colors.white),
        title: const Text('Detalles De Los Abonos'),
        centerTitle: true,
        elevation: 2,
      ),

      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future:
            FirebaseFirestore.instance
                .collection('clientes')
                .doc(clienteId)
                .get(),
        builder: (context, clienteSnapshot) {
          final nombreCliente = _obtenerNombre(
            clienteSnapshot.data?.data(),
            'Cliente no encontrado',
          );

          return StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('abonos')
                    .where('clienteId', isEqualTo: clienteId)
                    .orderBy('fecha', descending: true)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    'Error al cargar los abonos',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No hay abonos registrados.',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                );
              }

              final abonos = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                itemCount: abonos.length,
                itemBuilder: (context, index) {
                  final abono = abonos[index];
                  final abonoData = abono.data() as Map<String, dynamic>;

                  final valor = (abonoData['valor'] as num?) ?? 0;
                  final fecha = (abonoData['fecha'] as Timestamp).toDate();

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
                        vertical: 10,
                      ),
                      leading: const Icon(
                        Icons.attach_money,
                        color: Colors.green,
                      ),
                      title: Text(
                        'Abono: \$${_formatearMiles(valor)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        'Cliente: $nombreCliente\n'
                        'Fecha: ${fecha.day}/${fecha.month}/${fecha.year} '
                        '${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Detalles del Abono'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Valor: \$${_formatearMiles(valor)}'),
                                  const SizedBox(height: 8),
                                  Text('Cliente: $nombreCliente'),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Fecha: ${fecha.day}/${fecha.month}/${fecha.year} '
                                    '${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}',
                                  ),
                                  if (abonoData.containsKey('userId'))
                                    Text(
                                      'Registrado por: ${abonoData['userId']}',
                                    ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  child: const Text('Cerrar'),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ],
                            );
                          },
                        );
                      },
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
