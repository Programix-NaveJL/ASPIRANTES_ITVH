// ═════════════════════════════════════════════════════════════════
// tarjeta_publicacion.dart — Aspirantes ITVH
// (cambios: muestra 'nombre' en vez de 'nombre_usuario'; el número
// de reacciones ahora abre la lista de quién reaccionó por separado
// del ícono, que sigue alternando la reacción propia; avatar y
// nombre son tocables y navegan al perfil del autor vía
// navegacion_perfil.dart — propio o público según corresponda;
// nuevo: botón "···" con menú de opciones — publicación PROPIA →
// Editar/Eliminar, publicación AJENA → Reportar con lista de
// motivos. Editar reutiliza CrearPublicacion en modo edición.
// Los motivos de reporte mandan el VALOR exacto que acepta el CHECK
// constraint de la tabla reportes (spam, acoso_bullying,
// contenido_inapropiado, desinformacion, violencia, otro), no el
// texto legible que ve el usuario.)
// ═════════════════════════════════════════════════════════════════

import 'package:aspirantes_itvh_app/comunidad_aspirantes/reproductor_video.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../servicios_storage/url_helper.dart';
import 'crear_publicacion.dart';
import 'navegacion_perfil.dart';

class TarjetaPublicacion extends StatefulWidget {
  final Map<String, dynamic> publicacion;
  final List<Map<String, dynamic>> medios;
  final bool isDark;
  final bool yaReacciono;
  final Future<void> Function(bool nuevoEstado) onReaccionar;
  final VoidCallback onComentar;

  /// Se llama al tocar el CONTADOR de reacciones (no el ícono),
  /// para mostrar quién reaccionó. Opcional por compatibilidad.
  final VoidCallback? onVerReacciones;

  /// Se llama después de eliminar esta publicación desde el menú
  /// "···" — la pantalla que la usa debe quitarla de su lista local
  /// o refrescar. Opcional; si no se pasa, el menú de eliminar
  /// simplemente no notifica hacia arriba.
  final VoidCallback? onEliminada;

  /// Se llama después de editar esta publicación (el texto cambió).
  /// La pantalla que la usa debería recargar para reflejar el nuevo
  /// contenido. Opcional.
  final VoidCallback? onActualizada;

  const TarjetaPublicacion({
    super.key,
    required this.publicacion,
    required this.medios,
    required this.isDark,
    required this.yaReacciono,
    required this.onReaccionar,
    required this.onComentar,
    this.onVerReacciones,
    this.onEliminada,
    this.onActualizada,
  });

  @override
  State<TarjetaPublicacion> createState() => _TarjetaPublicacionState();
}

class _TarjetaPublicacionState extends State<TarjetaPublicacion> {
  static const Color _accent = Color(0xFF007AFF);
  static const Color _rojo   = Color(0xFFFF3B30);

  /// clave = valor que acepta reportes_motivo_check en la BD,
  /// valor = texto legible que ve el usuario en la hoja.
  static const Map<String, String> _motivosReporte = {
    'spam':                  'Spam o publicidad',
    'acoso_bullying':        'Acoso o bullying',
    'contenido_inapropiado': 'Contenido inapropiado u ofensivo',
    'desinformacion':        'Información falsa',
    'violencia':             'Violencia',
    'otro':                  'Otro',
  };

  late bool _reacciono   = widget.yaReacciono;
  late int  _totalReacc  = (widget.publicacion['total_reacciones'] as int?) ?? 0;

  final _pageController = PageController();
  int _paginaActual = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _toggleReaccion() async {
    final estadoAnterior = _reacciono;
    final totalAnterior  = _totalReacc;

    setState(() {
      _reacciono  = !_reacciono;
      _totalReacc += _reacciono ? 1 : -1;
    });

    try {
      await widget.onReaccionar(_reacciono);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _reacciono  = estadoAnterior;
        _totalReacc = totalAnterior;
      });
    }
  }

  /// autor_id viene plano en la fila de `publicaciones` (no dentro
  /// del join a perfiles_aspirantes), por eso se lee directo de
  /// widget.publicacion en vez de del mapa `perfil`.
  void _abrirPerfilAutor() {
    final autorId = widget.publicacion['autor_id'] as String?;
    if (autorId == null) return;
    abrirPerfil(context, perfilId: autorId, isDark: widget.isDark);
  }


  // ─────────────────────────────────────────────────────────────
  // MENÚ "···" — Editar / Eliminar (propia) o Reportar (ajena)
  // ─────────────────────────────────────────────────────────────

  Future<void> _mostrarOpciones() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final autorId = widget.publicacion['autor_id'] as String?;
    final esPropia = uid != null && uid == autorId;

    final accion = await showCupertinoModalPopup<String>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        actions: esPropia
            ? [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, 'editar'),
            child: const Text('Editar publicación'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, 'eliminar'),
            child: const Text('Eliminar publicación'),
          ),
        ]
            : [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, 'reportar'),
            child: const Text('Reportar publicación'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ),
    );

    if (!mounted || accion == null) return;

    switch (accion) {
      case 'editar':
        await _editar();
        break;
      case 'eliminar':
        await _confirmarEliminar();
        break;
      case 'reportar':
        await _elegirMotivoReporte();
        break;
    }
  }

  Future<void> _editar() async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CrearPublicacion(
          isDark: widget.isDark,
          publicacionExistente: widget.publicacion,
          tieneMediaExistente: widget.medios.isNotEmpty,
        ),
      ),
    );
    if (resultado == true) widget.onActualizada?.call();
  }

  Future<void> _confirmarEliminar() async {
    final confirmado = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('¿Eliminar publicación?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    try {
      await Supabase.instance.client
          .from('publicaciones')
          .delete()
          .eq('id', widget.publicacion['id'] as String);
      widget.onEliminada?.call();
    } catch (e) {
      debugPrint('TarjetaPublicacion – eliminar: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar la publicación.')),
      );
    }
  }

  Future<void> _elegirMotivoReporte() async {
    final isDark = widget.isDark;
    final motivo = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _HojaMotivos(isDark: isDark, motivos: _motivosReporte),
    );

    if (motivo == null || !mounted) return;

    String? detalle;
    if (motivo == 'otro') {
      detalle = await _pedirDetalle();
      if (detalle == null) return; // canceló el diálogo de detalle
    }

    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    try {
      await Supabase.instance.client.from('reportes').insert({
        'publicacion_id': widget.publicacion['id'],
        'reportado_por':  uid,
        'autor_id':       widget.publicacion['autor_id'],
        'motivo':         motivo,
        if (detalle != null && detalle.isNotEmpty) 'detalle': detalle,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gracias, revisaremos esta publicación.')),
      );
    } on PostgrestException catch (e) {
      debugPrint('TarjetaPublicacion – reportar (Postgrest): ${e.code} — ${e.message}');
      if (!mounted) return;
      final yaReportado = e.code == '23505'; // unique_violation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(yaReportado
              ? 'Ya habías reportado esta publicación.'
              : 'No se pudo enviar el reporte.'),
        ),
      );
    } catch (e) {
      debugPrint('TarjetaPublicacion – reportar: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo enviar el reporte.')),
      );
    }
  }

  Future<String?> _pedirDetalle() {
    final controller = TextEditingController();
    return showCupertinoDialog<String>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Cuéntanos más'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: CupertinoTextField(
            controller: controller,
            maxLines: 3,
            placeholder: 'Describe brevemente el problema (opcional)',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }


  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark      = widget.isDark;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final bgCard       = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final divColor     = isDark ? Colors.white10 : Colors.black12;

    final perfil  = widget.publicacion['perfiles_aspirantes'] as Map<String, dynamic>?;
    final carrera = perfil?['carreras'] as Map<String, dynamic>?;
    final fotoUrl = perfil != null ? resolverUrlPerfil(perfil) : '';
    final nombre  = perfil?['nombre'] as String? ?? 'Aspirante';

    final contenido = widget.publicacion['contenido'] as String?;
    final creadoEn  = DateTime.tryParse(widget.publicacion['creado_en'] as String? ?? '');
    final totalComentarios = (widget.publicacion['total_comentarios'] as int?) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:        bgCard,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: divColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _abrirPerfilAutor,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: _accent.withValues(alpha: 0.15),
                    backgroundImage: fotoUrl.isNotEmpty ? CachedNetworkImageProvider(fotoUrl) : null,
                    child: fotoUrl.isEmpty
                        ? Icon(CupertinoIcons.person_fill, color: _accent, size: 18)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _abrirPerfilAutor,
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          style: TextStyle(
                              color: textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (carrera?['nombre'] != null) carrera!['nombre'],
                            if (creadoEn != null) timeago.format(creadoEn, locale: 'es'),
                          ].join(' · '),
                          style: TextStyle(
                              color: textPrimary.withValues(alpha: 0.45), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _mostrarOpciones,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(CupertinoIcons.ellipsis,
                        size: 18, color: textPrimary.withValues(alpha: 0.45)),
                  ),
                ),
              ],
            ),
          ),

          if (contenido != null && contenido.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Text(
                contenido,
                style: TextStyle(color: textPrimary, fontSize: 14, height: 1.35),
              ),
            ),

          if (widget.medios.isNotEmpty) _carruselMedia(isDark),

          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
            child: Row(
              children: [
                _botonReaccion(textPrimary),
                const SizedBox(width: 18),
                _botonAccion(
                  icono:  CupertinoIcons.chat_bubble,
                  color:  textPrimary.withValues(alpha: 0.6),
                  label:  '$totalComentarios',
                  onTap:  widget.onComentar,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Ícono y contador separados: el ícono alterna tu reacción,
  /// el número abre la lista de quién reaccionó.
  Widget _botonReaccion(Color textPrimary) {
    final color = _reacciono ? _rojo : textPrimary.withValues(alpha: 0.6);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _toggleReaccion,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Icon(
                _reacciono ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                size: 20,
                color: color,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: widget.onVerReacciones,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Text('$_totalReacc',
                style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _carruselMedia(bool isDark) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 4 / 5,
          child: PageView.builder(
            controller: _pageController,
            itemCount:  widget.medios.length,
            onPageChanged: (i) => setState(() => _paginaActual = i),
            itemBuilder: (context, i) {
              final medio = widget.medios[i];
              final url   = resolverUrlMedio(medio);
              final esVideo = medio['tipo_medio'] == 'video';

              if (esVideo) {
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReproductorVideo(url: url),
                      ),
                    );
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(color: isDark ? Colors.black : Colors.black12),
                      const Center(
                        child: Icon(CupertinoIcons.play_circle_fill,
                            size: 56, color: Colors.white70),
                      ),
                    ],
                  ),
                );
              }

              return CachedNetworkImage(
                imageUrl: url,
                fit:      BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: isDark ? const Color(0xFF2C2C2E) : Colors.black12,
                ),
                errorWidget: (_, __, ___) => const Icon(CupertinoIcons.exclamationmark_triangle),
              );
            },
          ),
        ),
        if (widget.medios.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.medios.length, (i) {
              final activo = i == _paginaActual;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin:   const EdgeInsets.symmetric(horizontal: 3),
                width:    activo ? 8 : 6,
                height:   6,
                decoration: BoxDecoration(
                  color: activo ? _accent : _accent.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  Widget _botonAccion({
    required IconData     icono,
    required Color        color,
    required String       label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Icon(icono, size: 20, color: color),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────
// HOJA DE MOTIVOS DE REPORTE
// ─────────────────────────────────────────────────────────────────

class _HojaMotivos extends StatelessWidget {
  final bool isDark;

  /// clave = valor que se guarda en la BD, valor = texto que ve el usuario.
  final Map<String, String> motivos;

  const _HojaMotivos({required this.isDark, required this.motivos});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final divColor = isDark ? Colors.white10 : Colors.black12;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.only(bottom: 8),
        // Material envuelve el contenido para que el ListTile pinte
        // su ripple/splash correctamente (si no, el DecoratedBox de
        // arriba lo tapa y el toque se ve "sin feedback").
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '¿Por qué reportas esta publicación?',
                    style: TextStyle(
                        color: textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              Divider(height: 0.5, thickness: 0.5, color: divColor),
              ...motivos.entries.map((e) => ListTile(
                title: Text(e.value, style: TextStyle(color: textPrimary, fontSize: 14.5)),
                onTap: () => Navigator.pop(context, e.key),
              )),
            ],
          ),
        ),
      ),
    );
  }
}