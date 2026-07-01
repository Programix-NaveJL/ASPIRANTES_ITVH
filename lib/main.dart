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
// ═════════════════════════════════════════════════════════════════

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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url:     _supabaseUrl,
    anonKey: _supabaseAnonKey,
  );

  // Carga el modo guardado ANTES de correr la app, para que arranque
  // ya con el tema correcto (sin parpadeo al modo oscuro por default).
  final prefs = await SharedPreferences.getInstance();
  isDarkNotifier.value = prefs.getBool(_prefsKeyIsDark) ?? true;

  // Cada vez que isDarkNotifier cambie (desde cualquier pantalla, ej.
  // el switch del Drawer en feed.dart), se guarda solo. No hace falta
  // tocar feed.dart: ya solo hace isDarkNotifier.value = !isDark.
  isDarkNotifier.addListener(() {
    prefs.setBool(_prefsKeyIsDark, isDarkNotifier.value);
  });

  runApp(const AspirantesItvhApp());
}


// ═════════════════════════════════════════════════════════════════
// APP ROOT
// ═════════════════════════════════════════════════════════════════

class AspirantesItvhApp extends StatelessWidget {
  const AspirantesItvhApp({super.key});

  @override
  Widget build(BuildContext context) {
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
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Mientras se resuelve el estado inicial de la sesión.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = Supabase.instance.client.auth.currentSession;

        if (session == null) {
          return const LoginScreen();
        }

        return const FeedAspirantes();
      },
    );
  }
}