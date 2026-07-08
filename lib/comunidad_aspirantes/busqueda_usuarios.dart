// ═════════════════════════════════════════════════════════════════
// busqueda_usuarios.dart — Aspirantes ITVH
//
// Pantalla de búsqueda de perfiles por nombre o nombre de usuario.
// Búsqueda con debounce (400ms) para no disparar una query por
// cada tecla presionada. Al tocar un resultado, navega al perfil
// vía navegacion_perfil.dart (propio o público según corresponda).
//
// NUEVO: sugerencias automáticas al abrir la pantalla —
//   Mientras el campo de búsqueda está vacío, se muestra una lista
//   de hasta 15 perfiles activos que el usuario todavía NO sigue
//   (y que no es él mismo), bajo el encabezado "Sugerencias para ti".
//   En cuanto el usuario empieza a escribir, esa lista se reemplaza
//   por los resultados de búsqueda de siempre.
//
// ── AJUSTA ESTO SI TU ESQUEMA DIFIERE ───────────────────────────────
// _tablaSeguidores / _columnaSeguidor / _columnaSeguido asumen una
// tabla de "seguir" con esos nombres (no se vio en ningún archivo
// anterior). Si tu tabla real se llama distinto, es el único cambio
// que hace falta — todo lo demás sigue funcionando igual.
// ═════════════════════════════════════════════════════════════════

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../servicios_storage/url_helper.dart';
import 'navegacion_perfil.dart';

class BusquedaUsuarios extends StatefulWidget {
  final bool isDark;

  const BusquedaUsuarios({super.key, required this.isDark});

  @override
  State<BusquedaUsuarios> createState() => _BusquedaUsuariosState();
}

class _BusquedaUsuariosState extends State<BusquedaUsuarios> {
  static const Color _accent = Color(0xFF007AFF);

  // ── Ajusta estos 3 valores si el nombre real de tu tabla/columnas
  // de "seguir" es distinto. Ver nota de encabezado. ────────────────
  static const String _tablaSeguidores = 'seguidores_aspirantes';
  static const String _columnaSeguidor = 'seguidor_id'; // quién sigue
  static const String _columnaSeguido  = 'seguido_id';  // a quién sigue

  final _controller = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _resultados = [];
  bool _cargando = false;
  String _query = '';

  // ── Sugerencias (usuarios aún no seguidos) ─────────────────────
  List<Map<String, dynamic>> _sugeridos = [];
  bool _cargandoSugeridos = true;

  @override
  void initState() {
    super.initState();
    _cargarSugeridos();
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String texto) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _buscar(texto));
  }

  /// Quita caracteres que romperían la sintaxis del filtro .or()/.not()
  /// de PostgREST (coma y paréntesis son separadores estructurales de
  /// esos filtros). Sin esto, un término de búsqueda con una coma
  /// hace que la query truene silenciosamente en vez de buscar algo.
  String _sanearTermino(String texto) {
    return texto.replaceAll(RegExp(r'[,()]'), '');
  }

  Future<void> _buscar(String texto) async {
    final termino = texto.trim();
    setState(() => _query = termino);

    if (termino.isEmpty) {
      setState(() => _resultados = []);
      return;
    }

    setState(() => _cargando = true);
    try {
      final terminoSeguro = _sanearTermino(termino);
      final data = await Supabase.instance.client
          .from('perfiles_aspirantes')
          .select('id, nombre, nombre_usuario, cdn_foto_perfil, carreras ( nombre )')
          .or('nombre.ilike.%$terminoSeguro%,nombre_usuario.ilike.%$terminoSeguro%')
          .eq('estado_cuenta', 'activo')
          .limit(20);

      if (!mounted || _query != termino) return;
      setState(() {
        _resultados = List<Map<String, dynamic>>.from(data as List);
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  /// Carga hasta 15 perfiles activos que el usuario actual todavía no
  /// sigue (y que no es él mismo), para mostrarlos como sugerencia
  /// mientras el campo de búsqueda está vacío.
  Future<void> _cargarSugeridos() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      setState(() => _cargandoSugeridos = false);
      return;
    }

    try {
      // 1. IDs de las personas que el usuario ya sigue, para excluirlas.
      final siguiendo = await Supabase.instance.client
          .from(_tablaSeguidores)
          .select(_columnaSeguido)
          .eq(_columnaSeguidor, uid);

      final idsSeguidos = (siguiendo as List)
          .map((f) => f[_columnaSeguido] as String)
          .toList();

      // 2. Perfiles activos, excluyendo al propio usuario y a quienes
      //    ya sigue. El filtro .not('in', ...) se agrega solo si la
      //    lista no está vacía — con lista vacía, "(...)" rompe la
      //    sintaxis del filtro.
      final baseQuery = Supabase.instance.client
          .from('perfiles_aspirantes')
          .select('id, nombre, nombre_usuario, cdn_foto_perfil, carreras ( nombre )')
          .eq('estado_cuenta', 'activo')
          .neq('id', uid);

      final data = await (idsSeguidos.isEmpty
          ? baseQuery.limit(15)
          : baseQuery.not('id', 'in', '(${idsSeguidos.join(',')})').limit(15));

      if (!mounted) return;
      setState(() {
        _sugeridos = List<Map<String, dynamic>>.from(data as List);
        _cargandoSugeridos = false;
      });
    } catch (_) {
      // Se ignora — si falla, simplemente no se muestran sugerencias
      // y la pantalla se comporta como antes (solo búsqueda manual).
      if (!mounted) return;
      setState(() => _cargandoSugeridos = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final bg = isDark ? Colors.black : const Color(0xFFF2F2F7);
    final bgInput = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    // Mientras no hay texto de búsqueda, se muestra la lista de
    // sugeridos en vez de los resultados de búsqueda.
    final mostrandoSugeridos = _query.isEmpty;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        title: Text('Buscar usuarios',
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: bgInput,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _onChanged,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Nombre o @usuario',
                  hintStyle: TextStyle(color: textPrimary.withValues(alpha: 0.4)),
                  prefixIcon: Icon(CupertinoIcons.search, color: textPrimary.withValues(alpha: 0.4)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // ── Encabezado de sección ──────────────────────────────
          if (mostrandoSugeridos && (_cargandoSugeridos || _sugeridos.isNotEmpty))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'SUGERENCIAS PARA TI',
                  style: TextStyle(
                    color:         textPrimary.withValues(alpha: 0.38),
                    fontSize:      11,
                    fontWeight:    FontWeight.w600,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),

          if (!mostrandoSugeridos && _cargando)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: CircularProgressIndicator(),
            ),

          if (mostrandoSugeridos && _cargandoSugeridos)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: CircularProgressIndicator(),
            ),

          if (!mostrandoSugeridos && !_cargando && _resultados.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Text('No se encontraron usuarios',
                  style: TextStyle(color: textPrimary.withValues(alpha: 0.5))),
            ),

          if (mostrandoSugeridos && !_cargandoSugeridos && _sugeridos.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Text('No hay sugerencias por ahora',
                  style: TextStyle(color: textPrimary.withValues(alpha: 0.5))),
            ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: mostrandoSugeridos ? _sugeridos.length : _resultados.length,
              itemBuilder: (context, i) {
                final perfil = mostrandoSugeridos ? _sugeridos[i] : _resultados[i];
                return _tileUsuario(perfil, isDark, textPrimary);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Tile reutilizable para un perfil, usado tanto en la lista de
  /// sugerencias como en los resultados de búsqueda.
  Widget _tileUsuario(
      Map<String, dynamic> perfil,
      bool isDark,
      Color textPrimary,
      ) {
    final carrera = perfil['carreras'] as Map<String, dynamic>?;
    final fotoUrl = resolverUrlPerfil(perfil);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: _accent.withValues(alpha: 0.15),
        backgroundImage: fotoUrl.isNotEmpty ? CachedNetworkImageProvider(fotoUrl) : null,
        child: fotoUrl.isEmpty
            ? Icon(CupertinoIcons.person_fill, color: _accent, size: 18)
            : null,
      ),
      title: Text(perfil['nombre'] as String? ?? 'Aspirante',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600)),
      subtitle: Text(
        ['@${perfil['nombre_usuario'] ?? ''}', if (carrera?['nombre'] != null) carrera!['nombre']].join(' · '),
        style: TextStyle(color: textPrimary.withValues(alpha: 0.5), fontSize: 12),
      ),
      onTap: () => abrirPerfil(
        context,
        perfilId: perfil['id'] as String,
        isDark: isDark,
      ),
    );
  }
}