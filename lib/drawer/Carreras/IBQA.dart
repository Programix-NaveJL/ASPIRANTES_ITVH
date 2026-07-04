// ═════════════════════════════════════════════════════════════════
// IBQA.dart
//
// Pantalla informativa de la Ingeniería Bioquímica (IBQA).
//
// Secciones:
//   • Cards resumen        — Misión y Visión en dos cards lado a lado
//   • Objetivo General     — descripción completa del propósito
//   • Objetivos Específicos — siete competencias numeradas
//   • Perfil de Ingreso    — características deseables del aspirante
//   • Perfil de Egreso     — competencias del profesional al egresar
//   • Retícula 2010-207    — un plan con enlace a PDF
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
//                    (sin flag soloInformativo: el 9no semestre
//                    mezcla una materia con PDF y tres sin URL)
//   • _Especialidad — nombre, ícono, función de color y materias
//
// Color de acento:
//   • cs.primary   — color principal de la carrera; Misión, semestres,
//                    sección title, retícula y especialidad
//   • cs.secondary — acento del Perfil de Ingreso
//   • cs.tertiary  — acento del Perfil de Egreso y card Visión
//
// Nota de implementación:
//   • El 9no semestre de IBQA es distinto al de otras carreras: incluye
//     "Formulación y Evaluación de Proyectos" con PDF real, mientras que
//     Residencia Profesional, Servicio Social y Actividades
//     Complementarias tienen url vacía. _MateriaItem maneja ambos casos
//     con la verificación hasUrl.
//   • El widget _ObjetivoItem es idéntico al de LADM e IBQA en diseño,
//     pero sus instancias se declaran aquí como clase privada de archivo.
// ═════════════════════════════════════════════════════════════════

import 'package:aspirantes_itvh_app/drawer/Carreras/pdf_viewer_screen.dart';
import 'package:flutter/material.dart';


// ═════════════════════════════════════════════════════════════════
// PANTALLA PRINCIPAL
// ═════════════════════════════════════════════════════════════════

class IBQAScreen extends StatelessWidget {
  const IBQAScreen({super.key});

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
                  // Fondo con tinte en cs.primary — color de acento de IBQA.
                  Container(color: cs.primary.withValues(alpha: 0.12)),

                  // Ícono decorativo semitransparente en esquina superior derecha.
                  Positioned(
                    right: -30, top: -20,
                    child: Icon(Icons.biotech_rounded, size: 220, color: cs.primary.withValues(alpha: 0.07)),
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
                          'Departamento Química, Bioquímica y Ambiental',
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
                        'Ingeniería Bioquímica',
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
                        contenido: 'Formar profesionistas en ingeniería bioquímica con una preparación científica-tecnológica y una conciencia social que contribuya al desarrollo sustentable y a la calidad de vida del ser humano.',
                        color: cs.primary)),
                    const SizedBox(width: 12),
                    Expanded(child: _InfoCard(cs: cs, icono: Icons.visibility_rounded, titulo: 'Visión',
                        contenido: 'Ser un programa de ingeniería bioquímica reconocido por la calidad científica, tecnológica y humana de sus egresados, que impulsen el desarrollo sustentable.',
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
                    'Formar profesionales íntegros en la Ingeniería Bioquímica competentes para trabajar en equipos multidisciplinarios y multiculturales que, con sentido ético, crítico, creativo, emprendedor y actitud de liderazgo, diseñe, controlen, simulen y optimicen equipos, procesos y tecnologías sustentables que utilicen recursos bióticos y sus derivados, para la producción de bienes y servicios que contribuyan a elevar el nivel de vida de la sociedad.',
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
                  'Habilidades en las áreas de Matemáticas, Química, Física y Biología, utilizando la observación, el análisis, la síntesis (creatividad) y la evaluación (juicio crítico).',
                  'Capacidad para expresarse correctamente en forma oral y escrita.',
                  'Pensamiento analítico, objetivo, crítico, sintético y destreza manual.',
                  'Habilidades para realizar trabajo en equipo.',
                ]),

                const SizedBox(height: 28),

                // Perfil de egreso — cs.tertiary para distinguirlo
                // del perfil de ingreso (secondary).
                _SectionTitle(cs: cs, texto: 'Perfil de Egreso'),
                const SizedBox(height: 12),
                _PerfilSection(cs: cs, color: cs.tertiary, items: const [
                  'Ejerce su profesión para resolver problemas en su ámbito, trabajando en equipos interdisciplinarios y multiculturales, con liderazgo, sentido crítico, disposición al cambio y comprometido con la calidad.',
                  'Diseña y selecciona equipos y procesos para el aprovechamiento sustentable de los recursos bióticos.',
                  'Identifica y aplica tecnologías emergentes relacionadas con su campo de acción del Ingeniero Bioquímico para la mejora de procesos existentes.',
                  'Participa en el diseño y la aplicación de normas y programas para la gestión y aseguramiento de la calidad, en empresas e instituciones del ámbito de la Ingeniería Bioquímica.',
                  'Formula y evalúa proyectos de Ingeniería Bioquímica para coadyuvar al desarrollo regional con criterios de sustentabilidad.',
                  'Participa en proyectos de investigación científica y tecnológica en el campo de la Ingeniería Bioquímica para contribuir al desarrollo de la sociedad.',
                  'Crea y administra empresas productoras de bienes y servicios para satisfacer necesidades en el campo de aplicación de la Ingeniería Bioquímica.',
                ]),

                const SizedBox(height: 28),

                // Retícula — un único plan disponible para IBQA.
                _SectionTitle(cs: cs, texto: 'Retícula 2010-207'),
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
  (1, 'Trabajo en Equipo',      'Trabaja en equipos interdisciplinarios y multiculturales, con liderazgo, sentido crítico, disposición al cambio y comprometido con la calidad.'),
  (2, 'Diseño de Procesos',     'Diseña y selecciona equipos y procesos para el aprovechamiento sustentable de los recursos bióticos.'),
  (3, 'Tecnologías Emergentes', 'Identifica y aplica tecnologías emergentes relacionadas con su campo de acción del Ingeniero Bioquímico para la mejora de procesos existentes.'),
  (4, 'Gestión de Calidad',     'Participa en el diseño y la aplicación de normas y programas para la gestión y aseguramiento de la calidad, en empresas e instituciones del ámbito de la Ingeniería Bioquímica.'),
  (5, 'Actualización',          'Actualiza sus conocimientos permanentemente para responder a los cambios globales.'),
  (6, 'Investigación',          'Participa en proyectos de investigación científica y tecnológica en el campo de la Ingeniería Bioquímica para contribuir al desarrollo de la sociedad.'),
  (7, 'Emprendimiento',         'Crea y administra empresas productoras de bienes y servicios para satisfacer necesidades en el campo de aplicación de la Ingeniería Bioquímica.'),
];

// ── Modelo de retícula ────────────────────────────────────────
class _Reticula {
  final String clave, nombre, url;
  const _Reticula({required this.clave, required this.nombre, required this.url});
}

const _reticulas = [
  _Reticula(
    clave:  'IBQA-2010-207E',
    nombre: 'Retícula 2010',
    url:    'https://pub-f883231412d746839d3a41f6bc354031.r2.dev/IBQA/IBQA-2010-207E.pdf',
  ),
];

// ── Modelo de materia ─────────────────────────────────────────
class _Materia {
  final String nombre, url;
  const _Materia(this.nombre, this.url);
}

// ── Modelo de semestre ────────────────────────────────────────
// Sin flag soloInformativo: el 9no semestre mezcla una materia con
// PDF real ("Formulación y Evaluación de Proyectos") y tres sin URL.
// _MateriaItem detecta hasUrl y maneja ambos casos automáticamente.
class _Semestre {
  final int numero;
  final List<_Materia> materias;
  const _Semestre(this.numero, this.materias);
}

// URL base de los temarios para no repetirla en cada _Materia.
const _base = 'https://villahermosa.tecnm.mx/docs/oferta/ingbioquimica/temario2010';

final _semestres = [
  _Semestre(1, [
    _Materia('Fundamentos de Investigación',   '$_base/1semestre/FundamentosdeInvestigacion-AC006.pdf'),
    _Materia('Cálculo Diferencial',            '$_base/1semestre/CalculoDiferencial-AC001.pdf'),
    _Materia('Química',                        '$_base/1semestre/Quimica-AE057.pdf'),
    _Materia('Taller de Ética',                '$_base/1semestre/TallerdeEtica-AC007.pdf'),
    _Materia('Comportamiento Organizacional',  '$_base/1semestre/ComportamientoOrganizacional.pdf'),
    _Materia('Dibujo Asistido por Computadora','$_base/1semestre/DibujoAsistidoporComputadora-AE012.pdf'),
  ]),
  _Semestre(2, [
    _Materia('Administración y Legislación de Empresas', '$_base/2semestre/AdministracionyLegislacionEmpresas.pdf'),
    _Materia('Cálculo Integral',                         '$_base/2semestre/CalculoIntegral-AC002.pdf'),
    _Materia('Química Orgánica I',                       '$_base/2semestre/Qu%C3%ADmicaOrganica_I.pdf'),
    _Materia('Biología',                                 '$_base/2semestre/Biologia-AE005.pdf'),
    _Materia('Química Analítica',                        '$_base/2semestre/QuimicaAnalitica.pdf'),
    _Materia('Álgebra Lineal',                           '$_base/2semestre/AlgebraLineal-AC003.pdf'),
  ]),
  _Semestre(3, [
    _Materia('Cálculo Vectorial',       '$_base/3semestre/CalculoVectorial-AC004.pdf'),
    _Materia('Ecuaciones Diferenciales','$_base/3semestre/EcuacionesDiferenciales-AC005.pdf'),
    _Materia('Química Orgánica II',     '$_base/3semestre/QuimicaOrganica-II.pdf'),
    _Materia('Termodinámica',           '$_base/3semestre/Termodinamica-AE065.pdf'),
    _Materia('Física',                  '$_base/3semestre/Fisica.pdf'),
    _Materia('Estadística',             '$_base/3semestre/Estadistica.pdf'),
  ]),
  _Semestre(4, [
    _Materia('Programación y Métodos Numéricos', '$_base/4semestre/ProgramacionyMetodosNumericos.pdf'),
    _Materia('Electromagnetismo',                '$_base/4semestre/Electromagnetismo-AE020.pdf'),
    _Materia('Bioquímica',                       '$_base/4semestre/Bioquimica-AE007.pdf'),
    _Materia('Balance de Materia y Energía',     '$_base/4semestre/BalancedeMateriayEnergia-AE004.pdf'),
    _Materia('Análisis Instrumental',            '$_base/4semestre/AnalisisInstrumental.pdf'),
    _Materia('Aseguramiento de la Calidad',      '$_base/4semestre/AseguramientodelaCalidad.pdf'),
  ]),
  _Semestre(5, [
    _Materia('Ingeniería Económica',                          '$_base/5semestre/IngenieriaEconomica.pdf'),
    _Materia('Fenómenos de Transporte I',                     '$_base/5semestre/FenomenosdeTransporte-I.pdf'),
    _Materia('Bioquímica del Nitrógeno y Regulación Genética','$_base/5semestre/BioquimicadelNitrogenoyRegulacionGenetica.pdf'),
    _Materia('Fisicoquímica',                                 '$_base/5semestre/Fisicoquimica.pdf'),
    _Materia('Desarrollo Sustentable',                        '$_base/5semestre/DesarrolloSustentable-AC008.pdf'),
    _Materia('Instrumentación y Control',                     '$_base/5semestre/InstrumentacionyControl-AE039.pdf'),
  ]),
  _Semestre(6, [
    _Materia('Operaciones Unitarias I',   '$_base/6semestre/OperacionesUnitarias-I.pdf'),
    _Materia('Fenómenos de Transporte II','$_base/6semestre/FenomenosdeTransporte-II.pdf'),
    _Materia('Microbiología',             '$_base/6semestre/Microbiologia-AE050.pdf'),
    _Materia('Seguridad e Higiene',       '$_base/6semestre/SeguridadeHigiene.pdf'),
    _Materia('Cinética Química y Biológica','$_base/6semestre/Cineticaqumicaybiologica.pdf'),
    _Materia('Taller de Investigación I', '$_base/6semestre/TallerdeInvestigacion-I-AC009.pdf'),
  ]),
  _Semestre(7, [
    _Materia('Taller de Investigación II','$_base/7semestre/TallerdeInvestigacion-II-AC010.pdf'),
    _Materia('Operaciones Unitarias II',  '$_base/7semestre/OperacionesUnitarias-II.pdf'),
    _Materia('Operaciones Unitarias III', '$_base/7semestre/OperacionesUnitarias-III.pdf'),
    _Materia('Ingeniería de Biorreactores','$_base/7semestre/IngenieriadeBiorreactores.pdf'),
  ]),
  _Semestre(8, [
    _Materia('Ingeniería de Proyectos',       '$_base/8semestre/IngenieriadeProyectos.pdf'),
    _Materia('Ingeniería y Gestión Ambiental','$_base/8semestre/IngenieriayGestionAmbiental.pdf'),
    _Materia('Ingeniería de Procesos',        '$_base/8semestre/IngenieriadeProcesos.pdf'),
  ]),
  // 9no semestre: mezcla una materia con PDF real y tres sin URL.
  // _MateriaItem detecta hasUrl y maneja ambos casos automáticamente.
  _Semestre(9, [
    _Materia('Formulación y Evaluación de Proyectos','$_base/9semestre/FormulacionyEvaluaciondeProyectos-AE029.pdf'),
    _Materia('Residencia Profesional',               ''),
    _Materia('Servicio Social',                      ''),
    _Materia('Actividades Complementarias',          ''),
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
  const _Especialidad({
    required this.nombre,
    required this.icono,
    required this.color,
    required this.materias,
  });
}

// URL base de los temarios de especialidad de IBQA.
const _esp = 'https://villahermosa.tecnm.mx/docs/oferta/ingbioquimica/especialidad';

final _especialidades = [
  _Especialidad(
    nombre: 'Ciencias de los Alimentos (Plan IBQA-2010-207)',
    icono:  Icons.restaurant_rounded,
    color:  (cs) => cs.primary,
    materias: [
      _Materia('Análisis de Alimentos',              '$_esp/Analisisdealimentos.pdf'),
      _Materia('Biotecnología Alimentaria',           '$_esp/Biotecnologiaalimentaria.pdf'),
      _Materia('Desarrollo e Innovación de Productos','$_esp/Desarrolloeinnovaciondeproductos.pdf'),
      _Materia('Ingeniería de Alimentos',             '$_esp/IngenieriadeAlimentos.pdf'),
      _Materia('Química de Alimentos',                '$_esp/Quimicadealimentos.pdf'),
      _Materia('Tecnología de Alimentos',             '$_esp/TecnologiadeAlimentos.pdf'),
    ],
  ),
];


// ═════════════════════════════════════════════════════════════════
// WIDGETS PRIVADOS
// ═════════════════════════════════════════════════════════════════

/// Tile expandible que muestra las materias de un semestre.
/// El 9no semestre mezcla materias con y sin PDF; _MateriaItem
/// gestiona ambos casos con la verificación hasUrl.
class _SemestreExpansion extends StatelessWidget {
  final ColorScheme cs;
  final _Semestre semestre;
  const _SemestreExpansion({required this.cs, required this.semestre});

  // Ordinales en español para el título del tile.
  static const _ordinal = ['','1er','2do','3er','4to','5to','6to','7mo','8vo','9no'];

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
            tilePadding:     const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            backgroundColor:          cs.primary.withValues(alpha: 0.05),
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
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
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
            tilePadding:     const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            backgroundColor:          color.withValues(alpha: 0.05),
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
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
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
                size:  18,
                color: cs.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(materia.nombre,
                    style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.8))),
              ),
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
      Container(
        width: 4, height: 18,
        decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(2)),
      ),
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
          child: Center(
            child: Text('$numero',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cs.primary)),
          ),
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
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 6, height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(item,
                style: TextStyle(fontSize: 13, height: 1.6, color: cs.onSurface.withValues(alpha: 0.75))),
          ),
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
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
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