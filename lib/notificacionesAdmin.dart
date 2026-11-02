import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NotificacionesAdmin extends StatelessWidget {
  const NotificacionesAdmin({super.key});

  String _formatearFecha(dynamic fecha) {
    if (fecha == null) return 'Sin fecha';

    DateTime? fechaConvertida;

    if (fecha is Timestamp) {
      fechaConvertida = fecha.toDate();
    } else if (fecha is DateTime) {
      fechaConvertida = fecha;
    }

    if (fechaConvertida == null) return 'Fecha no disponible';

    return DateFormat('dd/MM/yyyy - hh:mm a').format(fechaConvertida);
  }

  String _formatearDinero(dynamic valor) {
    if (valor == null) return 'Sin información';

    final numero = valor is num ? valor : num.tryParse(valor.toString());

    if (numero == null) return 'Sin información';

    return NumberFormat('#,##0', 'es_CO').format(numero).replaceAll(',', '.');
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  void _mostrarDetalles(BuildContext context, Map<String, dynamic> data) {
    final nombre =
        data['clienteNombre'] ?? data['nombreCliente'] ?? 'Sin nombre';

    final correo = data['correoElectronico'] ?? data['correo'] ?? 'Sin correo';

    final fechaEnvio = _formatearFecha(data['fechaEnvio']);
    final fechaVencimiento = _formatearFecha(data['fechaVencimiento']);

    final estado = data['estado'] ?? 'Enviado';

    final valor = data['valor'] ?? data['valorCuota'];

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Detalles del recordatorio'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetail('Cliente', nombre.toString()),
                  _buildDetail('Correo electrónico', correo.toString()),
                  _buildDetail('Fecha de envío', fechaEnvio),
                  _buildDetail('Fecha de vencimiento', fechaVencimiento),
                  _buildDetail('Estado', estado.toString()),
                  if (valor != null)
                    _buildDetail(
                      'Valor de la cuota',
                      '\$${_formatearDinero(valor)}',
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildRecordatorio(BuildContext context, Map<String, dynamic> data) {
    final nombre =
        data['clienteNombre'] ?? data['nombreCliente'] ?? 'Sin nombre';

    final correo = data['correoElectronico'] ?? data['correo'] ?? 'Sin correo';

    final fechaEnvio = _formatearFecha(data['fechaEnvio']);

    final estado = (data['estado'] ?? 'Enviado').toString();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3FB),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: ListTile(
        leading: const Icon(
          Icons.mark_email_read,
          color: Colors.green,
          size: 30,
        ),
        title: Text(
          nombre.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Correo: $correo'),
            Text('Fecha de envío: $fechaEnvio'),
            Text('Estado: $estado'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _mostrarDetalles(context, data),
      ),
    );
  }

  Widget _buildRecordatoriosList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('recordatoriosEnviados')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar los recordatorios'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs.toList();

        docs.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;

          final fechaA = dataA['fechaEnvio'];
          final fechaB = dataB['fechaEnvio'];

          final dateA = fechaA is Timestamp ? fechaA.toDate() : DateTime(2000);

          final dateB = fechaB is Timestamp ? fechaB.toDate() : DateTime(2000);

          return dateB.compareTo(dateA);
        });

        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(25),
            child: Center(
              child: Text(
                'No hay recordatorios registrados',
                style: TextStyle(fontSize: 15),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;

            return _buildRecordatorio(context, data);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFFFEF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C290),
        title: const Text(
          'Recordatorios',
          style: TextStyle(color: Colors.black87),
        ),
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSectionTitle('Recordatorios enviados'),
            _buildRecordatoriosList(),
          ],
        ),
      ),
    );
  }
}
