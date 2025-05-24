import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hola_mundo/globals.dart';

class CobrosUsuario extends StatelessWidget {
  final String cedulaCobrador;

  CobrosUsuario({required this.cedulaCobrador});

  final CollectionReference creditosRef = FirebaseFirestore.instance.collection(
    'creditos',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFFFEF), // Color de fondo suave
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C290), // Color verde similar
        title: Text(
          'Cobros de $cedulaCobrador',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            creditosRef
                .where('cedulaCobradorAsignado', isEqualTo: cedulaCobrador)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final creditos = snapshot.data!.docs;

          if (creditos.isEmpty) {
            return const Center(
              child: Text(
                'No tienes cobros asignados',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }

          return ListView.builder(
            itemCount: creditos.length,
            itemBuilder: (context, index) {
              final credito = creditos[index];
              return Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  leading: const Icon(Icons.attach_money, color: Colors.green),
                  title: Text(
                    'Artículo: ${credito['articulo']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    'Deuda: \$${credito['deuda']} - Estado: ${credito['estado']}',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
