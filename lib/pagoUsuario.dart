import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cobro_app_flutter/detallePagoUsuario.dart';

class PagoUsuario extends StatefulWidget {
  final String creditoId;
  final String cuotaId;
  final double deudaActual;
  final double saldoCuota;
  final String clienteId;
  final String userId;

  const PagoUsuario({
    super.key,
    required this.creditoId,
    required this.cuotaId,
    required this.deudaActual,
    required this.saldoCuota,
    required this.clienteId,
    required this.userId,
  });

  @override
  State<PagoUsuario> createState() => _PagoUsuarioState();
}

class _PagoUsuarioState extends State<PagoUsuario> {
  final TextEditingController _valorController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _guardando = false;

  Future<void> _registrarAbono() async {
    if (_guardando || !_formKey.currentState!.validate()) return;

    final valor = double.tryParse(
      _valorController.text.trim().replaceAll(',', '.'),
    );

    if (valor == null || valor <= 0) return;

    setState(() => _guardando = true);

    try {
      final firestore = FirebaseFirestore.instance;

      final creditoRef = firestore.collection('creditos').doc(widget.creditoId);

      final cuotaRef = firestore.collection('cuotas').doc(widget.cuotaId);

      final abonoRef = firestore.collection('abonos').doc();

      final fechaAbono = DateTime.now();

      await firestore.runTransaction((transaction) async {
        final cuotaSnapshot = await transaction.get(cuotaRef);
        final creditoSnapshot = await transaction.get(creditoRef);

        if (!cuotaSnapshot.exists || !creditoSnapshot.exists) {
          throw Exception('No se encontró el crédito o la cuota.');
        }

        final cuota = cuotaSnapshot.data()!;
        final credito = creditoSnapshot.data()!;

        final valorOriginal = (cuota['valorCuota'] as num?)?.toDouble() ?? 0;

        final saldoCuota =
            (cuota['saldoPendiente'] as num?)?.toDouble() ?? valorOriginal;

        final saldoCredito = (credito['deuda'] as num?)?.toDouble() ?? 0;

        if (cuota['estado']?.toString().toLowerCase() == 'pagado' ||
            saldoCuota <= 0) {
          throw Exception('Esta cuota ya se encuentra pagada.');
        }

        if (valor > saldoCuota + 0.001) {
          throw Exception('El abono supera el saldo pendiente de la cuota.');
        }

        if (valor > saldoCredito + 0.001) {
          throw Exception('El abono supera la deuda pendiente del crédito.');
        }

        final nuevoSaldoCuota = (saldoCuota - valor).clamp(
          0.0,
          double.infinity,
        );
        final nuevoSaldoCredito = (saldoCredito - valor).clamp(
          0.0,
          double.infinity,
        );

        transaction.set(abonoRef, {
          'clienteId': widget.clienteId,
          'creditoId': widget.creditoId,
          'cuotaId': widget.cuotaId,
          'valor': valor,
          'fecha': Timestamp.fromDate(fechaAbono),
          'userId': widget.userId,
        });

        transaction.update(cuotaRef, {
          'saldoPendiente': nuevoSaldoCuota,
          'ultimoAbonoEn': Timestamp.fromDate(fechaAbono),
          'estado': nuevoSaldoCuota <= 0.001 ? 'Pagado' : 'Pendiente',
          'actualizadoEn': FieldValue.serverTimestamp(),
        });

        transaction.update(creditoRef, {
          'deuda': nuevoSaldoCredito,
          'estado': nuevoSaldoCredito <= 0.001 ? 'pagado' : 'Pendiente',
        });
      });

      if (!mounted) return;

      _valorController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green[600],
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Abono guardado correctamente'),
            ],
          ),
        ),
      );

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => DetallePagoUsuario(
                clienteId: widget.clienteId,
                userId: widget.userId,
              ),
        ),
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      final mensaje = e.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red[700], content: Text(mensaje)),
      );

      debugPrint('Error al guardar abono: $e');
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFFFEF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C290),
        leading: const BackButton(color: Colors.white),
        title: const Text('Registrar Abono'),
        centerTitle: true,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Saldo pendiente de la cuota',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '\$${widget.saldoCuota.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF008F69),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _valorController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Valor del abono',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(
                      Icons.attach_money,
                      color: Color(0xFF00C290),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingrese un valor';
                    }

                    final v = double.tryParse(
                      value.trim().replaceAll(',', '.'),
                    );

                    if (v == null || v <= 0) {
                      return 'Ingrese un valor válido mayor que 0';
                    }

                    if (v > widget.saldoCuota + 0.001) {
                      return 'El abono supera el saldo de la cuota';
                    }

                    if (v > widget.deudaActual + 0.001) {
                      return 'El abono supera la deuda del crédito';
                    }

                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _guardando ? null : _registrarAbono,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C290),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child:
                      _guardando
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            'Registrar y Ver Detalles',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
