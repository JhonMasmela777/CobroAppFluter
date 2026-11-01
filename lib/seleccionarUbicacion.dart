import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class SeleccionarUbicacion extends StatefulWidget {
  const SeleccionarUbicacion({super.key});

  @override
  State<SeleccionarUbicacion> createState() => _SeleccionarUbicacionState();
}

class _SeleccionarUbicacionState extends State<SeleccionarUbicacion> {
  final TextEditingController _busquedaController = TextEditingController();

  final MapController _mapController = MapController();

  // Centro aproximado de Tuluá para iniciar la visualización.
  // Este punto NO se guarda como ubicación del cliente.
  final LatLng _centroInicial = LatLng(4.08, -76.20);

  LatLng? _puntoSeleccionado;

  List<Map<String, dynamic>> _resultados = [];

  bool _buscando = false;
  String? _mensajeError;

  // Buscar una dirección utilizando Nominatim.
  Future<void> _buscarDireccion() async {
    final consulta = _busquedaController.text.trim();

    if (consulta.isEmpty) {
      setState(() {
        _mensajeError = 'Escribe una dirección para buscar.';
        _resultados = [];
      });
      return;
    }

    setState(() {
      _buscando = true;
      _mensajeError = null;
      _resultados = [];
    });

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': '$consulta, Tuluá, Valle del Cauca, Colombia',
        'format': 'jsonv2',
        'limit': '5',
        'countrycodes': 'co',
        'addressdetails': '1',
      });

      final respuesta = await http.get(
        uri,
        headers: {
          'User-Agent':
              'Cobramzas/1.0 (Flutter app; package cobro_app_flutter)',
          'Accept-Language': 'es',
        },
      );

      if (respuesta.statusCode != 200) {
        throw Exception('No fue posible consultar el servicio de direcciones.');
      }

      final List<dynamic> datos = jsonDecode(respuesta.body) as List<dynamic>;

      final resultadosValidos =
          datos
              .where(
                (elemento) =>
                    elemento['lat'] != null && elemento['lon'] != null,
              )
              .map((elemento) => elemento as Map<String, dynamic>)
              .toList();

      if (!mounted) return;

      setState(() {
        _resultados = resultadosValidos;

        if (_resultados.isEmpty) {
          _mensajeError =
              'No encontramos esa dirección. Puedes ubicarla manualmente en el mapa.';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _mensajeError =
            'Error al buscar la dirección. Intenta nuevamente o selecciona el punto en el mapa.';
      });
    } finally {
      if (mounted) {
        setState(() => _buscando = false);
      }
    }
  }

  // Seleccionar uno de los resultados encontrados.
  void _seleccionarResultado(Map<String, dynamic> resultado) {
    final latitud = double.tryParse(resultado['lat'].toString());
    final longitud = double.tryParse(resultado['lon'].toString());

    if (latitud == null || longitud == null) return;

    final punto = LatLng(latitud, longitud);

    setState(() {
      _puntoSeleccionado = punto;
      _resultados = [];
      _mensajeError = null;
    });

    _mapController.move(punto, 17);
  }

  // Seleccionar manualmente tocando el mapa.
  void _seleccionarPunto(LatLng punto) {
    setState(() {
      _puntoSeleccionado = punto;
      _mensajeError = null;
      _resultados = [];
    });
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C290),
        title: const Text(
          'Ubicación de vivienda',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _busquedaController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _buscarDireccion(),
                        decoration: InputDecoration(
                          hintText: 'Buscar dirección o barrio',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _buscando ? null : _buscarDireccion,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF00C290),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(14),
                      ),
                      icon: const Icon(Icons.search),
                    ),
                  ],
                ),

                if (_buscando)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  ),

                if (_mensajeError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      _mensajeError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),

                if (_resultados.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 170),
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _resultados.length,
                      itemBuilder: (context, index) {
                        final resultado = _resultados[index];

                        return ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.location_on,
                            color: Color(0xFF00C290),
                          ),
                          title: Text(
                            resultado['display_name']?.toString() ??
                                'Ubicación encontrada',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _seleccionarResultado(resultado),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Busca una dirección o toca el mapa para colocar el marcador en la vivienda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _centroInicial,
                initialZoom: 13,
                onTap: (tapPosition, punto) {
                  _seleccionarPunto(punto);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'cobro_app_flutter',
                ),

                if (_puntoSeleccionado != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _puntoSeleccionado!,
                        width: 50,
                        height: 55,
                        child: const Icon(
                          Icons.location_pin,
                          size: 48,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),

                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('© OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            color: Colors.white,
            child: Column(
              children: [
                if (_puntoSeleccionado == null)
                  const Text(
                    'Todavía no has seleccionado una ubicación.',
                    textAlign: TextAlign.center,
                  )
                else
                  Text(
                    'Ubicación seleccionada\n'
                    'Latitud: ${_puntoSeleccionado!.latitude.toStringAsFixed(6)}\n'
                    'Longitud: ${_puntoSeleccionado!.longitude.toStringAsFixed(6)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        _puntoSeleccionado == null
                            ? null
                            : () {
                              Navigator.pop(context, _puntoSeleccionado);
                            },
                    icon: const Icon(Icons.check),
                    label: const Text('Confirmar ubicación'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C290),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
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
