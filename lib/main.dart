// ═════════════════════════════════════════════════════════════════
// main.dart — Aspirantes ITVH
//
// Punto de entrada de la aplicación.
//
// Responsabilidades:
//   1. Inicializar Supabase (auth, db, storage) antes de correr la app.
//   2. Definir el MaterialApp con tema oscuro por defecto.
//   3. AuthGate — widget raíz que escucha los cambios de sesión de
//      Supabase Auth y decide qué pantalla mostrar:
//        • Sin sesión activa   → LoginScreen
//        • Sesión activa       → FeedAspirantes (feed.dart)
//   4. isDarkNotifier — ValueNotifier global de tema claro/oscuro.
//      Antes vivía como override local dentro de FeedAspirantes; ahora
//      cualquier pantalla de la app puede leerlo o cambiarlo, y el
//      MaterialApp reacciona reconstruyendo el ThemeData completo.
//
// ── DEBUG (no compila / no corre en Flutter Web) ────────────────────
// Se agregaron 3 capas de captura de errores porque en Web, si algo
// truena ANTES de runApp() (o en un microtask fuera del árbol de
// widgets), no aparece nada en pantalla — ni siquiera un error rojo.
// El único rastro queda en la consola del navegador (F12 → Console):
//   1. runZonedGuarded  → captura excepciones async no atrapadas
//      (ej. si Supabase.initialize() o SharedPreferences truenan).
//   2. FlutterError.onError → captura errores de framework/widgets.
//   3. PlatformDispatcher.instance.onError → captura errores que
//      escapan incluso de runZonedGuarded (errores de plataforma/JS,
//      comunes en web con CanvasKit/HTML renderer).
// Además hay debugPrint en cada paso del arranque y en AuthGate,
// para ver en la consola hasta dónde llega la ejecución.
//
// NOTA: si el problema es que el BUILD mismo falla (no que la app
// carga en blanco, sino que `flutter run -d chrome` o
// `flutter build web` tira un error de compilación), estos prints
// no van a ayudar — ese error sale directo en la terminal donde
// corriste el comando, antes de que la app siquiera llegue a
// ejecutarse. En ese caso pega aquí el error completo de la terminal.
// ═════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'iniciar_sesion.dart';
import 'feed.dart';

// ── Credenciales del proyecto Supabase de Aspirantes ITVH ────────
// La anon key es pública por diseño (protegida por RLS del lado
// del servidor); es seguro incluirla en el cliente.
const _supabaseUrl     = 'https://xllfczvhzfnccbzeedqd.supabase.co';
const _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhsbGZjenZoemZuY2NiemVlZHFkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI4NzEwNzMsImV4cCI6MjA5ODQ0NzA3M30.HXUKiwlG_Q8jEvFktjDHE-kYTuKSt5JddsIezxJADOs';


// ═════════════════════════════════════════════════════════════════
// TEMA GLOBAL
//
// true  = modo oscuro · false = modo claro.
// Vive aquí (no en feed.dart) porque es main.dart quien define el
// ThemeData del MaterialApp; cualquier otra pantalla que necesite
// leerlo o cambiarlo solo importa este archivo.
//
// No persiste entre sesiones todavía (no usa SharedPreferences).
// Valor inicial en oscuro para igualar el ThemeData previo.
// ═════════════════════════════════════════════════════════════════

final ValueNotifier<bool> isDarkNotifier = ValueNotifier<bool>(true);

/// Key de SharedPreferences donde se guarda el modo elegido.
const _prefsKeyIsDark = 'is_dark_mode';


// ═════════════════════════════════════════════════════════════════
// ENTRY POINT
// ═════════════════════════════════════════════════════════════════

void main() {
  // ── Capa 3: errores de plataforma/JS que escapan a todo lo demás.
  // Especialmente relevante en Web — sin esto, un error del motor de
  // renderizado (CanvasKit) o de una llamada a JS interop puede
  // matar el arranque sin dejar rastro visible.
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('🔴 [PlatformDispatcher] Error no capturado: $error');
    debugPrint('$stack');
    return true; // true = ya fue manejado, no relanzar.
  };

  // ── Capa 2: errores dentro del árbol de widgets (build/layout/paint).
  // Por default Flutter ya pinta un "red screen of death" en debug,
  // pero en Web a veces ni eso se ve si ocurre muy temprano.
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('🔴 [FlutterError] ${details.exceptionAsString()}');
    debugPrint('${details.stack}');
    FlutterError.presentError(details);
  };

  // ── Capa 1: todo lo que corre antes/fuera de runApp (async).
  // Si Supabase.initialize() o SharedPreferences.getInstance() truenan
  // (ej. URL/key mal copiada, CORS, proyecto pausado, etc.), esto es
  // lo único que lo va a atrapar y mostrar en consola.
  runZonedGuarded(() async {
    debugPrint('🟢 [main] Iniciando arranque de la app...');

    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('🟢 [main] WidgetsFlutterBinding listo.');

    try {
      debugPrint('🟢 [main] Inicializando Supabase...');
      await Supabase.initialize(
        url:     _supabaseUrl,
        anonKey: _supabaseAnonKey,
      );
      debugPrint('🟢 [main] Supabase inicializado correctamente.');
    } catch (e, st) {
      debugPrint('🔴 [main] FALLÓ Supabase.initialize(): $e');
      debugPrint('$st');
      // Re-lanzamos para que runZonedGuarded también lo registre y
      // para que sea obvio que la app no debe continuar así.
      rethrow;
    }

    // Carga el modo guardado ANTES de correr la app, para que arranque
    // ya con el tema correcto (sin parpadeo al modo oscuro por default).
    late final SharedPreferences prefs;
    try {
      debugPrint('🟢 [main] Cargando SharedPreferences...');
      prefs = await SharedPreferences.getInstance();
      isDarkNotifier.value = prefs.getBool(_prefsKeyIsDark) ?? true;
      debugPrint('🟢 [main] Tema cargado: '
          '${isDarkNotifier.value ? "oscuro" : "claro"}.');
    } catch (e, st) {
      debugPrint('🔴 [main] FALLÓ SharedPreferences.getInstance(): $e');
      debugPrint('$st');
      // No es fatal para el resto de la app — seguimos con el
      // valor default de isDarkNotifier (true) en vez de tronar.
    }

    // Cada vez que isDarkNotifier cambie (desde cualquier pantalla, ej.
    // el switch del Drawer en feed.dart), se guarda solo. No hace falta
    // tocar feed.dart: ya solo hace isDarkNotifier.value = !isDark.
    isDarkNotifier.addListener(() {
      SharedPreferences.getInstance().then((p) {
        p.setBool(_prefsKeyIsDark, isDarkNotifier.value);
      });
    });

    debugPrint('🟢 [main] Llamando runApp()...');
    runApp(const AspirantesItvhApp());
    debugPrint('🟢 [main] runApp() ejecutado.');
  }, (error, stack) {
    // Cualquier excepción async no atrapada arriba (incluida la
    // relanzada por Supabase.initialize) cae aquí.
    debugPrint('🔴 [runZonedGuarded] Error no capturado: $error');
    debugPrint('$stack');
  });
}


// ═════════════════════════════════════════════════════════════════
// APP ROOT
// ═════════════════════════════════════════════════════════════════

class AspirantesItvhApp extends StatelessWidget {
  const AspirantesItvhApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('🟢 [AspirantesItvhApp] build() llamado.');
    // Escucha isDarkNotifier y reconstruye el ThemeData completo
    // cada vez que cualquier pantalla de la app cambie el tema.
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkNotifier,
      builder: (context, isDark, _) {
        return MaterialApp(
          title:  'Aspirantes ITVH',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: isDark ? Brightness.dark : Brightness.light,
            scaffoldBackgroundColor: isDark
                ? const Color(0xFF0B0B14)
                : const Color(0xFFF2F2F7),
            colorScheme: ColorScheme.fromSeed(
              seedColor:  const Color(0xFF00C6FF),
              brightness: isDark ? Brightness.dark : Brightness.light,
            ),
          ),
          // Ruta nombrada usada por crear_cuenta.dart cuando la
          // confirmación de correo está deshabilitada y ya hay sesión.
          routes: {
            '/home': (_) => const FeedAspirantes(),
          },
          home: const AuthGate(),
        );
      },
    );
  }
}


// ═════════════════════════════════════════════════════════════════
// AUTH GATE
//
// Escucha el stream de estado de autenticación de Supabase y
// alterna entre LoginScreen y FeedAspirantes según haya o no sesión
// activa. Se ejecuta una sola vez al arrancar y luego reacciona
// a signIn / signOut / tokenRefresh en tiempo real.
// ═════════════════════════════════════════════════════════════════

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('🟢 [AuthGate] build() llamado.');
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        debugPrint('🟢 [AuthGate] StreamBuilder → '
            'connectionState=${snapshot.connectionState}, '
            'hasError=${snapshot.hasError}');

        if (snapshot.hasError) {
          debugPrint('🔴 [AuthGate] Error en el stream de auth: '
              '${snapshot.error}');
        }

        // Mientras se resuelve el estado inicial de la sesión.
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint('🟢 [AuthGate] Esperando estado inicial de sesión...');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = Supabase.instance.client.auth.currentSession;
        debugPrint('🟢 [AuthGate] session == null? ${session == null}');

        if (session == null) {
          debugPrint('🟢 [AuthGate] → mostrando LoginScreen.');
          return const LoginScreen();
        }

        debugPrint('🟢 [AuthGate] → mostrando FeedAspirantes.');
        return const FeedAspirantes();
      },
    );
  }
}