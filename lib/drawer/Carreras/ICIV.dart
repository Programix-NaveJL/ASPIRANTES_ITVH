// ═════════════════════════════════════════════════════════════════
// ICIV.dart
//
// Pantalla informativa de la Ingeniería Civil (ICIV).
//
// Secciones:
//   • Cards resumen        — Misión y Visión en dos cards lado a lado
//   • Objetivo General     — descripción completa del propósito
//   • Objetivos Específicos — siete competencias numeradas
//   • Perfil de Ingreso    — características deseables del aspirante
//   • Perfil de Egreso     — competencias del profesional al egresar
//   • Campo Laboral        — instituciones y sectores de inserción
//   • Retículas 2010-208   — dos especialidades con enlace a PDF
//   • Plan de Estudios     — ExpansionTile por semestre (1–9)
//   • Especialidades       — ExpansionTile por especialidad con materias
//
// Widgets privados de esta pantalla:
//   • _SemestreExpansion     — tile expandible de un semestre
//   • _EspecialidadExpansion — tile expandible de una especialidad
//   • _MateriaItem           — fila tappable que abre PdfViewerScreen;
//                              si la URL está vacía deshabilita el tap
//                              y cambia el ícono a info
//   • _SectionTitle          — título de sección con barra de acento cs.primary
//   • _InfoCard              — card de resumen con ícono y color
//                              (Misión en cs.primary, Visión en cs.tertiary)
//   • _ObjetivoItem          — fila numerada con título y descripción
//   • _PerfilSection         — lista de bullets con punto de color
//   • _ReticulaItem          — card tappable que abre PdfViewerScreen
//
// Modelos de datos (privados):
//   • _Reticula    — clave, nombre y URL de una retícula
//   • _Materia     — nombre y URL de un temario en PDF
//   • _Semestre    — número y lista de materias
//   • _Especialidad — nombre, ícono, función de color y materias
//
// Color de acento:
//   • cs.primary   — color principal de la carrera; semestres, sección
//                    title, retícula, objetivos y campo laboral
//   • cs.secondary — acento del Perfil de Ingreso
//   • cs.tertiary  — acento del Perfil de Egreso y card Visión
//
// Notas de implementación:
//   • ICIV define dos constantes de URL base (_base y _base24) porque
//     la especialidad "Estructuras" usa temarios del servidor 2010 y la
//     especialidad "Construcción y Mantenimiento de Vías Terrestres"
//     usa temarios del servidor 2024, cada uno en su propia carpeta.
//   • Las actividades del 9no semestre (url vacía) se renderizan con
//     _MateriaItem, que detecta hasUrl = false y desactiva el tap.
// ═════════════════════════════════════════════════════════════════

import 'package:aspirantes_itvh_app/drawer/Carreras/pdf_viewer_screen.dart';
import 'package:flutter/material.dart';


// ═════════════════════════════════════════════════════════════════
// PANTALLA PRINCIPAL
// ═════════════════════════════════════════════════════════════════

class ICIVScreen extends StatelessWidget {
  const ICIVScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [

          // SliverAppBar expandible: colapsa al hacer scroll y
          // muestra solo el título fijo en la barra superior.
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: cs.surface,
            title: Text(
              '',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cs.onSurface),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Fondo con tinte en cs.primary — color de acento de ICIV.
                  Container(color: cs.primary.withValues(alpha: 0.12)),

                  // Ícono decorativo semitransparente en esquina superior derecha.
                  Positioned(
                    right: -30, top: -20,
                    child: Icon(Icons.architecture_rounded, size: 220, color: cs.primary.withValues(alpha: 0.07)),
                  ),

                  // Chip del departamento al que pertenece la carrera.
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 56),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Departamento de Ciencias de la Tierra',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.primary),
                        ),
                      ),
                    ),
                  ),

                  // Título grande visible solo cuando el SliverAppBar está expandido.
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Text(
                        'Ingeniería Civil',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Contenido principal ────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // Cards resumen lado a lado: Misión (cs.primary) y
                // Visión (cs.tertiary) para diferenciarlas visualmente.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _InfoCard(cs: cs, icono: Icons.flag_rounded, titulo: 'Misión',
                        contenido: 'Formar profesionistas en Ingeniería Civil con una preparación científica-tecnológica con competencias sinérgicas, espíritu innovador que contribuya al desarrollo sustentable y a la calidad de vida del ser humano.',
                        color: cs.primary)),
                    const SizedBox(width: 12),
                    Expanded(child: _InfoCard(cs: cs, icono: Icons.visibility_rounded, titulo: 'Visión',
                        contenido: 'Ser un programa de ingeniería Civil de calidad, que impulsa el desarrollo integral, sostenido y sustentable.',
                        color: cs.tertiary)),
                  ],
                ),

                const SizedBox(height: 28),

                // Objetivo General completo
                _SectionTitle(cs: cs, texto: 'Objetivo General'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
                  ),
                  child: Text(
                    'Formar profesionistas en ingeniería civil de manera integral, con visión humana, analítica, creativa y emprendedora, capaces de identificar y resolver problemas con eficiencia, eficacia y pertinencia, mediante la planeación, diseño, construcción, operación y conservación de obras de infraestructura, en el marco de la globalización, la sustentabilidad y la calidad, contribuyendo al desarrollo de la sociedad.',
                    style: TextStyle(fontSize: 14, height: 1.65, color: cs.onSurface.withValues(alpha: 0.8)),
                  ),
                ),

                const SizedBox(height: 28),

                // Objetivos específicos — siete competencias numeradas.
                _SectionTitle(cs: cs, texto: 'Objetivos Específicos'),
                const SizedBox(height: 12),
                ..._objetivos.map((obj) => _ObjetivoItem(cs: cs, numero: obj.$1, titulo: obj.$2, descripcion: obj.$3)),

                const SizedBox(height: 28),

                // Perfil de ingreso — cs.secondary diferencia visualmente
                // de egreso (tertiary) y del acento principal (primary).
                _SectionTitle(cs: cs, texto: 'Perfil de Ingreso'),
                const SizedBox(height: 12),
                _PerfilSection(cs: cs, color: cs.secondary, items: const [
                  'El estudiante de Ingeniería Civil debe mostrar habilidad e ingenio para la solución de problemas.',
                  'Tener predilección por las ciencias físico-matemáticas.',
                  'Disposición para el trabajo arduo y en equipo.',
                ]),

                const SizedBox(height: 28),

                // Perfil de egreso — cs.tertiary para distinguirlo
                // del perfil de ingreso (secondary).
                _SectionTitle(cs: cs, texto: 'Perfil de Egreso'),
                const SizedBox(height: 12),
                _PerfilSection(cs: cs, color: cs.tertiary, items: const [
                  'Planea, proyecta, diseña, construye, opera y conserva obras hidráulicas y sanitarias, sistemas estructurales, vías terrestres, edificación y obras de infraestructura urbana e industrial para el desarrollo de la sociedad.',
                  'Dirige equipos técnicos para determinar la factibilidad ambiental, económica, técnica y social de los proyectos de obras civiles.',
                  'Formula y ejecuta proyectos de investigación para el desarrollo tecnológico en el ámbito de la Ingeniería Civil.',
                  'Crea, adapta, innova y aplica tecnologías en los estudios, proyectos y construcción de obras civiles para los requerimientos de la sociedad.',
                  'Administra proyectos para optimizar el uso de los recursos en el logro de los objetivos de las obras civiles.',
                  'Emplea técnicas de control de calidad en los materiales y procesos constructivos para la seguridad y durabilidad de las obras de ingeniería civil.',
                  'Utiliza tecnologías de la información y comunicación para la optimización de los proyectos de Ingeniería Civil.',
                  'Emprende proyectos productivos pertinentes para el desarrollo sustentable de las comunidades.',
                ]),

                const SizedBox(height: 28),

                // Campo Laboral — vuelve a cs.primary para cerrar el ciclo
                // de acentos y unificarlo con el color principal de la carrera.
                _SectionTitle(cs: cs, texto: 'Campo Laboral'),
                const SizedBox(height: 12),
                _PerfilSection(cs: cs, color: cs.primary, items: const [
                  'Pemex.',
                  'Secretaría de Comunicaciones y Transporte.',
                  'Secretarías de Obras Públicas (Ayuntamientos).',
                  'Secretaría de Ordenamiento Territorial y Obras Públicas del Estado de Tabasco.',
                ]),

                const SizedBox(height: 28),

                // Retículas — dos especialidades del plan 2010-208.
                _SectionTitle(cs: cs, texto: 'Retículas 2010-208'),
                const SizedBox(height: 12),
                ..._reticulas.map((r) => _ReticulaItem(cs: cs, reticula: r)),

                const SizedBox(height: 28),

                // Plan de Estudios — un ExpansionTile por semestre.
                _SectionTitle(cs: cs, texto: 'Plan de Estudios'),
                const SizedBox(height: 12),
                ..._semestres.map((sem) => _SemestreExpansion(cs: cs, semestre: sem)),

                const SizedBox(height: 20),

                // Especialidades — un ExpansionTile por especialidad.
                _SectionTitle(cs: cs, texto: 'Especialidades'),
                const SizedBox(height: 12),
                ..._especialidades.map((esp) => _EspecialidadExpansion(cs: cs, especialidad: esp)),

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}


// ═════════════════════════════════════════════════════════════════
// DATOS
// ═════════════════════════════════════════════════════════════════

// ── Objetivos específicos ─────────────────────────────────────
// Cada registro es una tupla (número, título corto, descripción).
const _objetivos = [
  (1, 'Resolver Problemas', 'Identifica, determina o resuelve problemas en las áreas de Hidráulica, Estructuras, Vías Terrestre y Construcción.'),
  (2, 'Saber Diseñar',      'Diseña y desarrolla proyectos para solucionar problemas de obras civiles.'),
  (3, 'Hacer Experimentos', 'Formula y ejecuta proyectos de investigación y desarrollo tecnológico en el ámbito de la Ingeniería Civil.'),
  (4, 'Saber Comunicarse',  'Utiliza Tecnologías de la Información y Comunicación (TIC\'s), software especializado y herramientas electrónicas para el diseño de proyectos de Ingeniería Civil.'),
  (5, 'Ser Ético',          'Optimiza el uso de los recursos en los procesos constructivos de obras civiles, con sentido ético y profesional.'),
  (6, 'Actualizarse',       'Se actualiza constantemente para realizar estudios de factibilidad ambiental, económica, técnica y financiera de los proyectos de obras civiles.'),
  (7, 'Trabajar en Equipo', 'Coordina y participa en equipos multidisciplinarios para la aplicación de soluciones innovadoras en proyectos de Ingeniería Civil.'),
];

// ── Modelo de retícula ────────────────────────────────────────
class _Reticula {
  final String clave, nombre, url;
  const _Reticula({required this.clave, required this.nombre, required this.url});
}

const _reticulas = [
  _Reticula(clave: 'ICIV-2010-208--ICIE-CMV-2024-04', nombre: 'Construcción y Mantenimiento de Vías Terrestres',
      url: 'http://cc.villahermosa.tecnm.mx/sys/estpro/reticulas/ICIV-2010-208--ICIE-CMV-2024-04.pdf'),
  _Reticula(clave: 'ICIV-2010-208--ICIE-EST-2023-01', nombre: 'Estructuras',
      url: 'http://cc.villahermosa.tecnm.mx/sys/estpro/reticulas/ICIV-2010-208--ICIE-EST-2023-01.pdf'),
];

// ── Modelo de materia ─────────────────────────────────────────
class _Materia {
  final String nombre, url;
  const _Materia(this.nombre, this.url);
}

// ── Modelo de semestre ────────────────────────────────────────
// Sin flag soloInformativo: las actividades del 9no semestre
// se modelan como _Materia con url vacía; _MateriaItem detecta
// hasUrl = false y desactiva el tap automáticamente.
class _Semestre {
  final int numero;
  final List<_Materia> materias;
  const _Semestre(this.numero, this.materias);
}

// Dos constantes de URL base porque las especialidades apuntan
// a servidores distintos: Estructuras (2010) y Vías Terrestres (2024).
const _base   = 'https://villahermosa.tecnm.mx/docs/oferta/ingcivil/temario2010';
const _base24 = 'https://villahermosa.tecnm.mx/docs/oferta/ingcivil/temario2024';

final _semestres = [
  _Semestre(1, [
    _Materia('Fundamentos de Investigación',  '$_base/1semestre/FundamentosdeInvestigacion-AC006.pdf'),
    _Materia('Cálculo Diferencial',           '$_base/1semestre/CalculoDiferencial-AC001.pdf'),
    _Materia('Taller de Ética',               '$_base/1semestre/TallerdeEtica-AC007.pdf'),
    _Materia('Química',                       '$_base/1semestre/Quimica-AE058.pdf'),
    _Materia('Software en Ingeniería Civil',  '$_base/1semestre/SOFTWARE-DE-INGENIERIA-CIVIL.pdf'),
    _Materia('Dibujo en Ingeniería Civil',    '$_base/1semestre/DIBUJO-EN-INGENIERIA-CIVIL.pdf'),
  ]),
  _Semestre(2, [
    _Materia('Cálculo Integral',                  '$_base/2semestre/CalculoIntegral-AC002.pdf'),
    _Materia('Cálculo Vectorial',                 '$_base/2semestre/CalculoVectorial-AC004.pdf'),
    _Materia('Probabilidad y Estadística',        '$_base/2semestre/PROBABILIDADYESTADISTICA.pdf'),
    _Materia('Topografía',                        '$_base/2semestre/TOPOGRAFIA.pdf'),
    _Materia('Materiales y Procesos Constructivos','$_base/2semestre/MATERIALESYPROCESOSCONSTRUCTIVOS.pdf'),
    _Materia('Geología',                          '$_base/2semestre/GEOLOGIA.pdf'),
  ]),
  _Semestre(3, [
    _Materia('Álgebra Lineal',           '$_base/3semestre/AlgebraLineal-AC003.pdf'),
    _Materia('Ecuaciones Diferenciales', '$_base/3semestre/EcuacionesDiferenciales-AC005.pdf'),
    _Materia('Estática',                 '$_base/3semestre/ESTATICA.pdf'),
    _Materia('Carreteras',               '$_base/3semestre/CARRETERAS.pdf'),
    _Materia('Tecnología del Concreto',  '$_base/3semestre/TECNOLOGIADELCONCRETO.pdf'),
    _Materia('Sistemas de Transporte',   '$_base/3semestre/SISTEMASDETRANSPORTE.pdf'),
  ]),
  _Semestre(4, [
    _Materia('Fundamentos de la Mecánica de los Medios Continuos', '$_base/4semestre/FUNDAMENTOSDELAMECANICADELOSMEDIOSCONTINUOS.pdf'),
    _Materia('Métodos Numéricos',                                  '$_base/4semestre/METODOSNUMERICOS.pdf'),
    _Materia('Mecánica de Suelos',                                 '$_base/4semestre/MECANICADESUELOS.pdf'),
    _Materia('Maquinaria Pesada y Movimiento de Tierras',          '$_base/4semestre/MAQUINARIAPESADAYMOVIMIENTODETIERRAS.pdf'),
    _Materia('Dinámica',                                           '$_base/4semestre/DINAMICA.pdf'),
    _Materia('Modelos de Optimización de Recursos',                '$_base/4semestre/MODELOSDEOPTIMIZACIONDERECURSOS.pdf'),
  ]),
  _Semestre(5, [
    _Materia('Mecánica de Materiales',    '$_base/5semestre/MECANICADEMATERIALES.pdf'),
    _Materia('Desarrollo Sustentable',    '$_base/5semestre/DesarrolloSustentable-AC008.pdf'),
    _Materia('Mecánica de Suelos Aplicada','$_base/5semestre/MECANICADESUELOSAPLICADA.pdf'),
    _Materia('Costos y Presupuestos',     '$_base/5semestre/COSTOSYPRESUPUESTOS.pdf'),
    _Materia('Taller de Investigación I', '$_base/5semestre/TallerdeInvestigacion-I-AC009.pdf'),
    _Materia('Hidráulica Básica',         '$_base/5semestre/HIDRAULICABASICA.pdf'),
  ]),
  _Semestre(6, [
    _Materia('Análisis Estructural',                '$_base/6semestre/ANALISISESTRUCTURAL.pdf'),
    _Materia('Instalaciones en los Edificios',      '$_base/6semestre/INSTALACIONESENLOSEDIFICIOS.pdf'),
    _Materia('Diseño y Construcción de Pavimentos', '$_base/6semestre/DISENOYCONSTRUCCIONDEPAVIMENTOS.pdf'),
    _Materia('Administración de la Construcción',   '$_base/6semestre/ADMINISTRACIONDELACONSTRUCCION.pdf'),
    _Materia('Hidrología Superficial',              '$_base/6semestre/HIDROLOGIASUPERFICIAL.pdf'),
    _Materia('Hidráulica de Canales',               '$_base/6semestre/HIDRAULICADECANALES.pdf'),
  ]),
  _Semestre(7, [
    _Materia('Análisis Estructural Avanzado',             '$_base/7semestre/ANALISISESTRUCTURAL-AVANZADO.pdf'),
    _Materia('Diseño de Elementos de Concreto Reforzado', '$_base/7semestre/DISENODEELEMENTOSDECONCRETOREFORZADO.pdf'),
    _Materia('Taller de Investigación II',                '$_base/7semestre/TallerdeInvestigacionII-AC010.pdf'),
    _Materia('Abastecimiento de Agua',                    '$_base/7semestre/ABASTECIMIENTODEAGUA.pdf'),
  ]),
  _Semestre(8, [
    _Materia('Diseño Estructural de Cimentaciones',   '$_base/8semestre/DISENOESTRUCTURALDECIMENTACIONES.pdf'),
    _Materia('Diseño de Elementos de Acero',          '$_base/8semestre/DISENODEELEMENTOSDEACERO.pdf'),
    _Materia('Formulación y Evaluación de Proyectos', '$_base/8semestre/FORMULACIONYEVALUACIONDEPROYECTOS.pdf'),
    _Materia('Alcantarillado',                        '$_base/8semestre/ALCANTARILLADO.pdf'),
  ]),
  // 9no semestre: actividades institucionales sin PDF de temario.
  // url vacía → _MateriaItem detecta hasUrl = false y desactiva el tap.
  _Semestre(9, [
    _Materia('Especialidad',              ''),
    _Materia('Residencia Profesional',    ''),
    _Materia('Servicio Social',           ''),
    _Materia('Actividades Complementarias', ''),
  ]),
];

// ── Modelo de especialidad ────────────────────────────────────
// El color se recibe como función (ColorScheme) → Color para
// resolverse en tiempo de build con el tema activo.
class _Especialidad {
  final String nombre;
  final IconData icono;
  final Color Function(ColorScheme) color;
  final List<_Materia> materias;
  const _Especialidad({required this.nombre, required this.icono, required this.color, required this.materias});
}

final _especialidades = [
  _Especialidad(
    nombre: 'Estructuras (ICIE-EST-2023-01)',
    icono: Icons.architecture_rounded,
    color: (cs) => cs.primary,
    // Temarios en el servidor 2010 (_base).
    materias: [
      _Materia('Normas y Reglamentos para Diseños Estructurales y Sostenibles', '$_base/Especialidad/ICIE-EST-2023-01/NormasyReglamentos.pdf'),
      _Materia('Obras de Ingeniería Sostenible',                                '$_base/Especialidad/ICIE-EST-2023-01/ObrasdeIngenieriIaSostenible.pdf'),
      _Materia('Análisis Sísmico y Eólico',                                     '$_base/Especialidad/ICIE-EST-2023-01/AnalisisSismicoyEolico.pdf'),
      _Materia('Estructuras de Mampostería',                                    '$_base/Especialidad/ICIE-EST-2023-01/EstructurasdeMamposteria.pdf'),
      _Materia('Diseño Estructural Sostenible Con Elementos Prefabricados',     '$_base/Especialidad/ICIE-EST-2023-01/Disen%CC%83oEstructuralSostenible.pdf'),
    ],
  ),
  _Especialidad(
    nombre: 'Construcción y Mantenimiento de Vías Terrestres (ICIE-CMV-2024-04)',
    icono: Icons.add_road_rounded,
    color: (cs) => cs.secondary,
    // Temarios en el servidor 2024 (_base24), distinto al de Estructuras.
    materias: [
      _Materia('Ingeniería de Tránsito Revisada',                 '$_base24/Especialidad/ICIE-CMV-2024-04/Ingenieriadetransitorevisada.pdf'),
      _Materia('Topografía Aplicada',                             '$_base24/Especialidad/ICIE-CMV-2024-04/TOPOGRAFIAAPLICADA.pdf'),
      _Materia('Construcción de Vías Férreas',                    '$_base24/Especialidad/ICIE-CMV-2024-04/CONSTRUCCIONDEVIASFERREAS.pdf'),
      _Materia('Mantenimiento y Conservación de Vías Terrestres', '$_base24/Especialidad/ICIE-CMV-2024-04/MantoconservacionViasterrestres.pdf'),
      _Materia('Auditoría de Seguridad a las Vías Férreas',       '$_base24/Especialidad/ICIE-CMV-2024-04/AuditoriaSeguridadViasFerreas.pdf'),
    ],
  ),
];


// ═════════════════════════════════════════════════════════════════
// WIDGETS PRIVADOS
// ═════════════════════════════════════════════════════════════════

/// Tile expandible que muestra las materias de un semestre.
/// Las actividades del 9no semestre (url vacía) se renderizan con
/// _MateriaItem, que detecta hasUrl y deshabilita el tap.
class _SemestreExpansion extends StatelessWidget {
  final ColorScheme cs;
  final _Semestre semestre;
  const _SemestreExpansion({required this.cs, required this.semestre});

  // Ordinales en español para el título del tile.
  static const _ordinal = ['', '1er', '2do', '3er', '4to', '5to', '6to', '7mo', '8vo', '9no'];

  @override
  Widget build(BuildContext context) {
    final ord = _ordinal[semestre.numero];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Theme(
          // Eliminar el Divider que Flutter agrega por defecto
          // al expandir un ExpansionTile.
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            backgroundColor: cs.primary.withValues(alpha: 0.05),
            collapsedBackgroundColor: cs.primary.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.primary.withValues(alpha: 0.12)),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outline.withValues(alpha: 0.12)),
            ),
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Center(
                child: Text('${semestre.numero}',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.primary)),
              ),
            ),
            title: Text('$ord Semestre',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
            subtitle: Text('${semestre.materias.length} materias',
                style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.45))),
            children: semestre.materias.map((m) => _MateriaItem(cs: cs, materia: m)).toList(),
          ),
        ),
      ),
    );
  }
}

/// Tile expandible que muestra las materias de una especialidad.
/// El color se resuelve en build con el ColorScheme activo.
class _EspecialidadExpansion extends StatelessWidget {
  final ColorScheme cs;
  final _Especialidad especialidad;
  const _EspecialidadExpansion({required this.cs, required this.especialidad});

  @override
  Widget build(BuildContext context) {
    final color = especialidad.color(cs);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            backgroundColor: color.withValues(alpha: 0.05),
            collapsedBackgroundColor: color.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: color.withValues(alpha: 0.15)),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outline.withValues(alpha: 0.12)),
            ),
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(especialidad.icono, color: color, size: 20),
            ),
            title: Text(especialidad.nombre,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
            subtitle: Text('${especialidad.materias.length} materias',
                style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.45))),
            children: especialidad.materias.map((m) => _MateriaItem(cs: cs, materia: m)).toList(),
          ),
        ),
      ),
    );
  }
}

/// Fila tappable que navega a PdfViewerScreen con el temario de la materia.
/// Si la materia no tiene URL (hasUrl = false), se deshabilita el tap
/// y el ícono cambia a info para indicar que no hay PDF disponible.
class _MateriaItem extends StatelessWidget {
  final ColorScheme cs;
  final _Materia materia;
  const _MateriaItem({required this.cs, required this.materia});

  @override
  Widget build(BuildContext context) {
    final hasUrl = materia.url.isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: hasUrl
            ? () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => PdfViewerScreen(titulo: materia.nombre, url: materia.url),
        ))
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              Icon(
                hasUrl ? Icons.picture_as_pdf_rounded : Icons.info_outline_rounded,
                size: 18,
                color: cs.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(materia.nombre,
                  style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.8)))),
              if (hasUrl)
                Icon(Icons.chevron_right_rounded, size: 18, color: cs.onSurface.withValues(alpha: 0.25)),
            ],
          ),
        ),
      ),
    );
  }
}


// ═════════════════════════════════════════════════════════════════
// WIDGETS REUTILIZABLES
// ═════════════════════════════════════════════════════════════════

/// Título de sección con barra vertical de acento (4 × 18 px).
/// Usa cs.primary como color de acento, coherente con los tiles
/// de semestre de esta pantalla.
class _SectionTitle extends StatelessWidget {
  final ColorScheme cs;
  final String texto;
  const _SectionTitle({required this.cs, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 4, height: 18,
          decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Text(texto, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: cs.onSurface)),
    ]);
  }
}

/// Card compacta con ícono, título y texto para las secciones de resumen.
/// El color se pasa como parámetro para soportar distintos acentos
/// en la misma fila de cards (Misión en primary, Visión en tertiary).
class _InfoCard extends StatelessWidget {
  final ColorScheme cs;
  final IconData icono;
  final String titulo, contenido;
  final Color color;
  const _InfoCard({required this.cs, required this.icono, required this.titulo, required this.contenido, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icono, color: color, size: 22),
        const SizedBox(height: 8),
        Text(titulo, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 6),
        Text(contenido, style: TextStyle(fontSize: 12, height: 1.55, color: cs.onSurface.withValues(alpha: 0.7))),
      ]),
    );
  }
}

/// Fila numerada con círculo de acento, título en negrita
/// y descripción en texto secundario.
class _ObjetivoItem extends StatelessWidget {
  final ColorScheme cs;
  final int numero;
  final String titulo, descripcion;
  const _ObjetivoItem({required this.cs, required this.numero, required this.titulo, required this.descripcion});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Center(child: Text('$numero',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cs.primary))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cs.onSurface)),
          const SizedBox(height: 3),
          Text(descripcion, style: TextStyle(fontSize: 13, height: 1.55, color: cs.onSurface.withValues(alpha: 0.65))),
        ])),
      ]),
    );
  }
}

/// Lista de bullets con un punto circular de color
/// seguido del texto del ítem.
class _PerfilSection extends StatelessWidget {
  final ColorScheme cs;
  final Color color;
  final List<String> items;
  const _PerfilSection({required this.cs, required this.color, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // El padding top: 5 alinea el punto con la primera línea del texto.
          Padding(padding: const EdgeInsets.only(top: 5),
              child: Container(width: 6, height: 6,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle))),
          const SizedBox(width: 12),
          Expanded(child: Text(item,
              style: TextStyle(fontSize: 13, height: 1.6, color: cs.onSurface.withValues(alpha: 0.75)))),
        ]),
      )).toList(),
    );
  }
}

/// Card tappable que abre PdfViewerScreen con la retícula correspondiente.
/// Muestra el nombre del plan, la clave y un ícono de PDF.
class _ReticulaItem extends StatelessWidget {
  final ColorScheme cs;
  final _Reticula reticula;
  const _ReticulaItem({required this.cs, required this.reticula});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => PdfViewerScreen(titulo: reticula.nombre, url: reticula.url),
          )),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
            ),
            child: Row(children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.grid_view_rounded, color: cs.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(reticula.nombre,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                const SizedBox(height: 3),
                Text(reticula.clave,
                    style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4), letterSpacing: 0.2)),
              ])),
              Icon(Icons.picture_as_pdf_rounded, color: cs.primary.withValues(alpha: 0.5), size: 20),
            ]),
          ),
        ),
      ),
    );
  }
}