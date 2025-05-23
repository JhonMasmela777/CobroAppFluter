import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GestionCreditosAdmin extends StatelessWidget {
  final CollectionReference creditosRef = FirebaseFirestore.instance.collection(
    'creditos',
  );

  Future<void> actualizarEstado(String docId, String nuevoEstado) async {
    await creditosRef.doc(docId).update({'estado': nuevoEstado});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFDFFFEF), // Verde claro como en el menú
      appBar: AppBar(
        backgroundColor: Color(
          0xFF00C290,
        ), // Verde oscuro como en el encabezado del menú
        title: Text(
          'Gestión De Créditos',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: creditosRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());

          final creditos = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: creditos.length,
            itemBuilder: (context, index) {
              final credito = creditos[index];
              final docId = credito.id;
              final estado = credito['estado'];

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Color(0xFFF6F3FB),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cliente ID: ${credito['idCliente']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.indigo,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('Artículo: ${credito['articulo']}'),
                      Text('Deuda: \$${credito['deuda']}'),
                      Text('Frecuencia de pago: ${credito['frecuenciaPago']}'),
                      Text('Estado actual: $estado'),
                      SizedBox(height: 16),
                      if (estado == 'pendiente')
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed:
                                  () => actualizarEstado(docId, 'pagado'),
                              icon: Icon(Icons.check),
                              label: Text('Pagado'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed:
                                  () => actualizarEstado(docId, 'cancelado'),
                              icon: Icon(Icons.cancel),
                              label: Text('Cancelar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Center(
                          child: Text(
                            'Estado finalizado: $estado',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
