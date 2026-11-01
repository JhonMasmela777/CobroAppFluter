import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:cobro_app_flutter/pagoUsuario.dart';

class RutaCobroUsuario extends StatefulWidget {
  final String userId;

  const RutaCobroUsuario({super.key, required this.userId});

  @override
  State<RutaCobroUsuario> createState() => _RutaCobroUsuarioState();
}

class _RutaCobroUsuarioState extends State<RutaCobroUsuario> {
  LatLng? _origen;
  List<_Parada> _paradas = [];
  List<LatLng> _puntosRuta = [];

  bool _cargando = false;
  String? _mensaje;

  Future<LatLng> _obtenerUbicacionActual() async {
    final servicioActivo = await Geolocator.isLocationServiceEnabled();

    if (!servicioActivo) {
      throw Exception('Activa el GPS de tu celular para generar la ruta.');
    }

    LocationPermission permiso = await Geolocator.checkPermission();

    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }

    if (permiso == LocationPermission.denied) {
      throw Exception('No autorizaste el acceso a la ubicación.');
    }

    if (permiso == LocationPermission.deniedForever) {
      throw Exception(
        'El permiso de ubicación está bloqueado. Actívalo desde los ajustes del celular.',
      );
    }

    final posicion = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    return LatLng(posicion.latitude, posicion.longitude);
  }

  Future<void> _generarRuta() async {
    if (!mounted) return;

    setState(() {
      _cargando = true;
      _mensaje = null;
      _paradas = [];
      _puntosRuta = [];
    });

    try {
      final origen = await _obtenerUbicacionActual();

      final ahora = DateTime.now();
      final inicioHoy = DateTime(ahora.year, ahora.month, ahora.day);
      final inicioManana = inicioHoy.add(const Duration(days: 1));

      // Identificar los clientes que ya recibieron un abono HOY
      // registrado por este cobrador.
      final Set<String> clientesConAbonoHoy = {};

      final abonosHoySnapshot =
          await FirebaseFirestore.instance
              .collection('abonos')
              .where(
                'fecha',
                isGreaterThanOrEqualTo: Timestamp.fromDate(inicioHoy),
              )
              .where('fecha', isLessThan: Timestamp.fromDate(inicioManana))
              .get();

      for (final abonoDoc in abonosHoySnapshot.docs) {
        final abono = abonoDoc.data();

        final cobradorAbono = abono['userId']?.toString() ?? '';
        final clienteAbono = abono['clienteId']?.toString() ?? '';

        if (cobradorAbono == widget.userId && clienteAbono.isNotEmpty) {
          clientesConAbonoHoy.add(clienteAbono);
        }
      }

      // Consultar exclusivamente los créditos asignados a este cobrador.
      final resultado =
          await FirebaseFirestore.instance
              .collection('creditos')
              .where('cedulaCobradorAsignado', isEqualTo: widget.userId)
              .get();

      // Agrupar las cuotas pendientes por cliente.
      final Map<String, List<_CuotaPendiente>> cuotasPorCliente = {};

      for (final creditoDoc in resultado.docs) {
        final credito = creditoDoc.data();

        final clienteId = credito['idCliente']?.toString() ?? '';

        if (clienteId.isEmpty) continue;

        // Si el cliente ya recibió un abono hoy, no aparece
        // en la ruta durante el resto del día.
        if (clientesConAbonoHoy.contains(clienteId)) continue;

        final estadoCredito = credito['estado']?.toString().toLowerCase() ?? '';

        final deudaCredito = (credito['deuda'] as num?)?.toDouble() ?? 0;

        if (estadoCredito == 'pagado' || deudaCredito <= 0) {
          continue;
        }

        // Consultar las cuotas del crédito asignado.
        final cuotasSnapshot =
            await FirebaseFirestore.instance
                .collection('cuotas')
                .where('idCredito', isEqualTo: creditoDoc.id)
                .get();

        for (final cuotaDoc in cuotasSnapshot.docs) {
          final cuota = cuotaDoc.data();

          final estadoCuota = cuota['estado']?.toString().toLowerCase() ?? '';

          // Solamente cuotas pendientes.
          if (estadoCuota != 'pendiente') continue;

          final valorCuota = (cuota['valorCuota'] as num?)?.toDouble() ?? 0;

          // Si no existe saldoPendiente, se toma valorCuota
          // como saldo inicial.
          final saldoPendiente =
              (cuota['saldoPendiente'] as num?)?.toDouble() ?? valorCuota;

          if (saldoPendiente <= 0) continue;

          final nuevaCuota = _CuotaPendiente(
            cuotaId: cuotaDoc.id,
            creditoId: creditoDoc.id,
            numeroCuota: (cuota['numeroCuota'] as num?)?.toInt() ?? 0,
            articulo: credito['articulo']?.toString() ?? 'Sin artículo',
            saldoPendiente: saldoPendiente,
            deudaCredito: deudaCredito,
          );

          cuotasPorCliente.putIfAbsent(clienteId, () => []);
          cuotasPorCliente[clienteId]!.add(nuevaCuota);
        }
      }

      if (cuotasPorCliente.isEmpty) {
        if (!mounted) return;

        setState(() {
          _origen = origen;
          _mensaje =
              'No tienes créditos asignados con cuotas pendientes para cobrar.';
        });
        return;
      }

      final List<_Parada> paradas = [];

      // Obtener los datos de cada cliente.
      for (final entrada in cuotasPorCliente.entries) {
        final clienteId = entrada.key;

        final clienteDoc =
            await FirebaseFirestore.instance
                .collection('clientes')
                .doc(clienteId)
                .get();

        if (!clienteDoc.exists) continue;

        final cliente = clienteDoc.data()!;

        final nombre =
            cliente['nombreCompleto']?.toString() ?? 'Cliente sin nombre';

        final direccion =
            cliente['direccionVivienda']?.toString() ?? 'Sin dirección';

        final latitud = cliente['latitud'];
        final longitud = cliente['longitud'];

        final cuotasCliente = entrada.value;

        final double deudaTotal = cuotasCliente.fold(
          0,
          (total, cuota) => total + cuota.saldoPendiente,
        );

        LatLng? ubicacion;

        if (latitud is num && longitud is num) {
          if (latitud >= -90 &&
              latitud <= 90 &&
              longitud >= -180 &&
              longitud <= 180 &&
              !(latitud == 0 && longitud == 0)) {
            ubicacion = LatLng(latitud.toDouble(), longitud.toDouble());
          }
        }

        paradas.add(
          _Parada(
            clienteId: clienteId,
            nombre: nombre,
            direccion: direccion,
            deudaTotal: deudaTotal,
            cuotas: cuotasCliente,
            ubicacion: ubicacion,
          ),
        );
      }

      final paradasConUbicacion =
          paradas.where((parada) => parada.ubicacion != null).toList();

      if (paradasConUbicacion.isEmpty) {
        if (!mounted) return;

        setState(() {
          _origen = origen;
          _paradas = paradas;
          _mensaje =
              'Los clientes tienen cuotas pendientes, pero ninguno tiene coordenadas válidas para mostrar en el mapa.';
        });
        return;
      }

      // Calcular el orden sugerido con OSRM.
      List<_Parada> paradasOrdenadas = paradasConUbicacion;
      List<LatLng> puntosRuta = [];

      try {
        final coordenadas = [
          '${origen.longitude},${origen.latitude}',
          ...paradasConUbicacion.map(
            (parada) =>
                '${parada.ubicacion!.longitude},${parada.ubicacion!.latitude}',
          ),
        ].join(';');

        final uri = Uri.parse(
          'https://router.project-osrm.org/trip/v1/driving/$coordenadas'
          '?roundtrip=false&source=first&destination=last&overview=full&geometries=geojson',
        );

        final respuesta = await http
            .get(uri)
            .timeout(const Duration(seconds: 20));

        if (respuesta.statusCode == 200) {
          final datos = jsonDecode(respuesta.body);

          if (datos['trips'] != null && (datos['trips'] as List).isNotEmpty) {
            final waypoints = datos['waypoints'] as List;

            final indices = List.generate(
              paradasConUbicacion.length,
              (index) => index,
            );

            indices.sort((a, b) {
              final ordenA = waypoints[a + 1]['waypoint_index'] as int;
              final ordenB = waypoints[b + 1]['waypoint_index'] as int;

              return ordenA.compareTo(ordenB);
            });

            paradasOrdenadas =
                indices.map((index) => paradasConUbicacion[index]).toList();

            final geometria =
                datos['trips'][0]['geometry']['coordinates'] as List;

            puntosRuta =
                geometria.map((coordenada) {
                  return LatLng(
                    (coordenada[1] as num).toDouble(),
                    (coordenada[0] as num).toDouble(),
                  );
                }).toList();
          }
        }
      } catch (e) {
        debugPrint('No se pudo calcular el recorrido: $e');
      }

      // Mantener los clientes que no tienen coordenadas.
      final paradasSinUbicacion =
          paradas.where((parada) => parada.ubicacion == null).toList();

      paradasOrdenadas = [...paradasOrdenadas, ...paradasSinUbicacion];

      if (!mounted) return;

      setState(() {
        _origen = origen;
        _paradas = paradasOrdenadas;
        _puntosRuta = puntosRuta;

        if (paradasSinUbicacion.isNotEmpty) {
          _mensaje =
              'Algunos clientes no tienen coordenadas válidas y aparecen al final de la lista.';
        } else if (puntosRuta.isEmpty) {
          _mensaje =
              'No fue posible calcular el recorrido por carretera. Se muestran los puntos disponibles.';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _mensaje = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  // Seleccionar una cuota específica del cliente.
  Future<void> _seleccionarCuota(_Parada parada) async {
    final cuotaSeleccionada = await showModalBottomSheet<_CuotaPendiente>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parada.nombre,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(parada.direccion),
                const SizedBox(height: 16),
                const Text(
                  'Selecciona la cuota que vas a cobrar:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: parada.cuotas.length,
                    itemBuilder: (context, index) {
                      final cuota = parada.cuotas[index];

                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFDFFFEF),
                            child: Icon(
                              Icons.receipt_long,
                              color: Color(0xFF00A878),
                            ),
                          ),
                          title: Text(
                            '${cuota.articulo} - Cuota ${cuota.numeroCuota}',
                          ),
                          subtitle: Text(
                            'Saldo pendiente: \$${cuota.saldoPendiente.toStringAsFixed(0)}',
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () {
                            Navigator.pop(context, cuota);
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );

    if (cuotaSeleccionada == null || !mounted) return;

    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder:
            (context) => PagoUsuario(
              creditoId: cuotaSeleccionada.creditoId,
              cuotaId: cuotaSeleccionada.cuotaId,
              deudaActual: cuotaSeleccionada.deudaCredito,
              saldoCuota: cuotaSeleccionada.saldoPendiente,
              clienteId: parada.clienteId,
              userId: widget.userId,
            ),
      ),
    );

    // Al registrar un abono, se vuelve a consultar la ruta.
    if (resultado == true && mounted) {
      await _generarRuta();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFFFEF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C290),
        foregroundColor: Colors.white,
        title: const Text('Mi ruta de cobro'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _cargando ? null : _generarRuta,
                icon: const Icon(Icons.route),
                label: Text(
                  _cargando ? 'Generando ruta...' : 'Generar ruta de cobro',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C290),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),

          if (_cargando)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: Color(0xFF00C290)),
            ),

          if (_mensaje != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _mensaje!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black87),
              ),
            ),

          if (_origen != null && _paradas.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Clientes pendientes: ${_paradas.length}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          if (_origen != null)
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: _origen!,
                        initialZoom: 14,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.cobro_app_flutter',
                        ),

                        if (_puntosRuta.length > 1)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _puntosRuta,
                                strokeWidth: 4,
                                color: const Color(0xFF00A878),
                              ),
                            ],
                          ),

                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _origen!,
                              width: 45,
                              height: 45,
                              child: const Icon(
                                Icons.my_location,
                                color: Colors.blue,
                                size: 35,
                              ),
                            ),

                            ..._paradas
                                .where((parada) => parada.ubicacion != null)
                                .toList()
                                .asMap()
                                .entries
                                .map((entrada) {
                                  return Marker(
                                    point: entrada.value.ubicacion!,
                                    width: 45,
                                    height: 45,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF00C290),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${entrada.key + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    flex: 2,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _paradas.length,
                      itemBuilder: (context, index) {
                        final parada = _paradas[index];

                        return Card(
                          color: Colors.white,
                          child: ListTile(
                            onTap: () => _seleccionarCuota(parada),
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFDFFFEF),
                              child: Text(
                                parada.ubicacion == null ? '-' : '${index + 1}',
                                style: const TextStyle(
                                  color: Color(0xFF008F69),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              parada.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${parada.direccion}\n'
                              'Cuotas para cobrar: ${parada.cuotas.length}\n'
                              'Total de cuotas pendientes: \$${parada.deudaTotal.toStringAsFixed(0)}',
                            ),
                            isThreeLine: true,
                            trailing: const Icon(
                              Icons.payments_outlined,
                              color: Color(0xFF00A878),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CuotaPendiente {
  final String cuotaId;
  final String creditoId;
  final int numeroCuota;
  final String articulo;
  final double saldoPendiente;
  final double deudaCredito;

  _CuotaPendiente({
    required this.cuotaId,
    required this.creditoId,
    required this.numeroCuota,
    required this.articulo,
    required this.saldoPendiente,
    required this.deudaCredito,
  });
}

class _Parada {
  final String clienteId;
  final String nombre;
  final String direccion;
  final double deudaTotal;
  final List<_CuotaPendiente> cuotas;
  final LatLng? ubicacion;

  _Parada({
    required this.clienteId,
    required this.nombre,
    required this.direccion,
    required this.deudaTotal,
    required this.cuotas,
    required this.ubicacion,
  });
}
