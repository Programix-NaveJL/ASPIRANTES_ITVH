// ═════════════════════════════════════════════════════════════════
// hoja_comentarios.dart — Aspirantes ITVH
//
// Modal deslizable con los comentarios de una publicación. Soporta
// un nivel de respuestas (parent_id): los comentarios raíz se listan
// en orden cronológico, y las respuestas se muestran indentadas
// justo debajo de su comentario padre.
//
// Avatar y nombre de cada comentario son tocables: cierran la hoja
// y navegan al perfil del autor vía navegacion_perfil.dart (propio
// o público según corresponda). autor_id viene plano en la fila de
// `comentarios` (no dentro del join a perfiles_aspirantes), por eso
// se lee directo de cada comentario `c['autor_id']`.
// ═════════════════════════════════════════════════════════════════

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../servicios_storage/url_helper.dart';
import 'navegacion_perfil.dart';

class HojaComentarios extends StatefulWidget {
  final String publicacionId;
  final bool isDark;

  const HojaComentarios({
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
      builder: (_) => HojaComentarios(publicacionId: publicacionId, isDark: isDark),
    );
  }

  @override
  State<HojaComentarios> createState() => _HojaComentariosState();
}

class _HojaComentariosState extends State<HojaComentarios> {
  static const Color _accent = Color(0xFF007AFF);

  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  List<Map<String, dynamic>> _comentarios = [];
  bool _cargando = true;
  bool _enviando = false;
  String? _error;
  Map<String, dynamic>? _respondiendoA;

  @override
  void initState() {
    super.initState();
    _cargarComentarios();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _cargarComentarios() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final data = await Supabase.instance.client
          .from('comentarios')
          .select('''
            id, contenido, creado_en, parent_id, autor_id,
            perfiles_aspirantes ( nombre, cdn_foto_perfil )
          ''')
          .eq('publicacion_id', widget.publicacionId)
          .order('creado_en', ascending: true);

      if (!mounted) return;
      setState(() {
        _comentarios = List<Map<String, dynamic>>.from(data as List);
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar los comentarios';
        _cargando = false;
      });
    }
  }

  Future<void> _enviarComentario() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty || _enviando) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _enviando = true);
    try {
      await Supabase.instance.client.from('comentarios').insert({
        'publicacion_id': widget.publicacionId,
        'autor_id': userId,
        'contenido': texto,
        'parent_id': _respondiendoA?['id'],
      });
      _controller.clear();
      _respondiendoA = null;
      await _cargarComentarios();
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo enviar el comentario')),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  List<Map<String, dynamic>> get _raiz =>
      _comentarios.where((c) => c['parent_id'] == null).toList();

  List<Map<String, dynamic>> _respuestasDe(String id) =>
      _comentarios.where((c) => c['parent_id'] == id).toList();

  /// Cierra la hoja de comentarios y navega al perfil del autor
  /// tocado (propio o público, resuelto por navegacion_perfil.dart).
  void _abrirPerfilDe(String? autorId) {
    if (autorId == null) return;
    Navigator.of(context).pop();
    abrirPerfil(context, perfilId: autorId, isDark: widget.isDark);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final bg = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollCtl) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 100),
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
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
                  child: Text('Comentarios',
                      style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                const Divider(height: 1),
                Expanded(child: _cuerpo(textPrimary)),
                _barraEntrada(isDark, textPrimary),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _cuerpo(Color textPrimary) {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: TextStyle(color: textPrimary.withValues(alpha: 0.6))),
            const SizedBox(height: 8),
            TextButton(onPressed: _cargarComentarios, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    if (_raiz.isEmpty) {
      return Center(
        child: Text('Sé el primero en comentar',
            style: TextStyle(color: textPrimary.withValues(alpha: 0.5))),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      itemCount: _raiz.length,
      itemBuilder: (context, i) {
        final comentario = _raiz[i];
        final respuestas = _respuestasDe(comentario['id'] as String);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _burbuja(comentario, textPrimary, esRespuesta: false),
            for (final r in respuestas)
              Padding(
                padding: const EdgeInsets.only(left: 36),
                child: _burbuja(r, textPrimary, esRespuesta: true),
              ),
          ],
        );
      },
    );
  }

  Widget _burbuja(Map<String, dynamic> c, Color textPrimary, {required bool esRespuesta}) {
    final perfil = c['perfiles_aspirantes'] as Map<String, dynamic>?;
    final fotoUrl = perfil != null ? resolverUrlPerfil(perfil) : '';
    final nombre = perfil?['nombre'] as String? ?? 'Aspirante';
    final autorId = c['autor_id'] as String?;
    final creadoEn = DateTime.tryParse(c['creado_en'] as String? ?? '');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _abrirPerfilDe(autorId),
            child: CircleAvatar(
              radius: esRespuesta ? 14 : 17,
              backgroundColor: _accent.withValues(alpha: 0.15),
              backgroundImage: fotoUrl.isNotEmpty ? CachedNetworkImageProvider(fotoUrl) : null,
              child: fotoUrl.isEmpty
                  ? Icon(CupertinoIcons.person_fill, color: _accent, size: esRespuesta ? 12 : 15)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _abrirPerfilDe(autorId),
                  child: Text(nombre,
                      style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
                const SizedBox(height: 2),
                Text(c['contenido'] as String? ?? '',
                    style: TextStyle(color: textPrimary, fontSize: 14, height: 1.3)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (creadoEn != null)
                      Text(timeago.format(creadoEn, locale: 'es'),
                          style: TextStyle(color: textPrimary.withValues(alpha: 0.4), fontSize: 11)),
                    if (!esRespuesta) ...[
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: () => setState(() => _respondiendoA = c),
                        child: Text('Responder',
                            style: TextStyle(
                                color: textPrimary.withValues(alpha: 0.4),
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _barraEntrada(bool isDark, Color textPrimary) {
    final bgInput = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_respondiendoA != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Row(
                  children: [
                    Text(
                      'Respondiendo a ${(_respondiendoA?['perfiles_aspirantes'] as Map?)?['nombre'] ?? 'comentario'}',
                      style: TextStyle(color: textPrimary.withValues(alpha: 0.5), fontSize: 12),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => setState(() => _respondiendoA = null),
                      child: Icon(CupertinoIcons.xmark_circle_fill,
                          size: 14, color: textPrimary.withValues(alpha: 0.4)),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgInput,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(color: textPrimary, fontSize: 14),
                      maxLength: 500,
                      minLines: 1,
                      maxLines: 4,
                      buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Escribe un comentario...',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _enviando
                    ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
                    : IconButton(
                  onPressed: _enviarComentario,
                  icon: const Icon(CupertinoIcons.arrow_up_circle_fill,
                      color: _accent, size: 30),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}