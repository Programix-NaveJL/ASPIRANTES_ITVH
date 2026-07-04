// ═════════════════════════════════════════════════════════════════
// iniciar_sesion.dart — Aspirantes ITVH
//
// Pantalla de inicio de sesión de Aspirantes ITVH.
//
// Permite autenticarse con correo electrónico o nombre de usuario.
// Si se ingresa un nombre de usuario, se resuelve primero el correo
// asociado en la tabla `perfiles_aspirantes` antes de llamar a
// Supabase Auth.
//
// Flujo de login:
//   1. Validar que los campos no estén vacíos.
//   2. Si el identificador no contiene '@', buscar el correo
//      asociado al nombre de usuario en `perfiles_aspirantes`.
//   3. Autenticar con Supabase Auth (email + password).
//   4. Verificar `estado_cuenta` en `perfiles_aspirantes`:
//        • 'suspendido' | 'expulsado' → cerrar sesión y mostrar
//          el bottom sheet de bloqueo.
//        • 'activo'                   → AuthGate detecta el evento
//          signedIn y navega al Feed automáticamente.
//
// Widgets internos:
//   • _GlassField — campo de texto con estilo glassmorphism,
//     animación de foco y soporte para trailing widget.
// ═════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui';

import 'crear_cuenta.dart';

// Nota: si Aspirantes ITVH tendrá su propia pantalla de recuperación
// de contraseña, agrégala aquí y descomenta el import + navegación
// en "¿Olvidaste tu contraseña?" más abajo.
// import 'recuperar_contrasena.dart';


// ═════════════════════════════════════════════════════════════════
// LOGIN SCREEN
// ═════════════════════════════════════════════════════════════════

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {

  // ── Controladores y focus nodes ──────────────────────────────
  final _identifierController = TextEditingController();
  final _passwordController   = TextEditingController();
  final _identifierFocus      = FocusNode();
  final _passwordFocus        = FocusNode();

  // ── Estado local ─────────────────────────────────────────────
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
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _identifierFocus.dispose();
    _passwordFocus.dispose();
    _animController.dispose();
    super.dispose();
  }


  // ─────────────────────────────────────────────────────────────
  // LOGIN
  // ─────────────────────────────────────────────────────────────

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    final identifier = _identifierController.text.trim();
    final password   = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      _showError('Completa todos los campos.');
      return;
    }

    setState(() => _loading = true);

    try {
      // Si no contiene '@', se asume que es un nombre de usuario
      // y se resuelve el correo asociado antes de autenticar.
      String email = identifier;

      if (!identifier.contains('@')) {
        final result = await Supabase.instance.client
            .from('perfiles_aspirantes')
            .select('email')
            .or('nombre_usuario.eq.$identifier,numero_ficha.eq.$identifier')
            .maybeSingle();

        if (result == null) {
          if (mounted) setState(() => _loading = false);
          _showError('Usuario o contraseña incorrectos.');
          return;
        }

        email = result['email'] as String;
      }

      // Autenticación con Supabase Auth.
      await Supabase.instance.client.auth.signInWithPassword(
        email:    email,
        password: password,
      );

      // Verificar que la cuenta no esté suspendida o expulsada.
      // AuthGate también lo verifica, pero esta comprobación local
      // permite mostrar el bottom sheet de bloqueo inmediatamente
      // sin esperar a que el stream de auth lo detecte.
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid != null) {
        final perfil = await Supabase.instance.client
            .from('perfiles_aspirantes')
            .select('estado_cuenta')
            .eq('id', uid)
            .single();

        final estado = perfil['estado_cuenta'] as String? ?? 'activo';

        if (estado == 'suspendido' || estado == 'expulsado') {
          await Supabase.instance.client.auth.signOut();

          if (mounted) {
            setState(() => _loading = false);
            _mostrarPantallaBloqueo(estado);
            return;
          }
        }
      }

      // Login exitoso — AuthGate detecta el evento signedIn
      // y navega al Feed automáticamente.
    } on AuthException catch (e) {
      if (mounted) setState(() => _loading = false);
      _showError(_traducirError(e.message));
    } catch (_) {
      if (mounted) setState(() => _loading = false);
      _showError('Error de conexión. Intenta de nuevo.');
    }
  }

  /// Traduce los mensajes de error de Supabase Auth al español.
  String _traducirError(String msg) {
    final lower = msg.toLowerCase();

    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid email or password')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Confirma tu correo antes de iniciar sesión.';
    }
    if (lower.contains('too many requests')) {
      return 'Demasiados intentos. Espera un momento.';
    }
    return 'Error al iniciar sesión. Intenta de nuevo.';
  }


  // ─────────────────────────────────────────────────────────────
  // BOTTOM SHEET DE BLOQUEO
  //
  // Se muestra cuando la cuenta está suspendida o expulsada.
  // No se puede cerrar con gesto ni con el botón de atrás.
  // ─────────────────────────────────────────────────────────────

  void _mostrarPantallaBloqueo(String estado) {
    final esSuspendido = estado == 'suspendido';
    final color        = esSuspendido ? Colors.amber : Colors.red;

    showModalBottomSheet(
      context:           context,
      isDismissible:     false,
      enableDrag:        false,
      isScrollControlled: true,
      backgroundColor:   Colors.transparent,
      builder: (_) => PopScope(
        canPop: false,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color:        Color(0xFF1C1C1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                // Ícono de estado
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color:  color.withValues(alpha:0.15),
                    shape:  BoxShape.circle,
                  ),
                  child: Icon(
                    esSuspendido
                        ? Icons.lock_outline_rounded
                        : Icons.block_rounded,
                    size:  48,
                    color: color,
                  ),
                ),
                const SizedBox(height: 24),

                // Título
                Text(
                  esSuspendido ? 'Cuenta suspendida' : 'Cuenta eliminada',
                  style: const TextStyle(
                    color:      Colors.white,
                    fontSize:   22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),

                // Descripción
                Text(
                  esSuspendido
                      ? 'Tu cuenta ha sido suspendida temporalmente por violar las normas de la comunidad. Si crees que es un error, contacta a un administrador.'
                      : 'Tu cuenta ha sido eliminada permanentemente de la plataforma por violar gravemente las normas de la comunidad. No es posible recuperarla.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color:    Colors.white60,
                    fontSize: 14,
                    height:   1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // Botón de confirmación
                SizedBox(
                  width:  double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side:  const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Entendido',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }


  // ─────────────────────────────────────────────────────────────
  // SNACKBAR DE ERROR
  // ─────────────────────────────────────────────────────────────

  /// Muestra un SnackBar flotante con el mensaje de error recibido.
  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(msg)),
        ]),
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
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [

          // ── Fondo: imagen del campus ───────────────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/images/tec_villahermosa.png',
              fit: BoxFit.cover,
            ),
          ),

          // ── Overlay: gradiente oscuro para legibilidad ─────────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha:0.65),
                    Colors.black.withValues(alpha:0.45),
                    Colors.black.withValues(alpha:0.85),
                  ],
                  begin: Alignment.topCenter,
                  end:   Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // ── Contenido principal ────────────────────────────────
          SafeArea(
            child: Center(
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
                        const SizedBox(height: 28),

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
                                color: Colors.white.withValues(alpha:0.08),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha:0.18),
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                mainAxisSize:       MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  // ── Encabezado ─────────────────
                                  const Text(
                                    'Bienvenido',
                                    style: TextStyle(
                                      color:      Colors.white,
                                      fontSize:   28,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Inicia sesión para continuar',
                                    style: TextStyle(
                                      color:    Colors.white60,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 28),

                                  // ── Campo usuario / correo ──────
                                  _GlassField(
                                    controller:      _identifierController,
                                    focusNode:       _identifierFocus,
                                    hint:            'Correo',
                                    icon:            Icons.person_outline_rounded,
                                    textInputAction: TextInputAction.next,
                                    onSubmitted:     (_) => _passwordFocus.requestFocus(),
                                    keyboardType:    TextInputType.text, // antes era emailAddress
                                  ),
                                  const SizedBox(height: 14),

                                  // ── Campo contraseña ────────────
                                  _GlassField(
                                    controller:      _passwordController,
                                    focusNode:       _passwordFocus,
                                    hint:            'Contraseña',
                                    icon:            Icons.lock_outline_rounded,
                                    obscure:         _obscure,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted:     (_) => _login(),
                                    trailing: GestureDetector(
                                      onTap: () => setState(() => _obscure = !_obscure),
                                      child: Icon(
                                        _obscure
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: Colors.white38,
                                        size:  20,
                                      ),
                                    ),
                                  ),

                                  // ── ¿Olvidaste tu contraseña? ───
                                  // Placeholder: implementa una pantalla de
                                  // recuperación (recuperar_contrasena.dart)
                                  // y reemplaza este SnackBar por la
                                  // navegación correspondiente.
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Recuperación de contraseña próximamente.',
                                            ),
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        padding:       EdgeInsets.zero,
                                        minimumSize:   Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      child: const Padding(
                                        padding: EdgeInsets.only(top: 8, bottom: 4),
                                        child: Text(
                                          '¿Olvidaste tu contraseña?',
                                          style: TextStyle(
                                            color:      Color(0xFF00C6FF),
                                            fontSize:   13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // ── Botón iniciar sesión ────────
                                  SizedBox(
                                    width:  double.infinity,
                                    height: 52,
                                    child: ElevatedButton(
                                      onPressed: _loading ? null : _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:        const Color(0xFF00C6FF),
                                        disabledBackgroundColor: const Color(0xFF00C6FF)
                                            .withValues(alpha:0.5),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: _loading
                                          ? const SizedBox(
                                        width:  22,
                                        height: 22,
                                        child:  CircularProgressIndicator(
                                          color:       Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                          : const Text(
                                        'Iniciar sesión',
                                        style: TextStyle(
                                          color:      Colors.white,
                                          fontSize:   16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // ── Ir a registro ───────────────
                                  Center(
                                    child: TextButton(
                                      onPressed: () => Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const RegisterScreen(),
                                        ),
                                            (_) => false,
                                      ),
                                      child: RichText(
                                        text: const TextSpan(
                                          style: TextStyle(
                                            fontSize: 13,
                                            color:    Colors.white54,
                                          ),
                                          children: [
                                            TextSpan(text: '¿No tienes cuenta? '),
                                            TextSpan(
                                              text:  'Regístrate',
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
          ),

        ],
      ),
    );
  }
}


// ═════════════════════════════════════════════════════════════════
// _GLASS FIELD
//
// Campo de texto con estilo glassmorphism reutilizable.
//
// Características:
//   • Animación de foco: cambia color de borde e ícono al enfocar.
//   • Soporte para campo de contraseña (obscureText).
//   • Trailing widget opcional (ej. toggle de visibilidad).
//   • Compatible con TextInputAction para navegación entre campos.
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

  // Función nombrada para poder removerla en dispose y evitar
  // acumulación de listeners si el widget se reconstruye.
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
            ? Colors.white.withValues(alpha:0.12)
            : Colors.white.withValues(alpha:0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _focused
              ? const Color(0xFF00C6FF).withValues(alpha:0.7)
              : Colors.white.withValues(alpha:0.12),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.icon,
            color: _focused ? const Color(0xFF00C6FF) : Colors.white38,
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