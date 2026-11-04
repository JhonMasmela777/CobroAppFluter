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

class HistorialPagosUsuario extends StatelessWidget {
  final String userId;

  const HistorialPagosUsuario({Key? key, required this.userId})
    : super(key: key);

  Future<String> _consultarNombreCliente(String clienteId) async {
    final documento =
        await FirebaseFirestore.instance
            .collection('clientes')
            .doc(clienteId)
            .get();

    return _obtenerNombre(documento.data(), 'Cliente no encontrado');
  }

  Future<void> _mostrarDetallesPago(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final valor = (data['valor'] as num?) ?? 0;
    final fecha = (data['fecha'] as Timestamp).toDate();
    final clienteId = (data['clienteId'] ?? '').toString();

    String nombreCliente = 'Cliente no encontrado';

    try {
      nombreCliente = await _consultarNombreCliente(clienteId);
    } catch (e) {
      debugPrint('Error al consultar cliente: $e');
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Detalles del Pago'),
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
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFFFEF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C290),
        leading: const BackButton(color: Colors.white),
        title: const Text('Historial De Pagos'),
        centerTitle: true,
        elevation: 2,
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

              final valor = (data['valor'] as num?) ?? 0;
              final fecha = (data['fecha'] as Timestamp).toDate();

              final clienteId = (data['clienteId'] ?? '').toString();

              return FutureBuilder<String>(
                future: _consultarNombreCliente(clienteId),
                builder: (context, nombreSnapshot) {
                  final nombreCliente =
                      nombreSnapshot.data ?? 'Cargando cliente...';

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
                      leading: const Icon(
                        Icons.payments,
                        color: Color(0xFF00C290),
                      ),
                      title: Text(
                        'Pago: \$${_formatearMiles(valor)}',
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
                      onTap: () => _mostrarDetallesPago(context, data),
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
