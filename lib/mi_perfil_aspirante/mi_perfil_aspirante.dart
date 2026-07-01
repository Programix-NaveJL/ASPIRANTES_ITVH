// ═════════════════════════════════════════════════════════════════
// page_home.dart — Aspirantes ITVH
//
// Encabezado visual de la pestaña "Comunidad Nuevo Ingreso".
// Título en dos líneas (estilo "Comunidad" blanco + "Aspirantes"
// azul, como en los ejemplos de referencia), alineado a la izquierda.
//
// Este widget es puramente visual: no depende de datos remotos ni
// de lógica de negocio. Se coloca al inicio del body de la pestaña
// correspondiente en FeedAspirantes.
// ═════════════════════════════════════════════════════════════════

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MiPerfilAspirante extends StatelessWidget {
  final bool isDark;

  const MiPerfilAspirante({super.key, required this.isDark});

  static const Color _accent = Color(0xFF007AFF);

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? Colors.white : Colors.black;

    return SizedBox(
      width: double.infinity,
      child: Padding(
        // Padding superior reducido (18 → 6) para subir el encabezado
        // ahora que ya no compensa la fila de íconos que se quitó.
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Título en dos líneas ──
            Text(
              'Mi',
              style: TextStyle(
                color: textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                height: 1.05,
              ),
            ),
            const Text(
              'Perfil',
              style: TextStyle(
                color: _accent,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1.05,
              ),
            ),
          ],
        ),
      ),
    );
  }
}