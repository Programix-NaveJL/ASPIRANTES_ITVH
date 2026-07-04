// ═════════════════════════════════════════════════════════════════
// historia_plantel_screen.dart
//
// Pantalla que narra la historia del Instituto Tecnológico de
// Villahermosa (ITVH) mediante una línea de tiempo vertical.
//
// Estructura:
//   • SliverAppBar con hero fotográfico y badge de fecha de fundación.
//   • Introducción con nombre del instituto y subtítulo.
//   • Línea de tiempo con tres hitos históricos (1974, 1979, 1992),
//     cada uno con paleta de color propia, imagen y pie de foto.
//   • Banner final con el resumen "+50 años".
//
// Clases principales:
//   • HistoriaPlantelScreen — pantalla raíz (StatelessWidget)
//   • _EventoTheme          — paleta temática por evento
//
// Widgets privados:
//   • _HeroHeader    — cabecera fotográfica con gradiente y badge
//   • _TimelineItem  — nodo + línea + contenido de un hito histórico
//   • _BottomBanner  — tarjeta de cierre "+50 años"
//
// Modelo privado:
//   • _Evento — datos estáticos de cada hito (año, título, cuerpo,
//               ícono, imagen y pie de foto)
// ═════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';


// ═════════════════════════════════════════════════════════════════
// PALETA TEMÁTICA POR EVENTO
// ═════════════════════════════════════════════════════════════════

/// Agrupa los colores específicos de cada hito de la línea de tiempo.
///
/// Se generan versiones diferenciadas para modo claro y oscuro
/// en [HistoriaPlantelScreen._themes], evitando hardcodear colores
/// directamente en los widgets.
class _EventoTheme {
  final Color node;          // Fondo del nodo circular
  final Color nodeText;      // Color del ícono dentro del nodo
  final Color yearLabel;     // Color del año sobre el contenido
  final Color imageOverlay;  // Tinte semitransparente sobre la imagen

  const _EventoTheme({
    required this.node,
    required this.nodeText,
    required this.yearLabel,
    required this.imageOverlay,
  });
}


// ═════════════════════════════════════════════════════════════════
// PANTALLA PRINCIPAL
// ═════════════════════════════════════════════════════════════════

class HistoriaPlantelScreen extends StatelessWidget {
  const HistoriaPlantelScreen({super.key});


  // ─────────────────────────────────────────────────────────────
  // CATÁLOGO DE EVENTOS
  // ─────────────────────────────────────────────────────────────

  /// Lista estática de los tres hitos históricos del ITVH.
  /// Se renderizan en orden de aparición en la línea de tiempo.
  static const _eventos = [
    _Evento(
      year:    '1974',
      title:   'Los orígenes',
      body:
      'El ITVH nació cuando la economía tabasqueña dependía de la agricultura, ganadería, pesca y cuatro industrias clave: azucarera, chocolatera, aceitera y petrolera. La falta de mano de obra calificada limitaba el crecimiento.',
      icon:    Icons.flag_rounded,
      image:   'assets/images/drawer_imagen2_2.jpg',
      caption: 'Gimnasio-Auditorio en sus primeros años.',
    ),
    _Evento(
      year:    '1979',
      title:   'Sede propia',
      body:
      'Tras operar en instituciones prestadas, el 20 de noviembre de 1979 el Instituto se trasladó a sus instalaciones definitivas en el Km. 3.5 de la carretera Villahermosa–Frontera.',
      icon:    Icons.location_city_rounded,
      image:   'assets/images/drawer_imagen2_1.jpg',
      caption: 'Centro de Información (Biblioteca) en sus inicios, sin techo.',
    ),
    _Evento(
      year:    '1992',
      title:   'Modernización',
      body:
      'Se construyó un laboratorio de cómputo de dos niveles, una unidad académica departamental y el nuevo Centro de Información. Se consolidó el SITE de Internet y se implementaron redes internas.',
      icon:    Icons.computer_rounded,
      image:   'assets/images/drawer_imagen2.jpg',
      caption: 'Centro de cómputo en sus inicios.',
    ),
  ];


  // ─────────────────────────────────────────────────────────────
  // PALETAS POR EVENTO
  // ─────────────────────────────────────────────────────────────

  /// Genera la lista de paletas temáticas adaptada al brillo actual.
  /// El índice de cada [_EventoTheme] corresponde al de [_eventos].
  static List<_EventoTheme> _themes(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      // 1974 — Amber / dorado
      _EventoTheme(
        node:         isDark ? const Color(0xFF7C5A1E) : const Color(0xFFFFF0CC),
        nodeText:     isDark ? const Color(0xFFFFD97D) : const Color(0xFF7C5A1E),
        yearLabel:    isDark ? const Color(0xFFFFD97D) : const Color(0xFF9A6F2B),
        imageOverlay: const Color(0xFFB8860B).withValues(alpha: 0.15),
      ),
      // 1979 — Teal / verde azulado
      _EventoTheme(
        node:         isDark ? const Color(0xFF0D4A3A) : const Color(0xFFCCF0E6),
        nodeText:     isDark ? const Color(0xFF5DE0B0) : const Color(0xFF0D6B52),
        yearLabel:    isDark ? const Color(0xFF5DE0B0) : const Color(0xFF0D6B52),
        imageOverlay: const Color(0xFF1D9E75).withValues(alpha: 0.15),
      ),
      // 1992 — Coral / terracota
      _EventoTheme(
        node:         isDark ? const Color(0xFF6B2510) : const Color(0xFFFFE8DF),
        nodeText:     isDark ? const Color(0xFFF0997B) : const Color(0xFF8C3820),
        yearLabel:    isDark ? const Color(0xFFF0997B) : const Color(0xFF8C3820),
        imageOverlay: const Color(0xFFD85A30).withValues(alpha: 0.12),
      ),
    ];
  }


  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final themes = _themes(context);

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [

          // SliverAppBar con hero fotográfico que colapsa al hacer scroll.
          SliverAppBar(
            expandedHeight: 260,
            pinned:          true,
            backgroundColor: cs.surface,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(
                  left: 16, bottom: 14, right: 60),
              title: Text(
                'Un poco de historia',
                style: TextStyle(
                  fontSize:   15,
                  fontWeight: FontWeight.bold,
                  color:      cs.onSurface,
                ),
              ),
              background: _HeroHeader(cs: cs),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Introducción ───────────────────────────────
                Text(
                  'Instituto Tecnológico\nde Villahermosa',
                  style: TextStyle(
                    fontSize:   28,
                    fontWeight: FontWeight.bold,
                    color:      cs.onSurface,
                    height:     1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Más de 50 años formando profesionistas en Tabasco.',
                  style: TextStyle(
                    fontSize: 15,
                    color:    cs.onSurface.withValues(alpha: 0.55),
                    height:   1.5,
                  ),
                ),

                const SizedBox(height: 32),
                Divider(color: cs.outline.withValues(alpha: 0.2)),
                const SizedBox(height: 32),

                // ── Línea de tiempo ────────────────────────────
                // Se genera un _TimelineItem por cada evento.
                // isLast determina si se omite la línea vertical inferior.
                ...List.generate(_eventos.length, (i) {
                  final e      = _eventos[i];
                  final isLast = i == _eventos.length - 1;
                  return _TimelineItem(
                    evento:  e,
                    cs:      cs,
                    isLast:  isLast,
                    theme:   themes[i],
                  );
                }),

                const SizedBox(height: 8),

                // ── Banner de cierre ───────────────────────────
                _BottomBanner(cs: cs),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}


// ═════════════════════════════════════════════════════════════════
// HERO HEADER
// ═════════════════════════════════════════════════════════════════

/// Cabecera fotográfica del SliverAppBar.
///
/// Muestra una imagen de fondo con un gradiente hacia el color de
/// superficie para que el título del AppBar sea legible al colapsar.
/// Incluye un badge con la fecha de fundación del instituto.
class _HeroHeader extends StatelessWidget {
  final ColorScheme cs;
  const _HeroHeader({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [

        // Imagen de fondo con fallback de color si no carga el asset.
        Image.asset(
          'assets/images/drawer_imagen2.jpg',
          fit:          BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Container(color: cs.surfaceContainerHigh),
        ),

        // Gradiente que va de transparente (arriba) al color de
        // superficie (abajo) para mejorar la legibilidad del título.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin:  Alignment.topCenter,
              end:    Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                cs.surface.withValues(alpha: 0.95),
              ],
              stops: const [0.35, 1.0],
            ),
          ),
        ),

        // Badge con la fecha de fundación sobre la imagen.
        // Se posiciona encima del área donde va el título del AppBar.
        Positioned(
          bottom: 52,
          left:   20,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color:        Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today_rounded,
                    size:  13,
                    color: Colors.white.withValues(alpha: 0.85)),
                const SizedBox(width: 6),
                Text(
                  'Fundado el 9 de septiembre de 1974',
                  style: TextStyle(
                    fontSize:   12,
                    fontWeight: FontWeight.w600,
                    color:      Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


// ═════════════════════════════════════════════════════════════════
// ÍTEM DE LÍNEA DE TIEMPO
// ═════════════════════════════════════════════════════════════════

/// Nodo + línea vertical + contenido de un hito histórico.
///
/// Usa [IntrinsicHeight] para que la línea vertical del lado izquierdo
/// se extienda exactamente hasta el final del contenido del lado derecho,
/// sin importar la altura variable de cada item.
///
/// [isLast] omite la línea vertical inferior en el último elemento
/// para no dejarla colgando visualmente.
class _TimelineItem extends StatelessWidget {
  final _Evento      evento;
  final ColorScheme  cs;
  final bool         isLast;
  final _EventoTheme theme;

  const _TimelineItem({
    required this.evento,
    required this.cs,
    required this.isLast,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // ── Columna izquierda: nodo circular + línea ──────────
          SizedBox(
            width: 56,
            child: Column(
              children: [
                // Nodo circular con ícono del evento.
                Container(
                  width:  44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.node,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(evento.icon,
                      size: 20, color: theme.nodeText),
                ),
                // Línea vertical que conecta con el siguiente nodo.
                // Se omite en el último item.
                if (!isLast)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 2,
                        color: cs.outline.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ── Columna derecha: año, título, cuerpo, imagen ──────
          Expanded(
            child: Padding(
              // El padding inferior separa visualmente cada item
              // del siguiente (excepto el último).
              padding: EdgeInsets.only(bottom: isLast ? 0 : 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Año con color temático del evento.
                  Text(
                    evento.year,
                    style: TextStyle(
                      fontSize:      12,
                      fontWeight:    FontWeight.bold,
                      color:         theme.yearLabel,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Título del hito.
                  Text(
                    evento.title,
                    style: TextStyle(
                      fontSize:   18,
                      fontWeight: FontWeight.bold,
                      color:      cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Descripción histórica del hito.
                  Text(
                    evento.body,
                    style: TextStyle(
                      fontSize: 14,
                      height:   1.65,
                      color:    cs.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Imagen del hito con overlay de color temático
                  // y fallback de ícono si el asset no carga.
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      children: [
                        Image.asset(
                          evento.image,
                          height: 180,
                          width:  double.infinity,
                          fit:    BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color:        cs.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.image_not_supported_rounded,
                                color: cs.onSurfaceVariant,
                                size:  28,
                              ),
                            ),
                          ),
                        ),
                        // Tinte de color sutil sobre la imagen para
                        // reforzar la identidad cromática del evento.
                        Positioned.fill(
                          child: ColoredBox(color: theme.imageOverlay),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Pie de foto en itálica y color atenuado.
                  Text(
                    evento.caption,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize:  12,
                      fontStyle: FontStyle.italic,
                      color:     cs.onSurface.withValues(alpha: 0.38),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ═════════════════════════════════════════════════════════════════
// BANNER FINAL
// ═════════════════════════════════════════════════════════════════

/// Tarjeta de cierre que resume en una frase el legado del instituto.
/// Se muestra al final del scroll, después del último hito histórico.
class _BottomBanner extends StatelessWidget {
  final ColorScheme cs;
  const _BottomBanner({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color:        cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cs.outline.withValues(alpha: 0.12),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // Ícono de graduación sobre fondo semitransparente.
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.school_rounded,
              color: cs.onSurface.withValues(alpha: 0.75),
              size:  28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '+50 años',
                  style: TextStyle(
                    fontSize:   22,
                    fontWeight: FontWeight.bold,
                    color:      cs.onSurface,
                  ),
                ),
                Text(
                  'formando profesionistas en Tabasco',
                  style: TextStyle(
                    fontSize: 13,
                    color:    cs.onSurface.withValues(alpha: 0.55),
                    height:   1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ═════════════════════════════════════════════════════════════════
// MODELO DE DATOS
// ═════════════════════════════════════════════════════════════════

/// Datos estáticos de un hito histórico del ITVH.
///
/// Todos los campos son requeridos; el catálogo se define directamente
/// en [HistoriaPlantelScreen._eventos] como constante en tiempo de compilación.
class _Evento {
  final String   year;     // Año del hito (ej. "1974")
  final String   title;    // Título corto del hito
  final String   body;     // Descripción histórica
  final IconData icon;     // Ícono representativo
  final String   image;    // Ruta del asset de imagen
  final String   caption;  // Pie de foto

  const _Evento({
    required this.year,
    required this.title,
    required this.body,
    required this.icon,
    required this.image,
    required this.caption,
  });
}