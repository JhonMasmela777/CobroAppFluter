import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:cobro_app_flutter/menuAdmin.dart';
import 'package:cobro_app_flutter/menuUsuario.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _cargando = false;

  Future<void> login() async {
    if (_cargando) return;

    final emailIngresado = emailController.text.trim();
    final passwordIngresada = passwordController.text;

    if (emailIngresado.isEmpty || passwordIngresada.isEmpty) {
      showError('Ingresa el correo y la contraseña.');
      return;
    }

    setState(() {
      _cargando = true;
    });

    try {
      // Verificar el proyecto Firebase utilizado por la aplicación.
      debugPrint('PROYECTO FIREBASE: ${_firestore.app.options.projectId}');

      // PASO 1: Autenticar al usuario.
      debugPrint('LOGIN 1: Intentando autenticar...');

      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: emailIngresado,
        password: passwordIngresada,
      );

      final User? usuarioAuth = credential.user;

      if (usuarioAuth == null || usuarioAuth.email == null) {
        await _auth.signOut();

        if (mounted) {
          showError('No se pudo identificar al usuario.');
        }
        return;
      }

      final String uidAuth = usuarioAuth.uid;
      final String emailAuth = usuarioAuth.email!.trim();

      debugPrint('LOGIN 2: Autenticación exitosa.');
      debugPrint('UID AUTH: [$uidAuth]');
      debugPrint('EMAIL AUTH: [$emailAuth]');

      // PASO 2: Buscar el perfil por UID.
      debugPrint('LOGIN 3: Buscando perfil por UID...');

      QuerySnapshot<Map<String, dynamic>> snapshot =
          await _firestore
              .collection('usuarios')
              .where('uid', isEqualTo: uidAuth)
              .limit(1)
              .get();

      debugPrint('DOCUMENTOS POR UID: ${snapshot.docs.length}');

      // PASO 3: Si no aparece, buscar por el campo "correo".
      if (snapshot.docs.isEmpty) {
        debugPrint('Intentando búsqueda por correo...');

        snapshot =
            await _firestore
                .collection('usuarios')
                .where('correo', isEqualTo: emailAuth)
                .limit(1)
                .get();

        debugPrint('DOCUMENTOS POR CORREO: ${snapshot.docs.length}');
      }

      // PASO 4: Como alternativa, buscar por el campo "email".
      if (snapshot.docs.isEmpty) {
        debugPrint('Intentando búsqueda por email...');

        snapshot =
            await _firestore
                .collection('usuarios')
                .where('email', isEqualTo: emailAuth)
                .limit(1)
                .get();

        debugPrint('DOCUMENTOS POR EMAIL: ${snapshot.docs.length}');
      }

      // PASO 5: Verificar que el perfil exista.
      if (snapshot.docs.isEmpty) {
        debugPrint('No se encontró el perfil en la colección usuarios.');

        await _auth.signOut();

        if (mounted) {
          showError(
            'No se encontró el perfil en Firestore. '
            'Revisa el proyecto Firebase y los datos del usuario.',
          );
        }
        return;
      }

      // PASO 6: Leer el perfil y el rol.
      // PASO 6: Leer el perfil y el rol.
      final userDoc = snapshot.docs.first;
      final userData = userDoc.data();

      // UID registrado dentro del perfil de Firestore.
      final String uidPerfil =
          (userData['uid'] ?? userData['userId'] ?? '').toString().trim();

      // Verificar que el perfil corresponde a la cuenta autenticada.
      debugPrint('ID DOCUMENTO FIRESTORE: ${userDoc.id}');
      debugPrint('UID AUTHENTICATION: $uidAuth');
      debugPrint('UID DEL PERFIL: $uidPerfil');

      if (uidPerfil.isEmpty) {
        throw Exception('El perfil no tiene registrado el UID del usuario.');
      }

      if (uidPerfil != uidAuth) {
        throw Exception(
          'El UID del perfil no coincide con Firebase Authentication.',
        );
      }

      // Este es el identificador que recibirán las demás pantallas.
      final String userId = uidAuth;

      // Obtener el rol.
      final String rol =
          (userData['rol'] ?? '').toString().trim().toLowerCase();

      debugPrint('USER ID ENVIADO: $userId');
      debugPrint('ROL EN FIRESTORE: $rol');

      debugPrint('ID DEL DOCUMENTO: ${userDoc.id}');
      debugPrint('UID DE AUTH: $uidAuth');
      debugPrint('UID DEL PERFIL: ${userData['uid']}');
      debugPrint('USERID DEL PERFIL: ${userData['userId']}');
      debugPrint('ROL: $rol');

      if (!mounted) return;

      // PASO 7: Redirigir según el rol.
      if (rol == 'administrador') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MenuAdmin(userId: userId)),
        );
      } else if (rol == 'usuario') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MenuUsuario(userId: userId)),
        );
      } else {
        await _auth.signOut();

        if (mounted) {
          showError('El perfil tiene un rol inválido: "$rol".');
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('ERROR AUTH: ${e.code}');
      debugPrint('DETALLE AUTH: ${e.message}');

      if (!mounted) return;

      switch (e.code) {
        case 'invalid-credential':
        case 'invalid-login-credentials':
        case 'wrong-password':
        case 'user-not-found':
          showError('El correo o la contraseña son incorrectos.');
          break;

        case 'invalid-email':
          showError('El correo electrónico no es válido.');
          break;

        case 'operation-not-allowed':
          showError('Habilita Email/Password en Firebase Authentication.');
          break;

        case 'too-many-requests':
          showError('Demasiados intentos. Intenta nuevamente más tarde.');
          break;

        case 'network-request-failed':
          showError('Revisa tu conexión a internet.');
          break;

        case 'user-disabled':
          showError('Esta cuenta está deshabilitada.');
          break;

        default:
          showError('Error de autenticación: ${e.code}');
      }
    } on FirebaseException catch (e) {
      debugPrint('ERROR FIREBASE: ${e.code}');
      debugPrint('DETALLE FIREBASE: ${e.message}');

      if (mounted) {
        showError('Error consultando Firebase: ${e.code}');
      }
    } catch (e) {
      debugPrint('ERROR LOGIN: $e');

      if (mounted) {
        showError('Error inesperado al iniciar sesión.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  void showError(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8FFF7),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.show_chart, color: Colors.teal, size: 80),

              const SizedBox(height: 30),

              const Text(
                'Cobra Tech',
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Inicia sesión para continuar',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),

              const SizedBox(height: 40),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onSubmitted: (_) {
                  if (!_cargando) login();
                },
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _cargando ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    disabledBackgroundColor: Colors.teal.shade200,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child:
                      _cargando
                          ? const SizedBox(
                            width: 23,
                            height: 23,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                          : const Text(
                            'Iniciar sesión',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
