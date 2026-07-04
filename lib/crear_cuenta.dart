// ═════════════════════════════════════════════════════════════════
// crear_cuenta.dart — Aspirantes ITVH
//
// Pantalla de registro de nuevos aspirantes.
//
// A diferencia de Comunidad TecNM (correo institucional), aquí se
// permite cualquier correo personal, y NO se exige confirmación de
// correo (Supabase Auth → Providers → Email → "Confirm email" está
// desactivado). La validación de identidad recae únicamente en:
//   • Número de ficha de aspirante (6 dígitos, debe iniciar en "26"
//     — ciclo de ingreso 2026, ej. 260000–269999). Declarado por el
//     usuario, sin validación contra una lista oficial por ahora.
//
// Flujo de registro:
//   1. Validar todos los campos localmente.
//   2. Verificar que el nombre de usuario no esté en uso (ilike).
//   3. Verificar que el número de ficha no esté en uso.
//   4. Crear el usuario en Supabase Auth (signUp). Como "Confirm
//      email" está desactivado, la sesión queda activa de inmediato
//      (no depende de ningún correo ni SMTP).
//   5. Intentar el upsert del perfil desde el cliente (best-effort —
//      se ignora si falla por RLS; el trigger handle_new_aspirante
//      del servidor cubre ese caso).
//   6. Navegar directo al Feed con la sesión ya activa.
//
// Secciones del formulario:
//   • Datos personales  — nombre completo, usuario, ficha de aspirante
//   • Información académica — carrera de interés (dropdown cargado
//     DINÁMICAMENTE desde la tabla `carreras` de Supabase — igual
//     que en editar_perfil_aspirante.dart, ya que carrera_id es una
//     FK real en perfiles_aspirantes, no texto libre)
//   • Datos de acceso   — correo personal y contraseña
//
// Widgets internos:
//   • _GlassField    — campo de texto glassmorphism con animación de foco
//   • _GlassDropdown — dropdown glassmorphism genérico tipado
// ═════════════════════════════════════════════════════════════════

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'iniciar_sesion.dart';

// Color de acento compartido en toda la pantalla.
const _accent = Color(0xFF00C6FF);


// ═════════════════════════════════════════════════════════════════
// REGISTER SCREEN
// ═════════════════════════════════════════════════════════════════

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {

  // ── Controladores de texto ────────────────────────────────────
  final _nombreController   = TextEditingController();
  final _usuarioController  = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _fichaController    = TextEditingController();

  // ── Focus nodes ───────────────────────────────────────────────
  final _nombreFocus   = FocusNode();
  final _usuarioFocus  = FocusNode();
  final _emailFocus    = FocusNode();
  final _passwordFocus = FocusNode();
  final _fichaFocus    = FocusNode();

  // ── Selección de dropdown ─────────────────────────────────────
  // Guarda el uuid (carrera_id) de la carrera seleccionada, no el
  // nombre — la columna real en perfiles_aspirantes es una FK.
  String? _carreraIdSeleccionada;

  // ── Catálogo de carreras del ITVH ────────────────────────────
  // Cargado dinámicamente desde la tabla `carreras` (igual que en
  // editar_perfil_aspirante.dart), para que el id coincida siempre
  // con la FK real y con lo que espera el trigger handle_new_aspirante.
  List<Map<String, dynamic>> _carreras = [];
  bool _cargandoCarreras = true;

  // ── Estado local ──────────────────────────────────────────────
  bool _loading = false;
  bool _obscure = true;

  // ── Animación de entrada (fade + slide) ──────────────────────
  late final AnimationController _animController;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;


  // ─────────────────────────────────────────────────────────────
  // CICLO DE VIDA
  // ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve:  Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end:   Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve:  Curves.easeOut,
    ));

    _animController.forward();
    _cargarCarreras();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _usuarioController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fichaController.dispose();
    _nombreFocus.dispose();
    _usuarioFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _fichaFocus.dispose();
    _animController.dispose();
    super.dispose();
  }


  // ─────────────────────────────────────────────────────────────
  // CARGA DE CARRERAS (dinámica, desde la tabla `carreras`)
  // ─────────────────────────────────────────────────────────────

  Future<void> _cargarCarreras() async {
    try {
      final data = await Supabase.instance.client
          .from('carreras')
          .select('id, nombre')
          .eq('activa', true)
          .order('nombre');

      if (!mounted) return;
      setState(() {
        _carreras         = (data as List).cast<Map<String, dynamic>>();
        _cargandoCarreras = false;
      });
    } catch (e) {
      debugPrint('RegisterScreen – error al cargar carreras: $e');
      if (mounted) setState(() => _cargandoCarreras = false);
    }
  }


  // ─────────────────────────────────────────────────────────────
  // REGISTRO
  // ─────────────────────────────────────────────────────────────

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    final nombre   = _nombreController.text.trim();
    final usuario  = _usuarioController.text.trim();
    final email    = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();
    final ficha    = _fichaController.text.trim();

    // ── Validaciones locales ──────────────────────────────────
    if (nombre.isEmpty) {
      _showError('Ingresa tu nombre completo.');
      return;
    }
    if (usuario.isEmpty) {
      _showError('Ingresa un nombre de usuario.');
      return;
    }
    if (usuario.contains(' ')) {
      _showError('El usuario no puede tener espacios.');
      return;
    }

    // Número de ficha de aspirante: 6 dígitos, debe empezar con "26"
    // (ciclo de ingreso 2026). Ej. 260000–269999.
    final regexFicha = RegExp(r'^26\d{4}$');
    if (!regexFicha.hasMatch(ficha)) {
      _showError('El número de ficha debe tener 6.');
      return;
    }

    if (email.isEmpty || !email.contains('@')) {
      _showError('Ingresa un correo electrónico válido.');
      return;
    }
    if (password.length < 6) {
      _showError('La contraseña debe tener al menos 6 caracteres.');
      return;
    }
    if (_carreraIdSeleccionada == null) {
      _showError('Selecciona la carrera de tu interés.');
      return;
    }

    setState(() => _loading = true);

    try {
      // Verificar unicidad del nombre de usuario (case-insensitive).
      final usuarioExistente = await Supabase.instance.client
          .from('perfiles_aspirantes')
          .select('id')
          .ilike('nombre_usuario', usuario)
          .maybeSingle();

      if (usuarioExistente != null) {
        _showError('Ese nombre de usuario ya está en uso.');
        setState(() => _loading = false);
        return;
      }

      // Verificar unicidad de la ficha de aspirante.
      final fichaExistente = await Supabase.instance.client
          .from('perfiles_aspirantes')
          .select('id')
          .eq('numero_ficha', ficha)
          .maybeSingle();

      if (fichaExistente != null) {
        _showError('Ese número de ficha ya está registrado.');
        setState(() => _loading = false);
        return;
      }

      // Crear el usuario en Supabase Auth. Se envían los datos del
      // perfil como metadata para que el trigger handle_new_aspirante
      // pueda crear la fila en `perfiles_aspirantes` sin depender de
      // que el cliente tenga sesión activa (correo aún sin confirmar).
      // 'carrera_id' es el uuid real de la tabla `carreras`, tal como
      // lo espera el trigger: (raw_user_meta_data->>'carrera_id')::uuid
      final res = await Supabase.instance.client.auth.signUp(
        email:    email,
        password: password,
        data: {
          'nombre':         nombre,
          'nombre_usuario': usuario,
          'numero_ficha':   ficha,
          'carrera_id':     _carreraIdSeleccionada,
        },
      );

      final uid = res.user?.id;
      if (uid == null) throw Exception('No se pudo crear el usuario.');

      // Intento best-effort de crear/actualizar el perfil desde el
      // cliente. Si la confirmación de correo está habilitada y el
      // cliente no tiene sesión todavía, esto puede fallar por RLS;
      // en ese caso el trigger handle_new_aspirante se encarga.
      try {
        await Supabase.instance.client.from('perfiles_aspirantes').upsert({
          'id':              uid,
          'nombre':          nombre,
          'nombre_usuario':  usuario,
          'email':           email,
          'numero_ficha':    ficha,
          'carrera_id':      _carreraIdSeleccionada,
        });
      } catch (_) {
        // Se ignora — el trigger del servidor debe cubrir este caso.
      }

      if (!mounted) return;

      // Con "Confirm email" desactivado en Supabase, signUp() siempre
      // regresa sesión activa de inmediato — no depende de que el
      // usuario confirme nada por correo. La validación de identidad
      // ahora recae solo en el número de ficha (6 dígitos, inicia en 26).
      if (res.session != null) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Fallback por si "Confirm email" se reactiva más adelante.
        setState(() => _loading = false);
        _mostrarAvisoConfirmacion(email);
      }

    } on AuthException catch (e) {
      // ── DEBUG: imprime el error real de Supabase Auth ──────────
      // _traducirError() generaliza el mensaje para el usuario, pero
      // aquí vemos exactamente qué está fallando del lado del servidor.
      debugPrint('❌ AuthException en _register():');
      debugPrint('   message    -> ${e.message}');
      debugPrint('   statusCode -> ${e.statusCode}');
      debugPrint('   code       -> ${e.code}');

      _showError(_traducirError(e.message));
      if (mounted) setState(() => _loading = false);
    } catch (e, stackTrace) {
      // ── DEBUG: captura cualquier error no-Auth (red, parsing, etc.) ──
      debugPrint('❌ Error inesperado en _register(): $e');
      debugPrint('$stackTrace');

      _showError('Error al crear la cuenta. Intenta de nuevo.');
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Traduce los mensajes de error de Supabase Auth al español.
  /// También captura errores de constraints de la base de datos
  /// que Supabase devuelve envueltos como AuthException.
  String _traducirError(String msg) {
    final lower = msg.toLowerCase();

    if (lower.contains('database error')         ||
        lower.contains('unexpected_failure')      ||
        lower.contains('violates check constraint')) {
      return 'Revisa tu número de ficha (6 dígitos) o el correo '
          'ya está registrado.';
    }
    if (lower.contains('user already registered') ||
        lower.contains('already been registered')) {
      return 'Ya existe una cuenta con ese correo.';
    }
    if (lower.contains('password should be at least')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (lower.contains('invalid email') || lower.contains('bad request')) {
      return 'El formato del correo electrónico no es válido.';
    }
    if (lower.contains('signup is disabled')) {
      return 'El registro está deshabilitado temporalmente.';
    }
    return msg;
  }


  // ─────────────────────────────────────────────────────────────
  // AVISO DE CONFIRMACIÓN DE CORREO
  // ─────────────────────────────────────────────────────────────

  void _mostrarAvisoConfirmacion(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: const Icon(Icons.mark_email_read_outlined,
            color: _accent, size: 36),
        title: const Text(
          'Confirma tu correo',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Enviamos un enlace de confirmación a $email. '
              'Ábrelo y luego inicia sesión con tu correo y contraseña.',
          style: const TextStyle(color: Colors.white60),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
            ),
            child: const Text('Entendido',
                style: TextStyle(color: _accent)),
          ),
        ],
      ),
    );
  }


  // ─────────────────────────────────────────────────────────────
  // SNACKBAR DE ERROR
  // ─────────────────────────────────────────────────────────────

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior:        SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }


  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Intercepta el botón de atrás para redirigir al Login
      // en lugar de cerrar la app o dejar el stack en mal estado.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
        );
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [

            // ── Fondo: imagen del campus ─────────────────────────
            Positioned.fill(
              child: Image.asset(
                'assets/images/tec_villahermosa.png',
                fit: BoxFit.cover,
              ),
            ),

            // ── Overlay: gradiente oscuro para legibilidad ───────
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.black.withValues(alpha: 0.70),
                      Colors.black.withValues(alpha: 0.90),
                    ],
                    begin: Alignment.topCenter,
                    end:   Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // ── Contenido principal ──────────────────────────────
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical:   32,
                ),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      children: [

                        // Logo de la app
                        Image.asset(
                          'assets/icons/splash_foreground.png',
                          height: 165,
                        ),
                        const SizedBox(height: 24),

                        // ── Tarjeta glassmorphism ────────────────
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical:   32,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  // Encabezado
                                  const Text(
                                    'Crear cuenta',
                                    style: TextStyle(
                                      color:         Colors.white,
                                      fontSize:      28,
                                      fontWeight:    FontWeight.w700,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Regístrate como aspirante de nuevo ingreso',
                                    style: TextStyle(
                                      color:    Colors.white60,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // ── Sección: Datos personales ──
                                  _sectionLabel('Datos personales'),
                                  const SizedBox(height: 10),

                                  _GlassField(
                                    controller:      _nombreController,
                                    focusNode:       _nombreFocus,
                                    hint:            'Nombre completo',
                                    icon:            Icons.badge_outlined,
                                    textInputAction: TextInputAction.next,
                                    onSubmitted:     (_) => _usuarioFocus.requestFocus(),
                                  ),
                                  const SizedBox(height: 12),

                                  _GlassField(
                                    controller:      _usuarioController,
                                    focusNode:       _usuarioFocus,
                                    hint:            'Nombre de usuario',
                                    icon:            Icons.alternate_email_rounded,
                                    textInputAction: TextInputAction.next,
                                    onSubmitted:     (_) => _fichaFocus.requestFocus(),
                                  ),
                                  const SizedBox(height: 12),

                                  _GlassField(
                                    controller:      _fichaController,
                                    focusNode:       _fichaFocus,
                                    hint:            'Número de ficha',
                                    icon:            Icons.numbers_rounded,
                                    keyboardType:    TextInputType.number,
                                    textInputAction: TextInputAction.next,
                                    onSubmitted:     (_) => _emailFocus.requestFocus(),
                                  ),
                                  const SizedBox(height: 20),

                                  // ── Sección: Académico ─────────
                                  _sectionLabel('Información académica'),
                                  const SizedBox(height: 10),

                                  // Catálogo dinámico: cargado desde la
                                  // tabla `carreras` de Supabase. Mientras
                                  // carga, el dropdown queda deshabilitado
                                  // (sin items) y con hint de "Cargando...".
                                  _GlassDropdown<String>(
                                    hint: _cargandoCarreras
                                        ? 'Cargando carreras...'
                                        : 'Carrera de tu interés',
                                    icon:      Icons.school_outlined,
                                    value:     _carreraIdSeleccionada,
                                    items:     _carreras
                                        .map((c) => c['id'] as String)
                                        .toList(),
                                    itemLabel: (id) => _carreras.firstWhere(
                                          (c) => c['id'] == id,
                                    )['nombre'] as String,
                                    onChanged: _cargandoCarreras
                                        ? null
                                        : (v) => setState(
                                            () => _carreraIdSeleccionada = v),
                                  ),
                                  const SizedBox(height: 20),

                                  // ── Sección: Datos de acceso ───
                                  _sectionLabel('Datos de acceso'),
                                  const SizedBox(height: 10),

                                  _GlassField(
                                    controller:      _emailController,
                                    focusNode:       _emailFocus,
                                    hint:            'Correo electrónico',
                                    icon:            Icons.email_outlined,
                                    keyboardType:    TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    onSubmitted:     (_) => _passwordFocus.requestFocus(),
                                  ),
                                  const SizedBox(height: 12),

                                  _GlassField(
                                    controller:      _passwordController,
                                    focusNode:       _passwordFocus,
                                    hint:            'Contraseña',
                                    icon:            Icons.lock_outline_rounded,
                                    obscure:         _obscure,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted:     (_) => _register(),
                                    trailing: GestureDetector(
                                      onTap: () => setState(() => _obscure = !_obscure),
                                      child: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 200),
                                        child: Icon(
                                          _obscure
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          key:   ValueKey(_obscure),
                                          color: Colors.white38,
                                          size:  20,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  const Text(
                                    'Usa tu número de ficha de aspirante '
                                        'para completar tu registro.',
                                    style: TextStyle(
                                      color:    Colors.white38,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // ── Botón crear cuenta ─────────
                                  SizedBox(
                                    width:  double.infinity,
                                    height: 52,
                                    child: ElevatedButton(
                                      onPressed: _loading ? null : _register,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:        _accent,
                                        disabledBackgroundColor: _accent.withValues(alpha: 0.5),
                                        foregroundColor:         Colors.white,
                                        elevation:               0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      // AnimatedSwitcher para transición
                                      // suave entre spinner y texto.
                                      child: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 200),
                                        child: _loading
                                            ? const SizedBox(
                                          key:    ValueKey('loading'),
                                          width:  22,
                                          height: 22,
                                          child:  CircularProgressIndicator(
                                            color:       Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                            : const Text(
                                          key: ValueKey('text'),
                                          'Crear cuenta',
                                          style: TextStyle(
                                            fontSize:      16,
                                            fontWeight:    FontWeight.w600,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // ── Ir al login ────────────────
                                  Center(
                                    child: TextButton(
                                      onPressed: () => Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const LoginScreen(),
                                        ),
                                            (route) => false,
                                      ),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white70,
                                      ),
                                      child: RichText(
                                        text: const TextSpan(
                                          style: TextStyle(
                                            fontSize: 13,
                                            color:    Colors.white54,
                                          ),
                                          children: [
                                            TextSpan(text: '¿Ya tienes cuenta? '),
                                            TextSpan(
                                              text:  'Inicia sesión',
                                              style: TextStyle(
                                                color:      Color(0xFF00C6FF),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                ],
                              ),
                            ),
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  /// Etiqueta de sección en mayúsculas con estilo discreto.
  /// Usada para separar visualmente los grupos del formulario.
  Widget _sectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color:         Colors.white38,
        fontSize:      11,
        fontWeight:    FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}


// ═════════════════════════════════════════════════════════════════
// _GLASS FIELD
//
// Campo de texto con estilo glassmorphism reutilizable.
// Mismo comportamiento que en LoginScreen: animación de foco,
// cambio de color en borde e ícono, y soporte para trailing.
// ═════════════════════════════════════════════════════════════════

class _GlassField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode             focusNode;
  final String                hint;
  final IconData              icon;
  final bool                  obscure;
  final Widget?               trailing;
  final TextInputAction       textInputAction;
  final ValueChanged<String>? onSubmitted;
  final TextInputType         keyboardType;

  const _GlassField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.icon,
    this.obscure         = false,
    this.trailing,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.keyboardType    = TextInputType.text,
  });

  @override
  State<_GlassField> createState() => _GlassFieldState();
}

class _GlassFieldState extends State<_GlassField> {
  bool _focused = false;

  void _onFocusChange() {
    if (mounted) setState(() => _focused = widget.focusNode.hasFocus);
  }

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding:  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: _focused
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _focused
              ? _accent.withValues(alpha: 0.7)
              : Colors.white.withValues(alpha: 0.12),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.icon,
            color: _focused ? _accent : Colors.white38,
            size:  20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller:      widget.controller,
              focusNode:       widget.focusNode,
              obscureText:     widget.obscure,
              textInputAction: widget.textInputAction,
              keyboardType:    widget.keyboardType,
              onSubmitted:     widget.onSubmitted,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                border:         InputBorder.none,
                hintText:       widget.hint,
                hintStyle:      const TextStyle(color: Colors.white30, fontSize: 15),
                isDense:        true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (widget.trailing != null) widget.trailing!,
        ],
      ),
    );
  }
}


// ═════════════════════════════════════════════════════════════════
// _GLASS DROPDOWN
//
// Dropdown genérico tipado con estilo glassmorphism.
// Acepta cualquier tipo T con un itemLabel opcional para
// personalizar el texto mostrado (ej. nombre de carrera a partir
// de su id).
// ═════════════════════════════════════════════════════════════════

class _GlassDropdown<T> extends StatelessWidget {
  final String           hint;
  final IconData         icon;
  final T?               value;
  final List<T>          items;
  final String Function(T)? itemLabel;
  final ValueChanged<T?>? onChanged;

  const _GlassDropdown({
    required this.hint,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
    this.itemLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value:         value,
                isExpanded:    true,
                dropdownColor: const Color(0xFF1C1C2E),
                style: const TextStyle(color: Colors.white, fontSize: 15),
                hint: Text(
                  hint,
                  style: const TextStyle(color: Colors.white30, fontSize: 15),
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white38,
                ),
                items: items.map((e) => DropdownMenuItem<T>(
                  value: e,
                  child: Text(
                    itemLabel != null ? itemLabel!(e) : e.toString(),
                    overflow: TextOverflow.ellipsis,
                  ),
                )).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}