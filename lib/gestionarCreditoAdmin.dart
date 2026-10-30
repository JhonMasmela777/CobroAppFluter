import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GestionCreditosAdmin extends StatefulWidget {
  const GestionCreditosAdmin({super.key});

  @override
  State<GestionCreditosAdmin> createState() => _GestionCreditosAdminState();
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

      setState(() {
        cobradores = lista;
        cargandoCobradores = false;
      });

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
        ),
      );
    }
  }

  Future<void> actualizarEstado(String docId, String nuevoEstado) async {
    try {
      await creditosRef.doc(docId).update({'estado': nuevoEstado});
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error al actualizar estado: $e'),
        ),
      );
    }
  }

  Future<void> asignarCobrador(String creditoId, String idCobrador) async {
    try {
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
        ),
      );
    }
  }

  Future<String> obtenerNombreCliente(String idCliente) async {
    try {
      // Primero comprobamos si idCliente es el ID del documento.
      final documento = await clientesRef.doc(idCliente).get();

      if (documento.exists) {
        final data = documento.data() as Map<String, dynamic>;

        return (data['nombreCompleto'] ?? data['nombre'] ?? 'Sin nombre')
            .toString();
      }

      // Compatibilidad si idCliente contiene una cédula.
      final consulta =
          await clientesRef
              .where('cedula', isEqualTo: idCliente)
              .limit(1)
              .get();

      if (consulta.docs.isNotEmpty) {
        final data = consulta.docs.first.data() as Map<String, dynamic>;

        return (data['nombreCompleto'] ?? data['nombre'] ?? 'Sin nombre')
            .toString();
      }

      return 'Cliente no encontrado';
    } catch (e) {
      debugPrint('Error buscando cliente: $e');
      return 'Error al obtener nombre';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFFFEF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C290),
        title: const Text(
          'Gestión De Créditos',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: creditosRef.snapshots(),
        builder: (context, snapshot) {
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
            itemCount: creditos.length,
            itemBuilder: (context, index) {
              final credito = creditos[index];
              final docId = credito.id;

              final data = credito.data() as Map<String, dynamic>;

              final estado = (data['estado'] ?? '').toString();

              final idCliente = (data['idCliente'] ?? '').toString();

              final asignadoA =
                  (data['cedulaCobradorAsignado'] ?? '').toString().trim();

              final sinAsignar = asignadoA.isEmpty;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
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
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<String>(
                        future: obtenerNombreCliente(idCliente),
                        builder: (context, nombreSnapshot) {
                          if (nombreSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Text('Cargando cliente...');
                          }

                          return Text(
                            'Cliente: $idCliente - '
                            '${nombreSnapshot.data ?? 'Sin nombre'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.indigo,
                            ),
                          );
                        },
                      ),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed:
                                  () => actualizarEstado(docId, 'pagado'),
                              icon: const Icon(Icons.check),
                              label: const Text('Pagado'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed:
                                  () => actualizarEstado(docId, 'cancelado'),
                              icon: const Icon(Icons.cancel),
                              label: const Text('Cancelar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
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
