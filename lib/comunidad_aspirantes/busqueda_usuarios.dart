// ═════════════════════════════════════════════════════════════════
// busqueda_usuarios.dart — Aspirantes ITVH
//
// Pantalla de búsqueda de perfiles por nombre o nombre de usuario.
// Búsqueda con debounce (400ms) para no disparar una query por
// cada tecla presionada. Al tocar un resultado, navega al perfil
// vía navegacion_perfil.dart (propio o público según corresponda).
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

  final _controller = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _resultados = [];
  bool _cargando = false;
  String _query = '';

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

  Future<void> _buscar(String texto) async {
    final termino = texto.trim();
    setState(() => _query = termino);

    if (termino.isEmpty) {
      setState(() => _resultados = []);
      return;
    }

    setState(() => _cargando = true);
    try {
      final data = await Supabase.instance.client
          .from('perfiles_aspirantes')
          .select('id, nombre, nombre_usuario, cdn_foto_perfil, carreras ( nombre )')
          .or('nombre.ilike.%$termino%,nombre_usuario.ilike.%$termino%')
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

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final bg = isDark ? Colors.black : const Color(0xFFF2F2F7);
    final bgInput = isDark ? const Color(0xFF1C1C1E) : Colors.white;

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
          if (_cargando) const Padding(
            padding: EdgeInsets.only(top: 20),
            child: CircularProgressIndicator(),
          ),
          if (!_cargando && _query.isNotEmpty && _resultados.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Text('No se encontraron usuarios',
                  style: TextStyle(color: textPrimary.withValues(alpha: 0.5))),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _resultados.length,
              itemBuilder: (context, i) {
                final perfil = _resultados[i];
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
              },
            ),
          ),
        ],
      ),
    );
  }
}