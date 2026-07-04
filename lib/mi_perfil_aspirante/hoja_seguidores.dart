// ═════════════════════════════════════════════════════════════════
// hoja_seguidores.dart — Aspirantes ITVH
//
// Bottom sheet con dos pestañas: "Seguidores" y "Seguidos", para un
// perfilId dado (propio o ajeno). Mismo patrón que HojaComentarios /
// HojaReacciones: método estático `mostrar()` que abre un
// showModalBottomSheet con DraggableScrollableSheet.
//
// Cada fila es tappable: navega al perfil de esa persona
// (PerfilPublicoAspirante) — si esa persona es el usuario actual,
// en teoría podríamos navegar a MiPerfilAspirante, pero se deja
// simple por ahora y siempre usa PerfilPublicoAspirante, que ya
// internamente detecta _esMiPropioPerfil y oculta el botón Seguir.
//
// Consulta en dos pasos (igual que _misReacciones en las pantallas
// de perfil): primero traemos los ids desde `seguidores`, luego
// pedimos los perfiles con inFilter. Evita depender del nombre
// exacto de la FK para hacer un embed directo.
// ═════════════════════════════════════════════════════════════════

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../servicios_storage/url_helper.dart';
import 'perfil_publico_aspirante.dart';

class HojaSeguidores {
  /// [tabInicial] = 0 → Seguidores, 1 → Seguidos.
  static Future<void> mostrar(
      BuildContext context, {
        required String perfilId,
        required bool isDark,
        int tabInicial = 0,
      }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HojaSeguidoresContenido(
        perfilId: perfilId,
        isDark: isDark,
        tabInicial: tabInicial,
      ),
    );
  }
}

class _HojaSeguidoresContenido extends StatefulWidget {
  final String perfilId;
  final bool isDark;
  final int tabInicial;

  const _HojaSeguidoresContenido({
    required this.perfilId,
    required this.isDark,
    required this.tabInicial,
  });

  @override
  State<_HojaSeguidoresContenido> createState() => _HojaSeguidoresContenidoState();
}

class _HojaSeguidoresContenidoState extends State<_HojaSeguidoresContenido> {
  static const Color _accent = Color(0xFF007AFF);

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final divColor = isDark ? Colors.white10 : Colors.black12;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return DefaultTabController(
          length: 2,
          initialIndex: widget.tabInicial,
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: divColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 8),
                TabBar(
                  labelColor: _accent,
                  unselectedLabelColor: textPrimary.withValues(alpha: 0.5),
                  indicatorColor: _accent,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  tabs: const [
                    Tab(text: 'Seguidores'),
                    Tab(text: 'Seguidos'),
                  ],
                ),
                Divider(height: 0.5, thickness: 0.5, color: divColor),
                Expanded(
                  child: TabBarView(
                    children: [
                      _ListaPersonas(
                        key: ValueKey('seguidores-${widget.perfilId}'),
                        perfilId: widget.perfilId,
                        modo: _ModoLista.seguidores,
                        isDark: isDark,
                      ),
                      _ListaPersonas(
                        key: ValueKey('seguidos-${widget.perfilId}'),
                        perfilId: widget.perfilId,
                        modo: _ModoLista.seguidos,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

enum _ModoLista { seguidores, seguidos }

class _ListaPersonas extends StatefulWidget {
  final String perfilId;
  final _ModoLista modo;
  final bool isDark;

  const _ListaPersonas({
    super.key,
    required this.perfilId,
    required this.modo,
    required this.isDark,
  });

  @override
  State<_ListaPersonas> createState() => _ListaPersonasState();
}

class _ListaPersonasState extends State<_ListaPersonas> {
  static const int _pageSize = 20;

  final _scrollController = ScrollController();
  final List<Map<String, dynamic>> _personas = [];

  bool _cargando = true;
  bool _cargandoMas = false;
  bool _hayMas = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _cargar(inicial: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hayMas || _cargandoMas) return;
    final umbral = _scrollController.position.maxScrollExtent - 200;
    if (_scrollController.position.pixels >= umbral) {
      _cargar();
    }
  }

  Future<void> _cargar({bool inicial = false}) async {
    if (inicial) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    } else {
      if (_cargandoMas || !_hayMas) return;
      setState(() => _cargandoMas = true);
    }

    try {
      final desde = inicial ? 0 : _personas.length;
      final hasta = desde + _pageSize - 1;

      // Paso 1: ids relevantes desde `seguidores`, según el modo.
      final columnaFiltro = widget.modo == _ModoLista.seguidores ? 'seguido_id' : 'seguidor_id';
      final columnaId = widget.modo == _ModoLista.seguidores ? 'seguidor_id' : 'seguido_id';

      final filas = await Supabase.instance.client
          .from('seguidores')
          .select(columnaId)
          .eq(columnaFiltro, widget.perfilId)
          .order('creado_en', ascending: false)
          .range(desde, hasta);

      final ids = (filas as List).map((f) => f[columnaId] as String).toList();

      List<Map<String, dynamic>> perfiles = [];
      if (ids.isNotEmpty) {
        final data = await Supabase.instance.client
            .from('perfiles_aspirantes')
            .select('id, nombre, nombre_usuario, cdn_foto_perfil, carreras ( nombre )')
            .inFilter('id', ids);
        // Reordenar según el orden de `ids` (inFilter no garantiza orden).
        final porId = {for (final p in (data as List)) p['id'] as String: p as Map<String, dynamic>};
        perfiles = ids.map((id) => porId[id]).whereType<Map<String, dynamic>>().toList();
      }

      if (!mounted) return;
      setState(() {
        if (inicial) _personas.clear();
        _personas.addAll(perfiles);
        _hayMas = ids.length == _pageSize;
        _cargando = false;
        _cargandoMas = false;
      });
    } catch (e) {
      debugPrint('HojaSeguidores – cargar (${widget.modo}): $e');
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _cargandoMas = false;
        if (inicial) _error = 'No se pudo cargar la lista.';
      });
    }
  }

  void _abrirPerfil(String id) {
    Navigator.of(context).pop(); // cierra la hoja
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PerfilPublicoAspirante(perfilId: id, isDark: widget.isDark),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final textSec = textPrimary.withValues(alpha: 0.5);

    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: TextStyle(color: textSec)),
      );
    }
    if (_personas.isEmpty) {
      final mensaje = widget.modo == _ModoLista.seguidores
          ? 'Nadie sigue a este perfil todavía.'
          : 'Este perfil no sigue a nadie todavía.';
      return Center(
        child: Text(mensaje, style: TextStyle(color: textSec)),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: _personas.length + (_hayMas ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _personas.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final p = _personas[index];
        final id = p['id'] as String;
        final nombre = p['nombre'] as String? ?? '';
        final usuario = p['nombre_usuario'] as String? ?? '';
        final carrera = (p['carreras'] as Map<String, dynamic>?)?['nombre'] as String?;
        final fotoUrl = resolverUrlPerfil(p);

        return ListTile(
          onTap: () => _abrirPerfil(id),
          leading: ClipOval(
            child: SizedBox(
              width: 44,
              height: 44,
              child: fotoUrl.isNotEmpty
                  ? Image.network(
                fotoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(CupertinoIcons.person_fill, color: textSec),
              )
                  : Icon(CupertinoIcons.person_fill, color: textSec),
            ),
          ),
          title: Text(
            nombre.isEmpty ? 'Aspirante' : nombre,
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 14.5),
          ),
          subtitle: Text(
            [
              if (usuario.isNotEmpty) '@$usuario',
              if (carrera != null) carrera,
            ].join(' · '),
            style: TextStyle(color: textSec, fontSize: 12.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Icon(CupertinoIcons.chevron_right, size: 16, color: textSec),
        );
      },
    );
  }
}