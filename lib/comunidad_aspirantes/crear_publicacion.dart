// ═════════════════════════════════════════════════════════════════
// crear_publicacion.dart — Aspirantes ITVH
//
// Pantalla para crear O editar una publicación del feed de Comunidad.
//
// MODO CREACIÓN (publicacionExistente == null):
//   Permite adjuntar fotos (varias, en carrusel) O un video (uno solo,
//   no se mezclan formatos) y un texto opcional. Flujo al publicar:
//     1. Insertar la fila en `publicaciones` y capturar su id.
//     2. Subir cada archivo de media a R2 vía StorageService, en orden.
//     3. Insertar una fila en `publicacion_medios` por cada archivo.
//     4. Si cualquier paso de media falla, se borra la publicación ya
//        insertada (rollback) para no dejar "posts fantasma".
//
// MODO EDICIÓN (publicacionExistente != null):
//   Solo permite editar el TEXTO — la media NO es editable aquí (si
//   el usuario quiere cambiar fotos/video, debe eliminar la
//   publicación y crear una nueva). Precarga el texto existente,
//   oculta los botones de selección de media, y al guardar hace un
//   UPDATE en vez de un INSERT. [tieneMediaExistente] evita que se
//   bloquee el guardado por "texto vacío" cuando la publicación
//   original solo tenía media y ahora se deja sin texto.
// ═════════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../servicios_storage/storage_service.dart';

class CrearPublicacion extends StatefulWidget {
  final bool isDark;

  /// Si no es null, la pantalla entra en modo edición. Debe contener
  /// al menos las llaves 'id' y 'contenido' de la publicación.
  final Map<String, dynamic>? publicacionExistente;

  /// Solo relevante en modo edición: si la publicación ya tiene
  /// fotos/video adjuntos. La media no se edita aquí, pero esto
  /// evita bloquear el guardado por "texto vacío" cuando la media
  /// sigue siendo el contenido principal del post.
  final bool tieneMediaExistente;

  const CrearPublicacion({
    super.key,
    required this.isDark,
    this.publicacionExistente,
    this.tieneMediaExistente = false,
  });

  @override
  State<CrearPublicacion> createState() => _CrearPublicacionState();
}

class _CrearPublicacionState extends State<CrearPublicacion> {
  final _picker = ImagePicker();
  late final _textoController = TextEditingController(
    text: widget.publicacionExistente?['contenido'] as String? ?? '',
  );

  // Solo uno de los dos puede tener contenido a la vez: fotos O video,
  // nunca ambos (mismo patrón que Instagram/redes similares).
  final List<File> _fotos = [];
  File? _video;

  bool _publicando = false;
  double _progresoVideo = 0; // 0-100, solo relevante durante compresión de video

  static const Color _accent = Color(0xFF007AFF);

  bool get _esEdicion => widget.publicacionExistente != null;

  @override
  void dispose() {
    _textoController.dispose();
    super.dispose();
  }


  // ─────────────────────────────────────────────────────────────
  // SELECCIÓN DE MEDIA (solo aplica en modo creación)
  // ─────────────────────────────────────────────────────────────

  Future<void> _elegirFotos() async {
    final archivos = await _picker.pickMultiImage(imageQuality: 90);
    if (archivos.isEmpty) return;
    setState(() {
      _video = null; // limpia el video si el usuario cambia de opinión
      _fotos
        ..clear()
      // límite de 10, mismo tope de carrusel que Comunidad ITVH
        ..addAll(archivos.map((x) => File(x.path)).take(10));
    });
  }

  Future<void> _elegirVideo() async {
    final archivo = await _picker.pickVideo(source: ImageSource.gallery);
    if (archivo == null) return;
    setState(() {
      _fotos.clear(); // limpia fotos si el usuario cambia de opinión
      _video = File(archivo.path);
    });
  }

  void _quitarFoto(int index) => setState(() => _fotos.removeAt(index));
  void _quitarVideo() => setState(() => _video = null);


  // ─────────────────────────────────────────────────────────────
  // PUBLICAR / GUARDAR
  // ─────────────────────────────────────────────────────────────

  Future<void> _publicar() async {
    final texto = _textoController.text.trim();
    final hayMedia = _fotos.isNotEmpty ||
        _video != null ||
        (_esEdicion && widget.tieneMediaExistente);

    if (texto.isEmpty && !hayMedia) {
      _mostrarError('Escribe algo o adjunta una foto/video antes de publicar');
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _mostrarError('Tu sesión expiró, vuelve a iniciar sesión');
      return;
    }

    setState(() => _publicando = true);

    // ── Modo edición: solo se actualiza el texto ──────────────
    if (_esEdicion) {
      try {
        await Supabase.instance.client
            .from('publicaciones')
            .update({'contenido': texto.isEmpty ? null : texto})
            .eq('id', widget.publicacionExistente!['id'] as String);

        if (!mounted) return;
        Navigator.of(context).pop(true); // true = se guardaron cambios
      } catch (e) {
        _mostrarError('No se pudo guardar: ${e.toString()}');
      } finally {
        if (mounted) setState(() => _publicando = false);
      }
      return;
    }

    // ── Modo creación: insert + subida de media ───────────────
    String? publicacionId;
    try {
      final tipo = _video != null ? 'reel' : 'post';
      final insertado = await Supabase.instance.client
          .from('publicaciones')
          .insert({
        'autor_id':   userId,
        'contenido':  texto.isEmpty ? null : texto,
        'tipo':       tipo,
      })
          .select('id')
          .single();

      publicacionId = insertado['id'] as String;

      if (_video != null) {
        await _subirYRegistrarMedio(
          file:           _video!,
          publicacionId:  publicacionId,
          userId:         userId,
          orden:          0,
          tipoMedio:      'video',
        );
      } else {
        for (var i = 0; i < _fotos.length; i++) {
          await _subirYRegistrarMedio(
            file:           _fotos[i],
            publicacionId:  publicacionId,
            userId:         userId,
            orden:          i,
            tipoMedio:      'imagen',
          );
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop(true); // true = se creó la publicación
    } catch (e) {
      // Rollback: si algo falló subiendo/registrando media, no dejamos
      // una publicación huérfana sin contenido consistente.
      if (publicacionId != null) {
        await Supabase.instance.client
            .from('publicaciones')
            .delete()
            .eq('id', publicacionId);
      }
      _mostrarError('No se pudo publicar: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _publicando = false);
    }
  }

  Future<void> _subirYRegistrarMedio({
    required File   file,
    required String publicacionId,
    required String userId,
    required int    orden,
    required String tipoMedio,
  }) async {
    final cdnUrl = await StorageService.instance.subirMediaPublicacion(
      file:   file,
      postId: publicacionId,
      userId: userId,
      orden:  orden,
      onProgress: tipoMedio == 'video'
          ? (pct) => setState(() => _progresoVideo = pct)
          : null,
    );

    await Supabase.instance.client.from('publicacion_medios').insert({
      'publicacion_id': publicacionId,
      'cdn_url':        cdnUrl,
      'tipo_medio':     tipoMedio,
      'orden':          orden,
    });
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating),
    );
  }


  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark      = widget.isDark;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final bg          = isDark ? Colors.black : const Color(0xFFF2F2F7);
    final bgCard       = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        title: Text(_esEdicion ? 'Editar publicación' : 'Nueva publicación',
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _publicando ? null : _publicar,
              child: _publicando
                  ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Text(_esEdicion ? 'Guardar' : 'Publicar',
                  style: const TextStyle(color: _accent, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Campo de texto ─────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color:        bgCard,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(14),
            child: TextField(
              controller: _textoController,
              maxLines:   5,
              minLines:   3,
              maxLength:  500,
              style: TextStyle(color: textPrimary),
              decoration: const InputDecoration(
                border:   InputBorder.none,
                hintText: '¿Qué quieres compartir con la comunidad?',
              ),
            ),
          ),

          // ── Aviso de media no editable (solo en edición) ────
          if (_esEdicion && widget.tieneMediaExistente) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.info_circle,
                      size: 16, color: textPrimary.withValues(alpha: 0.5)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'La foto o video no se puede editar. Si quieres cambiarlos, elimina esta publicación y crea una nueva.',
                      style: TextStyle(color: textPrimary.withValues(alpha: 0.5), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Selección de media (solo en modo creación) ──────
          if (!_esEdicion) ...[
            const SizedBox(height: 16),

            if (_fotos.isNotEmpty) _previewFotos(isDark),
            if (_video != null) _previewVideo(isDark),

            if (_publicando && _video != null) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: _progresoVideo / 100),
              const SizedBox(height: 4),
              Text('Procesando video: ${_progresoVideo.toStringAsFixed(0)}%',
                  style: TextStyle(color: textPrimary.withValues(alpha: 0.5), fontSize: 12)),
            ],

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _botonMedia(
                    icono:  CupertinoIcons.photo_on_rectangle,
                    label:  'Fotos',
                    isDark: isDark,
                    onTap:  _publicando ? null : _elegirFotos,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _botonMedia(
                    icono:  CupertinoIcons.videocam,
                    label:  'Video',
                    isDark: isDark,
                    onTap:  _publicando ? null : _elegirVideo,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _previewFotos(bool isDark) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection:   Axis.horizontal,
        itemCount:          _fotos.length,
        separatorBuilder:   (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_fotos[i], width: 100, height: 100, fit: BoxFit.cover),
            ),
            Positioned(
              top: 4, right: 4,
              child: GestureDetector(
                onTap: () => _quitarFoto(i),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(CupertinoIcons.xmark, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewVideo(bool isDark) {
    return Stack(
      children: [
        Container(
          height: 160,
          width:  double.infinity,
          decoration: BoxDecoration(
            color:        isDark ? const Color(0xFF1C1C1E) : Colors.black12,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: const Icon(CupertinoIcons.play_circle_fill, size: 48, color: Colors.white70),
        ),
        Positioned(
          top: 8, right: 8,
          child: GestureDetector(
            onTap: _quitarVideo,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(CupertinoIcons.xmark, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _botonMedia({
    required IconData      icono,
    required String        label,
    required bool          isDark,
    required VoidCallback? onTap,
  }) {
    final bgCard      = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color:        bgCard,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icono, color: _accent, size: 22),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(color: textPrimary, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}