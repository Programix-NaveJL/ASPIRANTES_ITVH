// ═════════════════════════════════════════════════════════════════
// oferta_educativa.dart
//
// Pantalla que lista todas las carreras ofertadas por el ITVH,
// con búsqueda por nombre o siglas y filtrado por área académica.
//
// Funcionalidades:
//   • Barra de búsqueda con botón de limpiar.
//   • Chips horizontales para filtrar por área.
//   • Tarjetas de estadística (total de programas y áreas).
//   • Lista agrupada por área con encabezado de color dinámico.
//   • Cards de carrera navegables; las sin destino se muestran
//     bloqueadas con ícono de candado y etiqueta "Próximamente".
//
// Widgets privados:
//   • _FilterChip   — chip animado de filtro por área
//   • _StatCard     — tarjeta de resumen numérico
//   • _CarreraCard  — card individual de carrera
//
// Modelos privados:
//   • _Area         — enum de áreas académicas con label, ícono y color
//   • _Carrera      — datos estáticos de cada programa educativo
// ═════════════════════════════════════════════════════════════════


import 'package:flutter/material.dart';
import 'Carreras/IAMB.dart';
import 'Carreras/IBQA.dart';
import 'Carreras/ICDA.dart';
import 'Carreras/ICIV.dart';
import 'Carreras/IGEE.dart';
import 'Carreras/IIND.dart';
import 'Carreras/IINF.dart';
import 'Carreras/IPET.dart';
import 'Carreras/IQUI.dart';
import 'Carreras/ISC.dart';
import 'Carreras/ITIC.dart';
import 'Carreras/LADM.dart';


// ═════════════════════════════════════════════════════════════════
// PANTALLA PRINCIPAL
// ═════════════════════════════════════════════════════════════════

class OfertaEducativaScreen extends StatefulWidget {
  const OfertaEducativaScreen({super.key});

  @override
  State<OfertaEducativaScreen> createState() => _OfertaEducativaScreenState();
}

class _OfertaEducativaScreenState extends State<OfertaEducativaScreen> {

  // null significa "sin filtro de área" (mostrar todas).
  _Area? _areaFiltro;

  // Texto actual del campo de búsqueda.
  String _busqueda = '';

  final _searchController = TextEditingController();


  // ─────────────────────────────────────────────────────────────
  // CATÁLOGO DE CARRERAS
  // ─────────────────────────────────────────────────────────────

  /// Lista estática con todas las carreras ofertadas por el ITVH.
  /// Cada entrada incluye nombre completo, siglas, ícono, área
  /// académica y la pantalla de destino al tocar la card.
  ///
  /// Si [destino] es null la card se muestra bloqueada con el
  /// indicador "Próximamente", sin acción al tocar.
  static const _carreras = [
    // ── Sistemas y Computación ────────────────────────────────
    _Carrera(
      nombre:  'Ing. en Sistemas Computacionales',
      siglas:  'ISC',
      icono:   Icons.computer_rounded,
      area:    _Area.sistemas,
      destino: ISCScreen(),
    ),
    _Carrera(
      nombre:  'Ing. en Tecnologías de la Información y Comunicaciones',
      siglas:  'ITIC',
      icono:   Icons.wifi_rounded,
      area:    _Area.sistemas,
      destino: ITICScreen(),
    ),
    _Carrera(
      nombre:  'Ing. en Ciencias de Datos',
      siglas:  'ICDA',
      icono:   Icons.bar_chart_rounded,
      area:    _Area.sistemas,
      destino: ICDAScreen(),
    ),
    _Carrera(
      nombre:  'Ing. Informática',
      siglas:  'IINF',
      icono:   Icons.memory_rounded,
      area:    _Area.sistemas,
      destino: IINFScreen(),
    ),

    // ── Ingeniería Industrial ─────────────────────────────────
    _Carrera(
      nombre:  'Ing. Industrial',
      siglas:  'IIND',
      icono:   Icons.precision_manufacturing_rounded,
      area:    _Area.industrial,
      destino: IINDScreen(),
    ),

    // ── Ciencias Económico-Administrativas ────────────────────
    _Carrera(
      nombre:  'Ing. en Gestión Empresarial',
      siglas:  'IGEE',
      icono:   Icons.business_center_rounded,
      area:    _Area.economico,
      destino: IGEEScreen(),
    ),
    _Carrera(
      nombre:  'Lic. en Administración',
      siglas:  'LADM',
      icono:   Icons.account_balance_rounded,
      area:    _Area.economico,
      destino: LADMScreen(),
    ),

    // ── Ingeniería Química, Bioquímica y Ambiental ────────────
    _Carrera(
      nombre:  'Ing. Química',
      siglas:  'IQUI',
      icono:   Icons.science_rounded,
      area:    _Area.quimica,
      destino: IQUIScreen(),
    ),
    _Carrera(
      nombre:  'Ing. Bioquímica',
      siglas:  'IBQA',
      icono:   Icons.biotech_rounded,
      area:    _Area.quimica,
      destino: IBQAScreen(),
    ),
    _Carrera(
      nombre:  'Ing. Ambiental',
      siglas:  'IAMB',
      icono:   Icons.eco_rounded,
      area:    _Area.quimica,
      destino: IAMBScreen(),
    ),

    // ── Ciencias de la Tierra ─────────────────────────────────
    _Carrera(
      nombre:  'Ing. Civil',
      siglas:  'ICIV',
      icono:   Icons.architecture_rounded,
      area:    _Area.tierra,
      destino: ICIVScreen(),
    ),
    _Carrera(
      nombre:  'Ing. Petrolera',
      siglas:  'IPET',
      icono:   Icons.oil_barrel_rounded,
      area:    _Area.tierra,
      destino: IPETScreen(),
    ),
  ];


  // ─────────────────────────────────────────────────────────────
  // FILTRADO
  // ─────────────────────────────────────────────────────────────

  /// Devuelve la sublista de carreras que pasan los dos filtros activos:
  ///   1. Área académica (si [_areaFiltro] != null).
  ///   2. Texto de búsqueda (compara contra nombre y siglas,
  ///      ignorando mayúsculas/minúsculas).
  List<_Carrera> get _carrerasFiltradas {
    return _carreras.where((c) {
      final coincideArea      = _areaFiltro == null || c.area == _areaFiltro;
      final coincideBusqueda  = _busqueda.isEmpty ||
          c.nombre.toLowerCase().contains(_busqueda.toLowerCase()) ||
          c.siglas.toLowerCase().contains(_busqueda.toLowerCase());
      return coincideArea && coincideBusqueda;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs       = Theme.of(context).colorScheme;
    final filtradas = _carrerasFiltradas;

    // Agrupar las carreras filtradas por área para renderizar los
    // encabezados de sección dinámicamente.
    final Map<_Area, List<_Carrera>> grupos = {};
    for (final c in filtradas) {
      grupos.putIfAbsent(c.area, () => []).add(c);
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title:            const Text('Oferta educativa'),
        centerTitle:      true,
        backgroundColor:  cs.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [

          // ── Barra de búsqueda ──────────────────────────────────────
          // El botón de limpiar (×) solo aparece cuando hay texto escrito.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: SearchBar(
              controller: _searchController,
              hintText:   'Buscar carrera o siglas...',
              leading:    const Icon(Icons.search_rounded, size: 20),
              trailing: _busqueda.isNotEmpty
                  ? [
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _busqueda = '');
                  },
                )
              ]
                  : null,
              onChanged:       (v) => setState(() => _busqueda = v),
              elevation:       const WidgetStatePropertyAll(0),
              backgroundColor: WidgetStatePropertyAll(
                cs.surfaceContainerHighest.withValues(alpha:0.5),
              ),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),

          // ── Chips de filtro por área ───────────────────────────────
          // "Todos" limpia el filtro de área.
          // Tocar el chip del área activa la deselecciona (toggle).
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              children: [
                _FilterChip(
                  label:    'Todos',
                  selected: _areaFiltro == null,
                  color:    cs.primary,
                  onTap:    () => setState(() => _areaFiltro = null),
                ),
                const SizedBox(width: 6),
                ..._Area.values.map((area) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _FilterChip(
                    label:    area.labelCorto,
                    selected: _areaFiltro == area,
                    color:    area.color(cs),
                    onTap:    () => setState(() =>
                    _areaFiltro = _areaFiltro == area ? null : area),
                  ),
                )),
              ],
            ),
          ),

          // ── Stats resumen ──────────────────────────────────────────
          // Muestra el total de programas y áreas del catálogo completo
          // (no de los filtrados) para dar contexto al usuario.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                _StatCard(
                  valor:      '${_carreras.length}',
                  etiqueta:   'programas',
                  color:      cs.primaryContainer,
                  colorTexto: cs.onPrimaryContainer,
                ),
                const SizedBox(width: 10),
                _StatCard(
                  valor:      '${_Area.values.length}',
                  etiqueta:   'áreas',
                  color:      cs.secondaryContainer,
                  colorTexto: cs.onSecondaryContainer,
                ),
              ],
            ),
          ),

          // ── Lista agrupada por área ────────────────────────────────
          Expanded(
            child: filtradas.isEmpty
            // Estado vacío cuando la búsqueda no arroja resultados.
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off_rounded,
                      size:  40,
                      color: cs.onSurface.withValues(alpha:0.25)),
                  const SizedBox(height: 12),
                  Text(
                    'Sin resultados para "$_busqueda"',
                    style: TextStyle(
                      fontSize: 14,
                      color:    cs.onSurface.withValues(alpha:0.45),
                    ),
                  ),
                ],
              ),
            )
                : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                ...grupos.entries.map((entry) {
                  final area      = entry.key;
                  final lista     = entry.value;
                  final areaColor = area.color(cs);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Encabezado de área: pastilla de color + divisor.
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 8, bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: areaColor.withValues(alpha:0.15),
                                borderRadius:
                                BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(area.icono,
                                      size:  13,
                                      color: areaColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    area.label,
                                    style: TextStyle(
                                      fontSize:   12,
                                      fontWeight: FontWeight.bold,
                                      color:      areaColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Divisor que ocupa el espacio restante
                            // de la fila para dar sensación de sección.
                            Expanded(
                              child: Divider(
                                color:     cs.outline.withValues(alpha:0.15),
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Cards de carreras pertenecientes a esta área.
                      ...lista.map((carrera) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CarreraCard(
                          carrera:   carrera,
                          areaColor: areaColor,
                          cs:        cs,
                        ),
                      )),

                      const SizedBox(height: 8),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ═════════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ═════════════════════════════════════════════════════════════════

/// Chip animado de filtro por área.
///
/// Cuando [selected] es true se rellena con el color del área al 15 %
/// de opacidad y el borde se vuelve más visible.
/// La transición usa [AnimatedContainer] de 180 ms para suavizar
/// el cambio de estado sin necesidad de un AnimationController explícito.
class _FilterChip extends StatelessWidget {
  final String       label;
  final bool         selected;
  final Color        color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha:0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? color.withValues(alpha:0.5)
                : cs.outline.withValues(alpha:0.25),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize:   12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color:      selected ? color : cs.onSurface.withValues(alpha:0.55),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de resumen numérico.
///
/// Usada en pares para mostrar "12 programas" y "5 áreas" en la
/// parte superior de la pantalla. Ocupa el espacio disponible de forma
/// equitativa gracias al [Expanded] interno.
class _StatCard extends StatelessWidget {
  final String valor;
  final String etiqueta;
  final Color  color;
  final Color  colorTexto;

  const _StatCard({
    required this.valor,
    required this.etiqueta,
    required this.color,
    required this.colorTexto,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color:        color.withValues(alpha:0.45),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              valor,
              style: TextStyle(
                fontSize:   22,
                fontWeight: FontWeight.bold,
                color:      colorTexto,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              etiqueta,
              style: TextStyle(
                fontSize: 13,
                color:    colorTexto.withValues(alpha:0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card individual de carrera.
///
/// Si [carrera.destino] es null, la card se muestra semi-transparente
/// (opacidad 50 %), con ícono de candado y el texto "Próximamente"
/// junto a las siglas. El tap queda deshabilitado en ese estado.
class _CarreraCard extends StatelessWidget {
  final _Carrera    carrera;
  final Color       areaColor;
  final ColorScheme cs;

  const _CarreraCard({
    required this.carrera,
    required this.areaColor,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final bloqueada = carrera.destino == null;

    return Opacity(
      opacity: bloqueada ? 0.5 : 1.0,
      child: Material(
        color:        cs.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: bloqueada
              ? null
              : () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => carrera.destino!),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: cs.outline.withValues(alpha:0.15)),
            ),
            child: Row(
              children: [

                // ── Ícono de la carrera ────────────────────────
                // Fondo semitransparente del color del área para
                // mantener coherencia visual con el encabezado de sección.
                Container(
                  width:  46,
                  height: 46,
                  decoration: BoxDecoration(
                    color:        areaColor.withValues(alpha:0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(carrera.icono,
                      color: areaColor, size: 22),
                ),
                const SizedBox(width: 14),

                // ── Nombre y siglas ────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        carrera.nombre,
                        style: TextStyle(
                          fontSize:   14,
                          fontWeight: FontWeight.w600,
                          color:      cs.onSurface,
                          height:     1.35,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        // Las carreras bloqueadas añaden "· Próximamente"
                        // para que el usuario sepa que estarán disponibles.
                        bloqueada
                            ? '${carrera.siglas} · Próximamente'
                            : carrera.siglas,
                        style: TextStyle(
                          fontSize: 12,
                          color:    cs.onSurface.withValues(alpha:0.45),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Candado si está bloqueada, flecha si está disponible.
                Icon(
                  bloqueada
                      ? Icons.lock_outline_rounded
                      : Icons.chevron_right_rounded,
                  color: cs.onSurface
                      .withValues(alpha: bloqueada ? 0.25 : 0.35),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ═════════════════════════════════════════════════════════════════
// MODELOS
// ═════════════════════════════════════════════════════════════════

/// Enum de áreas académicas del ITVH.
///
/// Cada valor expone:
///   • [label]       — nombre completo del área
///   • [labelCorto]  — versión abreviada para los chips de filtro
///   • [icono]       — ícono representativo del área
///   • [color]       — color principal tomado del [ColorScheme] activo
///   • [colorContainer] / [colorOnContainer] — variantes de contenedor
///     disponibles para uso futuro en encabezados o badges.
enum _Area {
  sistemas,
  industrial,
  economico,
  quimica,
  tierra;

  String get label => switch (this) {
    _Area.sistemas   => 'Sistemas y Computación',
    _Area.industrial => 'Ingeniería Industrial',
    _Area.economico  => 'Ciencias Económico-Administrativas',
    _Area.quimica    => 'Ing. Química, Bioquímica y Ambiental',
    _Area.tierra     => 'Ciencias de la Tierra',
  };

  String get labelCorto => switch (this) {
    _Area.sistemas   => 'Sistemas',
    _Area.industrial => 'Industrial',
    _Area.economico  => 'Económico-Admin.',
    _Area.quimica    => 'Química',
    _Area.tierra     => 'Tierra',
  };

  IconData get icono => switch (this) {
    _Area.sistemas   => Icons.devices_rounded,
    _Area.industrial => Icons.factory_rounded,
    _Area.economico  => Icons.account_balance_rounded,
    _Area.quimica    => Icons.science_rounded,
    _Area.tierra     => Icons.landscape_rounded,
  };

  Color color(ColorScheme cs) => switch (this) {
    _Area.sistemas   => cs.primary,
    _Area.industrial => cs.tertiary,
    _Area.economico  => cs.secondary,
    _Area.quimica    => cs.error,
    _Area.tierra     => cs.tertiaryFixed,
  };

  Color colorContainer(ColorScheme cs) => switch (this) {
    _Area.sistemas   => cs.primaryContainer,
    _Area.industrial => cs.tertiaryContainer,
    _Area.economico  => cs.secondaryContainer,
    _Area.quimica    => cs.errorContainer,
    _Area.tierra     => cs.tertiaryFixedDim,
  };

  Color colorOnContainer(ColorScheme cs) => switch (this) {
    _Area.sistemas   => cs.onPrimaryContainer,
    _Area.industrial => cs.onTertiaryContainer,
    _Area.economico  => cs.onSecondaryContainer,
    _Area.quimica    => cs.onErrorContainer,
    _Area.tierra     => cs.onTertiaryFixedVariant,
  };
}

/// Datos estáticos de un programa educativo.
///
/// [destino] es nullable: si es null la carrera se considera no
/// implementada aún y se muestra bloqueada en la UI.
class _Carrera {
  final String   nombre;
  final String   siglas;
  final IconData icono;
  final _Area    area;
  final Widget?  destino;

  const _Carrera({
    required this.nombre,
    required this.siglas,
    required this.icono,
    required this.area,
    this.destino,
  });
}