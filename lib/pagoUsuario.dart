import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hola_mundo/detallerPagoUsuario.dart';
import 'package:hola_mundo/historialPagoUsuario.dart';

class PagoUsuario extends StatefulWidget {
  final String creditoId;
  final double deudaActual;
  final String clienteCedula;

  PagoUsuario({
    required this.creditoId,
    required this.deudaActual,
    required this.clienteCedula,
  });

  @override
  State<PagoUsuario> createState() => _PagoUsuarioState();
}

class _PagoUsuarioState extends State<PagoUsuario> {
  final TextEditingController _abonoController = TextEditingController();
  String? clienteDocId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _buscarClientePorCedula();
  }

  Future<void> _buscarClientePorCedula() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('clientes')
              .where('cedula', isEqualTo: widget.clienteCedula)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          clienteDocId = snapshot.docs.first.id;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cliente no encontrado')));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al buscar cliente: $e')));
    }
  }

  void _registrarAbono() async {
    final abono = double.tryParse(_abonoController.text);
    if (abono == null || abono <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ingresa un abono válido')));
      return;
    }

    if (clienteDocId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener el cliente')),
      );
      return;
    }

    final nuevaDeuda = widget.deudaActual - abono;
    final Timestamp fechaActual = Timestamp.now();

    try {
      await FirebaseFirestore.instance.collection('abonos').add({
        'valor': abono,
        'fecha': fechaActual,
        'cedula': widget.clienteCedula,
        'creditoId': widget.creditoId,
        'clienteId': clienteDocId,
      });

      await FirebaseFirestore.instance
          .collection('creditos')
          .doc(widget.creditoId)
          .update({'deuda': nuevaDeuda < 0 ? 0 : nuevaDeuda});

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => Detallerpagousuario(cedula: widget.clienteCedula),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al registrar el pago: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFFFEF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C290),
        title: const Text(
          'Registrar Pago',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Deuda actual: \$${widget.deudaActual.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _abonoController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Monto del abono',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _registrarAbono,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C290),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                      ),
                      child: const Text(
                        'Registrar Pago',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Historial de Pagos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('abonos')
                                .where(
                                  'cedula',
                                  isEqualTo: widget.clienteCedula,
                                )
                                .where('creditoId', isEqualTo: widget.creditoId)
                                .orderBy('fecha', descending: true)
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Text('Sin pagos registrados'),
                            );
                          }

                          return ListView.builder(
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              final abono = snapshot.data!.docs[index];
                              final valor = abono['valor'] ?? 0.0;
                              final fecha =
                                  (abono['fecha'] as Timestamp).toDate();

                              return ListTile(
                                leading: const Icon(Icons.attach_money),
                                title: Text(
                                  'Abono: \$${valor.toStringAsFixed(2)}',
                                ),
                                subtitle: Text(
                                  'Fecha: ${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute}',
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
