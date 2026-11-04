import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class PerfilUsuario extends StatefulWidget {
  final String userId;

  const PerfilUsuario({super.key, required this.userId});

  @override
  State<PerfilUsuario> createState() => _PerfilUsuarioState();
}

class _PerfilUsuarioState extends State<PerfilUsuario> {
  late Future<Map<String, dynamic>?> perfilFuture;

  bool _subiendoFoto = false;

  @override
  void initState() {
    super.initState();
    perfilFuture = obtenerPerfil();
  }

  Future<DocumentReference<Map<String, dynamic>>?>
  _obtenerReferenciaUsuario() async {
    final usuariosRef = FirebaseFirestore.instance.collection('usuarios');

    // Primera búsqueda: ID del documento.
    final documento = await usuariosRef.doc(widget.userId).get();

    if (documento.exists) {
      return documento.reference;
    }

    // Segunda búsqueda: campo uid.
    final resultadoUid =
        await usuariosRef.where('uid', isEqualTo: widget.userId).limit(1).get();

    if (resultadoUid.docs.isNotEmpty) {
      return resultadoUid.docs.first.reference;
    }

    // Tercera búsqueda: campo userId.
    final resultadoUserId =
        await usuariosRef
            .where('userId', isEqualTo: widget.userId)
            .limit(1)
            .get();

    if (resultadoUserId.docs.isNotEmpty) {
      return resultadoUserId.docs.first.reference;
    }

    return null;
  }

  Future<Map<String, dynamic>?> obtenerPerfil() async {
    final referencia = await _obtenerReferenciaUsuario();

    if (referencia == null) {
      return null;
    }

    final documento = await referencia.get();

    return documento.data();
  }

  String obtenerValor(Map<String, dynamic> usuario, List<String> campos) {
    for (final campo in campos) {
      final valor = usuario[campo];

      if (valor != null && valor.toString().trim().isNotEmpty) {
        return valor.toString().trim();
      }
    }

    return 'No registrado';
  }

  Future<void> _seleccionarFoto(ImageSource origen) async {
    try {
      final ImagePicker picker = ImagePicker();

      final XFile? imagen = await picker.pickImage(
        source: origen,
        imageQuality: 75,
        maxWidth: 1000,
      );

      if (imagen == null) return;

      setState(() {
        _subiendoFoto = true;
      });

      final referenciaUsuario = await _obtenerReferenciaUsuario();

      if (referenciaUsuario == null) {
        throw Exception('No se encontró el usuario en Firestore.');
      }

      final referenciaFoto = FirebaseStorage.instance
          .ref()
          .child('fotos_perfil')
          .child('${widget.userId}.jpg');

      await referenciaFoto.putFile(File(imagen.path));

      final urlFoto = await referenciaFoto.getDownloadURL();

      await referenciaUsuario.update({'fotoUrl': urlFoto});

      if (!mounted) return;

      setState(() {
        perfilFuture = obtenerPerfil();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto de perfil actualizada correctamente'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar la foto: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _subiendoFoto = false;
        });
      }
    }
  }

  void _mostrarOpcionesFoto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Foto de perfil',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),

                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: Color(0xFF00C290),
                  ),
                  title: const Text('Tomar fotografía'),
                  onTap: () {
                    Navigator.pop(context);
                    _seleccionarFoto(ImageSource.camera);
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: Color(0xFF00C290),
                  ),
                  title: const Text('Seleccionar de galería'),
                  onTap: () {
                    Navigator.pop(context);
                    _seleccionarFoto(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0FFF1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C290),
        leading: const BackButton(color: Colors.white),
        title: const Text('Mi Perfil'),
        centerTitle: true,
        elevation: 2,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: perfilFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error al consultar el perfil'));
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Usuario no encontrado'));
          }

          final usuario = snapshot.data!;

          final nombre = obtenerValor(usuario, ['nombreCompleto', 'nombre']);

          final fotoUrl = obtenerValor(usuario, ['fotoUrl']);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // Foto de perfil y acceso a la galería.
                    GestureDetector(
                      onTap: _subiendoFoto ? null : _mostrarOpcionesFoto,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 65,
                            backgroundColor: const Color(0xFF00C28B),
                            backgroundImage:
                                fotoUrl != 'No registrado'
                                    ? NetworkImage(fotoUrl)
                                    : null,
                            child:
                                fotoUrl == 'No registrado'
                                    ? const Icon(
                                      Icons.person,
                                      size: 75,
                                      color: Colors.white,
                                    )
                                    : null,
                          ),

                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(9),
                              decoration: const BoxDecoration(
                                color: Color(0xFF007A52),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),

                          if (_subiendoFoto)
                            const Positioned.fill(
                              child: CircleAvatar(
                                backgroundColor: Colors.black45,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Toca la foto para cambiarla',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      nombre,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF007A52),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Información centrada.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          InfoRow(
                            icon: Icons.badge,
                            label: 'Cédula',
                            value: obtenerValor(usuario, ['cedula']),
                          ),
                          const Divider(),

                          InfoRow(
                            icon: Icons.email,
                            label: 'Email',
                            value: obtenerValor(usuario, [
                              'email',
                              'correo',
                              'correoElectronico',
                            ]),
                          ),
                          const Divider(),

                          InfoRow(
                            icon: Icons.phone,
                            label: 'Teléfono',
                            value: obtenerValor(usuario, ['telefono']),
                          ),
                          const Divider(),

                          InfoRow(
                            icon: Icons.security,
                            label: 'Rol',
                            value: obtenerValor(usuario, ['rol']),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF00C28B), size: 23),
              const SizedBox(width: 9),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF007A52),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
