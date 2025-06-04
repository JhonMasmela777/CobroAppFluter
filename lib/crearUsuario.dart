import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CrearUsuario extends StatefulWidget {
  final String adminId;

  const CrearUsuario({Key? key, required this.adminId}) : super(key: key);

  @override
  _CrearUsuarioState createState() => _CrearUsuarioState();
}

class _CrearUsuarioState extends State<CrearUsuario> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();
  final TextEditingController _confirmarContrasenaController =
      TextEditingController();
  String _rolSeleccionado = 'usuario';

  Future<void> _crearUsuario() async {
    if (_formKey.currentState!.validate()) {
      try {
        final docRef = FirebaseFirestore.instance.collection('usuarios').doc();

        await docRef.set({
          'uid': docRef.id,
          'nombre': _nombreController.text.trim(),
          'cedula': _cedulaController.text.trim(),
          'telefono': _telefonoController.text.trim(),
          'email': _emailController.text.trim(),
          'contrasena': _contrasenaController.text.trim(),
          'rol': _rolSeleccionado,
          'creadoPor': widget.adminId, // Guardar quién lo creó
        });

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
        _nombreController.clear();
        _cedulaController.clear();
        _telefonoController.clear();
        _emailController.clear();
        _contrasenaController.clear();
        _confirmarContrasenaController.clear();
        setState(() {
          _rolSeleccionado = 'usuario';
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text('Error al crear Usuario: $e')),
              ],
            ),
          ),
        );
        ;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEFE9F4),
      appBar: AppBar(
        backgroundColor: Color(0xFF00C290),
        title: Text('Crear Usuario'),
        centerTitle: true,
        leading: BackButton(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _campoTexto('Nombre Completo', _nombreController),
              _campoTexto(
                'Cédula',
                _cedulaController,
                tipo: TextInputType.number,
              ),
              _campoTexto(
                'Teléfono',
                _telefonoController,
                tipo: TextInputType.number,
              ),

              _campoTexto(
                'Email',
                _emailController,
                tipo: TextInputType.emailAddress,
              ),
              _campoTexto(
                'Contraseña',
                _contrasenaController,
                esPassword: true,
              ),
              _campoTexto(
                'Confirmar Contraseña',
                _confirmarContrasenaController,
                esPassword: true,
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: 'Rol',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                value: _rolSeleccionado,
                onChanged: (value) {
                  setState(() {
                    _rolSeleccionado = value!;
                  });
                },
                items:
                    ['usuario', 'administrador']
                        .map(
                          (rol) =>
                              DropdownMenuItem(value: rol, child: Text(rol)),
                        )
                        .toList(),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _crearUsuario,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF00C290),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
                child: Text(
                  'Crear',
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
    bool esPassword = false,
    TextInputType tipo = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: esPassword,
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
          if (label == 'Confirmar Contraseña' &&
              value != _contrasenaController.text) {
            return 'Las contraseñas no coinciden';
          }
          return null;
        },
      ),
    );
  }
}
