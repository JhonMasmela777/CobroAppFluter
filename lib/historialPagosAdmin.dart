import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class HistorialPagosAdmin extends StatefulWidget {
  const HistorialPagosAdmin({super.key});

  @override
  State<HistorialPagosAdmin> createState() => _HistorialPagosAdminState();
}

class _HistorialPagosAdminState extends State<HistorialPagosAdmin> {
  late final Future<void> _inicializacionLocale;

  @override
  void initState() {
    super.initState();
    _inicializacionLocale = initializeDateFormatting('es_CO');
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

  String _formatearDinero(dynamic valor) {
    final numero = valor is num ? valor : num.tryParse(valor.toString());

    if (numero == null) return '0';

    return NumberFormat('#,##0', 'es_CO').format(numero).replaceAll(',', '.');
  }

  String _formatearFecha(dynamic fecha) {
    if (fecha == null) return 'Sin fecha';

    DateTime? fechaConvertida;

    if (fecha is Timestamp) {
      fechaConvertida = fecha.toDate();
    } else if (fecha is DateTime) {
      fechaConvertida = fecha;
    }

    if (fechaConvertida == null) {
      return 'Fecha no disponible';
    }

    return DateFormat('dd/MM/yyyy - hh:mm a', 'es_CO').format(fechaConvertida);
  }

  Future<String> _obtenerNombreCliente(String clienteId) async {
    try {
      if (clienteId.isEmpty) return 'Cliente no disponible';

      final documento =
          await FirebaseFirestore.instance
              .collection('clientes')
              .doc(clienteId)
              .get();

      if (!documento.exists) return 'Cliente no encontrado';

      final data = documento.data()!;

      return (data['nombreCompleto'] ?? data['nombre'] ?? 'Sin nombre')
          .toString();
    } catch (e) {
      return 'No disponible';
    }
  }

  Future<String> _obtenerNombreCobrador(String uid) async {
    try {
      if (uid.isEmpty) return 'Cobrador no disponible';

      // Buscar en usuarios mediante el campo uid.
      final consulta =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .where('uid', isEqualTo: uid)
              .limit(1)
              .get();

      if (consulta.docs.isEmpty) {
        return 'Cobrador no encontrado';
      }

      final data = consulta.docs.first.data();

      return (data['nombreCompleto'] ?? data['nombre'] ?? 'Sin nombre')
          .toString();
    } catch (e) {
      return 'No disponible';
    }
  }

  Widget _buildListItem(BuildContext context, Map<String, dynamic> data) {
    final valor = data['valor'] ?? 0;
    final clienteId = (data['clienteId'] ?? '').toString();

    // En abonos el campo identificador del cobrador es userId.
    final userId = (data['userId'] ?? '').toString();

    final fecha = _formatearFecha(data['fecha']);

    return FutureBuilder<List<String>>(
      future: Future.wait([
        _obtenerNombreCliente(clienteId),
        _obtenerNombreCobrador(userId),
      ]),
      builder: (context, snapshot) {
        final nombreCliente =
            snapshot.hasData ? snapshot.data![0] : 'Cargando...';

        final nombreCobrador =
            snapshot.hasData ? snapshot.data![1] : 'Cargando...';

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F3FB),
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
            leading: const Icon(
              Icons.attach_money,
              color: Colors.green,
              size: 30,
            ),
            title: Text(
              'Valor: \$${_formatearDinero(valor)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cliente: $nombreCliente'),
                Text('Cobrador: $nombreCobrador'),
                Text('Fecha: $fecha'),
              ],
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) {
                  return AlertDialog(
                    title: const Text('Detalles del abono'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Valor: \$${_formatearDinero(valor)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Fecha: $fecha',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
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
            },
          ),
        );
      },
    );
  }

  Widget _buildAbonosList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('abonos').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar abonos'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text('No hay abonos registrados'));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;

            return _buildListItem(context, data);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _inicializacionLocale,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFDFFFEF),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            backgroundColor: Color(0xFFDFFFEF),
            body: Center(
              child: Text('Error al inicializar el formato regional'),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFDFFFEF),
          appBar: AppBar(
            backgroundColor: const Color(0xFF00C290),
            title: const Text(
              'Historial de Pagos',
              style: TextStyle(color: Colors.black87),
            ),
            centerTitle: true,
            leading: const BackButton(color: Colors.white),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [_buildSectionTitle('Abonos'), _buildAbonosList()],
            ),
          ),
        );
      },
    );
  }
}
