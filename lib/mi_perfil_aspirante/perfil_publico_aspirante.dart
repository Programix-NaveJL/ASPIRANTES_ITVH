// ═════════════════════════════════════════════════════════════════
// perfil_publico_aspirante.dart — Aspirantes ITVH
//
// Pantalla PUSHEADA (no es tab) para ver el perfil de OTRO
// aspirante — se abre desde búsqueda, desde el avatar/nombre en
// una TarjetaPublicacion, o desde la lista de "quién reaccionó".
//
// A diferencia de MiPerfilAspirante:
//   • recibe perfilId por parámetro y consulta ese perfil, no el
//     propio (Supabase.auth.currentUser)
//   • muestra botón "Seguir" / "Siguiendo" en vez de "Editar"
//     (tabla `seguidores`, optimistic update con rollback — mismo
//     patrón que el toggle de reacción en TarjetaPublicacion)
//   • si por alguna razón perfilId == uid actual (p. ej. se llegó
//     aquí desde un deep link viejo), se oculta el botón de seguir
//     para no permitir auto-seguirse
// ═════════════════════════════════════════════════════════════════

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../comunidad_aspirantes/hoja_comentarios.dart';
import '../comunidad_aspirantes/hoja_reacciones.dart';
import '../comunidad_aspirantes/tarjeta_publicacion.dart';
import '../servicios_storage/url_helper.dart';
import 'hoja_seguidores.dart';

class PerfilPublicoAspirante extends StatefulWidget {
  final String perfilId;
  final bool isDark;

  const PerfilPublicoAspirante({
    super.key,
    required this.perfilId,
    required this.isDark,
  });

  @override
  State<PerfilPublicoAspirante> createState() => _PerfilPublicoAspiranteState();
}

class _PerfilPublicoAspiranteState extends State<PerfilPublicoAspirante> {
  static const Color _accent = Color(0xFF007AFF);
  static const int _pageSize = 10;

  final _scrollController = ScrollController();
  final List<Map<String, dynamic>> _publicaciones = [];
  final Map<String, List<Map<String, dynamic>>> _mediosPorPost = {};
  final Set<String> _misReacciones = {};

  Map<String, dynamic>? _perfil;
  int _totalPublicaciones = 0;
  bool _sigo = false;

  bool _cargandoPerfil = true;
  bool _cargandoMas = false;
  bool _actualizandoSeguir = false;
  bool _hayMas = true;
  String? _error;

  bool get _esMiPropioPerfil =>
      widget.perfilId == Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _cargarTodo();
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

  Future<void> _cargarTodo() async {
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

    try {
      final consultas = <Future>[
        Supabase.instance.client
            .from('perfiles_aspirantes')
            .select('*, carreras ( nombre )')
            .eq('id', widget.perfilId)
            .single(),
        Supabase.instance.client
            .from('publicaciones')
            .select('id')
            .eq('autor_id', widget.perfilId)
            .count(CountOption.exact),
      ];
      if (uid != null && !_esMiPropioPerfil) {
        consultas.add(
          Supabase.instance.client
              .from('seguidores')
              .select('id')
              .eq('seguidor_id', uid)
              .eq('seguido_id', widget.perfilId)
              .maybeSingle(),
        );
      }

      final resultados = await Future.wait(consultas);

      if (!mounted) return;
      setState(() {
        _perfil = resultados[0] as Map<String, dynamic>;
        _totalPublicaciones = (resultados[1] as PostgrestResponse).count;
        if (resultados.length > 2) {
          _sigo = resultados[2] != null;
        }
      });
    } catch (e) {
      debugPrint('PerfilPublicoAspirante – cargar perfil: $e');
      if (mounted) setState(() => _error = 'No se pudo cargar este perfil.');
    }
  }

  Future<void> _cargarPublicaciones({bool inicial = false}) async {
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
          .eq('autor_id', widget.perfilId)
          .eq('esta_suspendida', false)
          .order('creado_en', ascending: false)
          .range(desde, hasta);

      final nuevos = List<Map<String, dynamic>>.from(data as List);

      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (nuevos.isNotEmpty && uid != null) {
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
      debugPrint('PerfilPublicoAspirante – cargar publicaciones: $e');
      if (mounted) setState(() => _cargandoMas = false);
    }
  }

  Future<void> _refrescar() => _cargarTodo();


  // ─────────────────────────────────────────────────────────────
  // SEGUIR / DEJAR DE SEGUIR
  // ─────────────────────────────────────────────────────────────

  Future<void> _alternarSeguir() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null || _esMiPropioPerfil || _actualizandoSeguir) return;

    final estadoAnterior = _sigo;
    final seguidoresAnterior = (_perfil?['total_seguidores'] as int?) ?? 0;

    setState(() {
      _actualizandoSeguir = true;
      _sigo = !_sigo;
      if (_perfil != null) {
        _perfil = {
          ..._perfil!,
          'total_seguidores': seguidoresAnterior + (_sigo ? 1 : -1),
        };
      }
    });

    try {
      if (_sigo) {
        await Supabase.instance.client.from('seguidores').insert({
          'seguidor_id': uid,
          'seguido_id': widget.perfilId,
        });
      } else {
        await Supabase.instance.client
            .from('seguidores')
            .delete()
            .eq('seguidor_id', uid)
            .eq('seguido_id', widget.perfilId);
      }
    } catch (e) {
      debugPrint('PerfilPublicoAspirante – alternar seguir: $e');
      if (!mounted) return;
      setState(() {
        _sigo = estadoAnterior;
        if (_perfil != null) {
          _perfil = {..._perfil!, 'total_seguidores': seguidoresAnterior};
        }
      });
    } finally {
      if (mounted) setState(() => _actualizandoSeguir = false);
    }
  }

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


  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final bg = isDark ? Colors.black : const Color(0xFFF2F2F7);
    final usuario = _perfil?['nombre_usuario'] as String?;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: _accent, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          usuario != null ? '@$usuario' : 'Perfil',
          style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refrescar,
        child: _cargandoPerfil
            ? const Center(child: CircularProgressIndicator())
            : (_error != null && _perfil == null)
            ? _vistaError(textPrimary)
            : ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          itemCount: 2 + _publicaciones.length,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _TarjetaPerfilPublico(
                perfil: _perfil,
                totalPublicaciones: _totalPublicaciones,
                sigo: _sigo,
                mostrarBotonSeguir: !_esMiPropioPerfil,
                actualizandoSeguir: _actualizandoSeguir,
                onAlternarSeguir: _alternarSeguir,
                isDark: isDark,
              );
            }
            if (index == 1) {
              if (_publicaciones.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      'Este aspirante aún no ha publicado nada.',
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
// TARJETA DE PERFIL (con botón de seguir)
// ─────────────────────────────────────────────────────────────────

class _TarjetaPerfilPublico extends StatelessWidget {
  final Map<String, dynamic>? perfil;
  final int totalPublicaciones;
  final bool sigo;
  final bool mostrarBotonSeguir;
  final bool actualizandoSeguir;
  final VoidCallback onAlternarSeguir;
  final bool isDark;

  const _TarjetaPerfilPublico({
    required this.perfil,
    required this.totalPublicaciones,
    required this.sigo,
    required this.mostrarBotonSeguir,
    required this.actualizandoSeguir,
    required this.onAlternarSeguir,
    required this.isDark,
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
          Text(nombre.isEmpty ? 'Aspirante' : nombre,
              style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(usuario.isEmpty ? '' : '@$usuario',
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
          if (mostrarBotonSeguir) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: sigo
                  ? OutlinedButton(
                onPressed: actualizandoSeguir ? null : onAlternarSeguir,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: divColor),
                  foregroundColor: textPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: actualizandoSeguir
                    ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Siguiendo', style: TextStyle(fontWeight: FontWeight.w600)),
              )
                  : ElevatedButton(
                onPressed: actualizandoSeguir ? null : onAlternarSeguir,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  disabledBackgroundColor: _accent.withValues(alpha: 0.4),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: actualizandoSeguir
                    ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Text('Seguir', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
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