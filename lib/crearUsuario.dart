import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
<<<<<<< HEAD
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
=======
>>>>>>> origin/main

class CrearUsuario extends StatefulWidget {
  final String adminId;

  const CrearUsuario({Key? key, required this.adminId}) : super(key: key);

  @override
<<<<<<< HEAD
  State<CrearUsuario> createState() => _CrearUsuarioState();
=======
  _CrearUsuarioState createState() => _CrearUsuarioState();
>>>>>>> origin/main
}

class _CrearUsuarioState extends State<CrearUsuario> {
  final _formKey = GlobalKey<FormState>();
<<<<<<< HEAD

  final TextEditingController _nombreController = TextEditingController();

  final TextEditingController _cedulaController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _contrasenaController = TextEditingController();

  final TextEditingController _confirmarContrasenaController =
      TextEditingController();

  String _rolSeleccionado = 'usuario';
  bool _cargando = false;

  Future<void> _crearUsuario() async {
    if (_cargando) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
    });

    FirebaseAuth? authSecundario;
    UserCredential? credencial;
    DocumentReference<Map<String, dynamic>>? docRef;

    try {
      // Crear o recuperar la aplicación secundaria.
      // Así conservamos la sesión del administrador.
      final appsExistentes =
          Firebase.apps.where((app) => app.name == 'RegistroUsuarios').toList();

      final FirebaseApp appSecundaria;

      if (appsExistentes.isNotEmpty) {
        appSecundaria = appsExistentes.first;
      } else {
        appSecundaria = await Firebase.initializeApp(
          name: 'RegistroUsuarios',
          options: Firebase.app().options,
        );
      }

      authSecundario = FirebaseAuth.instanceFor(app: appSecundaria);

      // 1. Crear la cuenta en Firebase Authentication.
      credencial = await authSecundario.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _contrasenaController.text,
      );

      final userId = credencial.user!.uid;

      // 2. Crear el perfil del usuario en Firestore.
      // Conservamos el ID automático del documento.
      docRef = FirebaseFirestore.instance.collection('usuarios').doc();

      await docRef.set({
        'userId': userId,
        'nombre': _nombreController.text.trim(),
        'cedula': _cedulaController.text.trim(),
        'email': _emailController.text.trim(),
        'rol': _rolSeleccionado,
      });

      await authSecundario.signOut();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Usuario creado exitosamente'),
        ),
      );

      _formKey.currentState!.reset();
      _nombreController.clear();
      _cedulaController.clear();
      _emailController.clear();
      _contrasenaController.clear();
      _confirmarContrasenaController.clear();

      setState(() {
        _rolSeleccionado = 'usuario';
      });
    } catch (e) {
      // Si se creó la cuenta de Authentication pero
      // falló el registro del perfil, intentamos revertir
      // ambos cambios para evitar cuentas incompletas.
      if (docRef != null && credencial?.user != null) {
        try {
          await docRef.delete();
        } catch (_) {}
      }

      if (credencial?.user != null) {
        try {
          await credencial!.user!.delete();
        } catch (_) {}
      }

      if (!mounted) return;

      String mensaje = 'No fue posible crear el usuario.';

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            mensaje = 'Este correo ya está registrado.';
            break;
          case 'invalid-email':
            mensaje = 'El correo electrónico no es válido.';
            break;
          case 'weak-password':
            mensaje = 'La contraseña es demasiado débil.';
            break;
          case 'operation-not-allowed':
            mensaje =
                'Activa el método Email/Password en Firebase Authentication.';
            break;
          case 'network-request-failed':
            mensaje = 'Error de conexión. Revisa tu conexión a internet.';
            break;
          default:
            mensaje = 'Error de autenticación: ${e.code}';
        }
      } else if (e is FirebaseException) {
        mensaje = 'Error de Firebase: ${e.code}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text(mensaje)),
      );
    } finally {
      try {
        await authSecundario?.signOut();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _cargando = false;
        });
=======
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
>>>>>>> origin/main
      }
    }
  }

  @override
<<<<<<< HEAD
  void dispose() {
    _nombreController.dispose();
    _cedulaController.dispose();
    _emailController.dispose();
    _contrasenaController.dispose();
    _confirmarContrasenaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFE9F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C290),
        title: const Text('Crear Usuario'),
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
=======
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEFE9F4),
      appBar: AppBar(
        backgroundColor: Color(0xFF00C290),
        title: Text('Crear Usuario'),
        centerTitle: true,
        leading: BackButton(color: Colors.white),
>>>>>>> origin/main
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _campoTexto('Nombre Completo', _nombreController),
              _campoTexto(
<<<<<<< HEAD
                'Correo electrónico',
                _emailController,
                tipo: TextInputType.emailAddress,
              ),
              _campoTexto(
=======
>>>>>>> origin/main
                'Cédula',
                _cedulaController,
                tipo: TextInputType.number,
              ),
              _campoTexto(
<<<<<<< HEAD
=======
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
>>>>>>> origin/main
                'Contraseña',
                _contrasenaController,
                esPassword: true,
              ),
              _campoTexto(
                'Confirmar Contraseña',
                _confirmarContrasenaController,
                esPassword: true,
<<<<<<< HEAD
                confirmarContrasena: true,
              ),
              const SizedBox(height: 10),

=======
              ),
              SizedBox(height: 10),
>>>>>>> origin/main
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
<<<<<<< HEAD
                items: const [
                  DropdownMenuItem(value: 'usuario', child: Text('Usuario')),
                  DropdownMenuItem(
                    value: 'administrador',
                    child: Text('Administrador'),
                  ),
                ],
                onChanged:
                    _cargando
                        ? null
                        : (value) {
                          if (value != null) {
                            setState(() {
                              _rolSeleccionado = value;
                            });
                          }
                        },
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _cargando ? null : _crearUsuario,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C290),
                  disabledBackgroundColor: const Color(0xFF9ADBC9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child:
                    _cargando
                        ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Text(
                          'Crear Usuario',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
=======
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
>>>>>>> origin/main
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
<<<<<<< HEAD
    bool confirmarContrasena = false,
=======
>>>>>>> origin/main
    TextInputType tipo = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: esPassword,
        keyboardType: tipo,
<<<<<<< HEAD
        enabled: !_cargando,
=======
>>>>>>> origin/main
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (value) {
<<<<<<< HEAD
          if (value == null || value.trim().isEmpty) {
            return 'Este campo es obligatorio.';
          }

          if (label == 'Correo electrónico' &&
              !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
            return 'Ingresa un correo válido.';
          }

          if (label == 'Nombre Completo' && value.trim().length < 3) {
            return 'Ingresa un nombre válido.';
          }

          if (label == 'Contraseña' && value.length < 6) {
            return 'La contraseña debe tener al menos 6 caracteres.';
          }

          if (confirmarContrasena && value != _contrasenaController.text) {
            return 'Las contraseñas no coinciden.';
          }

=======
          if (value == null || value.isEmpty) {
            return 'Este campo es obligatorio';
          }
          if (label == 'Confirmar Contraseña' &&
              value != _contrasenaController.text) {
            return 'Las contraseñas no coinciden';
          }
>>>>>>> origin/main
          return null;
        },
      ),
    );
  }
}
