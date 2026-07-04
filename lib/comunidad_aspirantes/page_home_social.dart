// ═════════════════════════════════════════════════════════════════
// page_home.dart — Aspirantes ITVH
//
// Feed principal de la pestaña "Comunidad Nuevo Ingreso".
// Header FIJO ("Comunidad Aspirantes" + búsqueda + notificaciones)
// + lista de publicaciones con scroll infinito + botón flotante
// para crear publicación.
//
// El encabezado ya NO forma parte del ListView (antes era el
// index == 0), por eso ahora permanece estático mientras el feed
// se desplaza debajo.
//
// NUEVO: badge de notificaciones no leídas sobre la campanita del
// encabezado. El conteo (notificacionesNoLeidas) y la navegación
// (onAbrirNotificaciones) llegan como parámetros desde feed.dart —
// esta pantalla ya NO trae su propia lógica de conteo/Realtime, solo
// pinta lo que le llega y delega la navegación hacia arriba para que
// el conteo se refresque justo al volver de PaginaNotificaciones.
//
// Responsabilidades:
//   - Cargar publicaciones paginadas (10 en 10) con autor, carrera
//     y medios ya embebidos vía el join de Supabase.
//   - Saber qué publicaciones ya reaccionó el usuario actual.
//   - Persistir reacciones (onReaccionar) y abrir CrearPublicacion.
//   - Navegar a búsqueda de usuarios; delegar la navegación a
//     notificaciones hacia feed.dart vía onAbrirNotificaciones.
// ═════════════════════════════════════════════════════════════════

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'busqueda_usuarios.dart';    // ajusta la ruta según tu estructura
import 'crear_publicacion.dart';
import 'hoja_comentarios.dart';
import 'hoja_reacciones.dart';
import 'pagina_notificaciones.dart'; // ajusta la ruta según tu estructura
import 'tarjeta_publicacion.dart';

class ComunidadAspirantes extends StatefulWidget {
  final bool isDark;

  /// Conteo de notificaciones sin leer del usuario actual, calculado
  /// y mantenido en tiempo real por FeedAspirantes (feed.dart). Se
  /// muestra como badge rojo sobre la campanita del encabezado.
  final int notificacionesNoLeidas;

  /// Función de navegación a PaginaNotificaciones inyectada desde
  /// feed.dart. Si se provee, se usa en vez de la navegación local —
  /// así, al volver, feed.dart puede refrescar notificacionesNoLeidas
  /// de inmediato en vez de esperar al siguiente evento de Realtime.
  /// Si es null (por compatibilidad), cae a la navegación propia.
  final VoidCallback? onAbrirNotificaciones;

  const ComunidadAspirantes({
    super.key,
    required this.isDark,
    this.notificacionesNoLeidas = 0,
    this.onAbrirNotificaciones,
  });

  @override
  State<ComunidadAspirantes> createState() => _ComunidadAspirantesState();
}

class _ComunidadAspirantesState extends State<ComunidadAspirantes> {
  static const Color _accent = Color(0xFF007AFF);
  static const int _pageSize = 10;

  final _scrollController = ScrollController();
  final List<Map<String, dynamic>> _publicaciones = [];
  final Map<String, List<Map<String, dynamic>>> _mediosPorPost = {};
  final Set<String> _misReacciones = {};

  bool _cargandoInicial = true;
  bool _cargandoMas = false;
  bool _hayMas = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _cargarFeed(inicial: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hayMas || _cargandoMas) return;
    final umbral = _scrollController.position.maxScrollExtent - 300;
    if (_scrollController.position.pixels >= umbral) {
      _cargarFeed();
    }
  }


  // ─────────────────────────────────────────────────────────────
  // CARGA DE DATOS
  // ─────────────────────────────────────────────────────────────

  Future<void> _cargarFeed({bool inicial = false}) async {
    if (inicial) {
      setState(() {
        _cargandoInicial = true;
        _error = null;
      });
    } else {
      if (_cargandoMas || !_hayMas) return;
      setState(() => _cargandoMas = true);
    }

    try {
      final desde = inicial ? 0 : _publicaciones.length;
      final hasta = desde + _pageSize - 1;

      final data = await Supabase.instance.client
          .from('publicaciones')
          .select('''
            id, contenido, tipo, creado_en, total_reacciones, total_comentarios,
            autor_id,
            perfiles_aspirantes (
              nombre, nombre_usuario, cdn_foto_perfil,
              carreras ( nombre )
            ),
            publicacion_medios ( id, cdn_url, url, tipo_medio, orden )
          ''')
          .eq('esta_suspendida', false)
          .order('creado_en', ascending: false)
          .range(desde, hasta);

      final nuevos = List<Map<String, dynamic>>.from(data as List);

      // Averigua cuáles de estos posts ya tienen reacción del usuario actual
      if (nuevos.isNotEmpty) {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          final ids = nuevos.map((p) => p['id'] as String).toList();
          final reacciones = await Supabase.instance.client
              .from('reacciones')
              .select('publicacion_id')
              .eq('usuario_id', userId)
              .inFilter('publicacion_id', ids);

          for (final r in (reacciones as List)) {
            _misReacciones.add(r['publicacion_id'] as String);
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _publicaciones.addAll(nuevos);
        for (final post in nuevos) {
          final medios = List<Map<String, dynamic>>.from(
              post['publicacion_medios'] as List? ?? []);
          medios.sort((a, b) =>
              ((a['orden'] as int?) ?? 0).compareTo((b['orden'] as int?) ?? 0));
          _mediosPorPost[post['id'] as String] = medios;
        }
        _hayMas = nuevos.length == _pageSize;
        _cargandoInicial = false;
        _cargandoMas = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar el feed: $e';
        _cargandoInicial = false;
        _cargandoMas = false;
      });
    }
  }

  Future<void> _refrescar() async {
    _publicaciones.clear();
    _mediosPorPost.clear();
    _misReacciones.clear();
    _hayMas = true;
    await _cargarFeed(inicial: true);
  }


  // ─────────────────────────────────────────────────────────────
  // ACCIONES
  // ─────────────────────────────────────────────────────────────

  Future<void> _reaccionar(String publicacionId, bool nuevoEstado) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw Exception('Sesión no válida');

    if (nuevoEstado) {
      await Supabase.instance.client.from('reacciones').insert({
        'publicacion_id': publicacionId,
        'usuario_id': userId,
        'tipo': 'like',
      });
      _misReacciones.add(publicacionId);
    } else {
      await Supabase.instance.client
          .from('reacciones')
          .delete()
          .eq('publicacion_id', publicacionId)
          .eq('usuario_id', userId);
      _misReacciones.remove(publicacionId);
    }
  }

  Future<void> _abrirCrearPublicacion() async {
    final creada = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CrearPublicacion(isDark: widget.isDark),
      ),
    );
    if (creada == true) {
      _refrescar();
    }
  }

  void _abrirComentarios(String publicacionId) {
    HojaComentarios.mostrar(context, publicacionId: publicacionId, isDark: widget.isDark);
  }

  void _abrirReacciones(String publicacionId) {
    HojaReacciones.mostrar(context, publicacionId: publicacionId, isDark: widget.isDark);
  }

  void _abrirBusqueda() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BusquedaUsuarios(isDark: widget.isDark)),
    );
  }

  /// Navega a PaginaNotificaciones. Si feed.dart inyectó
  /// onAbrirNotificaciones, se delega ahí (para que el conteo se
  /// refresque al volver); si no, cae a una navegación local simple
  /// por compatibilidad.
  void _abrirNotificaciones() {
    if (widget.onAbrirNotificaciones != null) {
      widget.onAbrirNotificaciones!();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PaginaNotificaciones(isDark: widget.isDark)),
    );
  }


  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textPrimary = isDark ? Colors.white : Colors.black;

    return Column(
      children: [
        // ── Encabezado FIJO: no forma parte del ListView ──────
        _EncabezadoComunidad(
          isDark: isDark,
          notificacionesNoLeidas: widget.notificacionesNoLeidas,
          onBuscar: _abrirBusqueda,
          onNotificaciones: _abrirNotificaciones,
        ),

        // ── Feed (scrollable) + FAB ────────────────────────────
        Expanded(
          child: Stack(
            children: [
              RefreshIndicator(
                onRefresh: _refrescar,
                child: _cargandoInicial
                    ? const Center(child: CircularProgressIndicator())
                    : (_error != null && _publicaciones.isEmpty)
                    ? _vistaError(textPrimary)
                    : (_publicaciones.isEmpty)
                    ? _vistaVacia(textPrimary)
                    : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                  itemCount: _publicaciones.length + 1, // posts + loader
                  itemBuilder: (context, index) {
                    if (index == _publicaciones.length) {
                      return _hayMas
                          ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator()),
                      )
                          : const SizedBox.shrink();
                    }
                    final post = _publicaciones[index];
                    final postId = post['id'] as String;
                    return TarjetaPublicacion(
                      publicacion: post,
                      medios: _mediosPorPost[postId] ?? const [],
                      isDark: isDark,
                      yaReacciono: _misReacciones.contains(postId),
                      onReaccionar: (nuevoEstado) =>
                          _reaccionar(postId, nuevoEstado),
                      onComentar: () => _abrirComentarios(postId),
                      onVerReacciones: () => _abrirReacciones(postId),
                    );
                  },
                ),
              ),
              Positioned(
                right: 20,
                bottom: 20,
                child: FloatingActionButton(
                  onPressed: _abrirCrearPublicacion,
                  backgroundColor: _accent,
                  child: const Icon(CupertinoIcons.add, color: Colors.white, size: 28),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _vistaError(Color textPrimary) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 100),
          child: Column(
            children: [
              Icon(CupertinoIcons.exclamationmark_triangle,
                  color: textPrimary.withValues(alpha: 0.4), size: 40),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(_error ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textPrimary.withValues(alpha: 0.6))),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _refrescar, child: const Text('Reintentar')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _vistaVacia(Color textPrimary) {
    // Ya no incluye el encabezado: ahora es fijo y vive fuera del ListView.
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 80),
          child: Center(
            child: Text('Aún no hay publicaciones. ¡Sé el primero!',
                style: TextStyle(color: textPrimary.withValues(alpha: 0.5))),
          ),
        ),
      ],
    );
  }
}

class _EncabezadoComunidad extends StatelessWidget {
  final bool isDark;
  final int notificacionesNoLeidas;
  final VoidCallback onBuscar;
  final VoidCallback onNotificaciones;

  const _EncabezadoComunidad({
    required this.isDark,
    required this.notificacionesNoLeidas,
    required this.onBuscar,
    required this.onNotificaciones,
  });

  static const Color _accent = Color(0xFF007AFF);

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? Colors.white : Colors.black;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 8, 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comunidad',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      height: 1.05,
                    ),
                  ),
                  const Text(
                    'Aspirantes',
                    style: TextStyle(
                      color: _accent,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      height: 1.05,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onBuscar,
              icon: Icon(CupertinoIcons.search, color: textPrimary, size: 24),
            ),

            // ── Campanita de notificaciones con badge ─────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: onNotificaciones,
                  icon: Icon(CupertinoIcons.bell, color: textPrimary, size: 24),
                ),
                if (notificacionesNoLeidas > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B30),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? Colors.black : Colors.white,
                          width: 1.5,
                        ),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        notificacionesNoLeidas > 9 ? '9+' : '$notificacionesNoLeidas',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}