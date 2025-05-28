import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BaseDatosAdmin extends StatelessWidget {
  const BaseDatosAdmin({super.key});

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
    String collectionName,
  ) {
    String titleText;

    if (collectionName == 'creditos') {
      titleText =
          data['nombreCompleto'] ??
          data['nombre'] ??
          data['idCliente'] ??
          'Sin información';
    } else {
      titleText = data['nombreCompleto'] ?? data['nombre'] ?? 'Sin nombre';
    }

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
        leading: const Icon(Icons.person, color: Colors.blue, size: 30),
        title: Text(
          titleText,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          data['cedula'] != null
              ? 'Cédula: ${data['cedula']}'
              : data['correoElectronico'] != null
              ? 'Correo: ${data['correoElectronico']}'
              : collectionName == 'creditos' && data['idCliente'] != null
              ? 'ID Cliente: ${data['idCliente']}'
              : collectionName == 'creditos' && data['adminId'] != null
              ? 'ID Admin: ${data['adminId']}'
              : 'Sin información adicional',
        ),
        onTap: () async {
          if (collectionName == 'creditos') {
            String nombreCliente = 'No encontrado';
            String nombreAdmin = 'No encontrado';

            // Obtener nombre cliente buscando por idCliente (document ID)
            if (data['idCliente'] != null) {
              final clienteDoc =
                  await FirebaseFirestore.instance
                      .collection('clientes')
                      .doc(data['idCliente'])
                      .get();

              if (clienteDoc.exists) {
                final clienteData = clienteDoc.data()!;
                nombreCliente =
                    clienteData['nombreCompleto'] ??
                    clienteData['nombre'] ??
                    'Sin nombre';
              }
            }

            // Obtener nombre admin por adminId
            if (data['adminId'] != null) {
              final adminDoc =
                  await FirebaseFirestore.instance
                      .collection(
                        'usuarios',
                      ) // Cambia por el nombre correcto si es distinto
                      .doc(data['adminId'])
                      .get();

              if (adminDoc.exists) {
                final adminData = adminDoc.data()!;
                nombreAdmin =
                    adminData['nombreCompleto'] ??
                    adminData['nombre'] ??
                    'Sin nombre';
              }
            }

            showDialog(
              context: context,
              builder: (_) {
                return AlertDialog(
                  title: const Text('Detalles del crédito'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        Text(
                          'Nombre del Cliente: $nombreCliente',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Nombre del Admin: $nombreAdmin',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...data.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Text(
                              '${entry.key}: ${entry.value}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
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
          } else {
            // Para otros documentos (no créditos o sin idCliente/adminId)
            showDialog(
              context: context,
              builder: (_) {
                return AlertDialog(
                  title: const Text('Detalles del documento'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: ListView(
                      shrinkWrap: true,
                      children:
                          data.entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 2.0,
                              ),
                              child: Text(
                                '${entry.key}: ${entry.value}',
                                style: const TextStyle(fontSize: 14),
                              ),
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
          }
        },
      ),
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
      backgroundColor: const Color(0xFFDFFFEF), // Verde muy claro
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C290), // Verde oscuro
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
