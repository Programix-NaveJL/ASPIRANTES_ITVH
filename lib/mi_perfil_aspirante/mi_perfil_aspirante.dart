// ═════════════════════════════════════════════════════════════════
// mi_perfil_aspirante.dart — Aspirantes ITVH
//
// Pestaña "Mi Perfil" del bottom nav. Header FIJO (título "Mi
// Perfil" + ícono de editar), igual patrón que _EncabezadoComunidad
// en page_home.dart, con el body scrolleable debajo mostrando:
//   - Avatar, nombre, @usuario, carrera, presentación
//   - Stats (publicaciones / seguidores / seguidos)
//   - Redes sociales (si el aspirante las configuró)
//   - Lista de sus propias publicaciones (reusa TarjetaPublicacion,
//     mismo widget que el feed — no un grid tipo Instagram)
//
// A diferencia de PerfilPublicoAspirante:
//   • no hay botón de seguir (es uno mismo)
//   • el botón de "editar" navega a EditarPerfilAspirante y, al
//     volver, refresca el perfil (pudo cambiar foto/nombre/carrera)
//   • el conteo de publicaciones se calcula con count() porque no
//     existe una columna total_publicaciones en el schema
// ═════════════════════════════════════════════════════════════════

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../comunidad_aspirantes/hoja_comentarios.dart';
import '../comunidad_aspirantes/hoja_reacciones.dart';
import '../comunidad_aspirantes/tarjeta_publicacion.dart';
import '../servicios_storage/url_helper.dart';
import 'editar_perfil_aspirante.dart';
import 'hoja_seguidores.dart';

class MiPerfilAspirante extends StatefulWidget {
  final bool isDark;

  /// true cuando se abre empujada (Navigator.push) desde otra
  /// pantalla — p. ej. al tocar tu propio avatar en una tarjeta de
  /// publicación — para mostrar botón de regreso. false (default)
  /// cuando vive como pestaña del bottom nav, donde no aplica.
  final bool mostrarBotonAtras;

  const MiPerfilAspirante({
    super.key,
    required this.isDark,
    this.mostrarBotonAtras = false,
  });

  @override
  State<MiPerfilAspirante> createState() => _MiPerfilAspiranteState();
}

class _MiPerfilAspiranteState extends State<MiPerfilAspirante> {
  static const Color _accent = Color(0xFF007AFF);
  static const int _pageSize = 10;

  final _scrollController = ScrollController();
  final List<Map<String, dynamic>> _publicaciones = [];
  final Map<String, List<Map<String, dynamic>>> _mediosPorPost = {};
  final Set<String> _misReacciones = {};

  Map<String, dynamic>? _perfil;
  int _totalPublicaciones = 0;

  bool _cargandoPerfil = true;
  bool _cargandoMas = false;
  bool _hayMas = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _cargarTodo(inicial: true);
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
      _cargarPublicaciones();
    }
  }


  // ─────────────────────────────────────────────────────────────
  // CARGA DE DATOS
  // ─────────────────────────────────────────────────────────────

  Future<void> _cargarTodo({bool inicial = false}) async {
    setState(() {
      _cargandoPerfil = true;
      _error = null;
    });
    await Future.wait([
      _cargarPerfil(),
      _cargarPublicaciones(inicial: true),
    ]);
    if (mounted) setState(() => _cargandoPerfil = false);
  }

  Future<void> _cargarPerfil() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    try {
      // Tipado explícito a <Future> (= Future<dynamic>): sin esto Dart
      // intenta inferir un tipo común entre Future<Map<String, dynamic>>
      // (.single()) y Future<PostgrestResponse> (.count()) y falla,
      // marcando todo el bloque en rojo aunque en runtime esté bien.
      final consultas = <Future>[
        Supabase.instance.client
            .from('perfiles_aspirantes')
            .select('*, carreras ( nombre )')
            .eq('id', uid)
            .single(),
        Supabase.instance.client
            .from('publicaciones')
            .select('id')
            .eq('autor_id', uid)
            .count(CountOption.exact),
      ];
      final resultados = await Future.wait(consultas);

      if (!mounted) return;
      setState(() {
        _perfil = resultados[0] as Map<String, dynamic>;
        _totalPublicaciones = (resultados[1] as PostgrestResponse).count;
      });
    } catch (e) {
      debugPrint('MiPerfilAspirante – cargar perfil: $e');
      if (mounted) setState(() => _error = 'No se pudo cargar tu perfil.');
    }
  }

  Future<void> _cargarPublicaciones({bool inicial = false}) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    if (!inicial) {
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
          .eq('autor_id', uid)
          .order('creado_en', ascending: false)
          .range(desde, hasta);

      final nuevos = List<Map<String, dynamic>>.from(data as List);

      if (nuevos.isNotEmpty) {
        final ids = nuevos.map((p) => p['id'] as String).toList();
        final reacciones = await Supabase.instance.client
            .from('reacciones')
            .select('publicacion_id')
            .eq('usuario_id', uid)
            .inFilter('publicacion_id', ids);
        for (final r in (reacciones as List)) {
          _misReacciones.add(r['publicacion_id'] as String);
        }
      }

      if (!mounted) return;
      setState(() {
        if (inicial) {
          _publicaciones.clear();
          _mediosPorPost.clear();
        }
        _publicaciones.addAll(nuevos);
        for (final post in nuevos) {
          final medios = List<Map<String, dynamic>>.from(
              post['publicacion_medios'] as List? ?? []);
          medios.sort((a, b) =>
              ((a['orden'] as int?) ?? 0).compareTo((b['orden'] as int?) ?? 0));
          _mediosPorPost[post['id'] as String] = medios;
        }
        _hayMas = nuevos.length == _pageSize;
        _cargandoMas = false;
      });
    } catch (e) {
      debugPrint('MiPerfilAspirante – cargar publicaciones: $e');
      if (mounted) setState(() => _cargandoMas = false);
    }
  }

  Future<void> _refrescar() => _cargarTodo();


  // ─────────────────────────────────────────────────────────────
  // ACCIONES
  // ─────────────────────────────────────────────────────────────

  Future<void> _reaccionar(String publicacionId, bool nuevoEstado) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) throw Exception('Sesión no válida');

    if (nuevoEstado) {
      await Supabase.instance.client.from('reacciones').insert({
        'publicacion_id': publicacionId,
        'usuario_id': uid,
        'tipo': 'like',
      });
      _misReacciones.add(publicacionId);
    } else {
      await Supabase.instance.client
          .from('reacciones')
          .delete()
          .eq('publicacion_id', publicacionId)
          .eq('usuario_id', uid);
      _misReacciones.remove(publicacionId);
    }
  }

  void _abrirComentarios(String publicacionId) {
    HojaComentarios.mostrar(context, publicacionId: publicacionId, isDark: widget.isDark);
  }

  void _abrirReacciones(String publicacionId) {
    HojaReacciones.mostrar(context, publicacionId: publicacionId, isDark: widget.isDark);
  }

  Future<void> _abrirEditar() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EditarPerfilAspirante()),
    );
    // El perfil pudo cambiar (foto, nombre, usuario, carrera, bio).
    if (mounted) _cargarPerfil();
  }

  Future<void> _abrirRedSocial(String? url) async {
    if (url == null || url.isEmpty) return;
    var normalizado = url.trim();
    if (!normalizado.startsWith('http://') && !normalizado.startsWith('https://')) {
      normalizado = 'https://$normalizado';
    }
    final uri = Uri.tryParse(normalizado);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
        _EncabezadoMiPerfil(
          isDark: isDark,
          onEditar: _abrirEditar,
          mostrarBotonAtras: widget.mostrarBotonAtras,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refrescar,
            child: _cargandoPerfil
                ? const Center(child: CircularProgressIndicator())
                : (_error != null && _perfil == null)
                ? _vistaError(textPrimary)
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
              itemCount: 2 + _publicaciones.length, // header + separador + posts
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _TarjetaPerfil(
                    perfil: _perfil,
                    totalPublicaciones: _totalPublicaciones,
                    isDark: isDark,
                    onAbrirRedSocial: _abrirRedSocial,
                  );
                }
                if (index == 1) {
                  if (_publicaciones.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text(
                          'Aún no has publicado nada.',
                          style: TextStyle(color: textPrimary.withValues(alpha: 0.5)),
                        ),
                      ),
                    );
                  }
                  return const SizedBox(height: 4);
                }
                final postIndex = index - 2;
                if (postIndex == _publicaciones.length) {
                  return _hayMas
                      ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  )
                      : const SizedBox.shrink();
                }
                final post = _publicaciones[postIndex];
                final postId = post['id'] as String;
                return TarjetaPublicacion(
                  publicacion: post,
                  medios: _mediosPorPost[postId] ?? const [],
                  isDark: isDark,
                  yaReacciono: _misReacciones.contains(postId),
                  onReaccionar: (nuevoEstado) => _reaccionar(postId, nuevoEstado),
                  onComentar: () => _abrirComentarios(postId),
                  onVerReacciones: () => _abrirReacciones(postId),
                );
              },
            ),
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
              Text(_error ?? '', style: TextStyle(color: textPrimary.withValues(alpha: 0.6))),
              const SizedBox(height: 12),
              TextButton(onPressed: _refrescar, child: const Text('Reintentar')),
            ],
          ),
        ),
      ],
    );
  }
}


// ─────────────────────────────────────────────────────────────────
// ENCABEZADO FIJO
// ─────────────────────────────────────────────────────────────────

class _EncabezadoMiPerfil extends StatelessWidget {
  final bool isDark;
  final VoidCallback onEditar;
  final bool mostrarBotonAtras;

  const _EncabezadoMiPerfil({
    required this.isDark,
    required this.onEditar,
    required this.mostrarBotonAtras,
  });

  static const Color _accent = Color(0xFF007AFF);

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? Colors.white : Colors.black;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(mostrarBotonAtras ? 8 : 20, 6, 8, 6),
        child: Row(
          children: [
            if (mostrarBotonAtras)
              IconButton(
                icon: Icon(CupertinoIcons.back, color: _accent, size: 24),
                onPressed: () => Navigator.of(context).pop(),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mi',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      height: 1.05,
                    ),
                  ),
                  const Text(
                    'Perfil',
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
              onPressed: onEditar,
              icon: Icon(CupertinoIcons.pencil, color: textPrimary, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────
// TARJETA DE PERFIL (avatar, stats, bio, redes)
// ─────────────────────────────────────────────────────────────────

class _TarjetaPerfil extends StatelessWidget {
  final Map<String, dynamic>? perfil;
  final int totalPublicaciones;
  final bool isDark;
  final Future<void> Function(String? url) onAbrirRedSocial;

  const _TarjetaPerfil({
    required this.perfil,
    required this.totalPublicaciones,
    required this.isDark,
    required this.onAbrirRedSocial,
  });

  static const Color _accent = Color(0xFF007AFF);

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? Colors.white : Colors.black;
    final textSec = textPrimary.withValues(alpha: 0.5);
    final bgCard = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final divColor = isDark ? Colors.white10 : Colors.black12;

    final p = perfil;
    final nombre = p?['nombre'] as String? ?? '';
    final usuario = p?['nombre_usuario'] as String? ?? '';
    final presentacion = p?['presentacion'] as String? ?? '';
    final carrera = (p?['carreras'] as Map<String, dynamic>?)?['nombre'] as String?;
    final fotoUrl = p != null ? resolverUrlPerfil(p) : '';
    final seguidores = (p?['total_seguidores'] as int?) ?? 0;
    final seguidos = (p?['total_seguidos'] as int?) ?? 0;
    final instagram = p?['instagram_url'] as String?;
    final facebook = p?['facebook_url'] as String?;
    final tiktok = p?['tiktok_url'] as String?;
    final hayRedes = [instagram, facebook, tiktok].any((r) => r != null && r.isNotEmpty);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: divColor, width: 0.5),
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _accent, width: 2.5),
              color: bgCard,
            ),
            child: ClipOval(
              child: fotoUrl.isNotEmpty
                  ? Image.network(
                fotoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(CupertinoIcons.person_fill, size: 44, color: textSec),
              )
                  : Icon(CupertinoIcons.person_fill, size: 44, color: textSec),
            ),
          ),
          const SizedBox(height: 12),
          Text(nombre.isEmpty ? 'Tu nombre' : nombre,
              style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(usuario.isEmpty ? '@usuario' : '@$usuario',
              style: TextStyle(color: textSec, fontSize: 13)),
          if (carrera != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(carrera,
                  style: const TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
          if (presentacion.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(presentacion,
                textAlign: TextAlign.center,
                style: TextStyle(color: textPrimary.withValues(alpha: 0.85), fontSize: 13.5, height: 1.35)),
          ],
          const SizedBox(height: 18),
          Divider(height: 0.5, thickness: 0.5, color: divColor),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _EstadisticaItem(valor: totalPublicaciones, label: 'Publicaciones', textPrimary: textPrimary, textSec: textSec),
              _EstadisticaItem(
                valor: seguidores, label: 'Seguidores', textPrimary: textPrimary, textSec: textSec,
                onTap: () => HojaSeguidores.mostrar(context, perfilId: perfil!['id'] as String, isDark: isDark, tabInicial: 0),
              ),
              _EstadisticaItem(
                valor: seguidos, label: 'Seguidos', textPrimary: textPrimary, textSec: textSec,
                onTap: () => HojaSeguidores.mostrar(context, perfilId: perfil!['id'] as String, isDark: isDark, tabInicial: 1),
              ),
            ],
          ),
          if (hayRedes) ...[
            const SizedBox(height: 16),
            Divider(height: 0.5, thickness: 0.5, color: divColor),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (instagram != null && instagram.isNotEmpty)
                  _BotonRedSocial(asset: 'assets/icons/instagram.png', onTap: () => onAbrirRedSocial(instagram)),
                if (facebook != null && facebook.isNotEmpty)
                  _BotonRedSocial(asset: 'assets/icons/facebook.png', onTap: () => onAbrirRedSocial(facebook)),
                if (tiktok != null && tiktok.isNotEmpty)
                  _BotonRedSocial(asset: 'assets/icons/tiktok.png', onTap: () => onAbrirRedSocial(tiktok)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EstadisticaItem extends StatelessWidget {
  final int valor;
  final String label;
  final Color textPrimary;
  final Color textSec;
  final VoidCallback? onTap;   // ← nuevo

  const _EstadisticaItem({
    required this.valor, required this.label, required this.textPrimary, required this.textSec,
    this.onTap,                 // ← nuevo
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(       // ← envuelve el Column existente
      onTap: onTap,
      child: Column(
        children: [
          Text('$valor', style: TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: textSec, fontSize: 11.5)),
        ],
      ),
    );
  }
}

class _BotonRedSocial extends StatelessWidget {
  final String asset;
  final VoidCallback onTap;
  const _BotonRedSocial({required this.asset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(width: 32, height: 32, child: Image.asset(asset, fit: BoxFit.cover)),
        ),
      ),
    );
  }
}