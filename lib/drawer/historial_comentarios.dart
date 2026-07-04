// ═════════════════════════════════════════════════════════════════
// historial_comentarios.dart — Aspirantes ITVH
//
// Muestra todos los comentarios que el usuario ha hecho, agrupados
// por fecha (Hoy / Esta semana / Anteriores). Cada publicación se
// renderiza con TarjetaPublicacion (la misma tarjeta del feed);
// el ícono de comentar abre HojaComentarios y el contador de
// reacciones abre HojaReacciones, igual que en el feed.
//
// Clases principales:
//   • _ItemComentario            — modelo de datos de un comentario
//   • HistorialComentariosScreen — pantalla principal con lista agrupada
//
// Widgets privados:
//   • _EstadoVacio — placeholder cuando no hay comentarios
// ═════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// TODO: ajusta estas rutas relativas según dónde coloques este archivo
// respecto a la carpeta comunidad_aspirantes/.
import '../comunidad_aspirantes/tarjeta_publicacion.dart';
import '../comunidad_aspirantes/hoja_comentarios.dart';
import '../comunidad_aspirantes/hoja_reacciones.dart';

// Instancia global del cliente Supabase compartida por todas las
// clases privadas del archivo.
final _sb = Supabase.instance.client;


// ═════════════════════════════════════════════════════════════════
// MODELO
// ═════════════════════════════════════════════════════════════════

/// Representa un comentario del usuario junto con la publicación
/// completa lista para pasarle directo a [TarjetaPublicacion].
///
/// [esRespuesta] es true cuando el comentario tiene parent_id (es una
/// respuesta a otro comentario), false si es un comentario de primer nivel.
class _ItemComentario {
  final String   id;
  final String   contenido;       // texto del comentario del usuario
  final DateTime creadoEn;
  final String   publicacionId;
  final bool     esRespuesta;     // parent_id != null
  final Map<String, dynamic> postData;

  const _ItemComentario({
    required this.id,
    required this.contenido,
    required this.creadoEn,
    required this.publicacionId,
    required this.esRespuesta,
    required this.postData,
  });

  /// Construye un [_ItemComentario] a partir de la fila cruda de Supabase.
  ///
  /// [postData] se arma con la misma forma que devuelve el feed:
  /// `perfiles_aspirantes` ya viene con el nombre correcto de la FK
  /// (publicaciones_autor_id_fkey → perfiles_aspirantes), así que
  /// TarjetaPublicacion lo consume sin adaptadores.
  factory _ItemComentario.fromMap(Map<String, dynamic> map) {
    final pub = map['publicaciones'] as Map<String, dynamic>? ?? {};

    final medios = ((pub['publicacion_medios'] as List?) ?? [])
        .cast<Map<String, dynamic>>();
    medios.sort((a, b) =>
        (a['orden'] as int? ?? 0).compareTo(b['orden'] as int? ?? 0));

    final postMap = Map<String, dynamic>.from(pub);
    postMap['id']                 = map['publicacion_id'];
    postMap['publicacion_medios'] = medios;
    // Se desconoce si el usuario reaccionó a esta publicación específica;
    // TarjetaPublicacion recalcula el estado local al tocar el ícono.
    postMap['yo_di_like'] = false;

    return _ItemComentario(
      id:            map['id'] as String,
      contenido:     map['contenido'] as String? ?? '',
      creadoEn:      DateTime.tryParse(map['creado_en'] as String? ?? '') ?? DateTime.now(),
      publicacionId: map['publicacion_id'] as String,
      esRespuesta:   map['parent_id'] != null,
      postData:      postMap,
    );
  }
}


// ═════════════════════════════════════════════════════════════════
// PANTALLA
// ═════════════════════════════════════════════════════════════════

class HistorialComentariosScreen extends StatefulWidget {
  final bool isDark;
  const HistorialComentariosScreen({super.key, required this.isDark});

  @override
  State<HistorialComentariosScreen> createState() =>
      _HistorialComentariosScreenState();
}

class _HistorialComentariosScreenState
    extends State<HistorialComentariosScreen> {
  List<_ItemComentario> _items    = [];
  bool                  _cargando = true;

  // El UID puede ser null si la sesión expiró entre navegaciones.
  String? get _uid => _sb.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _cargar();
  }


  // ─────────────────────────────────────────────────────────────
  // CARGA DE DATOS
  // ─────────────────────────────────────────────────────────────

  /// Consulta los 200 comentarios más recientes del usuario autenticado,
  /// incluyendo datos anidados de la publicación (autor, carrera, medios).
  Future<void> _cargar() async {
    if (_uid == null) return;
    setState(() => _cargando = true);
    try {
      final res = await _sb
          .from('comentarios')
          .select(
        'id, contenido, creado_en, publicacion_id, parent_id, '
            'publicaciones!comentarios_publicacion_id_fkey('
            'autor_id, contenido, tipo, total_reacciones, total_comentarios, '
            'perfiles_aspirantes!publicaciones_autor_id_fkey'
            '(nombre, nombre_usuario, cdn_foto_perfil, carreras(nombre)), '
            'publicacion_medios(url, cdn_url, tipo_medio, orden)'
            ')',
      )
          .eq('autor_id', _uid!)
          .order('creado_en', ascending: false)
          .limit(200);

      final lista = (res as List)
          .cast<Map<String, dynamic>>()
          .map(_ItemComentario.fromMap)
          .toList();

      if (mounted) setState(() { _items = lista; _cargando = false; });
    } catch (e) {
      debugPrint('HistorialComentarios – cargar: $e');
      if (mounted) setState(() => _cargando = false);
    }
  }


  // ─────────────────────────────────────────────────────────────
  // AGRUPACIÓN Y FORMATO
  // ─────────────────────────────────────────────────────────────

  /// Agrupa los comentarios en tres buckets temporales:
  ///   • Hoy         — menos de 24 horas
  ///   • Esta semana — entre 1 y 6 días
  ///   • Anteriores  — 7 días o más
  Map<String, List<_ItemComentario>> _agruparPorFecha() {
    final hoy      = <_ItemComentario>[];
    final semana   = <_ItemComentario>[];
    final antiguas = <_ItemComentario>[];
    final ahora    = DateTime.now();

    for (final n in _items) {
      final diff = ahora.difference(n.creadoEn);
      if (diff.inHours < 24)    { hoy.add(n); }
      else if (diff.inDays < 7) { semana.add(n); }
      else                      { antiguas.add(n); }
    }

    return {
      if (hoy.isNotEmpty)      'Hoy':         hoy,
      if (semana.isNotEmpty)   'Esta semana': semana,
      if (antiguas.isNotEmpty) 'Anteriores':  antiguas,
    };
  }

  /// Devuelve una cadena legible relativa al momento actual.
  String _tiempo(DateTime fecha) {
    final diff = DateTime.now().difference(fecha);
    if (diff.inSeconds < 60) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours   < 24) return 'hace ${diff.inHours} h';
    if (diff.inDays   == 1)  return 'ayer';
    if (diff.inDays    < 7)  return 'hace ${diff.inDays} d';
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }


  // ─────────────────────────────────────────────────────────────
  // ACCIONES SOBRE LA PUBLICACIÓN
  // ─────────────────────────────────────────────────────────────

  /// Inserta o elimina la reacción del usuario sobre una publicación.
  /// Usado como callback `onReaccionar` de [TarjetaPublicacion].
  /// No se usa upsert porque el schema no define una constraint única
  /// sobre (usuario_id, publicacion_id) en `reacciones`.
  Future<void> _toggleReaccion(String publicacionId, bool nuevoEstado) async {
    if (_uid == null) return;
    try {
      if (nuevoEstado) {
        final existe = await _sb
            .from('reacciones')
            .select('id')
            .eq('usuario_id', _uid!)
            .eq('publicacion_id', publicacionId)
            .maybeSingle();
        if (existe == null) {
          await _sb.from('reacciones').insert({
            'usuario_id':     _uid,
            'publicacion_id': publicacionId,
            'tipo':           'like',
          });
        }
      } else {
        await _sb
            .from('reacciones')
            .delete()
            .eq('usuario_id', _uid!)
            .eq('publicacion_id', publicacionId);
      }
    } catch (e) {
      debugPrint('HistorialComentarios – toggleReaccion: $e');
    }
  }

  void _abrirComentarios(_ItemComentario item) {
    HojaComentarios.mostrar(
      context,
      publicacionId: item.publicacionId,
      isDark:        widget.isDark,
    );
  }

  void _abrirReacciones(_ItemComentario item) {
    HojaReacciones.mostrar(
      context,
      publicacionId: item.publicacionId,
      isDark:        widget.isDark,
    );
  }


  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark   = widget.isDark;
    final bg       = isDark ? Colors.black            : const Color(0xFFF2F2F7);
    final bgCard   = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final bgBubble = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);
    final text1    = isDark ? Colors.white            : Colors.black87;
    final text2    = isDark ? Colors.white54          : Colors.black45;
    const accent   = Color(0xFF007AFF);

    final grupos = _agruparPorFecha();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor:        bgCard,
        elevation:              0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: text1, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mis comentarios',
          style: TextStyle(
              color: text1, fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: RefreshIndicator(
        color:     accent,
        onRefresh: _cargar,
        child: _cargando
            ? const Center(
            child: CircularProgressIndicator(color: Color(0xFF007AFF)))
            : _items.isEmpty
            ? _EstadoVacio(
          isDark:  isDark,
          icono:   Icons.chat_bubble_outline_rounded,
          mensaje: 'No has comentado en ninguna publicación aún.',
        )
            : ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            for (final entry in grupos.entries) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    color:         text2,
                    fontSize:      12,
                    fontWeight:    FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              for (final item in entry.value)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Etiqueta + burbuja con tu comentario ──
                      Text(
                        item.esRespuesta ? '↩︎ Respondiste' : '💬 Comentaste',
                        style: TextStyle(
                            color:      text1,
                            fontSize:   13,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width:   double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color:        bgBubble,
                          borderRadius: BorderRadius.circular(10),
                          border: const Border(
                            left: BorderSide(color: accent, width: 2.5),
                          ),
                        ),
                        child: Text(
                          item.contenido,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: text1, fontSize: 12, height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(_tiempo(item.creadoEn),
                          style: TextStyle(color: text2, fontSize: 11)),
                      const SizedBox(height: 8),

                      // ── Publicación completa ──────────────────
                      TarjetaPublicacion(
                        publicacion: item.postData,
                        medios: (item.postData['publicacion_medios'] as List)
                            .cast<Map<String, dynamic>>(),
                        isDark:      isDark,
                        yaReacciono: item.postData['yo_di_like'] as bool? ?? false,
                        onReaccionar: (nuevoEstado) =>
                            _toggleReaccion(item.publicacionId, nuevoEstado),
                        onComentar:      () => _abrirComentarios(item),
                        onVerReacciones: () => _abrirReacciones(item),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}


// ═════════════════════════════════════════════════════════════════
// ESTADO VACÍO
// ═════════════════════════════════════════════════════════════════

/// Pantalla de placeholder reutilizable para listas vacías.
class _EstadoVacio extends StatelessWidget {
  final bool     isDark;
  final IconData icono;
  final String   mensaje;
  const _EstadoVacio({
    required this.isDark,
    required this.icono,
    required this.mensaje,
  });

  @override
  Widget build(BuildContext context) {
    final text2 = isDark ? Colors.white38 : Colors.black38;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono,
                size:  64,
                color: isDark ? Colors.white12 : Colors.black12),
            const SizedBox(height: 16),
            Text(
              'Sin actividad',
              style: TextStyle(
                  color:      isDark ? Colors.white54 : Colors.black54,
                  fontSize:   16,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(color: text2, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}