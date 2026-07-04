// ═════════════════════════════════════════════════════════════════
// ubicatecnm.dart
//
// Pantalla de mapa interactivo del campus del ITVH.
//
// Carga un archivo GeoJSON con la geometría de los edificios y
// puntos de interés del campus, los dibuja como polígonos y
// marcadores personalizados sobre Google Maps, y permite al
// usuario buscar y navegar a cualquier edificio por nombre.
//
// Flujo de carga:
//   1. Solicitar permiso de ubicación al sistema.
//   2. Leer y decodificar `assets/mapas/campus_data.geojson`.
//   3. Por cada Feature de tipo Polygon:
//        a. Calcular su centroide promediando coordenadas.
//        b. Crear un Polygon pintado con el color institucional.
//        c. Renderizar un marcador tipo "globito" con el nombre
//           del edificio usando canvas (BitmapDescriptor custom).
//   4. Por cada Feature de tipo Point:
//        a. Colocar un marcador con color según categoría
//           (accesos, deportes, edificios genéricos).
//   5. Mostrar el mapa con polígonos y marcadores; ocultar loader.
//
// Interacciones del usuario:
//   • Tap en polígono / marcador → InfoWindow o BottomSheet según
//     si la descripción tiene HTML complejo (esLarga).
//   • Buscador flotante → filtra edificios por nombre, muestra
//     sugerencias cuando está vacío y lista de resultados al
//     escribir; seleccionar anima la cámara al centroide.
//
// ← FIX punto azul de "mi ubicación":
//   `myLocationEnabled` del GoogleMap ahora depende de la bandera
//   reactiva `_permisoUbicacionConcedido` en lugar de un `true` fijo.
//   Antes, el permiso se solicitaba de forma asíncrona en initState
//   mientras el GoogleMap ya se construía con myLocationEnabled:true
//   desde el primer frame; si el permiso aún no estaba resuelto en
//   ese instante, el plugin nativo nunca activaba el punto azul, ni
//   siquiera después de que el usuario lo aceptara. Ahora se hace
//   setState() en cuanto se confirma el permiso, forzando un rebuild
//   del GoogleMap con el flag ya en true.
//
// ← FIX marcadores rojos en Web:
//   En Flutter Web, el plugin de google_maps necesita conocer el
//   tamaño (`size`) del BitmapDescriptor de forma explícita — en
//   Android se infiere solo desde el PNG, pero en web, si no se
//   provee, el marcador cae al ícono rojo por defecto en lugar del
//   "globito" institucional dibujado con Canvas. Se agregó el
//   parámetro `size` en `_crearMarkerEdificio`. Es inofensivo en
//   Android (el SDK nativo lo ignora si ya puede leer el bitmap).
//
// ← FIX sensibilidad de gestos en Web:
//   `rotateGesturesEnabled`, `tiltGesturesEnabled` y el
//   `EagerGestureRecognizer` se sienten demasiado bruscos en
//   pantallas táctiles dentro de un navegador (el navegador también
//   interpreta gestos, y compiten con el plugin). Se condicionaron
//   con `kIsWeb` para suavizar la experiencia solo en web, sin tocar
//   el comportamiento ya afinado en Android nativo.
// ═════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:permission_handler/permission_handler.dart';


// ═════════════════════════════════════════════════════════════════
// UBICA TEC SCREEN
// ═════════════════════════════════════════════════════════════════

class UbicaTecScreen extends StatefulWidget {
  const UbicaTecScreen({super.key});

  @override
  State<UbicaTecScreen> createState() => _UbicaTecScreenState();
}

class _UbicaTecScreenState extends State<UbicaTecScreen> {

  // ── Google Maps ───────────────────────────────────────────────
  late gmaps.GoogleMapController _mapController;
  final Set<gmaps.Polygon> _polygons = {};
  final Set<gmaps.Marker>  _markers  = {};
  bool _isLoading = true;

  // Coordenadas aproximadas del centro geográfico del campus ITVH.
  final gmaps.LatLng _centroCampus = const gmaps.LatLng(18.0234, -92.9040);

  // Lista de edificios procesados del GeoJSON.
  // Cada entrada contiene: nombre, descripcion, centroide,
  // polygonId y esLarga (booleano para distinguir el modo de vista).
  final List<Map<String, dynamic>> _edificios = [];

  // ── Buscador ──────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _resultadosBusqueda = [];
  bool _mostrandoResultados = false;

  // Controla si el panel del buscador (sugerencias / resultados)
  // está expandido. Se activa al enfocar el campo de búsqueda y
  // se colapsa al tocar el mapa o seleccionar un edificio.
  bool _buscadorActivo = false;

  // ← NUEVO: indica si el permiso de ubicación ya fue concedido.
  // `myLocationEnabled` del GoogleMap depende de esta bandera en
  // lugar de un `true` fijo: como el permiso se pide de forma
  // asíncrona en initState, el mapa puede llegar a construirse antes
  // de que el usuario responda al diálogo del sistema. Sin este
  // estado reactivo, el punto azul nunca aparecía aunque el usuario
  // sí hubiera aceptado el permiso justo después.
  bool _permisoUbicacionConcedido = false;


  // ─────────────────────────────────────────────────────────────
  // CICLO DE VIDA
  // ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _pedirPermisoUbicacion();
    _cargarGeoJsonDelCampus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  // ─────────────────────────────────────────────────────────────
  // PERMISOS
  // ─────────────────────────────────────────────────────────────

  /// Solicita permiso de ubicación en primer plano.
  ///
  /// Si el permiso ya estaba concedido de antes (`status.isGranted`),
  /// o el usuario lo acepta en el diálogo del sistema, se actualiza
  /// `_permisoUbicacionConcedido` con `setState` para que el
  /// `GoogleMap` se reconstruya con `myLocationEnabled: true` y
  /// aparezca el punto azul.
  ///
  /// Si lo deniega (incluso permanentemente), muestra un SnackBar
  /// informativo — la pantalla sigue funcionando pero sin el punto
  /// de posición propia en el mapa.
  Future<void> _pedirPermisoUbicacion() async {
    final status = await Permission.locationWhenInUse.request();

    if (status.isGranted) {
      if (mounted) setState(() => _permisoUbicacionConcedido = true);
      return;
    }

    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activa la ubicación para verte en el mapa'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }


  // ─────────────────────────────────────────────────────────────
  // UTILIDADES DE DESCRIPCIÓN
  // ─────────────────────────────────────────────────────────────

  /// Determina si una descripción del GeoJSON contiene HTML
  /// estructurado (listas, negritas, párrafos) o es demasiado
  /// larga para caber en un InfoWindow de Google Maps.
  /// En ese caso se usa un BottomSheet con flutter_html en su lugar.
  bool _esDescripcionLarga(String descripcion) {
    return descripcion.contains('<li>') ||
        descripcion.contains('<b>')   ||
        descripcion.contains('<p>')   ||
        descripcion.length > 80;
  }

  /// Elimina etiquetas HTML y entidades básicas para obtener texto
  /// plano utilizable en el snippet del InfoWindow.
  String _limpiarHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();
  }


  // ─────────────────────────────────────────────────────────────
  // MARCADORES
  // ─────────────────────────────────────────────────────────────

  /// Retorna un BitmapDescriptor de color según el tipo de punto:
  ///   • Verde  → accesos / entradas al campus.
  ///   • Naranja → instalaciones deportivas.
  ///   • Azul    → edificios y puntos genéricos.
  gmaps.BitmapDescriptor _colorPorTipo(String nombre) {
    final n = nombre.toLowerCase();
    if (n.contains('acceso')) {
      return gmaps.BitmapDescriptor.defaultMarkerWithHue(
          gmaps.BitmapDescriptor.hueGreen);
    } else if (n.contains('cancha') ||
        n.contains('gimnasio') ||
        n.contains('deporti')) {
      return gmaps.BitmapDescriptor.defaultMarkerWithHue(
          gmaps.BitmapDescriptor.hueOrange);
    } else {
      return gmaps.BitmapDescriptor.defaultMarkerWithHue(
          gmaps.BitmapDescriptor.hueAzure);
    }
  }

  /// Dibuja con canvas un marcador tipo "globito de texto" con el
  /// nombre del edificio y lo convierte a BitmapDescriptor.
  ///
  /// Estructura del globito:
  ///   ┌──────────────────┐
  ///   │   Nombre          │  ← burbuja con fondo institucional
  ///   └────────▼─────────┘  ← triángulo centrado apuntando al centroide
  ///
  /// Se usa canvas en lugar de un widget porque BitmapDescriptor
  /// solo acepta bytes PNG — no widgets de Flutter.
  ///
  /// ← FIX Web: se agrega `size` al construir el BitmapDescriptor.
  /// En Flutter Web el plugin necesita las dimensiones explícitas del
  /// bitmap; sin ellas, descarta el ícono custom y usa el marcador
  /// rojo por defecto. En Android este parámetro es innecesario pero
  /// inofensivo (el SDK nativo ya lee el tamaño real del PNG).
  Future<gmaps.BitmapDescriptor> _crearMarkerEdificio(String nombre) async {
    const double paddingH       = 12;
    const double paddingV       = 8;
    const double fontSize       = 12;
    const double triangleHeight = 8;
    const double cornerRadius   = 8;

    // Medir el texto para dimensionar la burbuja dinámicamente.
    final textPainter = TextPainter(
      text: TextSpan(
        text: nombre,
        style: const TextStyle(
          color:      Colors.white,
          fontSize:   fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final double textWidth   = textPainter.width;
    final double textHeight  = textPainter.height;
    final double bubbleWidth  = textWidth  + paddingH * 2;
    final double bubbleHeight = textHeight + paddingV * 2;
    final double totalHeight  = bubbleHeight + triangleHeight;

    final recorder = ui.PictureRecorder();
    final canvas   = Canvas(recorder);

    // Sombra difuminada detrás de la burbuja para dar profundidad.
    final shadowPaint = Paint()
      ..color      = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 2, bubbleWidth, bubbleHeight),
        const Radius.circular(cornerRadius),
      ),
      shadowPaint,
    );

    // Fondo de la burbuja con el color institucional del ITVH.
    final bubblePaint = Paint()..color = const Color(0xFF1B365D);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, bubbleWidth, bubbleHeight),
        const Radius.circular(cornerRadius),
      ),
      bubblePaint,
    );

    // Triángulo inferior centrado que apunta al centroide del edificio.
    final trianglePath = Path()
      ..moveTo(bubbleWidth / 2 - 6, bubbleHeight)
      ..lineTo(bubbleWidth / 2 + 6, bubbleHeight)
      ..lineTo(bubbleWidth / 2,     bubbleHeight + triangleHeight)
      ..close();
    canvas.drawPath(trianglePath, bubblePaint);

    // Texto del nombre encima de la burbuja.
    textPainter.paint(canvas, Offset(paddingH, paddingV));

    // Convertir el dibujo a PNG y empaquetarlo como BitmapDescriptor.
    final picture  = recorder.endRecording();
    final double bmpWidth  = bubbleWidth + 4;
    final double bmpHeight = totalHeight + 4;
    final img      = await picture.toImage(
      bmpWidth.toInt(),
      bmpHeight.toInt(),
    );
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes    = byteData!.buffer.asUint8List();

    return gmaps.BitmapDescriptor.bytes(
      bytes,
      // ← NUEVO: requerido en Web para que el ícono custom se
      // muestre en vez del pin rojo por defecto. Se ignora sin
      // problema en Android.
      width: bmpWidth,
      height: bmpHeight,
    );
  }


  // ─────────────────────────────────────────────────────────────
  // CARGA DEL GEOJSON
  // ─────────────────────────────────────────────────────────────

  /// Lee el archivo GeoJSON del campus desde assets, lo procesa y
  /// construye los Sets de polígonos y marcadores que Google Maps
  /// renderizará al terminar el setState.
  ///
  /// Notas de coordenadas GeoJSON:
  ///   • GeoJSON usa [longitud, latitud] — al revés de LatLng.
  ///   • El centroide de cada polígono se calcula como promedio
  ///     aritmético de todas sus vértices (suficientemente preciso
  ///     para polígonos convexos del tamaño de un edificio).
  Future<void> _cargarGeoJsonDelCampus() async {
    try {
      final String response =
      await rootBundle.loadString('assets/mapas/campus_data.geojson');
      final Map<String, dynamic> geojsonData = json.decode(response);
      final List<dynamic> features = geojsonData['features'];

      final Set<gmaps.Polygon> nuevosPoligonos = {};
      final Set<gmaps.Marker>  nuevosMarkers   = {};
      int idCounter = 0;

      for (var feature in features) {
        final geometry   = feature['geometry'];
        final properties = feature['properties'];

        final String nombre         = properties['Name'] ?? 'Sin nombre';
        final String descripcionRaw = properties['description'] ?? '';
        final String descripcion    = descripcionRaw.isNotEmpty
            ? descripcionRaw
            : '<p>Sin descripción disponible.</p>';

        // Elegir el modo de presentación antes de construir el marcador
        // para que tanto el polígono como el marcador compartan la misma
        // decisión sin recalcularla dos veces.
        final bool   esLarga      = _esDescripcionLarga(descripcion);
        final String snippetTexto = esLarga
            ? 'Toca para ver más información'
            : _limpiarHtml(descripcion);

        // ── POLÍGONOS ─────────────────────────────────────────
        if (geometry['type'] == 'Polygon') {
          List<dynamic> coordenadasExternas = geometry['coordinates'][0];
          List<gmaps.LatLng> puntosPoligono = [];
          double sumLat = 0, sumLng = 0;

          for (var coord in coordenadasExternas) {
            // GeoJSON: [lng, lat] → LatLng(lat, lng)
            double lng = coord[0].toDouble();
            double lat = coord[1].toDouble();
            puntosPoligono.add(gmaps.LatLng(lat, lng));
            sumLat += lat;
            sumLng += lng;
          }

          // Centroide del polígono para colocar el marcador encima.
          final gmaps.LatLng centroide = gmaps.LatLng(
            sumLat / coordenadasExternas.length,
            sumLng / coordenadasExternas.length,
          );

          idCounter++;
          final String pid = 'edificio_$idCounter';

          // Registrar el edificio para que el buscador pueda filtrarlo.
          _edificios.add({
            'nombre':      nombre,
            'descripcion': descripcion,
            'centroide':   centroide,
            'polygonId':   pid,
            'esLarga':     esLarga,
          });

          nuevosPoligonos.add(
            gmaps.Polygon(
              polygonId:        gmaps.PolygonId(pid),
              points:           puntosPoligono,
              strokeWidth:      2,
              strokeColor:      const Color(0xFF1B365D),
              fillColor:        const Color(0xFF1B365D).withValues(alpha: 0.3),
              consumeTapEvents: true,
              onTap: () {
                // Descripción larga → BottomSheet con HTML completo.
                // Descripción corta → InfoWindow nativo del marcador.
                if (esLarga) {
                  _mostrarDetallesEdificio(nombre, descripcion);
                } else {
                  _mapController.showMarkerInfoWindow(
                      gmaps.MarkerId('marker_$pid'));
                }
              },
            ),
          );

          // Crear el marcador tipo globito con canvas y añadirlo al set.
          final gmaps.BitmapDescriptor iconoEdificio =
          await _crearMarkerEdificio(nombre);

          nuevosMarkers.add(
            gmaps.Marker(
              markerId: gmaps.MarkerId('marker_$pid'),
              position: centroide,
              icon:     iconoEdificio,
              // anchor (0.5, 1.0) para que el triángulo apunte al centroide
              // en lugar de la esquina superior izquierda del bitmap.
              anchor:   const Offset(0.5, 1.0),
              infoWindow: gmaps.InfoWindow(
                title:   nombre,
                snippet: snippetTexto,
                onTap:   esLarga
                    ? () => _mostrarDetallesEdificio(nombre, descripcion)
                    : null,
              ),
            ),
          );
        }

        // ── PUNTOS ────────────────────────────────────────────
        if (geometry['type'] == 'Point') {
          final double lng      = geometry['coordinates'][0].toDouble();
          final double lat      = geometry['coordinates'][1].toDouble();
          final gmaps.LatLng posicion = gmaps.LatLng(lat, lng);

          nuevosMarkers.add(
            gmaps.Marker(
              markerId: gmaps.MarkerId('punto_$nombre'),
              position: posicion,
              icon:     _colorPorTipo(nombre),
              infoWindow: gmaps.InfoWindow(
                title:   nombre,
                snippet: snippetTexto.isNotEmpty ? snippetTexto : null,
                onTap:   esLarga
                    ? () => _mostrarDetallesEdificio(nombre, descripcion)
                    : null,
              ),
            ),
          );
        }
      }

      setState(() {
        _polygons.addAll(nuevosPoligonos);
        _markers.addAll(nuevosMarkers);
        _isLoading = false;
      });

    } catch (e) {
      debugPrint('Error al cargar el mapa del campus: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:  Text('Error: $e'),
            duration: const Duration(seconds: 10),
          ),
        );
      }
    }
  }


  // ─────────────────────────────────────────────────────────────
  // BUSCADOR
  // ─────────────────────────────────────────────────────────────

  /// Filtra la lista de edificios por nombre (case-insensitive)
  /// cada vez que el usuario escribe en el campo de búsqueda.
  /// Con query vacío colapsa la lista de resultados.
  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _resultadosBusqueda  = [];
        _mostrandoResultados = false;
      });
      return;
    }
    setState(() {
      _resultadosBusqueda = _edificios
          .where((e) =>
          e['nombre'].toLowerCase().contains(query.toLowerCase()))
          .toList();
      _mostrandoResultados = true;
    });
  }

  /// Maneja la selección de un edificio desde el buscador:
  ///   1. Limpia y colapsa el buscador.
  ///   2. Coloca un marcador rojo temporal en el centroide.
  ///   3. Anima la cámara al centroide con zoom de detalle.
  ///   4. Tras 600 ms (tiempo de animación), muestra el detalle
  ///      del edificio (BottomSheet o InfoWindow según esLarga).
  void _seleccionarEdificio(Map<String, dynamic> edificio) {
    FocusScope.of(context).unfocus();
    _searchController.clear();
    setState(() {
      _resultadosBusqueda  = [];
      _mostrandoResultados = false;
      _buscadorActivo      = false;
    });

    final gmaps.LatLng centroide = edificio['centroide'];

    // Marcador temporal de destino; se reemplaza si el usuario
    // selecciona otro edificio antes de que el anterior se limpie.
    final markerDestino = gmaps.Marker(
      markerId: const gmaps.MarkerId('destino'),
      position: centroide,
      icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
          gmaps.BitmapDescriptor.hueRed),
      infoWindow: gmaps.InfoWindow(title: '📍 ${edificio['nombre']}'),
    );

    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'destino');
      _markers.add(markerDestino);
    });

    _mapController.animateCamera(
      gmaps.CameraUpdate.newCameraPosition(
        gmaps.CameraPosition(target: centroide, zoom: 19.5),
      ),
    );

    // El delay permite que la animación de cámara termine antes de
    // abrir el BottomSheet o el InfoWindow para una experiencia más fluida.
    Future.delayed(const Duration(milliseconds: 600), () {
      if (edificio['esLarga'] == true) {
        _mostrarDetallesEdificio(edificio['nombre'], edificio['descripcion']);
      } else {
        _mapController.showMarkerInfoWindow(
            const gmaps.MarkerId('destino'));
      }
    });
  }


  // ─────────────────────────────────────────────────────────────
  // DETALLE DE EDIFICIO
  // ─────────────────────────────────────────────────────────────

  /// Muestra un BottomSheet arrastrable con el nombre y la
  /// descripción HTML del edificio usando flutter_html.
  ///
  /// Se usa DraggableScrollableSheet para permitir al usuario
  /// expandirlo hasta el 85 % de la pantalla si el contenido
  /// es extenso (e.g., listas de laboratorios o servicios).
  void _mostrarDetallesEdificio(String nombre, String descripcion) {
    showModalBottomSheet(
      context:             context,
      backgroundColor:     Colors.white,
      isScrollControlled:  true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand:            false,
          initialChildSize:  0.4,
          minChildSize:      0.2,
          maxChildSize:      0.85,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Indicador de arrastre
                    Center(
                      child: Container(
                        width:  40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color:        Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // Nombre del edificio
                    Text(
                      nombre,
                      style: const TextStyle(
                        fontSize:   22,
                        fontWeight: FontWeight.bold,
                        color:      Color(0xFF1B365D),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Descripción HTML renderizada con flutter_html
                    Html(
                      data: descripcion,
                      style: {
                        'body': Style(
                          fontSize:  FontSize(15),
                          color:     Colors.grey[800],
                          lineHeight: LineHeight(1.4),
                          margin:    Margins.zero,
                          padding:   HtmlPaddings.zero,
                        ),
                        'b': Style(color: const Color(0xFF1B365D)),
                      },
                    ),
                    const SizedBox(height: 16),

                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      // ── AppBar institucional ───────────────────────────────────
      // Dos líneas de título: "UbicaTecNM" en color del tema y
      // "Campus Villahermosa" en azul iOS para dar identidad visual.
      appBar: AppBar(
        toolbarHeight:    72,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation:        0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize:       MainAxisSize.min,
          children: [
            Text(
              'UbicaTecNM',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
                fontSize:      26,
                fontWeight:    FontWeight.w800,
                height:        1.1,
                letterSpacing: -0.5,
              ),
            ),
            const Text(
              'Campus Villahermosa',
              style: TextStyle(
                color:         Color(0xFF007AFF),
                fontSize:      26,
                fontWeight:    FontWeight.w800,
                height:        1.1,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),

      // ── Cuerpo ────────────────────────────────────────────────
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [

          // ── Mapa de Google Maps ──────────────────────────
          // Se usa EagerGestureRecognizer (solo fuera de web) para
          // que el mapa capture gestos de scroll aunque esté dentro
          // de un Stack, evitando conflictos con el
          // SingleChildScrollView de la pantalla padre si lo hubiera
          // en el futuro. En web se deja vacío para que el manejo de
          // gestos por defecto del navegador se sienta más natural.
          Positioned.fill(
            child: gmaps.GoogleMap(
              initialCameraPosition: gmaps.CameraPosition(
                target: _centroCampus,
                zoom:   17.5,
              ),
              mapType:                  gmaps.MapType.hybrid,
              polygons:                 _polygons,
              markers:                  _markers,
              // ← CAMBIADO: antes era `true` fijo. Ahora depende del
              // estado reactivo `_permisoUbicacionConcedido`, que se
              // actualiza con setState en cuanto el permiso se
              // confirma, forzando al GoogleMap a reconstruirse y
              // activar el punto azul de ubicación.
              myLocationEnabled:        _permisoUbicacionConcedido,
              myLocationButtonEnabled:  _permisoUbicacionConcedido,
              scrollGesturesEnabled:    true,
              zoomGesturesEnabled:      true,
              // ← CAMBIADO (solo Web): en pantallas táctiles dentro
              // de un navegador, rotar/inclinar con dos dedos se
              // siente demasiado sensible y compite con los gestos
              // propios del navegador. En Android nativo se dejan
              // habilitados como antes.
              rotateGesturesEnabled:    kIsWeb ? false : true,
              tiltGesturesEnabled:      kIsWeb ? false : true,
              // Zoom acotado: < 15 el campus se pierde;
              // > 20 el mapa híbrido pierde calidad.
              minMaxZoomPreference: const gmaps.MinMaxZoomPreference(
                  15.0, 20.0),
              // ← CAMBIADO (solo Web): se deja el set de gesture
              // recognizers vacío para que el navegador maneje los
              // gestos táctiles de forma nativa y menos brusca. En
              // Android se conserva el EagerGestureRecognizer.
              gestureRecognizers: kIsWeb
                  ? const {}
                  : {
                Factory<OneSequenceGestureRecognizer>(
                      () => EagerGestureRecognizer(),
                ),
              },
              // ← NUEVO (solo Web): por defecto, el plugin web usa el
              // modo "cooperative" de Google Maps, que exige DOS dedos
              // para mover el mapa (pensado para no "atrapar" el scroll
              // de la página cuando hay varios mapas embebidos). Como
              // esta pantalla es de mapa a pantalla completa, se cambia
              // a "greedy" para que se pueda mover con un solo dedo,
              // igual que en Android. Este parámetro no existe/aplica
              // fuera de web, así que se deja en su valor por defecto
              // ahí.
              webGestureHandling: kIsWeb
                  ? gmaps.WebGestureHandling.greedy
                  : null,
              onMapCreated: (gmaps.GoogleMapController controller) {
                _mapController = controller;
              },
              // Tap en el mapa vacío → cerrar buscador.
              onTap: (_) {
                FocusScope.of(context).unfocus();
                setState(() {
                  _resultadosBusqueda  = [];
                  _mostrandoResultados = false;
                  _buscadorActivo      = false;
                  _searchController.clear();
                });
              },
            ),
          ),

          // ── Buscador flotante ────────────────────────────
          // Overlay posicionado sobre el mapa. Tiene tres
          // estados visuales:
          //   1. Inactivo → solo muestra el TextField.
          //   2. Activo sin texto → panel de sugerencias.
          //   3. Activo con texto → lista de resultados.
          Positioned(
            top:   16,
            left:  16,
            right: 16,
            child: Column(
              children: [

                // ── Campo de búsqueda ──────────────────────
                Material(
                  elevation:    6,
                  borderRadius: BorderRadius.circular(12),
                  child: TextField(
                    controller: _searchController,
                    onChanged:  _onSearchChanged,
                    onTap: () =>
                        setState(() => _buscadorActivo = true),
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      hintText:    'Buscar edificio en el campus...',
                      hintStyle:   const TextStyle(color: Colors.grey),
                      prefixIcon:  const Icon(Icons.search,
                          color: Color(0xFF1B365D)),
                      // Botón de limpiar solo visible cuando hay texto.
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                          FocusScope.of(context).unfocus();
                          setState(
                                  () => _buscadorActivo = false);
                        },
                      )
                          : null,
                      filled:      true,
                      fillColor:   Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:   BorderSide.none,
                      ),
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),

                // ── Panel de sugerencias (campo vacío) ──────
                if (_buscadorActivo &&
                    _searchController.text.isEmpty)
                  Material(
                    elevation:    6,
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(12)),
                    child: Container(
                      width:   double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(12)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // Mensaje de ayuda
                          Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: 16, color: Colors.grey[500]),
                              const SizedBox(width: 6),
                              Text(
                                'Escribe el nombre de un edificio',
                                style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Etiqueta de sugerencias
                          Text(
                            'Sugerencias',
                            style: TextStyle(
                              color:         Colors.grey[700],
                              fontSize:      12,
                              fontWeight:    FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Chips de búsqueda rápida.
                          // Hardcodeados con los espacios más
                          // buscados por los estudiantes.
                          Wrap(
                            spacing:    8,
                            runSpacing: 6,
                            children: [
                              'Biblioteca',
                              'Centro de Cómputo',
                              'Cafetería',
                              'Edificio M',
                              'Gimnasio',
                            ].map((sugerencia) => GestureDetector(
                              onTap: () {
                                _searchController.text = sugerencia;
                                _onSearchChanged(sugerencia);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B365D)
                                      .withValues(alpha: 0.08),
                                  borderRadius:
                                  BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF1B365D)
                                        .withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Text(
                                  sugerencia,
                                  style: const TextStyle(
                                    fontSize:   12,
                                    color:      Color(0xFF1B365D),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )).toList(),
                          ),

                        ],
                      ),
                    ),
                  ),

                // ── Lista de resultados ────────────────────
                if (_mostrandoResultados &&
                    _resultadosBusqueda.isNotEmpty)
                  Material(
                    elevation:    6,
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(12)),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(12)),
                      ),
                      // Altura máxima para no tapar el mapa
                      // cuando hay muchos resultados.
                      constraints:
                      const BoxConstraints(maxHeight: 220),
                      child: ListView.separated(
                        shrinkWrap:      true,
                        padding:         EdgeInsets.zero,
                        itemCount:       _resultadosBusqueda.length,
                        separatorBuilder: (_, __) =>
                        const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final edificio =
                          _resultadosBusqueda[index];
                          return ListTile(
                            leading: const Icon(Icons.location_on,
                                color: Color(0xFF1B365D)),
                            title: Text(
                              edificio['nombre'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color:      Color(0xFF1B365D),
                              ),
                            ),
                            onTap: () =>
                                _seleccionarEdificio(edificio),
                          );
                        },
                      ),
                    ),
                  ),

                // ── Sin resultados ─────────────────────────
                if (_mostrandoResultados &&
                    _resultadosBusqueda.isEmpty)
                  Material(
                    elevation:    6,
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(12)),
                    child: Container(
                      color:   Colors.white,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.search_off,
                              color: Colors.grey[400]),
                          const SizedBox(width: 8),
                          Text(
                            'No se encontraron edificios',
                            style:
                            TextStyle(color: Colors.grey[500]),
                          ),
                        ],
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