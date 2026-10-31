import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GestionCreditosAdmin extends StatefulWidget {
<<<<<<< HEAD
  const GestionCreditosAdmin({super.key});

  @override
  State<GestionCreditosAdmin> createState() => _GestionCreditosAdminState();
=======
  @override
  _GestionCreditosAdminState createState() => _GestionCreditosAdminState();
>>>>>>> origin/main
}

class _GestionCreditosAdminState extends State<GestionCreditosAdmin> {
  final CollectionReference creditosRef = FirebaseFirestore.instance.collection(
    'creditos',
  );
<<<<<<< HEAD

  final CollectionReference clientesRef = FirebaseFirestore.instance.collection(
    'clientes',
  );

=======
  final CollectionReference clientesRef = FirebaseFirestore.instance.collection(
    'clientes',
  );
>>>>>>> origin/main
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
<<<<<<< HEAD
      // Leemos los perfiles para admitir las dos estructuras:
      // userId y uid.
      final snapshot = await usuariosRef.get();

      final List<Map<String, dynamic>> lista = [];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        final rol = (data['rol'] ?? '').toString().trim().toLowerCase();

        if (rol != 'usuario') continue;

        // El ID utilizado para asignar el crédito debe ser
        // el UID de Authentication, no el ID automático
        // del documento de Firestore.
        final idUsuario =
            (data['userId'] ?? data['uid'] ?? '').toString().trim();

        if (idUsuario.isEmpty) {
          debugPrint('Cobrador sin UID válido. Documento: ${doc.id}');
          continue;
        }

        lista.add({
          ...data,
          'id': idUsuario,
          'nombre': data['nombre'] ?? 'Sin nombre',
          'cedula': data['cedula'] ?? 'Sin cédula',
        });
      }

      if (!mounted) return;

=======
      final snapshot =
          await usuariosRef.where('rol', isEqualTo: 'usuario').get();
      final lista =
          snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = data['uid']; // ← ahora se usa el campo uid
            return data;
          }).toList();
>>>>>>> origin/main
      setState(() {
        cobradores = lista;
        cargandoCobradores = false;
      });
<<<<<<< HEAD

      debugPrint('COBRADORES CARGADOS: ${cobradores.length}');

      for (final cobrador in cobradores) {
        debugPrint('Nombre: ${cobrador['nombre']} | UID: ${cobrador['id']}');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargandoCobradores = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error cargando cobradores: $e'),
=======
    } catch (e) {
      setState(() {
        cargandoCobradores = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 10),
              Expanded(child: Text('Error cargando cobradores: $e')),
            ],
          ),
>>>>>>> origin/main
        ),
      );
    }
  }

  Future<void> actualizarEstado(String docId, String nuevoEstado) async {
    try {
      await creditosRef.doc(docId).update({'estado': nuevoEstado});
    } catch (e) {
<<<<<<< HEAD
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error al actualizar estado: $e'),
=======
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 10),
              Expanded(child: Text('Error al actualizar estado: $e')),
            ],
          ),
>>>>>>> origin/main
        ),
      );
    }
  }

  Future<void> asignarCobrador(String creditoId, String idCobrador) async {
    try {
<<<<<<< HEAD
      debugPrint('CRÉDITO: $creditoId');
      debugPrint('UID DEL COBRADOR: $idCobrador');

      await creditosRef.doc(creditoId).update({
        'cedulaCobradorAsignado': idCobrador,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Cobrador asignado correctamente'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error al asignar cobrador: $e'),
=======
      await creditosRef.doc(creditoId).update({
        'cedulaCobradorAsignado': idCobrador,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Cobrador Asignado Correctamente'),
            ],
          ),
        ),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 10),
              Expanded(child: Text('Error al asignar cobrador: $e')),
            ],
          ),
>>>>>>> origin/main
        ),
      );
    }
  }

  Future<String> obtenerNombreCliente(String idCliente) async {
    try {
<<<<<<< HEAD
      // Primero comprobamos si idCliente es el ID del documento.
      final documento = await clientesRef.doc(idCliente).get();

      if (documento.exists) {
        final data = documento.data() as Map<String, dynamic>;

        return (data['nombreCompleto'] ?? data['nombre'] ?? 'Sin nombre')
            .toString();
      }

      // Compatibilidad si idCliente contiene una cédula.
      final consulta =
=======
      final querySnapshot =
>>>>>>> origin/main
          await clientesRef
              .where('cedula', isEqualTo: idCliente)
              .limit(1)
              .get();
<<<<<<< HEAD

      if (consulta.docs.isNotEmpty) {
        final data = consulta.docs.first.data() as Map<String, dynamic>;

        return (data['nombreCompleto'] ?? data['nombre'] ?? 'Sin nombre')
            .toString();
      }

      return 'Cliente no encontrado';
    } catch (e) {
      debugPrint('Error buscando cliente: $e');
=======
      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data() as Map<String, dynamic>;
        return data['nombreCompleto'] ?? 'Sin nombre';
      } else {
        return 'Cliente no encontrado';
      }
    } catch (e) {
>>>>>>> origin/main
      return 'Error al obtener nombre';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD
      backgroundColor: const Color(0xFFDFFFEF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C290),
        title: const Text(
=======
      backgroundColor: Color(0xFFDFFFEF),
      appBar: AppBar(
        backgroundColor: Color(0xFF00C290),
        title: Text(
>>>>>>> origin/main
          'Gestión De Créditos',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
<<<<<<< HEAD
        leading: const BackButton(color: Colors.white),
=======
        automaticallyImplyLeading: true, // Activamos el botón de atrás
        leading: BackButton(color: Colors.white), // Flecha blanca
>>>>>>> origin/main
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: creditosRef.snapshots(),
        builder: (context, snapshot) {
<<<<<<< HEAD
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar los créditos'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final creditos = snapshot.data!.docs;

          if (creditos.isEmpty) {
            return const Center(child: Text('No hay créditos registrados.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
=======
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());

          final creditos = snapshot.data!.docs;
          if (creditos.isEmpty)
            return Center(child: Text('No hay créditos registrados.'));

          return ListView.builder(
            padding: EdgeInsets.all(16),
>>>>>>> origin/main
            itemCount: creditos.length,
            itemBuilder: (context, index) {
              final credito = creditos[index];
              final docId = credito.id;
<<<<<<< HEAD

              final data = credito.data() as Map<String, dynamic>;

              final estado = (data['estado'] ?? '').toString();

              final idCliente = (data['idCliente'] ?? '').toString();

              final asignadoA =
                  (data['cedulaCobradorAsignado'] ?? '').toString().trim();

              final sinAsignar = asignadoA.isEmpty;
=======
              final estado = credito['estado'];
              final idCliente = credito['idCliente'];

              final asignadoA =
                  credito.data().toString().contains('cedulaCobradorAsignado')
                      ? credito['cedulaCobradorAsignado']
                      : 'Sin asignar';
>>>>>>> origin/main

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
<<<<<<< HEAD
                  color: const Color(0xFFF6F3FB),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
=======
                  color: Color(0xFFF6F3FB),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
>>>>>>> origin/main
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
<<<<<<< HEAD
                        builder: (context, nombreSnapshot) {
                          if (nombreSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Text('Cargando cliente...');
                          }

                          return Text(
                            'Cliente: $idCliente - '
                            '${nombreSnapshot.data ?? 'Sin nombre'}',
                            style: const TextStyle(
=======
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
>>>>>>> origin/main
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.indigo,
                            ),
                          );
                        },
                      ),
<<<<<<< HEAD
                      const SizedBox(height: 8),
                      Text('Artículo: ${data['articulo'] ?? 'No registrado'}'),
                      Text('Deuda: \$${data['deuda'] ?? 0}'),
                      Text(
                        'Frecuencia de pago: '
                        '${data['frecuenciaPago'] ?? 'No registrada'}',
                      ),
                      Text('Estado actual: $estado'),
                      Text(
                        sinAsignar
                            ? 'Asignado a: Sin asignar'
                            : 'Asignado a UID: $asignadoA',
                      ),
                      const SizedBox(height: 16),

                      if (estado.trim().toLowerCase() == 'pendiente') ...[
=======
                      SizedBox(height: 8),
                      Text('Artículo: ${credito['articulo']}'),
                      Text('Deuda: \$${credito['deuda']}'),
                      Text('Frecuencia de pago: ${credito['frecuenciaPago']}'),
                      Text('Estado actual: $estado'),
                      Text('Asignado a: $asignadoA'),
                      SizedBox(height: 16),
                      if (estado == 'Pendiente') ...[
>>>>>>> origin/main
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed:
                                  () => actualizarEstado(docId, 'pagado'),
<<<<<<< HEAD
                              icon: const Icon(Icons.check),
                              label: const Text('Pagado'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
=======
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
>>>>>>> origin/main
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed:
                                  () => actualizarEstado(docId, 'cancelado'),
<<<<<<< HEAD
                              icon: const Icon(Icons.cancel),
                              label: const Text('Cancelar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
=======
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
>>>>>>> origin/main
                              ),
                            ),
                          ],
                        ),
<<<<<<< HEAD
                        const SizedBox(height: 10),

                        if (sinAsignar) ...[
                          if (cargandoCobradores)
                            const Center(child: CircularProgressIndicator())
                          else if (cobradores.isEmpty)
                            const Text('No hay cobradores con UID válido.')
                          else
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                              hint: const Text('Asignar cobrador'),
                              items:
                                  cobradores.map((usuario) {
                                    return DropdownMenuItem<String>(
                                      value: usuario['id'] as String,
                                      child: Text(
                                        '${usuario['nombre']} '
                                        '(${usuario['cedula']})',
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (idSeleccionado) {
                                if (idSeleccionado != null) {
                                  asignarCobrador(docId, idSeleccionado);
                                }
                              },
                            ),
                        ] else
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Este crédito ya tiene un cobrador asignado.',
=======
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
>>>>>>> origin/main
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
