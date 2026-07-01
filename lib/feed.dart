// ═════════════════════════════════════════════════════════════════
// feed.dart — Aspirantes ITVH  —  R2
//
// Pantalla raíz de la app "Aspirantes ITVH".
// Versión de SOLO VISUALIZACIÓN: aún no existe backend/lógica para
// esta app, por lo que no hay llamadas a Supabase (salvo signOut), ni
// Realtime, ni navegación real a pantallas externas. Todo lo que en
// Comunidad ITVH dependía de datos remotos aquí se muestra con
// placeholders estáticos o con un SnackBar "Próximamente".
//
// Responsabilidades:
//   • Renderizar el TabBar con 3 pestañas fijas, propias del perfil
//     de aspirante (no hay rol admin en esta app):
//       1. Comunidad Nuevo Ingreso
//       2. Mi Perfil Aspirante
//       3. UbicaTecNM Campus Villahermosa
//   • Mostrar un AppBar con el logo institucional (claro/oscuro) y un
//     avatar placeholder (sin datos de perfil reales todavía).
//   • Construir el Drawer lateral con las mismas secciones visuales
//     que Comunidad ITVH (Plantel, Plataformas, Preferencias), pero
//     sin navegación real: cada opción muestra un aviso de "Próximamente".
//   • Alternar tema claro/oscuro de forma GLOBAL a través de
//     isDarkNotifier (definido en main.dart) — el cambio se refleja
//     en toda la app, no solo en esta pantalla.
//   • Cerrar sesión (Supabase Auth signOut) desde el Drawer — al
//     hacerlo, AuthGate en main.dart detecta el cambio y regresa
//     automáticamente a LoginScreen.
//
// Widgets internos:
//   • _TabItem                    — modelo de datos para cada pestaña
//   • _PlaceholderTabBody          — cuerpo genérico para cada tab
// ═════════════════════════════════════════════════════════════════

import 'package:aspirantes_itvh_app/ubica_tecnm/ubica_tecnm_itvh.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'comunidad_aspirantes/page_home_social.dart';
import 'main.dart';
import 'mi_perfil_aspirante/mi_perfil_aspirante.dart';

class FeedAspirantes extends StatefulWidget {
  const FeedAspirantes({super.key});

  @override
  State<FeedAspirantes> createState() => _FeedAspirantesState();
}

class _FeedAspirantesState extends State<FeedAspirantes>
    with TickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;

  // Índice de la pestaña activa. Se actualiza con el animation listener
  // para cambiar íconos filled/outlined sin esperar el snap final.
  int _currentTabIndex = 0;

  // Pestañas fijas de la identidad "Aspirantes ITVH".
  // A diferencia de Comunidad ITVH, aquí no existe rol admin,
  // por lo que la lista es estática (siempre 3 elementos).
  static const List<_TabItem> _tabs = [
    _TabItem(
      label: 'Comunidad',
      icon: CupertinoIcons.person_3,
      activeIcon: CupertinoIcons.person_3_fill,
    ),
    _TabItem(
      label: 'Mi Perfil',
      icon: CupertinoIcons.person,
      activeIcon: CupertinoIcons.person_fill,
    ),
    _TabItem(
      label: 'UbicaTec',
      icon: CupertinoIcons.map,
      activeIcon: CupertinoIcons.map_fill,
    ),
  ];


  // ─────────────────────────────────────────────────────────────
  // CICLO DE VIDA
  // ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);

    // Listener en la animación (no en index) para actualizar el ícono
    // activo durante el deslizamiento, no solo al finalizar el snap.
    _tabController.animation!.addListener(() {
      final index = _tabController.animation!.value.round();
      if (index != _currentTabIndex) {
        setState(() => _currentTabIndex = index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  // ─────────────────────────────────────────────────────────────
  // HELPERS VISUALES
  // ─────────────────────────────────────────────────────────────

  /// Muestra un aviso breve para las opciones del Drawer que todavía
  /// no tienen pantalla o lógica implementada.
  void _proximamente(String funcion) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$funcion estará disponible próximamente'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Cierra la sesión activa en Supabase Auth. No navega manualmente:
  /// AuthGate (main.dart) escucha onAuthStateChange y regresa solo
  /// a LoginScreen en cuanto detecta el evento signedOut.
  Future<void> _cerrarSesion() async {
    await Supabase.instance.client.auth.signOut();
  }


  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // El tema ya no es local a esta pantalla: se escucha directo
    // desde isDarkNotifier (main.dart), así que esta pantalla se
    // reconstruye sola cuando el tema cambia desde cualquier lugar
    // de la app.
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkNotifier,
      builder: (context, isDark, _) {
        final textPrimary = isDark ? Colors.white : Colors.black;
        final bgCard   = isDark ? const Color(0xFF1C1C1E) : Colors.white;
        final divColor = isDark ? Colors.white10 : Colors.black12;
        const accent   = Color(0xFF007AFF);

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: isDark ? Colors.black : const Color(0xFFF2F2F7),

          drawer: _buildDrawer(isDark, bgCard, divColor, textPrimary, accent),

          appBar: AppBar(
            toolbarHeight: 70,
            backgroundColor: isDark ? Colors.black : Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0.5,
            leading: IconButton(
              icon: Icon(CupertinoIcons.line_horizontal_3,
                  color: textPrimary, size: 22),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            titleSpacing: 0,
            // Offset vertical para alinear visualmente el logo con los íconos
            // del AppBar, compensando el padding interno del widget Image.
            title: Transform.translate(
              offset: const Offset(0, -6),
              child: Image.asset(
                isDark
                    ? 'assets/images/appbar_modo_oscuro.png'
                    : 'assets/images/appbar_modo_claro.png',
                key: ValueKey(isDark), // Fuerza rebuild al cambiar tema.
                height: 33,
                fit: BoxFit.contain,
              ),
            ),
            centerTitle: false,
            actions: [
              // Avatar placeholder: sin datos de perfil reales todavía,
              // se muestra siempre el ícono genérico de persona.
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: GestureDetector(
                  onTap: () => _proximamente('Mi Perfil'),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accent.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: Container(
                        color: accent.withValues(alpha: 0.15),
                        alignment: Alignment.center,
                        child: Icon(CupertinoIcons.person_fill,
                            color: accent, size: 16),
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // ── TabBar estilo segmented control ───────────────────
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(54),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2C2C2E)
                        : const Color(0xFFE5E5EA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: TabBar(
                    controller:    _tabController,
                    dividerColor:  Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: isDark ? const Color(0xFF3A3A3C) : Colors.white,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: isDark
                          ? null
                          : [
                        BoxShadow(
                          color:      Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset:     const Offset(0, 1),
                        ),
                      ],
                    ),
                    labelColor:           const Color(0xFF007AFF),
                    unselectedLabelColor: isDark ? Colors.white38 : Colors.black38,
                    overlayColor:         const WidgetStatePropertyAll(Colors.transparent),
                    splashFactory:        NoSplash.splashFactory,
                    tabs: List.generate(_tabs.length, (i) {
                      final t = _tabs[i];
                      return Tab(
                        icon: Icon(
                          _currentTabIndex == i ? t.activeIcon : t.icon,
                          size: 22,
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),

          // TabBarView sincronizado con el mismo controller del TabBar.
          // Los tres cuerpos son placeholders visuales, sin datos reales
          // hasta que se defina la lógica/backend de esta app.
          body: TabBarView(
            controller: _tabController,
            children: [
              // ── Tab 1: Comunidad Nuevo Ingreso ──────────────────
              ComunidadAspirantes(isDark: isDark),

              // ── Tab 2: Mi Perfil Aspirante ───────────────────────
              Column(
                children: [
                  MiPerfilAspirante(isDark: isDark),
                  const Expanded(
                    child: _PlaceholderContenido(
                      subtitulo: 'Aquí podrás consultar y editar tu\n'
                          'información como aspirante',
                    ),
                  ),
                ],
              ),

              const UbicaTecScreen(),
            ],
          ),
        );
      },
    );
  }


  // ─────────────────────────────────────────────────────────────
  // DRAWER
  // ─────────────────────────────────────────────────────────────

  /// Construye el Drawer lateral con tres secciones visuales:
  ///   • PLANTEL      — pantallas informativas + compartir (sin lógica)
  ///   • PLATAFORMAS  — accesos a SIE y SWS (sin lógica)
  ///   • PREFERENCIAS — toggle de tema global y ajustes (sin lógica)
  ///
  /// Ninguna opción navega todavía a una pantalla real: todas muestran
  /// un SnackBar de "Próximamente" mediante _proximamente().
  Widget _buildDrawer(bool isDark, Color bgCard, Color divColor,
      Color textPrimary, Color accent) {
    return Drawer(
      backgroundColor:
      isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF2F2F7),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                'Menú',
                style: TextStyle(
                  color:         textPrimary,
                  fontSize:      22,
                  fontWeight:    FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),

              // ── Sección: Plantel ───────────────────────────
              _drawerSectionLabel('PLANTEL', textPrimary),
              const SizedBox(height: 10),

              _drawerImageTile(
                imagePath: 'assets/images/drawer_imagen1.jpg',
                label:    'Conoce el plantel',
                subtitle: 'Descubre nuestras instalaciones',
                icon:     CupertinoIcons.location_solid,
                iconBg:   const Color(0xFF007AFF),
                isDark:   isDark,
                onTap: () => _proximamente('Conoce el plantel'),
              ),
              const SizedBox(height: 10),

              _drawerImageTile(
                imagePath: 'assets/images/drawer_imagen2.jpg',
                label:    'Un poco de historia',
                subtitle: 'Conoce los orígenes del plantel',
                icon:     CupertinoIcons.book_solid,
                iconBg:   const Color(0xFF007AFF),
                isDark:   isDark,
                onTap: () => _proximamente('Un poco de historia'),
              ),
              const SizedBox(height: 10),

              _drawerImageTile(
                imagePath: 'assets/images/drawer_imagen3.jpg',
                label:    'Oferta educativa',
                subtitle: 'Conoce las carreras del ITVH',
                icon:     CupertinoIcons.add_circled_solid,
                iconBg:   const Color(0xFF34C759),
                isDark:   isDark,
                onTap: () => _proximamente('Oferta educativa'),
              ),
              const SizedBox(height: 10),

              // Sin imagePath: se renderiza como tile sólido en lugar
              // de card con imagen de fondo. Misma firma, comportamiento condicional.
              _drawerImageTile(
                label:     'Comparte "Aspirantes ITVH"',
                subtitle:  'Invita a otros aspirantes a la app',
                imagePath: '',
                icon:      Icons.share_rounded,
                iconBg:    const Color(0xFF34C759),
                isDark:    isDark,
                onTap: () => _proximamente('Compartir'),
              ),
              const SizedBox(height: 24),

              // ── Sección: Plataformas ───────────────────────
              _drawerSectionLabel('PLATAFORMAS', textPrimary),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _plataformaBtn(
                      imagePath:     'assets/images/sie_logo.png',
                      fallbackLabel: 'SIE Aspirantes',
                      fallbackColor: const Color(0xFF007AFF),
                      subtitle:      'SIE Aspirantes',
                      isDark:        isDark,
                      onTap: () => launchUrl(
                        Uri.parse(
                          'https://villahermosa.sistemasie.app/cgi-bin/sie.pl'
                              '?Opc=PINDEXASPIRANTE&psie=villahermosa&dummy=0',
                        ),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
              const SizedBox(height: 24),

              // ── Sección: Preferencias ──────────────────────
              _drawerSectionLabel('PREFERENCIAS', textPrimary),
              const SizedBox(height: 10),

              // Toggle de tema GLOBAL: cambia isDarkNotifier.value
              // (main.dart) directamente, sin setState local. El
              // ValueListenableBuilder del build() de arriba se
              // encarga de reconstruir esta pantalla solo.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color:        bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border:       Border.all(color: divColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isDark
                            ? CupertinoIcons.moon_fill
                            : CupertinoIcons.sun_max_fill,
                        color: isDark
                            ? const Color(0xFF5AC8FA)
                            : const Color(0xFFFF9500),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isDark ? 'Modo oscuro' : 'Modo claro',
                        style: TextStyle(
                            color:      textPrimary,
                            fontSize:   15,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    CupertinoSwitch(
                      value:       isDark,
                      activeTrackColor: const Color(0xFF007AFF),
                      onChanged:   (_) {
                        isDarkNotifier.value = !isDark;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              _drawerTile(
                icon:        CupertinoIcons.settings,
                iconBg:      Colors.grey.shade600,
                label:       'Ajustes',
                subtitle:    'Cuenta, notificaciones, privacidad',
                bgCard:      bgCard,
                divColor:    divColor,
                textPrimary: textPrimary,
                onTap: () => _proximamente('Ajustes'),
              ),
              const SizedBox(height: 10),

              // Cerrar sesión: única opción del Drawer con lógica real,
              // ya que Supabase Auth signOut ya existe en esta app.
              _drawerTile(
                icon:        CupertinoIcons.square_arrow_right,
                iconBg:      const Color(0xFFFF3B30),
                label:       'Cerrar sesión',
                subtitle:    'Salir de tu cuenta de aspirante',
                bgCard:      bgCard,
                divColor:    divColor,
                textPrimary: textPrimary,
                onTap: _cerrarSesion,
              ),
              const SizedBox(height: 32),

              // Pie del Drawer.
              Center(
                child: Column(
                  children: [
                    Text(
                      'Aspirantes ITVH',
                      style: TextStyle(
                        color:      textPrimary.withValues(alpha: 0.55),
                        fontSize:   13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Programix NaveJL © 2026',
                      style: TextStyle(
                        color:    textPrimary.withValues(alpha: 0.30),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

            ],
          ),
        ),
      ),
    );
  }


  // ─────────────────────────────────────────────────────────────
  // HELPERS DEL DRAWER
  // ─────────────────────────────────────────────────────────────

  /// Etiqueta de sección en mayúsculas con estilo discreto.
  Widget _drawerSectionLabel(String label, Color textPrimary) => Text(
    label,
    style: TextStyle(
      color:         textPrimary.withValues(alpha: 0.38),
      fontSize:      11,
      fontWeight:    FontWeight.w600,
      letterSpacing: 1.1,
    ),
  );

  /// Tile de texto genérico con ícono de color sólido.
  /// Usado para opciones sin imagen de fondo (ej. Ajustes).
  Widget _drawerTile({
    required IconData      icon,
    required Color         iconBg,
    required String        label,
    required String        subtitle,
    required Color         bgCard,
    required Color         divColor,
    required Color         textPrimary,
    required VoidCallback  onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color:        bgCard,
            borderRadius: BorderRadius.circular(14),
            border:       Border.all(color: divColor),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color:        iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 15),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            color:      textPrimary,
                            fontSize:   14,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 1),
                    Text(subtitle,
                        style: TextStyle(
                            color:    textPrimary.withValues(alpha: 0.40),
                            fontSize: 11)),
                  ],
                ),
              ),
              Icon(CupertinoIcons.chevron_right,
                  size: 13, color: textPrimary.withValues(alpha: 0.25)),
            ],
          ),
        ),
      ),
    );
  }

  /// Tile con imagen de fondo opcional (DecorationImage) y overlay oscuro
  /// para asegurar legibilidad del texto sobre cualquier imagen.
  /// Si imagePath está vacío se renderiza como tile sólido sin imagen.
  Widget _drawerImageTile({
    required String?       imagePath,
    required String        label,
    required String        subtitle,
    required IconData      icon,
    required Color         iconBg,
    required bool          isDark,
    required VoidCallback  onTap,
  }) {
    final bool hasImage = imagePath != null && imagePath.isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            height: 88,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: hasImage
                  ? null
                  : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
              border: hasImage
                  ? null
                  : Border.all(
                  color: isDark ? Colors.white10 : Colors.black12),
              image: hasImage
                  ? DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
                // Overlay oscuro del 42 % para contraste con el texto blanco.
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.42),
                  BlendMode.darken,
                ),
              )
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      // Ícono semitransparente sobre imagen; sólido sobre fondo plano.
                      color: hasImage
                          ? Colors.white.withValues(alpha: 0.18)
                          : iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment:  MainAxisAlignment.center,
                      children: [
                        Text(label,
                            style: TextStyle(
                              color: hasImage
                                  ? Colors.white
                                  : (isDark ? Colors.white : Colors.black),
                              fontSize:   14,
                              fontWeight: FontWeight.w600,
                              // Sombra de texto solo sobre imagen para legibilidad.
                              shadows: hasImage
                                  ? const [Shadow(
                                  color:      Colors.black54,
                                  blurRadius: 6,
                                  offset:     Offset(0, 1))]
                                  : null,
                            )),
                        const SizedBox(height: 3),
                        Text(subtitle,
                            style: TextStyle(
                              color: hasImage
                                  ? Colors.white60
                                  : (isDark ? Colors.white38 : Colors.black38),
                              fontSize: 12,
                            )),
                      ],
                    ),
                  ),
                  Icon(CupertinoIcons.chevron_right,
                      size:  13,
                      color: hasImage
                          ? Colors.white60
                          : (isDark ? Colors.white24 : Colors.black26)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Botón cuadrado para plataformas institucionales.
  /// Muestra un logo asset; si falla la carga, usa un texto de fallback
  /// para no dejar el botón vacío (errorBuilder de Image.asset).
  Widget _plataformaBtn({
    required String       imagePath,
    required String       fallbackLabel,
    required Color        fallbackColor,
    required String       subtitle,
    required VoidCallback onTap,
    required bool         isDark,
  }) {
    final bg       = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final divColor = isDark ? Colors.white10 : Colors.black12;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 84,
          decoration: BoxDecoration(
            color:        bg,
            borderRadius: BorderRadius.circular(14),
            border:       Border.all(color: divColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                imagePath,
                height: 34,
                fit:    BoxFit.contain,
                errorBuilder: (_, __, ___) => Text(
                  fallbackLabel,
                  style: TextStyle(
                    color:         fallbackColor,
                    fontSize:      20,
                    fontWeight:    FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(subtitle,
                  style: TextStyle(
                    color:      isDark ? Colors.white54 : Colors.black45,
                    fontSize:   11,
                    fontWeight: FontWeight.w500,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────
// MODELO DE TAB
//
// Encapsula el label y los dos íconos (inactivo/activo) de cada
// pestaña. En esta app la lista de tabs es fija (3 elementos),
// a diferencia de Comunidad ITVH donde variaba por rol de admin.
// ─────────────────────────────────────────────────────────────────

class _TabItem {
  final String   label;
  final IconData icon;
  final IconData activeIcon;
  const _TabItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}


// ─────────────────────────────────────────────────────────────────
// CUERPO PLACEHOLDER DE CADA TAB
//
// Widget genérico reutilizado en las tres pestañas mientras no exista
// la lógica/backend real de "Aspirantes ITVH". Muestra un ícono grande,
// un título y un subtítulo descriptivo de lo que irá en esa sección.
//
// Nota: sigue leyendo Theme.of(context).brightness directo (no
// isDarkNotifier) porque MaterialApp ya reconstruye su ThemeData
// completo desde main.dart cuando el tema global cambia, así que
// este widget se entera igual sin necesidad de escuchar el notifier
// por su cuenta.
// ─────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────
// CUERPO PLACEHOLDER SIN ÍCONO/TÍTULO
//
// Versión reducida de _PlaceholderTabBody, usada en tabs que ya
// tienen su propio encabezado real (como ComunidadAspirantes en
// page_home.dart) y por lo tanto no necesitan repetir ícono y título
// dentro del cuerpo — solo el mensaje descriptivo mientras no exista
// contenido real.
// ─────────────────────────────────────────────────────────────────

class _PlaceholderContenido extends StatelessWidget {
  final String subtitulo;

  const _PlaceholderContenido({required this.subtitulo});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          subtitulo,
          textAlign: TextAlign.center,
          style: TextStyle(
            color:    isDark ? Colors.white38 : Colors.black38,
            fontSize: 13,
            height:   1.4,
          ),
        ),
      ),
    );
  }
}


class _PlaceholderTabBody extends StatelessWidget {
  final IconData icono;
  final String   titulo;
  final String   subtitulo;

  const _PlaceholderTabBody({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF007AFF)
                    .withValues(alpha: isDark ? 0.16 : 0.10),
              ),
              child: Icon(icono, size: 38, color: const Color(0xFF007AFF)),
            ),
            const SizedBox(height: 18),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:      isDark ? Colors.white : Colors.black87,
                fontSize:   18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:    isDark ? Colors.white38 : Colors.black38,
                fontSize: 13,
                height:   1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}