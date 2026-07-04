// ═════════════════════════════════════════════════════════════════
// hoja_reacciones.dart — Aspirantes ITVH
//
// Modal deslizable que lista los perfiles que reaccionaron a una
// publicación, con el ícono correspondiente a su tipo de reacción.
//
// Avatar y nombre de cada fila son tocables: cierran la hoja y
// navegan al perfil de quien reaccionó vía navegacion_perfil.dart
// (propio o público según corresponda). usuario_id viene plano en
// la fila de `reacciones` (no dentro del join a perfiles_aspirantes).
// ═════════════════════════════════════════════════════════════════

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../servicios_storage/url_helper.dart';
import 'navegacion_perfil.dart';

class HojaReacciones extends StatefulWidget {
  final String publicacionId;
  final bool isDark;

  const HojaReacciones({
    super.key,
    required this.publicacionId,
    required this.isDark,
  });

  static Future<void> mostrar(
      BuildContext context, {
        required String publicacionId,
        required bool isDark,
      }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HojaReacciones(publicacionId: publicacionId, isDark: isDark),
    );
  }

  @override
  State<HojaReacciones> createState() => _HojaReaccionesState();
}

class _HojaReaccionesState extends State<HojaReacciones> {
  static const Color _accent = Color(0xFF007AFF);

  List<Map<String, dynamic>> _reacciones = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final data = await Supabase.instance.client
          .from('reacciones')
          .select('''
            tipo, creado_en, usuario_id,
            perfiles_aspirantes ( nombre, cdn_foto_perfil )
          ''')
          .eq('publicacion_id', widget.publicacionId)
          .order('creado_en', ascending: false);

      if (!mounted) return;
      setState(() {
        _reacciones = List<Map<String, dynamic>>.from(data as List);
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar las reacciones';
        _cargando = false;
      });
    }
  }

  IconData _iconoDe(String? tipo) {
    switch (tipo) {
      case 'funny':   return CupertinoIcons.smiley_fill;
      case 'support': return CupertinoIcons.hand_thumbsup_fill;
      case 'love':
      case 'like':
      default:        return CupertinoIcons.heart_fill;
    }
  }

  Color _colorDe(String? tipo) {
    switch (tipo) {
      case 'funny':   return const Color(0xFFFFCC00);
      case 'support': return const Color(0xFF34C759);
      case 'love':
      case 'like':
      default:        return const Color(0xFFFF3B30);
    }
  }

  /// Cierra la hoja de reacciones y navega al perfil de quien
  /// reaccionó (propio o público, resuelto por navegacion_perfil.dart).
  void _abrirPerfilDe(String? usuarioId) {
    if (usuarioId == null) return;
    Navigator.of(context).pop();
    abrirPerfil(context, perfilId: usuarioId, isDark: widget.isDark);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final bg = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollCtl) {
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: textPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('Reacciones',
                    style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              const Divider(height: 1),
              Expanded(
                child: _cargando
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(
                    child: Text(_error!,
                        style: TextStyle(color: textPrimary.withValues(alpha: 0.6))))
                    : _reacciones.isEmpty
                    ? Center(
                    child: Text('Nadie ha reaccionado todavía',
                        style: TextStyle(color: textPrimary.withValues(alpha: 0.5))))
                    : ListView.builder(
                  controller: scrollCtl,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  itemCount: _reacciones.length,
                  itemBuilder: (context, i) {
                    final r = _reacciones[i];
                    final perfil = r['perfiles_aspirantes'] as Map<String, dynamic>?;
                    final fotoUrl = perfil != null ? resolverUrlPerfil(perfil) : '';
                    final nombre = perfil?['nombre'] as String? ?? 'Aspirante';
                    final tipo = r['tipo'] as String?;
                    final usuarioId = r['usuario_id'] as String?;

                    return GestureDetector(
                      onTap: () => _abrirPerfilDe(usuarioId),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: _accent.withValues(alpha: 0.15),
                                  backgroundImage: fotoUrl.isNotEmpty
                                      ? CachedNetworkImageProvider(fotoUrl)
                                      : null,
                                  child: fotoUrl.isEmpty
                                      ? Icon(CupertinoIcons.person_fill, color: _accent, size: 16)
                                      : null,
                                ),
                                Positioned(
                                  right: -2, bottom: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                                    child: Icon(_iconoDe(tipo), size: 11, color: _colorDe(tipo)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Text(nombre,
                                style: TextStyle(
                                    color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}