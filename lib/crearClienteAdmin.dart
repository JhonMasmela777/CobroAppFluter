import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cobro_app_flutter/crearCreditoAdmin.dart';
import 'package:latlong2/latlong.dart';
import 'package:cobro_app_flutter/seleccionarUbicacion.dart';

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
    if (_formKey.currentState!.validate()) {
      try {
        final cedula = _cedulaController.text.trim();

        // Ya no se busca si existe por cedula
        // El id se genera automáticamente con doc()

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
        // Limpiar los campos de ubicación
        _barrioController.clear();

        _latitud = null;
        _longitud = null;
        _ubicacionVerificada = false;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text('Usuario creado exitosamente'),
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

        // Ahora pasamos docRef.id (uid) en vez de cedula
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
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text('Error al crear usuario: $e')),
              ],
            ),
          ),
        );
      }
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
                    'Crear Crédito',
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
}
