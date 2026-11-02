import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BaseDatosAdmin extends StatelessWidget {
  const BaseDatosAdmin({super.key});

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

  String _formatearFecha(dynamic fecha) {
    if (fecha == null) return 'Sin fecha';

    DateTime? fechaConvertida;

    if (fecha is Timestamp) {
      fechaConvertida = fecha.toDate();
    } else if (fecha is DateTime) {
      fechaConvertida = fecha;
    }

    if (fechaConvertida == null) return 'Fecha no disponible';

    return DateFormat('dd/MM/yyyy').format(fechaConvertida);
  }

  String _formatearDinero(dynamic valor) {
    final numero = valor is num ? valor : num.tryParse(valor.toString());

    if (numero == null) return 'Sin información';

    return NumberFormat('#,##0', 'es_CO').format(numero).replaceAll(',', '.');
  }

  Widget _buildDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(
    BuildContext context,
    Map<String, dynamic> data,
    String collectionName,
  ) {
    final esCredito = collectionName == 'creditos';

    final titulo =
        esCredito
            ? (data['articulo'] ?? 'Crédito').toString()
            : (data['nombreCompleto'] ?? data['nombre'] ?? 'Sin nombre')
                .toString();

    final subtitulo =
        esCredito
            ? 'Deuda: \$${_formatearDinero(data['deuda'])}'
            : 'Cédula: ${data['cedula'] ?? 'Sin cédula'}';

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
        leading: Icon(
          esCredito ? Icons.receipt_long : Icons.person,
          color: const Color(0xFF00A878),
          size: 30,
        ),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(subtitulo),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () async {
          if (esCredito) {
            _mostrarDetallesCredito(context, data);
          } else {
            _mostrarDetallesCliente(context, data);
          }
        },
      ),
    );
  }

  void _mostrarDetallesCliente(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Detalles del cliente'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetail(
                  'Nombre',
                  (data['nombreCompleto'] ?? data['nombre'] ?? 'Sin nombre')
                      .toString(),
                ),
                _buildDetail(
                  'Barrio',
                  (data['barrio'] ?? 'Sin información').toString(),
                ),
                _buildDetail(
                  'Cédula',
                  (data['cedula'] ?? 'Sin información').toString(),
                ),
                _buildDetail(
                  'Correo electrónico',
                  (data['correoElectronico'] ?? 'Sin información').toString(),
                ),
                _buildDetail(
                  'Dirección de vivienda',
                  (data['direccionVivienda'] ?? 'Sin información').toString(),
                ),
                _buildDetail(
                  'Número de celular',
                  (data['numeroCelular'] ?? 'Sin información').toString(),
                ),
                _buildDetail(
                  'Ubicación verificada',
                  data['ubicacionVerificada'] == true ? 'Sí' : 'No',
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
        );
      },
    );
  }

  void _mostrarDetallesCredito(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Detalles del crédito'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetail(
                  'Artículo',
                  (data['articulo'] ?? 'Sin información').toString(),
                ),
                _buildDetail('Deuda', '\$${_formatearDinero(data['deuda'])}'),
                _buildDetail(
                  'Estado',
                  (data['estado'] ?? 'Sin información').toString(),
                ),
                _buildDetail(
                  'Frecuencia de pago',
                  (data['frecuenciaPago'] ?? 'Sin información').toString(),
                ),
                _buildDetail(
                  'Número de cuotas',
                  (data['numeroCuotas'] ?? 'Sin información').toString(),
                ),
                _buildDetail(
                  'Fecha de inicio',
                  _formatearFecha(data['fechaInicio']),
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
        );
      },
    );
  }

  Widget _buildCollectionList(String collectionName) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collectionName).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar $collectionName'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(child: Text('No hay datos en $collectionName'));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;

            return _buildListItem(context, data, collectionName);
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
          'Base de Datos',
          style: TextStyle(color: Colors.black87),
        ),
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSectionTitle('Clientes'),
            _buildCollectionList('clientes'),
            _buildSectionTitle('Créditos'),
            _buildCollectionList('creditos'),
          ],
        ),
      ),
    );
  }
}
