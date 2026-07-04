// ═════════════════════════════════════════════════════════════════
// navegacion_perfil.dart — Aspirantes ITVH
//
// Punto único de navegación hacia un perfil de aspirante. Se usa
// en cualquier lugar donde se toque un avatar/nombre (tarjeta de
// publicación, resultados de búsqueda, lista de "quién reaccionó",
// comentarios, etc.) para no repetir la lógica de "¿es mi propio
// perfil o el de alguien más?" en cada pantalla.
//
// Regla:
//   • Si perfilId es el usuario autenticado: NO se empuja una
//     pantalla nueva. Se vuelve a la raíz del Navigator (donde
//     vive FeedAspirantes con su TabBarView) y se le pide, vía
//     irATabNotifier, que deslice a la pestaña "Mi Perfil" —
//     mismo feed con todo y tabs, sin apilar una ruta extra.
//   • Si es otro aspirante: se empuja PerfilPublicoAspirante
//     normalmente, con botón de regreso.
// ═════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../mi_perfil_aspirante/navegacion_global.dart';
import '../mi_perfil_aspirante/perfil_publico_aspirante.dart';

void abrirPerfil(
    BuildContext context, {
      required String perfilId,
      required bool isDark,
    }) {
  final uid = Supabase.instance.client.auth.currentUser?.id;

  if (uid != null && uid == perfilId) {
    // popUntil((route) => route.isFirst) es un no-op si ya estamos
    // en la raíz (p. ej. tocaste tu avatar dentro del mismo feed),
    // y descarta cualquier pantalla empujada encima (perfil público
    // de alguien más, búsqueda, etc.) si veníamos de más adentro.
    Navigator.of(context).popUntil((route) => route.isFirst);
    irATabNotifier.value = tabIndexMiPerfil;
    return;
  }

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => PerfilPublicoAspirante(perfilId: perfilId, isDark: isDark),
    ),
  );
}