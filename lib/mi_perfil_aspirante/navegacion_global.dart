// ═════════════════════════════════════════════════════════════════
// navegacion_global.dart — Aspirantes ITVH
//
// ValueNotifier global (mismo patrón que isDarkNotifier en main.dart)
// para pedirle al TabController de FeedAspirantes que se deslice a
// una pestaña específica desde cualquier parte del árbol de widgets,
// sin tener que pasar el TabController por parámetro capa por capa.
//
// Uso típico: alguien toca su propio avatar en una tarjeta de
// publicación (posiblemente en una pantalla empujada encima del
// feed, como PerfilPublicoAspirante o resultados de búsqueda).
// En vez de empujar otra pantalla de "Mi Perfil" con botón de
// regreso, se hace popUntil hasta la raíz (FeedAspirantes) y se
// notifica el índice de pestaña deseado — FeedAspirantes escucha
// este notifier y anima el TabController con _tabController.animateTo().
//
// El valor vuelve a null justo después de aplicarse (ver feed.dart)
// para que una señal repetida al mismo índice (p. ej. tocar tu
// avatar dos veces seguidas) también dispare el listener.
// ═════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';

final ValueNotifier<int?> irATabNotifier = ValueNotifier<int?>(null);

/// Índice de la pestaña "Mi Perfil" en FeedAspirantes — se centraliza
/// aquí para no repetir el número mágico "1" en cada lugar que
/// navega al perfil propio.
const int tabIndexMiPerfil = 1;