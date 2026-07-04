// ═════════════════════════════════════════════════════════════════
// pagina_notificaciones.dart — Aspirantes ITVH
//
// Lista de notificaciones del usuario actual (likes, comentarios,
// respuestas, nuevos seguidores). Al abrir la pantalla se marcan
// todas como leídas.
//
// Navegación al tocar una notificación:
//   • 'seguidor'                       → PerfilPublicoAspirante (origen_id)
//   • 'like' / 'comentario' / etc.     → VerPublicacion (publicacion_id)
// ═════════════════════════════════════════════════════════════════

import 'package:aspirantes_itvh_app/comunidad_aspirantes/ver_publicacion.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../mi_perfil_aspirante/perfil_publico_aspirante.dart'; // ajusta la ruta según tu estructura
import '../servicios_storage/url_helper.dart';

class PaginaNotificaciones extends StatefulWidget {
  final bool isDark;

  const PaginaNotificaciones({super.key, required this.isDark});

  @override
  State<PaginaNotificaciones> createState() => _PaginaNotificacionesState();
}

class _PaginaNotificacionesState extends State<PaginaNotificaciones> {
  static const Color _accent = Color(0xFF007AFF);

  List<Map<String, dynamic>> _notificaciones = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final data = await Supabase.instance.client
          .from('notificaciones')
          .select('''
          id, tipo, leida, creado_en, publicacion_id, origen_id,
          perfiles_aspirantes!notificaciones_origen_id_fkey ( nombre, cdn_foto_perfil ),
          publicaciones (
            id,
            publicacion_medios ( cdn_url, url, tipo_medio, orden )
          )
        ''')
          .eq('destinatario_id', userId)
          .order('creado_en', ascending: false)
          .limit(50);

      if (!mounted) return;
      setState(() {
        _notificaciones = List<Map<String, dynamic>>.from(data as List);
        _cargando = false;
      });

      _marcarTodasLeidas(userId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar las notificaciones';
        _cargando = false;
      });
    }
  }

  Future<void> _marcarTodasLeidas(String userId) async {
    try {
      await Supabase.instance.client
          .from('notificaciones')
          .update({'leida': true})
          .eq('destinatario_id', userId)
          .eq('leida', false);
    } catch (_) {
      // silencioso: no es crítico si falla el marcado de leídas
    }
  }

  Map<String, String?> _miniaturaDe(Map<String, dynamic> n) {
    final publicacionData = n['publicaciones'] as Map<String, dynamic>?;
    if (publicacionData == null) return {'url': null, 'tipoMedio': null};

    final medios = List<Map<String, dynamic>>.from(
        publicacionData['publicacion_medios'] as List? ?? []);
    if (medios.isEmpty) return {'url': null, 'tipoMedio': null};

    medios.sort((a, b) =>
        ((a['orden'] as int?) ?? 0).compareTo((b['orden'] as int?) ?? 0));

    final primero = medios.first;
    return {
      'url': (primero['cdn_url'] as String?) ?? (primero['url'] as String?),
      'tipoMedio': primero['tipo_medio'] as String?,
    };
  }

  Widget _miniaturaWidget(String? url, String? tipoMedio) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 46,
        height: 46,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: _accent.withValues(alpha: 0.08)),
              errorWidget: (_, __, ___) => Container(
                color: _accent.withValues(alpha: 0.08),
                child: Icon(CupertinoIcons.photo, size: 16, color: _accent),
              ),
            ),
            if (tipoMedio == 'video')
              Container(
                color: Colors.black26,
                alignment: Alignment.center,
                child: const Icon(CupertinoIcons.play_fill,
                    color: Colors.white, size: 14),
              ),
          ],
        ),
      ),
    );
  }

  String _textoDe(String? tipo) {
    switch (tipo) {
      case 'like': return 'reaccionó a tu publicación';
      case 'comentario': return 'comentó tu publicación';
      case 'respuesta': return 'respondió a tu comentario';
      case 'seguidor': return 'comenzó a seguirte';
      case 'like_historia': return 'reaccionó a tu historia';
      case 'comentario_historia': return 'comentó tu historia';
      case 'like_comentario': return 'le gustó tu comentario';
      default: return 'tiene una actualización para ti';
    }
  }

  IconData _iconoDe(String? tipo) {
    switch (tipo) {
      case 'like':
      case 'like_historia':
      case 'like_comentario': return CupertinoIcons.heart_fill;
      case 'comentario':
      case 'comentario_historia':
      case 'respuesta': return CupertinoIcons.chat_bubble_fill;
      case 'seguidor': return CupertinoIcons.person_add_solid;
      default: return CupertinoIcons.bell_fill;
    }
  }

  /// Navega según el tipo de notificación:
  ///   • 'seguidor' → perfil de quien originó la notificación (origen_id)
  ///   • el resto   → la publicación involucrada (publicacion_id), si existe
  void _abrirDestino(Map<String, dynamic> n) {
    final tipo = n['tipo'] as String?;
    final origenId = n['origen_id'] as String?;
    final publicacionId = n['publicacion_id'] as String?;

    if (tipo == 'seguidor') {
      if (origenId == null) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PerfilPublicoAspirante(
            perfilId: origenId,
            isDark: widget.isDark,
          ),
        ),
      );
      return;
    }

    if (publicacionId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VerPublicacion(
          publicacionId: publicacionId,
          isDark: widget.isDark,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final bg = isDark ? Colors.black : const Color(0xFFF2F2F7);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        title: Text('Notificaciones',
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: TextStyle(color: textPrimary.withValues(alpha: 0.6))),
            const SizedBox(height: 8),
            TextButton(onPressed: _cargar, child: const Text('Reintentar')),
          ],
        ),
      )
          : _notificaciones.isEmpty
          ? Center(
        child: Text('No tienes notificaciones todavía',
            style: TextStyle(color: textPrimary.withValues(alpha: 0.5))),
      )
          : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _notificaciones.length,
        itemBuilder: (context, i) {
          final n = _notificaciones[i];
          final perfil = n['perfiles_aspirantes'] as Map<String, dynamic>?;
          final fotoUrl = perfil != null ? resolverUrlPerfil(perfil) : '';
          final nombre = perfil?['nombre'] as String? ?? 'Alguien';
          final creadoEn = DateTime.tryParse(n['creado_en'] as String? ?? '');
          final leida = n['leida'] as bool? ?? true;
          final tipo = n['tipo'] as String?;
          final esSeguidor = tipo == 'seguidor';
          final miniatura = _miniaturaDe(n);

          return ListTile(
            contentPadding: EdgeInsets.zero,
            onTap: () => _abrirDestino(n),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _accent.withValues(alpha: 0.15),
                  backgroundImage: fotoUrl.isNotEmpty
                      ? CachedNetworkImageProvider(fotoUrl)
                      : null,
                  child: fotoUrl.isEmpty
                      ? Icon(CupertinoIcons.person_fill, color: _accent, size: 18)
                      : null,
                ),
                Positioned(
                  right: -2, bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                    child: Icon(_iconoDe(tipo), size: 11, color: _accent),
                  ),
                ),
              ],
            ),
            title: RichText(
              text: TextSpan(
                style: TextStyle(color: textPrimary, fontSize: 14),
                children: [
                  TextSpan(text: '$nombre ', style: const TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: _textoDe(tipo)),
                ],
              ),
            ),
            subtitle: creadoEn != null
                ? Text(timeago.format(creadoEn, locale: 'es'),
                style: TextStyle(color: textPrimary.withValues(alpha: 0.4), fontSize: 12))
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!leida) ...[
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: _accent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                ],
                // Sin miniatura de post para 'seguidor' — en su lugar,
                // una flecha para dejar claro que también es tappable
                // (lleva al perfil de quien te siguió).
                if (esSeguidor)
                  Icon(CupertinoIcons.chevron_right,
                      size: 15, color: textPrimary.withValues(alpha: 0.25))
                else if (miniatura['url'] != null)
                  _miniaturaWidget(miniatura['url'], miniatura['tipoMedio']),
              ],
            ),
          );
        },
      ),
    );
  }
}