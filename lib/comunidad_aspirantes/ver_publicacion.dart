// ═════════════════════════════════════════════════════════════════
// ver_publicacion.dart — Aspirantes ITVH
//
// Pantalla de una sola publicación, usada como deep-link desde
// pagina_notificaciones.dart (like, comentario, respuesta,
// like_comentario). Reutiliza TarjetaPublicacion tal cual la usa
// page_home.dart, así que el look & feel y las hojas de comentarios/
// reacciones son idénticas a las del feed.
// ═════════════════════════════════════════════════════════════════

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'hoja_comentarios.dart';
import 'hoja_reacciones.dart';
import 'tarjeta_publicacion.dart';

class VerPublicacion extends StatefulWidget {
  final String publicacionId;
  final bool isDark;

  const VerPublicacion({
    super.key,
    required this.publicacionId,
    required this.isDark,
  });

  @override
  State<VerPublicacion> createState() => _VerPublicacionState();
}

class _VerPublicacionState extends State<VerPublicacion> {
  Map<String, dynamic>? _publicacion;
  List<Map<String, dynamic>> _medios = [];
  bool _yaReacciono = false;
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
      final post = await Supabase.instance.client
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
          .eq('id', widget.publicacionId)
          .maybeSingle();

      if (post == null) {
        if (!mounted) return;
        setState(() {
          _error = 'Esta publicación ya no está disponible.';
          _cargando = false;
        });
        return;
      }

      final medios = List<Map<String, dynamic>>.from(
          post['publicacion_medios'] as List? ?? []);
      medios.sort((a, b) =>
          ((a['orden'] as int?) ?? 0).compareTo((b['orden'] as int?) ?? 0));

      bool yaReacciono = false;
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final reaccion = await Supabase.instance.client
            .from('reacciones')
            .select('id')
            .eq('publicacion_id', widget.publicacionId)
            .eq('usuario_id', userId)
            .maybeSingle();
        yaReacciono = reaccion != null;
      }

      if (!mounted) return;
      setState(() {
        _publicacion = post;
        _medios = medios;
        _yaReacciono = yaReacciono;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar la publicación: $e';
        _cargando = false;
      });
    }
  }

  Future<void> _reaccionar(bool nuevoEstado) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    if (nuevoEstado) {
      await Supabase.instance.client.from('reacciones').insert({
        'publicacion_id': widget.publicacionId,
        'usuario_id': userId,
        'tipo': 'like',
      });
    } else {
      await Supabase.instance.client
          .from('reacciones')
          .delete()
          .eq('publicacion_id', widget.publicacionId)
          .eq('usuario_id', userId);
    }
    if (!mounted) return;
    setState(() => _yaReacciono = nuevoEstado);
  }

  void _abrirComentarios() {
    HojaComentarios.mostrar(context,
        publicacionId: widget.publicacionId, isDark: widget.isDark);
  }

  void _abrirReacciones() {
    HojaReacciones.mostrar(context,
        publicacionId: widget.publicacionId, isDark: widget.isDark);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textPrimary = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        title: Text('Publicación',
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.exclamationmark_triangle,
                  color: textPrimary.withValues(alpha: 0.4), size: 36),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textPrimary.withValues(alpha: 0.6))),
              const SizedBox(height: 12),
              TextButton(onPressed: _cargar, child: const Text('Reintentar')),
            ],
          ),
        ),
      )
          : ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          TarjetaPublicacion(
            publicacion: _publicacion!,
            medios: _medios,
            isDark: isDark,
            yaReacciono: _yaReacciono,
            onReaccionar: _reaccionar,
            onComentar: _abrirComentarios,
            onVerReacciones: _abrirReacciones,
          ),
        ],
      ),
    );
  }
}