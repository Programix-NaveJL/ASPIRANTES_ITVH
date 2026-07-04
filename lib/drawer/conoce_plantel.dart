// ═════════════════════════════════════════════════════════════════
// conoce_plantel.dart
//
// Pantalla informativa sobre el Instituto Tecnológico de Villahermosa.
//
// Secciones:
//   • Ficha rápida     — ubicación, fundación, tipo y sitio web
//   • Acerca del plantel — descripción institucional en dos párrafos
//   • Galería del campus — PageView deslizable + miniaturas + puntos
//   • Misión y Visión  — tarjetas con ícono de color + chips de valores
//   • Contacto y Ubicación — dirección, teléfono, correo, web y mapa
//
// Widgets internos:
//   • _GaleriaPlantel  — galería con PageView, miniaturas y navegación
//   • _NavArrow        — flecha de navegación con AnimatedOpacity
//   • _FotoGaleria     — modelo de datos de cada foto de la galería
// ═════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ConocePlantelScreen extends StatelessWidget {
  const ConocePlantelScreen({super.key});

  /// Abre una URL en el navegador externo del sistema operativo.
  Future<void> _abrirUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? Colors.black             : const Color(0xFFF2F2F7);
    final bgCard = isDark ? const Color(0xFF1C1C1E)  : Colors.white;
    final text1  = isDark ? Colors.white             : Colors.black87;
    final text2  = isDark ? Colors.white60           : Colors.black54;
    final div    = isDark ? Colors.white10           : Colors.black12;
    const accent = Color(0xFF007AFF);
    const green  = Color(0xFF34C759);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [

          // SliverAppBar expandible con logo del ITVH como cabecera visual.
          // Al hacer scroll, colapsa y muestra solo la barra con el botón de regreso.
          SliverAppBar(
            expandedHeight: 220,
            pinned:          true,
            backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            elevation:       0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_rounded, color: text1, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 48),
                    Image.asset(
                      'assets/images/logo_itvh.png',
                      height: 110,
                      fit:    BoxFit.contain,
                      // Fallback si el asset no existe: ícono de escuela semitransparente.
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.school_rounded,
                        size:  80,
                        color: accent.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Instituto Tecnológico de Villahermosa',
                      style: TextStyle(
                        color:      text1,
                        fontSize:   13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Sección: Ficha rápida ──────────────────────
                Container(
                  color:   bgCard,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Instituto Tecnológico de Villahermosa',
                        style: TextStyle(
                          color:      text1,
                          fontSize:   22,
                          fontWeight: FontWeight.w700,
                          height:     1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'ITVH · TecNM',
                        style: TextStyle(
                          color:      accent,
                          fontSize:   13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _fichaRow(
                        icon:  Icons.location_on_rounded,
                        label: 'Ubicación',
                        value: 'Carretera Villahermosa–Frontera km 3.5, '
                            'Col. Tecnológico, Villahermosa, Tab.',
                        text1: text1,
                        text2: text2,
                      ),
                      _fichaRow(
                        icon:  Icons.calendar_today_rounded,
                        label: 'Fundación',
                        value: '1974',
                        text1: text1,
                        text2: text2,
                      ),
                      _fichaRow(
                        icon:  Icons.account_balance_rounded,
                        label: 'Tipo',
                        value: 'Institución pública de educación superior',
                        text1: text1,
                        text2: text2,
                      ),
                      // El sitio web es tappable: text2 se sobreescribe con accent
                      // para dar apariencia de enlace.
                      _fichaRow(
                        icon:  Icons.language_rounded,
                        label: 'Sitio web',
                        value: 'villahermosa.tecnm.mx',
                        text1: text1,
                        text2: accent,
                        onTap: () => _abrirUrl('https://villahermosa.tecnm.mx'),
                      ),
                      const SizedBox(height: 8),
                      Divider(color: div, thickness: 0.5),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Sección: Acerca del plantel ────────────────
                _seccion(
                  bgCard: bgCard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _tituloSeccion('Acerca del plantel', text1),
                      const SizedBox(height: 12),
                      _parrafo(
                        'El Instituto Tecnológico de Villahermosa (ITVH) '
                            'es una institución pública de educación superior '
                            'perteneciente al Tecnológico Nacional de México '
                            '(TecNM), dependiente de la Secretaría de Educación '
                            'Pública (SEP). Fundado en 1974, ha formado durante '
                            'más de cinco décadas a miles de profesionistas en '
                            'diversas disciplinas de ingeniería y ciencias.',
                        text2,
                      ),
                      const SizedBox(height: 10),
                      _parrafo(
                        'El ITVH se distingue por su enfoque en la '
                            'vinculación con el sector productivo de la región '
                            'sureste de México, contribuyendo activamente al '
                            'desarrollo económico, científico y tecnológico del '
                            'estado de Tabasco y del país.',
                        text2,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Sección: Galería ───────────────────────────
                _seccion(
                  bgCard: bgCard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _tituloSeccion('Galería del campus', text1),
                      const SizedBox(height: 14),
                      _GaleriaPlantel(isDark: isDark),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Sección: Misión, Visión y Valores ─────────
                _seccion(
                  bgCard: bgCard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _tituloSeccion('Misión y Visión', text1),
                      const SizedBox(height: 16),
                      _tarjetaMisionVision(
                        icon:   Icons.flag_rounded,
                        color:  accent,
                        titulo: 'Misión',
                        texto:
                        'Formar profesionistas de excelencia en '
                            'ciencias y tecnología, con valores éticos y '
                            'humanistas, capaces de contribuir al desarrollo '
                            'sustentable del país, a través de la docencia, '
                            'investigación y vinculación con los sectores '
                            'productivo y social.',
                        isDark: isDark,
                        text1:  text1,
                        text2:  text2,
                      ),
                      const SizedBox(height: 12),
                      _tarjetaMisionVision(
                        icon:   Icons.visibility_rounded,
                        color:  green,
                        titulo: 'Visión',
                        texto:
                        'Ser reconocida como una institución de educación '
                            'superior de calidad, acreditada nacional e '
                            'internacionalmente, líder en innovación tecnológica '
                            'y en la formación integral de profesionistas '
                            'competitivos, comprometidos con el desarrollo '
                            'sostenible de la región y del país.',
                        isDark: isDark,
                        text1:  text1,
                        text2:  text2,
                      ),
                      const SizedBox(height: 12),
                      _tituloSeccion('Valores institucionales', text1),
                      const SizedBox(height: 12),
                      // Chips generados dinámicamente desde la lista de valores.
                      Wrap(
                        spacing:    8,
                        runSpacing: 8,
                        children: [
                          'Honestidad', 'Responsabilidad', 'Respeto',
                          'Innovación', 'Compromiso', 'Excelencia',
                          'Trabajo en equipo', 'Sustentabilidad',
                        ].map((v) => _chip(v, accent, isDark)).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Sección: Contacto y Ubicación ──────────────
                _seccion(
                  bgCard: bgCard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _tituloSeccion('Contacto y Ubicación', text1),
                      const SizedBox(height: 16),
                      _contactoTile(
                        icon:      Icons.location_on_rounded,
                        color:     const Color(0xFFFF3B30),
                        titulo:    'Dirección',
                        subtitulo: 'Carretera Villahermosa–Frontera km 3.5, '
                            'Col. Tecnológico, C.P. 86010, '
                            'Villahermosa, Tabasco, México.',
                        isDark:    isDark,
                        text1:     text1,
                        text2:     text2,
                        onTap: () => _abrirUrl(
                            'https://maps.google.com/?q=Instituto+Tecnologico+de+Villahermosa'),
                      ),
                      _contactoTile(
                        icon:      Icons.phone_rounded,
                        color:     green,
                        titulo:    'Teléfono',
                        subtitulo: '(993) 354-2020',
                        isDark:    isDark,
                        text1:     text1,
                        text2:     text2,
                        onTap: () => _abrirUrl('tel:+529933542020'),
                      ),
                      _contactoTile(
                        icon:      Icons.email_rounded,
                        color:     accent,
                        titulo:    'Correo institucional',
                        subtitulo: 'difusion@villahermosa.tecnm.mx',
                        isDark:    isDark,
                        text1:     text1,
                        text2:     text2,
                        onTap: () => _abrirUrl(
                            'mailto:difusion@villahermosa.tecnm.mx'),
                      ),
                      _contactoTile(
                        icon:      Icons.language_rounded,
                        color:     const Color(0xFF5856D6),
                        titulo:    'Sitio web oficial',
                        subtitulo: 'villahermosa.tecnm.mx',
                        isDark:    isDark,
                        text1:     text1,
                        text2:     text2,
                        onTap: () => _abrirUrl('https://villahermosa.tecnm.mx'),
                      ),
                      const SizedBox(height: 12),

                      // Placeholder de mapa: abre Google Maps al tocar.
                      // Se usa un Container con ícono en lugar de un mapa real
                      // para evitar dependencias de API key en esta versión.
                      GestureDetector(
                        onTap: () => _abrirUrl(
                            'https://maps.google.com/?q=Instituto+Tecnologico+de+Villahermosa'),
                        child: Container(
                          width:  double.infinity,
                          height: 120,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2C2C2E)
                                : const Color(0xFFE5E5EA),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(Icons.map_rounded,
                                  size:  56,
                                  color: isDark
                                      ? Colors.white12
                                      : Colors.black12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color:        accent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.directions_rounded,
                                        color: Colors.white, size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'Ver en Google Maps',
                                      style: TextStyle(
                                        color:      Colors.white,
                                        fontSize:   13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Pie de página con aviso de fuente de información.
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 24, horizontal: 20),
                  child: Center(
                    child: Text(
                      'Información con fines informativos.\n'
                          'Fuente: TecNM / ITVH',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:    text2.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }


  // ─────────────────────────────────────────────────────────────
  // HELPERS DE LAYOUT
  // ─────────────────────────────────────────────────────────────

  /// Contenedor de sección con fondo de card y padding uniforme.
  Widget _seccion({required Color bgCard, required Widget child}) =>
      Container(
        color:   bgCard,
        width:   double.infinity,
        padding: const EdgeInsets.all(20),
        child:   child,
      );

  /// Título de sección con acento de barra azul de 40 × 3 px debajo.
  Widget _tituloSeccion(String texto, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        texto,
        style: TextStyle(
          color:      color,
          fontSize:   18,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 6),
      Container(
        width: 40, height: 3,
        decoration: BoxDecoration(
          color:        const Color(0xFF007AFF),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    ],
  );

  /// Párrafo de texto justificado con interlineado 1.65.
  Widget _parrafo(String texto, Color color) => Text(
    texto,
    style:     TextStyle(color: color, fontSize: 14, height: 1.65),
    textAlign: TextAlign.justify,
  );

  /// Fila de ficha rápida con ícono, etiqueta fija de 80 px y valor expandible.
  /// Si se pasa [onTap], el valor actúa como enlace (usado para sitio web).
  Widget _fichaRow({
    required IconData    icon,
    required String      label,
    required String      value,
    required Color       text1,
    required Color       text2,
    VoidCallback?        onTap,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: onTap,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: const Color(0xFF007AFF)),
              const SizedBox(width: 10),
              SizedBox(
                width: 80,
                child: Text(
                  label,
                  style: TextStyle(
                    color:      text1,
                    fontSize:   13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(color: text2, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );

  /// Tarjeta de Misión/Visión con fondo semitransparente del color del ícono.
  /// El alpha del 8 % en el fondo y 20 % en el borde da profundidad sin saturar.
  Widget _tarjetaMisionVision({
    required IconData icon,
    required Color    color,
    required String   titulo,
    required String   texto,
    required bool     isDark,
    required Color    text1,
    required Color    text2,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: TextStyle(
                  color:      color,
                  fontSize:   15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Text(
              texto,
              style:     TextStyle(color: text2, fontSize: 13, height: 1.6),
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      );

  /// Chip de valor institucional con fondo y borde del color de acento.
  Widget _chip(String label, Color accent, bool isDark) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color:        accent.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(20),
      border:       Border.all(color: accent.withValues(alpha: 0.25)),
    ),
    child: Text(
      label,
      style: TextStyle(
        color:      accent,
        fontSize:   12,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  /// Tile de contacto con ícono de color, título, subtítulo tappable y flecha.
  Widget _contactoTile({
    required IconData     icon,
    required Color        color,
    required String       titulo,
    required String       subtitulo,
    required bool         isDark,
    required Color        text1,
    required Color        text2,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color:        color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        color:      text1,
                        fontSize:   13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: TextStyle(color: color, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size:  13,
                  color: text2.withValues(alpha: 0.4)),
            ],
          ),
        ),
      );
}


// ═════════════════════════════════════════════════════════════════
// GALERÍA DEL CAMPUS
//
// Galería interactiva con tres elementos sincronizados:
//   • PageView principal deslizable (16:9).
//   • Miniaturas horizontales con borde de selección animado.
//   • Indicadores de puntos con ancho animado para el activo.
//
// La navegación puede hacerse por swipe, flechas o tap en miniatura.
// Todos los métodos sincronizan _indiceActual y el PageController.
// ═════════════════════════════════════════════════════════════════

class _GaleriaPlantel extends StatefulWidget {
  final bool isDark;
  const _GaleriaPlantel({required this.isDark});

  @override
  State<_GaleriaPlantel> createState() => _GaleriaPlantelState();
}

class _GaleriaPlantelState extends State<_GaleriaPlantel> {
  final PageController _pageController = PageController();
  int _indiceActual = 0;

  // Lista de fotos de la galería. Se declara const para evitar
  // re-allocations en cada rebuild.
  static const List<_FotoGaleria> _fotos = [
    _FotoGaleria(path: 'assets/images/galeria_imagen1.jpeg', descripcion: 'Vista del campus del ITVH'),
    _FotoGaleria(path: 'assets/images/galeria_imagen2.jpeg', descripcion: 'Instalaciones del plantel'),
    _FotoGaleria(path: 'assets/images/galeria_imagen3.jpeg', descripcion: 'Áreas académicas del ITVH'),
    _FotoGaleria(path: 'assets/images/galeria_imagen4.jpeg', descripcion: 'Espacios de aprendizaje'),
    _FotoGaleria(path: 'assets/images/galeria_imagen5.jpeg', descripcion: 'Infraestructura del campus'),
    _FotoGaleria(path: 'assets/images/galeria_imagen6.jpeg', descripcion: 'Exterior del ITVH'),
    _FotoGaleria(path: 'assets/images/galeria_imagen7.jpeg', descripcion: 'Instituto Tecnológico de Villahermosa'),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Navega a la foto en el índice [i] animando el PageView
  /// y actualizando el índice activo para miniaturas y puntos.
  void _irA(int i) {
    setState(() => _indiceActual = i);
    _pageController.animateToPage(
      i,
      duration: const Duration(milliseconds: 280),
      curve:    Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── Imagen principal con flechas superpuestas ──────────
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [

                PageView.builder(
                  controller:    _pageController,
                  itemCount:     _fotos.length,
                  onPageChanged: (i) => setState(() => _indiceActual = i),
                  itemBuilder:   (_, i) => Image.asset(
                    _fotos[i].path,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: widget.isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFE5E5EA),
                      child: Icon(Icons.image_outlined,
                          size:  48,
                          color: widget.isDark
                              ? Colors.white12
                              : Colors.black12),
                    ),
                  ),
                ),

                // Contador "X / N" en esquina superior derecha.
                Positioned(
                  top: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:        Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_indiceActual + 1} / ${_fotos.length}',
                      style: const TextStyle(
                        color:      Colors.white,
                        fontSize:   11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Flechas de navegación: se ocultan con AnimatedOpacity
                // cuando no hay más páginas en esa dirección.
                Positioned(
                  left: 8, top: 0, bottom: 0,
                  child: Center(
                    child: _NavArrow(
                      icon:  Icons.chevron_left_rounded,
                      onTap: _indiceActual > 0
                          ? () => _irA(_indiceActual - 1)
                          : null,
                    ),
                  ),
                ),
                Positioned(
                  right: 8, top: 0, bottom: 0,
                  child: Center(
                    child: _NavArrow(
                      icon:  Icons.chevron_right_rounded,
                      onTap: _indiceActual < _fotos.length - 1
                          ? () => _irA(_indiceActual + 1)
                          : null,
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Descripción en cursiva de la foto actualmente visible.
        Text(
          _fotos[_indiceActual].descripcion,
          style: TextStyle(
            color:     widget.isDark ? Colors.white54 : Colors.black45,
            fontSize:  12,
            fontStyle: FontStyle.italic,
          ),
        ),

        const SizedBox(height: 12),

        // ── Miniaturas horizontales ───────────────────────────
        // La miniatura activa muestra borde azul y opacidad completa;
        // las inactivas tienen opacidad reducida al 55 %.
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection:  Axis.horizontal,
            itemCount:        _fotos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final sel = i == _indiceActual;
              return GestureDetector(
                onTap: () => _irA(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: sel
                          ? const Color(0xFF007AFF)
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Opacity(
                      opacity: sel ? 1.0 : 0.55,
                      child: Image.asset(
                        _fotos[i].path,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: widget.isDark
                              ? const Color(0xFF2C2C2E)
                              : const Color(0xFFE5E5EA),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // ── Indicadores de puntos ─────────────────────────────
        // El punto activo se expande a 16 px de ancho con AnimatedContainer.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_fotos.length, (i) {
            final activo = i == _indiceActual;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin:   const EdgeInsets.symmetric(horizontal: 3),
              width:    activo ? 16 : 6,
              height:   6,
              decoration: BoxDecoration(
                color: activo
                    ? const Color(0xFF007AFF)
                    : (widget.isDark ? Colors.white24 : Colors.black26),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),

      ],
    );
  }
}


// ═════════════════════════════════════════════════════════════════
// FLECHA DE NAVEGACIÓN
//
// Botón circular semitransparente con AnimatedOpacity.
// Cuando onTap es null (primera/última página), se oculta
// con opacity 0 en lugar de desaparecer abruptamente.
// ═════════════════════════════════════════════════════════════════

class _NavArrow extends StatelessWidget {
  final IconData     icon;
  final VoidCallback? onTap;
  const _NavArrow({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity:  onTap != null ? 1.0 : 0.0,
        child: Container(
          width: 32, height: 32,
          decoration: const BoxDecoration(
            color: Color(0x59000000), // ~35 % de opacidad en hex.
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}


// ═════════════════════════════════════════════════════════════════
// MODELO DE FOTO DE GALERÍA
//
// Encapsula la ruta del asset y la descripción de cada imagen.
// Se declara const para que _GaleriaPlantelState pueda usar
// una lista static const sin overhead de instanciación.
// ═════════════════════════════════════════════════════════════════

class _FotoGaleria {
  final String path;
  final String descripcion;
  const _FotoGaleria({required this.path, required this.descripcion});
}