import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistorialPagosAdmin extends StatelessWidget {
  const HistorialPagosAdmin({super.key});

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
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

  Widget _buildListItem(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
  ) {
    final valor = data['valor'] ?? 0;
    final clienteId = data['clienteId'] ?? 'Sin ID';
    final userId = data['userId'] ?? 'Sin ID';
    final fecha =
        data['fecha'] != null
            ? (data['fecha'] as Timestamp).toDate().toString()
            : 'Sin fecha';

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
        leading: const Icon(Icons.attach_money, color: Colors.green, size: 30),
        title: Text(
          'Valor: \$${valor.toString()}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cliente ID: $clienteId'),
            Text('Usuario ID: $userId'),
            Text('Fecha: $fecha'),
          ],
        ),
        onTap: () {
          showDialog(
            context: context,
            builder: (_) {
              return AlertDialog(
                title: const Text('Detalles del abono'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView(
                    shrinkWrap: true,
                    children:
                        data.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Text('${entry.key}: ${entry.value}'),
                          );
                        }).toList(),
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
        },
      ),
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
            try {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;
              print('✅ Abono cargado: $data');
              return _buildListItem(context, data, docId);
            } catch (e) {
              final docId = docs[index].id;
              print('❌ Error al cargar abono $docId: $e');
              return ListTile(
                title: Text('Error al mostrar abono: $docId'),
                subtitle: Text('Detalles: $e'),
              );
            }
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
  }
}
