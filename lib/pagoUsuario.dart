import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hola_mundo/detallerPagoUsuario.dart';

class PagoUsuario extends StatefulWidget {
  final String creditoId;
  final double deudaActual;
  final String clienteId;
  final String userId;

  PagoUsuario({
    required this.creditoId,
    required this.deudaActual,
    required this.clienteId,
    required this.userId,
  });

  @override
  _PagoUsuarioState createState() => _PagoUsuarioState();
}

class _PagoUsuarioState extends State<PagoUsuario> {
  final TextEditingController _valorController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _registrarAbono() async {
    if (!_formKey.currentState!.validate()) return;

    final valor = double.parse(_valorController.text);

    try {
      await FirebaseFirestore.instance.collection('abonos').add({
        'clienteId': widget.clienteId,
        'valor': valor,
        'fecha': Timestamp.now(),
        'userId': widget.userId,
      });

      final nuevoSaldo = widget.deudaActual - valor;
      await FirebaseFirestore.instance
          .collection('creditos')
          .doc(widget.creditoId)
          .update({'deuda': nuevoSaldo});

      // Limpiar el campo de texto después de guardar el abono
      _valorController.clear();

      // Mostrar SnackBar con icono de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green[600],
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Abono guardado correctamente'),
            ],
          ),
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => DetallePagoUsuario(
                clienteId: widget.clienteId,
                userId: widget.userId,
              ),
        ),
      );
    } catch (e) {
      // Mostrar SnackBar con icono de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red[700],
          content: Row(
            children: const [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Text('No se pudo efectuar el abono'),
            ],
          ),
        ),
      );

      print('Error al guardar abono: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFFFEF), // Fondo igual a CobrosUsuario
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
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese un valor';
                    }
                    final v = double.tryParse(value);
                    if (v == null || v <= 0) {
                      return 'Ingrese un valor válido mayor que 0';
                    }
                    if (v > widget.deudaActual) {
                      return 'El abono no puede ser mayor a la deuda actual';
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
                  onPressed: _registrarAbono,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C290),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
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
