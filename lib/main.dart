// ═════════════════════════════════════════════════════════════════
// main.dart — Aspirantes ITVH
//
// Punto de entrada de la aplicación.
//
// Responsabilidades:
//   1. Inicializar Supabase (auth, db, storage) antes de correr la app.
//   2. Inicializar Firebase + FCM (notificaciones push) y las
//      notificaciones locales que las muestran en primer plano.
//   3. Definir el MaterialApp con tema oscuro por defecto.
//   4. AuthGate — widget raíz que escucha los cambios de sesión de
//      Supabase Auth y decide qué pantalla mostrar:
//        • Sin sesión activa   → LoginScreen
//        • Sesión activa       → FeedAspirantes (feed.dart)
//   5. isDarkNotifier — ValueNotifier global de tema claro/oscuro.
//      Cualquier pantalla de la app puede leerlo o cambiarlo, y el
//      MaterialApp reacciona reconstruyendo el ThemeData completo.
//
// NOTA (build): esta versión ya no soporta Flutter Web. Se removió
// PlatformDispatcher.instance.onError (capa de captura pensada para
// errores de renderizado/JS en Web) y todo el debugPrint de rastreo
// de arranque, ya que la app entra en fase de pruebas en Google
// Play Console (solo Android).
// ═════════════════════════════════════════════════════════════════

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
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
// Persiste entre sesiones vía SharedPreferences (ver _prefsKeyIsDark).
// Valor inicial en oscuro mientras se carga la preferencia guardada.
// ═════════════════════════════════════════════════════════════════

final ValueNotifier<bool> isDarkNotifier = ValueNotifier<bool>(true);

/// Key de SharedPreferences donde se guarda el modo elegido.
const _prefsKeyIsDark = 'is_dark_mode';


// ═════════════════════════════════════════════════════════════════
// NOTIFICACIONES PUSH (Firebase Cloud Messaging)
//
// _firebaseMessagingBackgroundHandler DEBE ser una función top-level
// (no un método de clase) y llevar @pragma('vm:entry-point'), porque
// Android la ejecuta en un isolate separado cuando la app está en
// background o cerrada.
//
// _localNotifications se usa solo para el caso "app en primer plano":
// FCM no muestra automáticamente un banner si el usuario ya está
// dentro de la app, así que la disparamos nosotros a mano.
// ═════════════════════════════════════════════════════════════════

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Intencionalmente vacío por ahora: no navegamos ni tocamos UI aquí.
  // Si más adelante se necesita lógica ligera (ej. actualizar un badge
  // local), va aquí — nunca código pesado ni de UI.
}

final FlutterLocalNotificationsPlugin _localNotifications =
FlutterLocalNotificationsPlugin();

Future<void> _initLocalNotifications() async {
  const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
  const initSettings = InitializationSettings(android: androidInit);
  await _localNotifications.initialize(initSettings);
}

Future<void> _mostrarNotificacionLocal(RemoteMessage message) async {
  final notification = message.notification;
  if (notification == null) return;

  const androidDetails = AndroidNotificationDetails(
    'aspirantes_itvh_default',
    'Notificaciones',
    channelDescription: 'Notificaciones generales de Aspirantes ITVH',
    importance: Importance.high,
    priority: Priority.high,
  );

  await _localNotifications.show(
    notification.hashCode,
    notification.title,
    notification.body,
    const NotificationDetails(android: androidDetails),
  );
}

/// Pide permiso de notificaciones y guarda/actualiza el token FCM del
/// usuario actual en la tabla `push_tokens`. Se llama después de que
/// hay sesión activa (login o sesión restaurada), nunca antes.
Future<void> _registrarTokenPush() async {
  final messaging = FirebaseMessaging.instance;

  final settings = await messaging.requestPermission();
  if (settings.authorizationStatus == AuthorizationStatus.denied) return;

  final token = await messaging.getToken();
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (token == null || userId == null) return;

  try {
    await Supabase.instance.client.from('push_tokens').upsert({
      'usuario_id': userId,
      'token': token,
      'plataforma': 'android',
    }, onConflict: 'token');
  } catch (_) {
    // No es crítico: si falla, el usuario simplemente no recibirá
    // push hasta el siguiente intento (próximo login/apertura).
  }
}


// ═════════════════════════════════════════════════════════════════
// ENTRY POINT
// ═════════════════════════════════════════════════════════════════

void main() {
  // runZonedGuarded captura cualquier excepción async no atrapada
  // antes de runApp() (ej. si Supabase.initialize() truena por URL/key
  // mal copiada, proyecto pausado, etc.). Se conserva en producción
  // como red de seguridad silenciosa; para reportar crashes reales,
  // aquí es donde se engancharía un servicio como Crashlytics/Sentry.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Supabase.initialize(
      url:            _supabaseUrl,
      publishableKey: _supabaseAnonKey,
    );

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await _initLocalNotifications();

    // App en primer plano: FCM no muestra banner solo, lo disparamos
    // nosotros con flutter_local_notifications.
    FirebaseMessaging.onMessage.listen(_mostrarNotificacionLocal);

    // Si ya hay sesión activa al abrir la app (token guardado), registra
    // el token FCM de una vez. Si no hay sesión, AuthGate se encarga de
    // llamar esto después de un login exitoso (ver nota más abajo).
    if (Supabase.instance.client.auth.currentSession != null) {
      unawaited(_registrarTokenPush());
    }

    // Carga el modo guardado ANTES de correr la app, para que arranque
    // ya con el tema correcto (sin parpadeo al modo oscuro por default).
    try {
      final prefs = await SharedPreferences.getInstance();
      isDarkNotifier.value = prefs.getBool(_prefsKeyIsDark) ?? true;
    } catch (_) {
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

    runApp(const AspirantesItvhApp());
  }, (error, stack) {
    // Aquí caen las excepciones no atrapadas arriba. En esta etapa de
    // pruebas se dejan silenciosas; conectar a un servicio de crash
    // reporting antes de release público.
  });
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
//
// También aprovecha el evento signedIn para registrar el token FCM
// justo después de que el usuario inicia sesión (login recién hecho,
// no sesión ya restaurada — ese caso ya se cubrió en main()).
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

        final event = snapshot.data?.event;
        if (event == AuthChangeEvent.signedIn) {
          unawaited(_registrarTokenPush());
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