import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GestionCreditosAdmin extends StatefulWidget {
  @override
  _GestionCreditosAdminState createState() => _GestionCreditosAdminState();
}

class _GestionCreditosAdminState extends State<GestionCreditosAdmin> {
  final CollectionReference creditosRef = FirebaseFirestore.instance.collection(
    'creditos',
  );
  final CollectionReference clientesRef = FirebaseFirestore.instance.collection(
    'clientes',
  );
  final CollectionReference usuariosRef = FirebaseFirestore.instance.collection(
    'usuarios',
  );

  List<Map<String, dynamic>> cobradores = [];
  bool cargandoCobradores = true;

  @override
  void initState() {
    super.initState();
    cargarCobradores();
  }

  Future<void> cargarCobradores() async {
    try {
      final snapshot =
          await usuariosRef.where('rol', isEqualTo: 'usuario').get();
      final lista =
          snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = data['uid']; // ← ahora se usa el campo uid
            return data;
          }).toList();
      setState(() {
        cobradores = lista;
        cargandoCobradores = false;
      });
    } catch (e) {
      setState(() {
        cargandoCobradores = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error cargando cobradores: $e')));
    }
  }

  Future<void> actualizarEstado(String docId, String nuevoEstado) async {
    try {
      await creditosRef.doc(docId).update({'estado': nuevoEstado});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al actualizar estado: $e')));
    }
  }

  Future<void> asignarCobrador(String creditoId, String idCobrador) async {
    try {
      await creditosRef.doc(creditoId).update({
        'cedulaCobradorAsignado': idCobrador,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cobrador asignado correctamente')),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al asignar cobrador: $e')));
    }
  }

  Future<String> obtenerNombreCliente(String idCliente) async {
    try {
      final querySnapshot =
          await clientesRef
              .where('cedula', isEqualTo: idCliente)
              .limit(1)
              .get();
      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data() as Map<String, dynamic>;
        return data['nombreCompleto'] ?? 'Sin nombre';
      } else {
        return 'Cliente no encontrado';
      }
    } catch (e) {
      return 'Error al obtener nombre';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFDFFFEF),
      appBar: AppBar(
        backgroundColor: Color(0xFF00C290),
        title: Text(
          'Gestión De Créditos',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false, // Sin botón de volver atrás
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: creditosRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());

          final creditos = snapshot.data!.docs;
          if (creditos.isEmpty)
            return Center(child: Text('No hay créditos registrados.'));

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: creditos.length,
            itemBuilder: (context, index) {
              final credito = creditos[index];
              final docId = credito.id;
              final estado = credito['estado'];
              final idCliente = credito['idCliente'];

              final asignadoA =
                  credito.data().toString().contains('cedulaCobradorAsignado')
                      ? credito['cedulaCobradorAsignado']
                      : 'Sin asignar';

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
                      FutureBuilder<String>(
                        future: obtenerNombreCliente(idCliente),
                        builder: (context, snapshotNombre) {
                          if (snapshotNombre.connectionState ==
                              ConnectionState.waiting)
                            return Text('Cargando cliente...');
                          if (snapshotNombre.hasError)
                            return Text('Error al cargar cliente');
                          final nombreCliente =
                              snapshotNombre.data ?? 'Sin nombre';
                          return Text(
                            'Cliente: $idCliente - $nombreCliente',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.indigo,
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 8),
                      Text('Artículo: ${credito['articulo']}'),
                      Text('Deuda: \$${credito['deuda']}'),
                      Text('Frecuencia de pago: ${credito['frecuenciaPago']}'),
                      Text('Estado actual: $estado'),
                      Text('Asignado a: $asignadoA'),
                      SizedBox(height: 16),
                      if (estado == 'pendiente') ...[
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
                        ),
                        SizedBox(height: 10),
                        if (asignadoA == 'Sin asignar') ...[
                          cargandoCobradores
                              ? Center(child: CircularProgressIndicator())
                              : DropdownButtonFormField<String>(
                                hint: Text("Asignar cobrador"),
                                onChanged: (idSeleccionado) {
                                  if (idSeleccionado != null) {
                                    asignarCobrador(docId, idSeleccionado);
                                  }
                                },
                                items:
                                    cobradores.map((usuario) {
                                      return DropdownMenuItem<String>(
                                        value: usuario['id'],
                                        child: Text(
                                          '${usuario['nombre']} (${usuario['cedula']})',
                                        ),
                                      );
                                    }).toList(),
                              ),
                        ] else
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Cobrador asignado: $asignadoA',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                      ] else
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
