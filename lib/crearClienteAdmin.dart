import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cobro_app_flutter/crearCreditoAdmin.dart';
import 'package:latlong2/latlong.dart';
import 'package:cobro_app_flutter/seleccionarUbicacion.dart';
import 'package:flutter/services.dart';

class CrearClienteAdmin extends StatefulWidget {
  final String adminId;

  const CrearClienteAdmin({Key? key, required this.adminId}) : super(key: key);

  @override
  _CrearClienteAdminState createState() => _CrearClienteAdminState();
}

class _CrearClienteAdminState extends State<CrearClienteAdmin> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _direccionTrabajoController =
      TextEditingController();
  final TextEditingController _direccionViviendaController =
      TextEditingController();

  final TextEditingController _nombreCompletoController =
      TextEditingController();
  final TextEditingController _numeroCelularController =
      TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();

  final TextEditingController _barrioController = TextEditingController();

  double? _latitud;
  double? _longitud;
  bool _ubicacionVerificada = false;
  Future<void> _abrirSelectorUbicacion() async {
    final LatLng? ubicacion = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (context) => const SeleccionarUbicacion()),
    );

    if (!mounted || ubicacion == null) return;

    setState(() {
      _latitud = ubicacion.latitude;
      _longitud = ubicacion.longitude;
      _ubicacionVerificada = true;
    });
  }

  Future<void> _crearCliente() async {
    // PRIORIDAD 1: VALIDAR LOS CAMPOS DEL FORMULARIO
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // PRIORIDAD 2: VALIDAR QUE LA VIVIENDA ESTÉ UBICADA EN EL MAPA
    if (!_ubicacionVerificada || _latitud == null || _longitud == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Row(
            children: [
              Icon(Icons.location_off, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Debes ubicar y confirmar la vivienda en el mapa antes de crear el crédito.',
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    // VALIDAR LOS DEMÁS CAMPOS DEL FORMULARIO
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final cedula = _cedulaController.text.trim();

      final docRef = FirebaseFirestore.instance.collection('clientes').doc();

      await docRef.set({
        'uid': docRef.id,
        'cedula': cedula,
        'correoElectronico': _correoController.text.trim(),
        'direccionTrabajo': _direccionTrabajoController.text.trim(),
        'direccionVivienda': _direccionViviendaController.text.trim(),
        'nombreCompleto': _nombreCompletoController.text.trim(),
        'numeroCelular': _numeroCelularController.text.trim(),
        'referencia': _referenciaController.text.trim(),
        'barrio': _barrioController.text.trim(),
        'latitud': _latitud,
        'longitud': _longitud,
        'ubicacionVerificada': _ubicacionVerificada,
      });

      // LIMPIAR LOS CAMPOS DE UBICACIÓN
      _barrioController.clear();

      _latitud = null;
      _longitud = null;
      _ubicacionVerificada = false;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Cliente creado exitosamente'),
            ],
          ),
        ),
      );

      _formKey.currentState!.reset();
      _cedulaController.clear();
      _correoController.clear();
      _direccionTrabajoController.clear();
      _direccionViviendaController.clear();
      _nombreCompletoController.clear();
      _numeroCelularController.clear();
      _referenciaController.clear();

      // NAVEGAR A CREAR CRÉDITO
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CrearCreditoAdmin(clienteId: docRef.id),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text('Error al crear cliente: $e')),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEFE9F4),
      appBar: AppBar(
        backgroundColor: Color(0xFF00C290),
        title: Text('Crear Cliente'),
        centerTitle: true,
        leading: BackButton(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _campoTexto('Nombre Completo', _nombreCompletoController),
              _campoTexto(
                'Cédula',
                _cedulaController,
                tipo: TextInputType.number,
              ),
              _campoTexto(
                'Teléfono',
                _numeroCelularController,
                tipo: TextInputType.number,
              ),

              _campoTexto(
                'Correo Electrónico',
                _correoController,
                tipo: TextInputType.emailAddress,
              ),
              _campoTexto('Dirección de Trabajo', _direccionTrabajoController),
              _campoTexto(
                'Dirección de Vivienda',
                _direccionViviendaController,
              ),
              _campoTexto('Barrio', _barrioController),
              _campoTexto('Referencia', _referenciaController),
              const SizedBox(height: 12),

              ElevatedButton.icon(
                onPressed: _abrirSelectorUbicacion,
                icon: const Icon(Icons.map),
                label: const Text('Ubicar vivienda en el mapa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C290),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _ubicacionVerificada
                    ? 'Ubicación seleccionada correctamente'
                    : 'Ubicación pendiente de confirmar',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _ubicacionVerificada ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _crearCliente,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF00C290),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: Text(
                    'Crear Cliente',
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
    final bool esNombre = label == 'Nombre Completo';
    final bool esCedula = label == 'Cédula';
    final bool esTelefono = label == 'Teléfono';
    final bool esDireccion =
        label == 'Dirección de Trabajo' || label == 'Dirección de Vivienda';
    final bool esReferencia = label == 'Referencia';
    final bool esCorreo = label == 'Correo Electrónico';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,

        keyboardType:
            esNombre || esReferencia
                ? TextInputType.name
                : esCedula || esTelefono
                ? TextInputType.number
                : esCorreo
                ? TextInputType.emailAddress
                : tipo,

        textCapitalization:
            esNombre || esReferencia || esDireccion
                ? TextCapitalization.words
                : TextCapitalization.none,

        inputFormatters: [
          if (esNombre || esReferencia)
            FilteringTextInputFormatter.allow(
              RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]'),
            ),

          if (esCedula || esTelefono) FilteringTextInputFormatter.digitsOnly,

          if (esTelefono) LengthLimitingTextInputFormatter(10),

          if (esDireccion)
            FilteringTextInputFormatter.allow(
              RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ0-9\s#./,\-]'),
            ),
        ],

        maxLength: esTelefono ? 10 : null,

        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          counterText: esTelefono ? '' : null,
        ),

        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Este campo es obligatorio';
          }

          final texto = value.trim();

          // VALIDACIÓN DEL NOMBRE COMPLETO
          if (esNombre) {
            if (texto.length < 3) {
              return 'Ingresa un nombre válido';
            }

            if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$').hasMatch(texto)) {
              return 'Solo se permiten letras y espacios';
            }
          }

          // VALIDACIÓN DE LA REFERENCIA
          if (esReferencia) {
            if (!RegExp(
              r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ]+(?:\s+[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ]+)+$',
            ).hasMatch(texto)) {
              return 'Ingresa nombre y apellido de la referencia';
            }
          }

          // VALIDACIÓN DE CÉDULA
          if (esCedula) {
            if (!RegExp(r'^[0-9]+$').hasMatch(texto)) {
              return 'La cédula solo debe contener números';
            }
          }

          // VALIDACIÓN DE TELÉFONO
          if (esTelefono) {
            if (!RegExp(r'^[0-9]{10}$').hasMatch(texto)) {
              return 'El teléfono debe tener exactamente 10 dígitos';
            }
          }

          // VALIDACIÓN DE CORREO
          if (esCorreo) {
            if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(texto)) {
              return 'Ingresa un correo electrónico válido';
            }
          }

          // VALIDACIÓN DE DIRECCIONES
          if (esDireccion) {
            final tieneNumero = RegExp(r'[0-9]').hasMatch(texto);

            final tieneLetra = RegExp(
              r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ]',
            ).hasMatch(texto);

            if (texto.length < 7 || !tieneNumero || !tieneLetra) {
              return 'Ingresa una dirección completa con letras y números';
            }
          }

          return null;
        },
      ),
    );
  }
}
