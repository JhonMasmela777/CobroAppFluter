import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NuevoCreditoView extends StatefulWidget {
  const NuevoCreditoView({Key? key}) : super(key: key);

  @override
  State<NuevoCreditoView> createState() => _NuevoCreditoViewState();
}

class _NuevoCreditoViewState extends State<NuevoCreditoView> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController montoController = TextEditingController();
  final TextEditingController fechaInicioController = TextEditingController();
  final TextEditingController valorCuotaController = TextEditingController();
  final TextEditingController cantidadCuotasController =
      TextEditingController();
  final TextEditingController frecuenciaPagoController =
      TextEditingController();
  final TextEditingController referenciasController = TextEditingController();
  late String clienteId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args != null && args is String) {
      clienteId = args;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00C3A5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C3A5),
        elevation: 0,
        title: const Text(
          "Nuevo Crédito",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              Map<String, dynamic> creditoData = {
                'monto': int.parse(montoController.text),
                'fecha_inicio': fechaInicioController.text,
                'valor_cuota': int.parse(valorCuotaController.text),
                'cantidad_cuotas': int.parse(cantidadCuotasController.text),
                'frecuencia_pago': frecuenciaPagoController.text,
                'referencias': referenciasController.text,
                'registrado': Timestamp.now(),
              };

              try {
                await FirebaseFirestore.instance
                    .collection('clientes')
                    .doc(clienteId)
                    .collection('creditos')
                    .add(creditoData);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Crédito registrado correctamente'),
                  ),
                );
                Navigator.pop(context); // Volver después de guardar
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al guardar crédito: $e')),
                );
              }
            }
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF2FDFB),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                _buildInputField(
                  montoController,
                  "Monto del Crédito",
                  "Ej: 500000",
                ),
                _buildInputField(
                  fechaInicioController,
                  "Fecha de Inicio",
                  "DD/MM/AAAA",
                ),
                _buildInputField(
                  valorCuotaController,
                  "Valor de la Cuota",
                  "Ej: 25000",
                ),
                _buildInputField(
                  cantidadCuotasController,
                  "Cantidad de Cuotas",
                  "Ej: 20",
                ),
                _buildInputField(
                  frecuenciaPagoController,
                  "Frecuencia de Pago",
                  "Ej: Semanal",
                ),
                _buildInputField(
                  referenciasController,
                  "Referencias",
                  "Persona de contacto",
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C3A5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Aquí puedes guardar en Firebase o local
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Crédito registrado correctamente'),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    "Guardar Crédito",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String label,
    String hint,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        ),
        validator:
            (value) =>
                value == null || value.isEmpty
                    ? 'Este campo es obligatorio'
                    : null,
      ),
    );
  }
}
