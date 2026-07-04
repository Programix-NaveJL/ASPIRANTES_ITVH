// ═════════════════════════════════════════════════════════════════
// editar_perfil_aspirante.dart — Aspirantes ITVH
//
// Pantalla para editar el perfil del aspirante. A diferencia de
// Comunidad ITVH:
//   • carrera es una FK (carrera_id) a la tabla `carreras`, cargada
//     dinámicamente — no una lista de strings hardcodeada.
//   • no existe `semestre` en perfiles_aspirantes (aspirantes de
//     nuevo ingreso no tienen semestre todavía).
//   • email y numero_ficha son NOT NULL/UNIQUE fijados en el
//     registro (crear_cuenta.dart) — aquí se muestran de solo
//     lectura, no se editan.
//   • solo existe cdn_foto_perfil (sin fallback a Supabase Storage,
//     esta app nace ya en R2).
//
// Theme-aware (isDarkNotifier) para ser consistente con el resto
// de la app — a diferencia del original de Comunidad ITVH que
// forzaba paleta oscura fija.
// ═════════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';
import '../servicios_storage/r2_config.dart';
import '../servicios_storage/storage_service.dart';
import '../servicios_storage/url_helper.dart';

class EditarPerfilAspirante extends StatefulWidget {
  const EditarPerfilAspirante({super.key});

  @override
  State<EditarPerfilAspirante> createState() => _EditarPerfilAspiranteState();
}

class _EditarPerfilAspiranteState extends State<EditarPerfilAspirante> {
  final _nombreController       = TextEditingController();
  final _usuarioController      = TextEditingController();
  final _presentacionController = TextEditingController();
  final _instagramController    = TextEditingController();
  final _facebookController     = TextEditingController();
  final _tiktokController       = TextEditingController();

  static const Color _accent = Color(0xFF007AFF);
  static const Color _danger = Color(0xFFFF3B30);

  // Datos de solo lectura, fijados en el registro.
  String _email        = '';
  String _numeroFicha  = '';

  // Carreras cargadas dinámicamente desde la tabla `carreras`.
  List<Map<String, dynamic>> _carreras = [];
  String? _carreraIdSeleccionada;

  String? _fotoUrl;
  File?   _imagenLocal;

  bool _isLoading = true;
  bool _isSaving  = false;

  String  _nombreOriginal       = '';
  String  _usuarioOriginal      = '';
  String  _presentacionOriginal = '';
  String  _instagramOriginal    = '';
  String  _facebookOriginal     = '';
  String  _tiktokOriginal       = '';
  String? _carreraIdOriginal;

  bool get _hayCambios =>
      _nombreController.text.trim()       != _nombreOriginal       ||
          _usuarioController.text.trim()      != _usuarioOriginal      ||
          _presentacionController.text.trim() != _presentacionOriginal ||
          _instagramController.text.trim()    != _instagramOriginal    ||
          _facebookController.text.trim()     != _facebookOriginal     ||
          _tiktokController.text.trim()       != _tiktokOriginal       ||
          _carreraIdSeleccionada              != _carreraIdOriginal    ||
          _imagenLocal                        != null;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _usuarioController.dispose();
    _presentacionController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    _tiktokController.dispose();
    super.dispose();
  }


  // ─────────────────────────────────────────────────────────────
  // CARGA
  // ─────────────────────────────────────────────────────────────

  Future<void> _cargarDatos() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    try {
      // Carreras y perfil en paralelo — no dependen entre sí.
      final resultados = await Future.wait([
        Supabase.instance.client
            .from('carreras')
            .select('id, nombre')
            .eq('activa', true)
            .order('nombre'),
        Supabase.instance.client
            .from('perfiles_aspirantes')
            .select()
            .eq('id', uid)
            .single(),
      ]);

      if (!mounted) return;

      final carreras = resultados[0] as List<dynamic>;
      final data     = resultados[1] as Map<String, dynamic>;

      final nombre       = data['nombre']        as String? ?? '';
      final usuario      = data['nombre_usuario'] as String? ?? '';
      final presentacion = data['presentacion']  as String? ?? '';
      final instagram    = data['instagram_url'] as String? ?? '';
      final facebook     = data['facebook_url']  as String? ?? '';
      final tiktok       = data['tiktok_url']    as String? ?? '';
      final carreraId    = data['carrera_id']    as String?;

      _nombreController.text       = nombre;
      _usuarioController.text      = usuario;
      _presentacionController.text = presentacion;
      _instagramController.text    = instagram;
      _facebookController.text     = facebook;
      _tiktokController.text       = tiktok;

      setState(() {
        _carreras              = carreras.cast<Map<String, dynamic>>();
        _carreraIdSeleccionada = carreraId;
        _carreraIdOriginal     = carreraId;
        _email                 = data['email']        as String? ?? '';
        _numeroFicha           = data['numero_ficha'] as String? ?? '';
        _fotoUrl                = resolverUrlPerfil(data);
        _nombreOriginal        = nombre;
        _usuarioOriginal       = usuario;
        _presentacionOriginal  = presentacion;
        _instagramOriginal     = instagram;
        _facebookOriginal      = facebook;
        _tiktokOriginal        = tiktok;
        _isLoading             = false;
      });
    } catch (e) {
      debugPrint('EditarPerfilAspirante – cargar datos: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }


  // ─────────────────────────────────────────────────────────────
  // SALIDA CON CONFIRMACIÓN SI HAY CAMBIOS SIN GUARDAR
  // ─────────────────────────────────────────────────────────────

  Future<bool> _confirmarSalida() async {
    if (!_hayCambios) return true;
    final salir = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Cambios sin guardar'),
        content: const Text('Tienes cambios sin guardar. ¿Deseas salir?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Seguir editando'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir sin guardar'),
          ),
        ],
      ),
    );
    return salir ?? false;
  }


  // ─────────────────────────────────────────────────────────────
  // FOTO DE PERFIL
  // ─────────────────────────────────────────────────────────────

  void _verFotoCompleta() {
    ImageProvider? imagen;
    if (_imagenLocal != null) {
      imagen = FileImage(_imagenLocal!);
    } else if (_fotoUrl != null && _fotoUrl!.isNotEmpty) {
      imagen = NetworkImage(_fotoUrl!);
    }
    if (imagen != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _FotoViewer(imagen: imagen!)),
      );
    }
  }

  Future<void> _seleccionarImagen(ImageSource source) async {
    PermissionStatus status;
    if (source == ImageSource.camera) {
      status = await Permission.camera.request();
    } else {
      status = await Permission.photos.request();
      if (status.isDenied && Platform.isAndroid) {
        status = await Permission.storage.request();
      }
    }
    if (!mounted) return;

    if (status.isGranted) {
      try {
        final picked = await ImagePicker().pickImage(
          source: source,
          imageQuality: 75,
          maxWidth: 1000,
          maxHeight: 1000,
        );
        if (picked != null && mounted) {
          setState(() => _imagenLocal = File(picked.path));
        }
      } catch (e) {
        _showSnackBar('Error al abrir la cámara o galería', isError: true);
      }
    } else if (status.isPermanentlyDenied) {
      _showSnackBar('Permiso denegado. Actívalo en ajustes.', isError: false);
      await openAppSettings();
    } else {
      _showSnackBar('Se necesita permiso para acceder a la imagen', isError: false);
    }
  }

  void _mostrarOpcionesFoto(bool isDark) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Foto de perfil'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _seleccionarImagen(ImageSource.gallery);
            },
            child: const Text('Seleccionar de la galería'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _seleccionarImagen(ImageSource.camera);
            },
            child: const Text('Tomar una foto'),
          ),
          if ((_fotoUrl != null && _fotoUrl!.isNotEmpty) || _imagenLocal != null)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _imagenLocal = null;
                  _fotoUrl     = null;
                });
              },
              child: const Text('Eliminar foto'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ),
    );
  }

  /// Sube la foto nueva a R2 si el usuario eligió una. Si no hay
  /// imagen nueva, devuelve null (no se toca cdn_foto_perfil).
  Future<String?> _subirImagenSiHayNueva(String uid) async {
    if (_imagenLocal == null) return null;
    return StorageService.instance.subirFotoPerfil(
      file:   _imagenLocal!,
      userId: uid,
    );
  }


  // ─────────────────────────────────────────────────────────────
  // GUARDAR
  // ─────────────────────────────────────────────────────────────

  Future<void> _guardar() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    final nombre       = _nombreController.text.trim();
    final usuario      = _usuarioController.text.trim();
    final presentacion = _presentacionController.text.trim();
    final instagram    = _instagramController.text.trim();
    final facebook     = _facebookController.text.trim();
    final tiktok       = _tiktokController.text.trim();

    if (nombre.isEmpty) {
      _showSnackBar('El nombre no puede estar vacío', isError: false);
      return;
    }
    if (usuario.isEmpty) {
      _showSnackBar('El nombre de usuario no puede estar vacío', isError: false);
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (usuario != _usuarioOriginal) {
        final existe = await Supabase.instance.client
            .from('perfiles_aspirantes')
            .select('id')
            .eq('nombre_usuario', usuario)
            .maybeSingle();
        if (existe != null) {
          _showSnackBar('Ese nombre de usuario ya está en uso', isError: false);
          setState(() => _isSaving = false);
          return;
        }
      }

      final fotoAnterior = _fotoUrl;
      String? cdnUrl;
      try {
        cdnUrl = await _subirImagenSiHayNueva(uid);
      } catch (e) {
        _showSnackBar('Error al subir imagen: $e', isError: true);
      }

      final updateData = <String, dynamic>{
        'nombre':         nombre,
        'nombre_usuario': usuario,
        'carrera_id':     _carreraIdSeleccionada,
        'presentacion':   presentacion.isEmpty ? null : presentacion,
        'instagram_url':  instagram.isEmpty ? null : instagram,
        'facebook_url':   facebook.isEmpty  ? null : facebook,
        'tiktok_url':     tiktok.isEmpty    ? null : tiktok,
      };
      if (cdnUrl != null) updateData['cdn_foto_perfil'] = cdnUrl;

      await Supabase.instance.client
          .from('perfiles_aspirantes')
          .update(updateData)
          .eq('id', uid);

      // Solo borrar la foto anterior DESPUÉS de confirmar que la
      // actualización en BD tuvo éxito y que la nueva ya subió.
      if (cdnUrl != null &&
          fotoAnterior != null &&
          fotoAnterior.isNotEmpty &&
          fotoAnterior != cdnUrl) {
        try {
          final r2Path = fotoAnterior.replaceFirst('${R2Config.dominioPerfil}/', '');
          await StorageService.instance.eliminarDeR2(
            bucket: R2Config.bucketPerfil,
            path:   r2Path,
          );
        } catch (e) {
          debugPrint('EditarPerfilAspirante – borrar foto anterior: $e');
          // No interrumpir el flujo si falla el borrado de la vieja.
        }
      }

      if (!mounted) return;
      setState(() {
        _nombreOriginal       = nombre;
        _usuarioOriginal      = usuario;
        _presentacionOriginal = presentacion;
        _instagramOriginal    = instagram;
        _facebookOriginal     = facebook;
        _tiktokOriginal       = tiktok;
        _carreraIdOriginal    = _carreraIdSeleccionada;
        _imagenLocal          = null;
        if (cdnUrl != null) _fotoUrl = cdnUrl;
      });

      _showSnackBar('Perfil actualizado ✓', isError: false);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _showSnackBar('Error al guardar: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Solo cierra la sesión — no navega manualmente. AuthGate
  /// (main.dart) escucha onAuthStateChange y regresa solo a
  /// LoginScreen, mismo patrón que en feed.dart.
  Future<void> _cerrarSesion() async {
    final confirmar = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar tu sesión?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    await Supabase.instance.client.auth.signOut();
  }


  // ─────────────────────────────────────────────────────────────
  // PICKER DE CARRERA (dinámico, desde la tabla `carreras`)
  // ─────────────────────────────────────────────────────────────

  void _mostrarPickerCarrera(bool isDark) {
    final bgSheet = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final divColor = isDark ? Colors.white10 : Colors.black12;
    final textPrimary = isDark ? Colors.white : Colors.black;

    showModalBottomSheet(
      context: context,
      backgroundColor: bgSheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: divColor,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Text('Selecciona tu carrera',
                    style: TextStyle(
                        color: textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close_rounded,
                      color: textPrimary.withValues(alpha: 0.5), size: 20),
                ),
              ],
            ),
          ),
          Divider(height: 0.5, thickness: 0.5, color: divColor),
          if (_carreras.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text('No hay carreras disponibles',
                  style: TextStyle(color: textPrimary.withValues(alpha: 0.5))),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _carreras.length,
                itemBuilder: (ctx, i) {
                  final carrera  = _carreras[i];
                  final selected = carrera['id'] == _carreraIdSeleccionada;
                  return InkWell(
                    onTap: () {
                      setState(() => _carreraIdSeleccionada = carrera['id'] as String);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: selected ? _accent.withValues(alpha: 0.10) : Colors.transparent,
                        border: Border(bottom: BorderSide(color: divColor, width: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(carrera['nombre'] as String,
                                style: TextStyle(
                                  color: selected ? _accent : textPrimary,
                                  fontSize: 14,
                                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                                )),
                          ),
                          if (selected) const Icon(Icons.check_rounded, color: _accent, size: 18),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  void _showSnackBar(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: const TextStyle(color: Colors.white))),
        ],
      ),
      backgroundColor: isError ? _danger : _accent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }


  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkNotifier,
      builder: (context, isDark, _) {
        final textPrimary = isDark ? Colors.white : Colors.black;
        final textSec      = textPrimary.withValues(alpha: 0.5);
        final bg           = isDark ? Colors.black : const Color(0xFFF2F2F7);
        final bgCard       = isDark ? const Color(0xFF1C1C1E) : Colors.white;
        final divColor     = isDark ? Colors.white10 : Colors.black12;

        if (_isLoading) {
          return Scaffold(
            backgroundColor: bg,
            body: const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2)),
          );
        }

        final nombreCarreraActual = _carreras.firstWhere(
              (c) => c['id'] == _carreraIdSeleccionada,
          orElse: () => const {},
        )['nombre'] as String?;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final salir = await _confirmarSalida();
            if (salir && context.mounted) Navigator.pop(context);
          },
          child: Scaffold(
            backgroundColor: bg,
            appBar: AppBar(
              backgroundColor: isDark ? Colors.black : Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: Icon(CupertinoIcons.back, color: _accent, size: 22),
                onPressed: () async {
                  final salir = await _confirmarSalida();
                  if (salir && context.mounted) Navigator.pop(context);
                },
              ),
              title: Text('Mi perfil',
                  style: TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.w600)),
              centerTitle: true,
              actions: [
                if (_hayCambios)
                  TextButton(
                    onPressed: _isSaving ? null : _guardar,
                    child: _isSaving
                        ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(color: _accent, strokeWidth: 2),
                    )
                        : const Text('Guardar',
                        style: TextStyle(color: _accent, fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const SizedBox(height: 16),

                // ── Avatar + nombre/usuario ─────────────────────
                _Card(
                  bgCard: bgCard, divColor: divColor,
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: (_imagenLocal != null || (_fotoUrl != null && _fotoUrl!.isNotEmpty))
                            ? _verFotoCompleta
                            : () => _mostrarOpcionesFoto(isDark),
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 90, height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: _accent, width: 2.5),
                                color: bgCard,
                              ),
                              child: ClipOval(
                                child: _imagenLocal != null
                                    ? Image.file(_imagenLocal!, fit: BoxFit.cover)
                                    : (_fotoUrl != null && _fotoUrl!.isNotEmpty)
                                    ? Image.network(
                                  _fotoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _avatarPlaceholder(textSec),
                                )
                                    : _avatarPlaceholder(textSec),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _mostrarOpcionesFoto(isDark),
                              child: Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(
                                  color: _accent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: bgCard, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _nombreController.text.isEmpty ? 'Tu nombre' : _nombreController.text,
                        style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _usuarioController.text.isEmpty ? '@usuario' : '@${_usuarioController.text}',
                        style: TextStyle(color: textSec, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Identidad (solo lectura) ─────────────────────
                _SectionHeader(
                  label: 'IDENTIDAD',
                  subtitle: 'Fijados en el registro, no editables',
                  textSec: textSec,
                ),
                _Card(
                  bgCard: bgCard, divColor: divColor,
                  child: Column(
                    children: [
                      _Row(
                        icon: CupertinoIcons.mail,
                        label: 'Email',
                        textPrimary: textPrimary,
                        child: Text(_email,
                            textAlign: TextAlign.right,
                            style: TextStyle(color: textSec, fontSize: 13),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Divider(height: 0.5, thickness: 0.5, color: divColor, indent: 48),
                      _Row(
                        icon: CupertinoIcons.number,
                        label: 'Ficha',
                        textPrimary: textPrimary,
                        child: Text(_numeroFicha,
                            textAlign: TextAlign.right,
                            style: TextStyle(color: textSec, fontSize: 13)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                _SectionHeader(label: 'INFORMACIÓN PERSONAL', textSec: textSec),
                _Card(
                  bgCard: bgCard, divColor: divColor,
                  child: Column(
                    children: [
                      _Row(
                        icon: CupertinoIcons.person,
                        label: 'Nombre',
                        textPrimary: textPrimary,
                        child: _CampoTexto(
                          controller: _nombreController,
                          placeholder: 'Tu nombre completo',
                          textPrimary: textPrimary,
                        ),
                      ),
                      Divider(height: 0.5, thickness: 0.5, color: divColor, indent: 48),
                      _Row(
                        icon: CupertinoIcons.at,
                        label: 'Usuario',
                        textPrimary: textPrimary,
                        child: _CampoTexto(
                          controller: _usuarioController,
                          placeholder: 'nombre_usuario',
                          textPrimary: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                _SectionHeader(label: 'PRESENTACIÓN', textSec: textSec),
                _Card(
                  bgCard: bgCard, divColor: divColor,
                  child: TextField(
                    controller: _presentacionController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 3,
                    maxLength: 160, // constraint real de la tabla
                    style: TextStyle(color: textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Cuéntale algo a la comunidad...',
                      hintStyle: TextStyle(color: textSec, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      counterStyle: TextStyle(color: textSec, fontSize: 11),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                _SectionHeader(label: 'CARRERA DE INTERÉS', textSec: textSec),
                _Card(
                  bgCard: bgCard, divColor: divColor,
                  child: _Row(
                    icon: CupertinoIcons.book,
                    label: 'Carrera',
                    textPrimary: textPrimary,
                    onTap: () => _mostrarPickerCarrera(isDark),
                    child: Text(
                      nombreCarreraActual ?? 'Seleccionar',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 13, color: nombreCarreraActual != null ? textSec : textSec.withValues(alpha: 0.6)),
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Icon(CupertinoIcons.chevron_right, color: textSec, size: 16),
                  ),
                ),

                const SizedBox(height: 20),

                _SectionHeader(
                  label: 'REDES SOCIALES',
                  subtitle: 'Opcional — aparecerán en tu perfil',
                  textSec: textSec,
                ),
                _Card(
                  bgCard: bgCard, divColor: divColor,
                  child: Column(
                    children: [
                      _Row(
                        iconWidget: _SocialIcon(assetPath: 'assets/icons/instagram.png'),
                        label: '',
                        textPrimary: textPrimary,
                        child: _CampoTexto(
                          controller: _instagramController,
                          placeholder: 'instagram.com/tu_perfil',
                          keyboardType: TextInputType.url,
                          fontSize: 13,
                          textPrimary: textPrimary,
                        ),
                      ),
                      Divider(height: 0.5, thickness: 0.5, color: divColor, indent: 48),
                      _Row(
                        iconWidget: _SocialIcon(assetPath: 'assets/icons/facebook.png'),
                        label: '',
                        textPrimary: textPrimary,
                        child: _CampoTexto(
                          controller: _facebookController,
                          placeholder: 'facebook.com/tu_perfil',
                          keyboardType: TextInputType.url,
                          fontSize: 13,
                          textPrimary: textPrimary,
                        ),
                      ),
                      Divider(height: 0.5, thickness: 0.5, color: divColor, indent: 48),
                      _Row(
                        iconWidget: _SocialIcon(assetPath: 'assets/icons/tiktok.png'),
                        label: '',
                        textPrimary: textPrimary,
                        child: _CampoTexto(
                          controller: _tiktokController,
                          placeholder: 'tiktok.com/@tu_perfil',
                          keyboardType: TextInputType.url,
                          fontSize: 13,
                          textPrimary: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      disabledBackgroundColor: _accent.withValues(alpha: 0.4),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                        : const Text('Guardar cambios',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),

                const SizedBox(height: 16),

                Center(
                  child: TextButton.icon(
                    onPressed: _cerrarSesion,
                    icon: const Icon(CupertinoIcons.square_arrow_right, color: _danger, size: 16),
                    label: const Text('Cerrar sesión',
                        style: TextStyle(color: _danger, fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _avatarPlaceholder(Color color) => Icon(Icons.person_rounded, size: 48, color: color);
}


// ─────────────────────────────────────────────────────────────────
// WIDGETS AUXILIARES (theme-aware)
// ─────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String  label;
  final String? subtitle;
  final Color   textSec;
  const _SectionHeader({required this.label, this.subtitle, required this.textSec});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(color: textSec, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.1)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: TextStyle(color: textSec.withValues(alpha: 0.7), fontSize: 11)),
          ],
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final Color  bgCard;
  final Color  divColor;
  const _Card({required this.child, required this.bgCard, required this.divColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: divColor, width: 0.5),
      ),
      child: child,
    );
  }
}

class _Row extends StatelessWidget {
  final IconData?      icon;
  final Widget?         iconWidget;
  final String          label;
  final Widget          child;
  final Widget?         trailing;
  final VoidCallback?   onTap;
  final Color           textPrimary;

  const _Row({
    this.icon, this.iconWidget, required this.label, required this.child,
    this.trailing, this.onTap, required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          if (iconWidget != null) iconWidget! else if (icon != null) Icon(icon, color: const Color(0xFF007AFF), size: 20),
          const SizedBox(width: 12),
          if (label.isNotEmpty)
            SizedBox(width: 72, child: Text(label, style: TextStyle(color: textPrimary, fontSize: 15))),
          Expanded(child: child),
          if (trailing != null) ...[const SizedBox(width: 4), trailing!],
        ],
      ),
    );
    if (onTap != null) return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: row);
    return row;
  }
}

class _CampoTexto extends StatelessWidget {
  final TextEditingController controller;
  final String                placeholder;
  final TextInputType         keyboardType;
  final double                fontSize;
  final Color                 textPrimary;

  const _CampoTexto({
    required this.controller, required this.placeholder,
    this.keyboardType = TextInputType.text, this.fontSize = 15, required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textAlign: TextAlign.right,
      style: TextStyle(color: textPrimary, fontSize: fontSize),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: TextStyle(color: textPrimary.withValues(alpha: 0.35), fontSize: fontSize - 1),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final String assetPath;
  const _SocialIcon({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(width: 26, height: 26, child: Image.asset(assetPath, fit: BoxFit.cover)),
    );
  }
}

class _FotoViewer extends StatelessWidget {
  final ImageProvider imagen;
  const _FotoViewer({required this.imagen});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Foto de perfil', style: TextStyle(color: Colors.white, fontSize: 16)),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF007AFF)),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image(
            image: imagen,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
            const Icon(Icons.image_not_supported_outlined, color: Colors.white38, size: 64),
          ),
        ),
      ),
    );
  }
}