import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Para formatear fecha y hora

class CrearCreditoAdmin extends StatefulWidget {
  final String cedula;

  const CrearCreditoAdmin({super.key, required this.cedula});

  @override
  State<CrearCreditoAdmin> createState() => _CrearCreditoAdminState();
}

class _CrearCreditoAdminState extends State<CrearCreditoAdmin> {
  final _formKey = GlobalKey<FormState>();

  // Controllers para campos que siguen siendo texto
  final TextEditingController _deudaController = TextEditingController();
  final TextEditingController _estadoController = TextEditingController();

  // Variables para dropdowns
  String? _articuloSeleccionado;
  String? _frecuenciaSeleccionada;

  // Opciones para dropdown
  final List<String> _articulos = [
    'zapatero',
    'sabana',
    'silla mecedora',
    'espejo',
    'cuadro',
  ];

  final List<String> _frecuencias = ['Quincenal', 'Mensual', 'Semanal'];

  @override
  Widget build(BuildContext context) {
    // Formatear fecha y hora actual
    final String fechaHoraActual = DateFormat(
      'dd/MM/yyyy HH:mm:ss',
    ).format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFEFE9F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00B894),
        title: const Text('Crear Crédito'),
        centerTitle: true,
        leading: BackButton(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Cédula del Cliente: ${widget.cedula}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Mostrar fecha y hora actual
              Text(
                'Fecha y Hora: $fechaHoraActual',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 16),

              // Dropdown para Artículo
              _campoDropdown('Artículo', _articulos, _articuloSeleccionado, (
                String? nuevoValor,
              ) {
                setState(() {
                  _articuloSeleccionado = nuevoValor;
                });
              }),

              // Campo Deuda
              _campoTexto(
                'Deuda',
                _deudaController,
                tipo: TextInputType.number,
              ),

              // Campo Estado
              _campoTexto('Estado', _estadoController),

              // Dropdown para Frecuencia de Pago
              _campoDropdown(
                'Frecuencia de Pago',
                _frecuencias,
                _frecuenciaSeleccionada,
                (String? nuevoValor) {
                  setState(() {
                    _frecuenciaSeleccionada = nuevoValor;
                  });
                },
              ),

              const SizedBox(height: 20),

              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Validar dropdowns
                      if (_articuloSeleccionado == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Seleccione un artículo'),
                          ),
                        );
                        return;
                      }
                      if (_frecuenciaSeleccionada == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Seleccione frecuencia de pago'),
                          ),
                        );
                        return;
                      }

                      // Actualizar los controladores de texto para guardar en firestore (si quieres mantener lógica intacta)
                      // En vez de controladores, puedes usar las variables en la función _crearCredito
                      // Pero como pediste no cambiar lógica, esto es solo para evitar errores en validación
                      // Sin embargo, se puede ajustar la función _crearCredito para usar estas variables.
                      // Pero como me pediste, dejo lógica intacta.

                      _crearCredito(); // Tu función original
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B894),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                  ),
                  child: const Text(
                    'Guardar Crédito',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campoTexto(
    String label,
    TextEditingController controller, {
    TextInputType tipo = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: tipo,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Este campo es obligatorio';
          }
          return null;
        },
      ),
    );
  }

  Widget _campoDropdown(
    String label,
    List<String> items,
    String? valorSeleccionado,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InputDecorator(
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: valorSeleccionado,
            isExpanded: true,
            onChanged: onChanged,
            items:
                items
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item)),
                    )
                    .toList(),
            hint: Text('Seleccione $label'),
          ),
        ),
      ),
    );
  }

  Future<void> _crearCredito() async {
    // Aquí queda intacta tu función original, solo he copiado para que funcione con las variables dropdown
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('creditos').add({
          'articulo': _articuloSeleccionado ?? '',
          'deuda': double.tryParse(_deudaController.text.trim()) ?? 0.0,
          'estado': _estadoController.text.trim(),
          'fechaInicio': Timestamp.now(),
          'frecuenciaPago': _frecuenciaSeleccionada ?? '',
          'idCliente': widget.cedula,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Crédito creado exitosamente')),
        );

        Navigator.pop(context); // Opcional: volver después de crear
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al crear crédito: $e')));
      }
    }
  }
}
