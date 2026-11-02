import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class CrearCreditoAdmin extends StatefulWidget {
  final String clienteId;

  const CrearCreditoAdmin({super.key, required this.clienteId});

  @override
  State<CrearCreditoAdmin> createState() => _CrearCreditoAdminState();
}

class _CrearCreditoAdminState extends State<CrearCreditoAdmin> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _deudaController = TextEditingController();
  final TextEditingController _numeroCuotasController = TextEditingController();

  String? _articuloSeleccionado;
  String? _frecuenciaSeleccionada;
  bool _cargando = false;

  final List<String> _articulos = [
    'Zapatero',
    'Sabana',
    'Silla mecedora',
    'Espejo',
    'Cuadro',
  ];

  final List<String> _frecuencias = ['Semanal', 'Quincenal', 'Mensual'];

  // Calcula el vencimiento según la frecuencia.
  // Para pagos mensuales conserva el día cuando es posible
  // y ajusta al último día del mes cuando es necesario.
  DateTime _calcularVencimiento(DateTime inicio, int numeroCuota) {
    switch (_frecuenciaSeleccionada) {
      case 'Semanal':
        return inicio.add(Duration(days: 7 * numeroCuota));

      case 'Quincenal':
        return inicio.add(Duration(days: 15 * numeroCuota));

      case 'Mensual':
        final mesBase = inicio.month - 1 + numeroCuota;
        final anio = inicio.year + mesBase ~/ 12;
        final mes = mesBase % 12 + 1;

        final primerDiaMesSiguiente = DateTime(anio, mes + 1, 1);
        final ultimoDiaMes =
            primerDiaMesSiguiente.subtract(const Duration(days: 1)).day;

        final dia = inicio.day > ultimoDiaMes ? ultimoDiaMes : inicio.day;

        return DateTime(
          anio,
          mes,
          dia,
          inicio.hour,
          inicio.minute,
          inicio.second,
        );

      default:
        throw Exception('Selecciona una frecuencia válida.');
    }
  }

  Future<void> _crearCredito() async {
    if (_cargando) return;
    if (!_formKey.currentState!.validate()) return;

    if (_articuloSeleccionado == null || _frecuenciaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona el artículo y la frecuencia.'),
        ),
      );
      return;
    }

    // Quitamos los puntos de miles antes de convertir el valor.
    final deudaTexto = _deudaController.text.replaceAll('.', '');
    final deuda = int.tryParse(deudaTexto);

    final numeroCuotas = int.tryParse(_numeroCuotasController.text.trim());

    if (deuda == null ||
        deuda < 100000 ||
        deuda > 1000000 ||
        numeroCuotas == null ||
        numeroCuotas < 2 ||
        numeroCuotas > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La deuda debe estar entre 100.000 y 1.000.000. '
            'Las cuotas deben estar entre 2 y 10.',
          ),
        ),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final fechaInicio = DateTime.now();

      // Convertimos a centavos para conservar la lógica de distribución.
      final deudaPesos = deuda * 100;
      final cuotaBase = deudaPesos ~/ numeroCuotas;
      final creditoRef = firestore.collection('creditos').doc();

      final batch = firestore.batch();

      batch.set(creditoRef, {
        'idCliente': widget.clienteId,
        'articulo': _articuloSeleccionado,
        'deuda': deudaPesos / 100,
        'frecuenciaPago': _frecuenciaSeleccionada,
        'numeroCuotas': numeroCuotas,
        'fechaInicio': Timestamp.fromDate(fechaInicio),
        'estado': 'Pendiente',
        'creadoEn': FieldValue.serverTimestamp(),
      });

      for (int i = 1; i <= numeroCuotas; i++) {
        final valorCuotaPesos =
            i == numeroCuotas
                ? deudaPesos - cuotaBase * (numeroCuotas - 1)
                : cuotaBase;

        final fechaVencimiento = _calcularVencimiento(fechaInicio, i);

        final cuotaRef = firestore.collection('cuotas').doc();

        batch.set(cuotaRef, {
          'idCredito': creditoRef.id,
          'idCliente': widget.clienteId,
          'numeroCuota': i,
          'valorCuota': valorCuotaPesos / 100,
          'fechaVencimiento': Timestamp.fromDate(fechaVencimiento),
          'estado': 'Pendiente',
          'recordatorioEnviado': false,
          'creadoEn': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF00C290),
          content: Text('Crédito y calendario de cuotas creados exitosamente.'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error al crear el crédito: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  @override
  void dispose() {
    _deudaController.dispose();
    _numeroCuotasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFE9F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C290),
        title: const Text('Crear Crédito'),
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 16),

              _campoDropdown(
                'Artículo',
                _articulos,
                _articuloSeleccionado,
                (value) => setState(() => _articuloSeleccionado = value),
              ),

              _campoTexto(
                'Deuda total',
                _deudaController,
                tipo: const TextInputType.numberWithOptions(decimal: true),
              ),

              _campoTexto(
                'Número de cuotas',
                _numeroCuotasController,
                tipo: TextInputType.number,
              ),

              _campoDropdown(
                'Frecuencia de pago',
                _frecuencias,
                _frecuenciaSeleccionada,
                (value) => setState(() => _frecuenciaSeleccionada = value),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _cargando ? null : _crearCredito,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C290),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child:
                    _cargando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          'Guardar Crédito',
                          style: TextStyle(fontSize: 18, color: Colors.white),
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
    final esDeuda = label == 'Deuda total';
    final esNumeroCuotas = label == 'Número de cuotas';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters:
            esDeuda
                ? [FilteringTextInputFormatter.digitsOnly, FormatoMiles()]
                : esNumeroCuotas
                ? [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ]
                : null,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Este campo es obligatorio.';
          }

          if (esDeuda) {
            final valor = int.tryParse(value.replaceAll('.', '').trim());

            if (valor == null || valor < 100000 || valor > 1000000) {
              return 'La deuda debe estar entre 100.000 y 1.000.000.';
            }
          }

          if (esNumeroCuotas) {
            final numero = int.tryParse(value.trim());

            if (numero == null || numero < 2 || numero > 10) {
              return 'Ingresa un número de cuotas entre 2 y 10.';
            }
          }

          return null;
        },
      ),
    );
  }

  Widget _campoDropdown(
    String label,
    List<String> items,
    String? seleccionado,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: seleccionado,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items:
            items
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
        onChanged: _cargando ? null : onChanged,
        validator: (value) => value == null ? 'Selecciona una opción.' : null,
      ),
    );
  }
}

class FormatoMiles extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final numeros = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (numeros.isEmpty) {
      return newValue.copyWith(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    final valor = int.tryParse(numeros);

    if (valor == null || valor >= 1000000) {
      return oldValue;
    }

    final textoFormateado = numeros.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    return TextEditingValue(
      text: textoFormateado,
      selection: TextSelection.collapsed(offset: textoFormateado.length),
    );
  }
}
