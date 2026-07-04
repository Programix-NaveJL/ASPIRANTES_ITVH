// ═════════════════════════════════════════════════════════════════
// ajustes_screen.dart
//
// Pantalla de configuración de la cuenta del usuario.
//
// Secciones:
//   • CUENTA        — cambiar contraseña
//   • NOTIFICACIONES — historial de reacciones y comentarios
//   • LEGAL         — términos y política de privacidad
//   • SESIÓN        — cerrar sesión y eliminar cuenta
//
// Sub-pantallas internas (privadas):
//   • _CambiarContrasenaScreen  — actualiza contraseña vía Supabase Auth
//
// Widgets reutilizables (privados):
//   • _SectionLabel    — etiqueta de sección en mayúsculas
//   • _CardGroup       — contenedor con bordes redondeados y borde sutil
//   • _Divider         — separador interno con sangría de ícono
//   • _SettingsTile    — fila con ícono, título y flecha opcional
//   • _SettingsRow     — fila con ícono, título, subtítulo y flecha
//   • _IconBox         — contenedor cuadrado con fondo semitransparente
//   • _PasswordField   — campo de contraseña con toggle de visibilidad
// ═════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../iniciar_sesion.dart';
import '../servicios_storage/r2_config.dart';
import '../servicios_storage/storage_service.dart';
import 'historial_comentarios.dart';
import 'historial_reacciones.dart';

// Instancia global del cliente Supabase. Se accede desde múltiples
// clases privadas del archivo, por lo que se declara a nivel de archivo.
final _sb = Supabase.instance.client;


// ═════════════════════════════════════════════════════════════════
// PANTALLA PRINCIPAL DE AJUSTES
// ═════════════════════════════════════════════════════════════════

class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {

  // Colores de acento reutilizados en múltiples secciones.
  static const _accent = Color(0xFF007AFF);
  static const _red    = Color(0xFFFF3B30);
  static const _orange = Color(0xFFFF9500);

  // Getter para el UID del usuario autenticado. Puede ser null si
  // la sesión expiró entre navegaciones.
  String? get _uid => _sb.auth.currentUser?.id;


  // ─────────────────────────────────────────────────────────────
  // SESIÓN
  // ─────────────────────────────────────────────────────────────

  /// Muestra un diálogo de confirmación antes de cerrar la sesión.
  /// Si el usuario confirma, llama a signOut y navega al LoginScreen
  /// eliminando todo el stack de navegación.
  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Cerrar sesión',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            '¿Estás seguro que deseas cerrar tu sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar sesión',
                style: TextStyle(
                    color: _accent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;
    await _sb.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
    );
  }

  /// Abre el diálogo de eliminación de cuenta.
  /// Al confirmarse, navega al LoginScreen limpiando el stack.
  void _mostrarEliminarCuenta() {
    showDialog(
      context: context,
      builder: (_) => _DialogoEliminarCuenta(
        uid: _uid,
        onEliminado: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
          );
        },
      ),
    );
  }


  // ─────────────────────────────────────────────────────────────
  // UTILIDADES
  // ─────────────────────────────────────────────────────────────

  /// Abre una URL en el navegador externo del sistema operativo.
  Future<void> _abrirUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }


  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? Colors.black            : const Color(0xFFF2F2F7);
    final bgCard = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final text1  = isDark ? Colors.white            : Colors.black87;
    final text2  = isDark ? Colors.white54          : Colors.black45;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [

          // SliverAppBar pinned para que el título quede visible al hacer scroll.
          SliverAppBar(
            pinned:          true,
            backgroundColor: bgCard,
            elevation:       0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_rounded,
                  color: text1, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('Ajustes',
                style: TextStyle(
                    color:      text1,
                    fontSize:   17,
                    fontWeight: FontWeight.w600)),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 28),

                // ── Sección: Cuenta ────────────────────────────
                _SectionLabel(label: 'CUENTA', text2: text2),
                _CardGroup(
                  bgCard: bgCard,
                  isDark: isDark,
                  children: [
                    _SettingsTile(
                      icon:      Icons.lock_outline_rounded,
                      iconColor: _accent,
                      title:     'Cambiar contraseña',
                      text1:     text1,
                      text2:     text2,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const _CambiarContrasenaScreen(),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ── Sección: Notificaciones ────────────────────
                _SectionLabel(label: 'NOTIFICACIONES', text2: text2),
                _CardGroup(
                  bgCard: bgCard,
                  isDark: isDark,
                  children: [
                    _SettingsRow(
                      icon:      Icons.favorite_border_rounded,
                      iconColor: _red,
                      title:     'Reacciones',
                      subtitle:  'Publicaciones a las que reaccionaste',
                      text1:     text1,
                      text2:     text2,
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => HistorialReaccionesScreen(isDark: isDark),
                      )),
                    ),
                    _Divider(isDark: isDark),
                    _SettingsRow(
                      icon:      Icons.chat_bubble_outline_rounded,
                      iconColor: _accent,
                      title:     'Comentarios',
                      subtitle:  'Publicaciones en las que comentaste',
                      text1:     text1,
                      text2:     text2,
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => HistorialComentariosScreen(isDark: isDark),
                      )),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ── Sección: Legal ─────────────────────────────
                _SectionLabel(label: 'LEGAL', text2: text2),
                _CardGroup(
                  bgCard: bgCard,
                  isDark: isDark,
                  children: [
                    _SettingsTile(
                      icon:      Icons.description_outlined,
                      iconColor: _orange,
                      title:     'Términos y condiciones',
                      text1:     text1,
                      text2:     text2,
                      onTap: () => _abrirUrl(
                        'https://programix-navejl.github.io/ASPIRANTES_ITVH/terminos.html',
                      ),
                    ),
                    _Divider(isDark: isDark),
                    _SettingsTile(
                      icon:      Icons.privacy_tip_outlined,
                      iconColor: _orange,
                      title:     'Política de privacidad',
                      text1:     text1,
                      text2:     text2,
                      onTap: () => _abrirUrl(
                        'https://programix-navejl.github.io/ASPIRANTES_ITVH/politicas.html',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ── Sección: Sesión ────────────────────────────
                _SectionLabel(label: 'SESIÓN', text2: text2),
                _CardGroup(
                  bgCard: bgCard,
                  isDark: isDark,
                  children: [
                    _SettingsTile(
                      icon:      Icons.logout_rounded,
                      iconColor: _accent,
                      title:     'Cerrar sesión',
                      text1:     text1,
                      text2:     text2,
                      showArrow: false,
                      onTap:     _cerrarSesion,
                    ),
                    _Divider(isDark: isDark),
                    _SettingsTile(
                      icon:       Icons.delete_forever_rounded,
                      iconColor:  _red,
                      title:      'Eliminar cuenta',
                      titleColor: _red,
                      text1:      text1,
                      text2:      text2,
                      showArrow:  false,
                      onTap:      _mostrarEliminarCuenta,
                    ),
                  ],
                ),

                const SizedBox(height: 48),

                // Pie de página con créditos.
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Aspirantes ITVH',
                        style: TextStyle(
                          color:      text2.withValues(alpha: 0.5),
                          fontSize:   13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Programix NaveJL © 2026',
                        style: TextStyle(
                          color:    text2.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ═════════════════════════════════════════════════════════════════
// SUB-PANTALLA: Cambiar contraseña
//
// Actualiza la contraseña del usuario autenticado vía Supabase Auth.
// Valida que la nueva contraseña tenga al menos 8 caracteres y que
// ambos campos coincidan antes de llamar a updateUser.
// ═════════════════════════════════════════════════════════════════

class _CambiarContrasenaScreen extends StatefulWidget {
  const _CambiarContrasenaScreen();

  @override
  State<_CambiarContrasenaScreen> createState() =>
      _CambiarContrasenaScreenState();
}

class _CambiarContrasenaScreenState
    extends State<_CambiarContrasenaScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _nuevaCtrl     = TextEditingController();
  final _confirmarCtrl = TextEditingController();

  bool _verNueva     = false;
  bool _verConfirmar = false;
  bool _cargando     = false;

  @override
  void dispose() {
    _nuevaCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  /// Valida el formulario y actualiza la contraseña en Supabase Auth.
  /// Los errores de AuthException se muestran en un SnackBar rojo;
  /// errores genéricos muestran un mensaje de reintento.
  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);

    try {
      await _sb.auth.updateUser(
        UserAttributes(password: _nuevaCtrl.text.trim()),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:  Text('Contraseña actualizada correctamente.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:         Text(e.message),
          behavior:        SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFFF3B30),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:         Text('Ocurrió un error. Intenta de nuevo.'),
          behavior:        SnackBarBehavior.floating,
          backgroundColor: Color(0xFFFF3B30),
        ),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? Colors.black            : const Color(0xFFF2F2F7);
    final bgCard = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final text1  = isDark ? Colors.white            : Colors.black87;
    final text2  = isDark ? Colors.white38          : Colors.black38;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor:        bgCard,
        elevation:              0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: text1, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Cambiar contraseña',
            style: TextStyle(
                color:      text1,
                fontSize:   17,
                fontWeight: FontWeight.w600)),
        actions: [
          TextButton(
            onPressed: _cargando ? null : _guardar,
            child: _cargando
                ? const SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF007AFF)),
            )
                : const Text('Guardar',
                style: TextStyle(
                    color:      Color(0xFF007AFF),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 8),
            _CardGroup(
              bgCard: bgCard,
              isDark: isDark,
              children: [
                _PasswordField(
                  controller: _nuevaCtrl,
                  label:      'Nueva contraseña',
                  visible:    _verNueva,
                  onToggle:   () =>
                      setState(() => _verNueva = !_verNueva),
                  validator: (v) {
                    // FIX: sentencias del if encerradas en bloque.
                    if (v == null || v.isEmpty) {
                      return 'Ingresa tu nueva contraseña';
                    }
                    if (v.length < 8) { return 'Mínimo 8 caracteres'; }
                    return null;
                  },
                ),
                _Divider(isDark: isDark),
                _PasswordField(
                  controller: _confirmarCtrl,
                  label:      'Confirmar contraseña',
                  visible:    _verConfirmar,
                  onToggle:   () =>
                      setState(() => _verConfirmar = !_verConfirmar),
                  validator: (v) => v != _nuevaCtrl.text
                      ? 'Las contraseñas no coinciden'
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'La nueva contraseña debe tener al menos 8 caracteres.',
                style: TextStyle(fontSize: 12, color: text2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ═════════════════════════════════════════════════════════════════
// DIÁLOGO: Eliminar cuenta
//
// Requiere que el usuario escriba "ELIMINAR" para habilitar el botón,
// previniendo eliminaciones accidentales.
//
// Flujo de eliminación:
//   1. Obtener URLs de medios de publicaciones del usuario.
//   2. Obtener URLs de historias del usuario.
//   3. Obtener foto de perfil del usuario.
//   4. Borrar el perfil en Supabase (cascade elimina el resto en BD).
//   5. Borrar los archivos físicos en Cloudflare R2.
//   6. Cerrar sesión y navegar al login.
//
// Los errores de borrado en R2 se silencian individualmente para
// no bloquear el flujo si un archivo ya no existe.
// ═════════════════════════════════════════════════════════════════

class _DialogoEliminarCuenta extends StatefulWidget {
  final String?      uid;
  final VoidCallback onEliminado;

  const _DialogoEliminarCuenta({
    required this.uid,
    required this.onEliminado,
  });

  @override
  State<_DialogoEliminarCuenta> createState() =>
      _DialogoEliminarCuentaState();
}

class _DialogoEliminarCuentaState
    extends State<_DialogoEliminarCuenta> {
  final _ctrl     = TextEditingController();
  bool  _valido   = false;
  bool  _cargando = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _eliminar() async {
    if (widget.uid == null) return;
    setState(() { _cargando = true; _error = null; });

    try {
      // 1. Medios de publicaciones del usuario.
      final mediosRaw = await _sb
          .from('publicacion_medios')
          .select('cdn_url, publicaciones!inner(autor_id)')
          .eq('publicaciones.autor_id', widget.uid!);

      // 2. Foto de perfil del usuario.
      final perfilRaw = await _sb
          .from('perfiles_aspirantes')
          .select('cdn_foto_perfil')
          .eq('id', widget.uid!)
          .maybeSingle();

      // 3. Borrar perfil — el cascade de Supabase elimina el resto en BD.
      await _sb.from('perfiles_aspirantes').delete().eq('id', widget.uid!);

      // 4. Borrar archivos físicos en R2.
      // Se itera en orden: publicaciones → foto de perfil.
      // Cada borrado se silencia individualmente para no bloquear
      // el flujo si el archivo ya fue eliminado previamente.
      for (final m in mediosRaw as List) {
        final url = m['cdn_url'] as String?;
        if (url == null || url.isEmpty) continue;
        try {
          await StorageService.instance.eliminarDeR2(
            bucket: R2Config.bucketPublicaciones,
            path:   url.replaceFirst('${R2Config.dominioPublicaciones}/', ''),
          );
        } catch (_) {}
      }

      final fotoPerfil = perfilRaw?['cdn_foto_perfil'] as String?;
      if (fotoPerfil != null && fotoPerfil.isNotEmpty) {
        try {
          await StorageService.instance.eliminarDeR2(
            bucket: R2Config.bucketPerfil,
            path:   fotoPerfil.replaceFirst('${R2Config.dominioPerfil}/', ''),
          );
        } catch (_) {}
      }

      // 5. Cerrar sesión y notificar al padre para navegar al login.
      await _sb.auth.signOut();
      if (!mounted) return;
      Navigator.pop(context);
      widget.onEliminado();
    } catch (_) {
      if (mounted) {
        setState(() {
          _cargando = false;
          _error    = 'No se pudo eliminar la cuenta. Intenta de nuevo.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      title: const Row(children: [
        Icon(Icons.warning_amber_rounded,
            color: Color(0xFFFF3B30), size: 22),
        SizedBox(width: 8),
        Text('Eliminar cuenta',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ]),
      content: Column(
        mainAxisSize:        MainAxisSize.min,
        crossAxisAlignment:  CrossAxisAlignment.start,
        children: [
          const Text(
            'Esta acción es permanente e irreversible. '
                'Se eliminarán tu perfil, publicaciones, '
                'historias y todos tus datos.\n',
          ),
          const Text(
            'Escribe ELIMINAR para confirmar:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          TextField(
            controller:         _ctrl,
            autofocus:          true,
            enabled:            !_cargando,
            // Mayúsculas automáticas para que coincida con "ELIMINAR"
            // sin que el usuario tenga que activar Caps Lock.
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'ELIMINAR',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              errorText: _error,
            ),
            onChanged: (v) =>
                setState(() => _valido = v.trim() == 'ELIMINAR'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _cargando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar',
              style: TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: (_valido && !_cargando) ? _eliminar : null,
          child: _cargando
              ? const SizedBox(
            width: 18, height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFFF3B30)),
          )
              : Text(
            'Eliminar cuenta',
            style: TextStyle(
                color: (_valido && !_cargando)
                    ? const Color(0xFFFF3B30)
                    : Colors.grey,
                fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}


// ═════════════════════════════════════════════════════════════════
// WIDGETS REUTILIZABLES
// ═════════════════════════════════════════════════════════════════

/// Etiqueta de sección en mayúsculas con sangría izquierda.
class _SectionLabel extends StatelessWidget {
  final String label;
  final Color  text2;
  const _SectionLabel({required this.label, required this.text2});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 20, bottom: 8),
    child: Text(
      label,
      style: TextStyle(
          color:         text2,
          fontSize:      12,
          fontWeight:    FontWeight.w600,
          letterSpacing: 0.6),
    ),
  );
}

/// Contenedor agrupador con bordes redondeados y borde sutil.
/// Usado para agrupar tiles relacionados en una sola card visual.
class _CardGroup extends StatelessWidget {
  final Color        bgCard;
  final bool         isDark;
  final List<Widget> children;

  const _CardGroup({
    required this.bgCard,
    required this.isDark,
    required this.children,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin:      const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color:        bgCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        // Borde muy sutil (6 % de opacidad) para diferenciar la card
        // del fondo sin generar un contraste agresivo.
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.06),
        width: 0.5,
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(children: children),
  );
}

/// Separador horizontal con sangría de 56 px para alinearse
/// con el texto de los tiles (después del ícono de 32 px + 12 px de gap).
class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 56),
    child: Divider(
      height:    0.5,
      thickness: 0.5,
      color: isDark ? Colors.white10 : Colors.black12,
    ),
  );
}

/// Fila de ajuste con ícono, título y flecha de navegación opcional.
/// `showArrow: false` se usa para acciones destructivas o de sesión
/// donde la flecha implicaría falsamente que hay una sub-pantalla.
class _SettingsTile extends StatelessWidget {
  final IconData      icon;
  final Color         iconColor;
  final String        title;
  final Color?        titleColor;
  final Color         text1;
  final Color         text2;
  final bool          showArrow;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.text1,
    required this.text2,
    this.titleColor,
    this.showArrow = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        _IconBox(icon: icon, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
                color:      titleColor ?? text1,
                fontSize:   15,
                fontWeight: FontWeight.w400),
          ),
        ),
        if (showArrow)
          Icon(Icons.chevron_right_rounded,
              size:  20,
              color: text2.withValues(alpha: 0.5)),
      ]),
    ),
  );
}

/// Contenedor cuadrado con fondo semitransparente del color del ícono.
/// El alpha de 12 % da el look de ícono sobre pastilla de color
/// sin saturar visualmente la pantalla.
class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color    color;
  const _IconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 32, height: 32,
    decoration: BoxDecoration(
      color:        color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(icon, size: 18, color: color),
  );
}

/// Campo de contraseña con toggle de visibilidad.
/// Acepta un validator para integrarse con Form/GlobalKey.
class _PasswordField extends StatelessWidget {
  final TextEditingController      controller;
  final String                     label;
  final bool                       visible;
  final VoidCallback               onToggle;
  final String? Function(String?)? validator;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.visible,
    required this.onToggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text1  = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller:  controller,
        obscureText: !visible,
        validator:   validator,
        style: TextStyle(color: text1, fontSize: 15),
        decoration: InputDecoration(
          labelText:  label,
          labelStyle: TextStyle(
              color:    isDark ? Colors.white54 : Colors.black45,
              fontSize: 13),
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(
              visible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size:  20,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }
}

/// Fila de ajuste con ícono, título, subtítulo y flecha de navegación.
/// A diferencia de _SettingsTile, siempre muestra subtítulo y flecha,
/// usado para accesos a sub-pantallas con contexto descriptivo.
class _SettingsRow extends StatelessWidget {
  final IconData     icon;
  final Color        iconColor;
  final String       title;
  final String       subtitle;
  final Color        text1;
  final Color        text2;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.text1,
    required this.text2,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color:        iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color:      text1,
                          fontSize:   15,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(color: text2, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: text2, size: 20),
          ],
        ),
      ),
    );
  }
}