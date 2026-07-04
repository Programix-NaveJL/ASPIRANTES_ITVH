// ═════════════════════════════════════════════════════════════════
// IAMB.dart
//
// Pantalla informativa de la Ingeniería Ambiental (IAMB).
//
// Secciones:
//   • Objetivo General     — descripción del propósito de la carrera
//   • Perfil de Ingreso    — características deseables del aspirante
//   • Perfil de Egreso     — competencias del profesional al egresar
//   • Campo Laboral        — sectores y ámbitos de inserción
//   • Aviso de cruce       — _AvisoCard: alerta ámbar sobre
//                            inconsistencias conocidas en el backend
//                            del portal institucional
//   • Retículas            — tres planes con enlace a PDF
//   • Plan de Estudios     — ExpansionTile por semestre (1–9)
//   • Especialidad         — ExpansionTile por especialidad con materias
//
// Widgets privados de esta pantalla:
//   • _SemestreExpansion   — tile expandible de un semestre
//   • _EspecialidadExpansion — tile expandible de una especialidad
//   • _MateriaItem         — fila tappable que abre PdfViewerScreen;
//                            si la URL está vacía deshabilita el tap
//                            y cambia el ícono a info
//   • _SectionTitle        — título de sección con barra de acento cs.primary
//   • _PerfilSection       — lista de bullets con punto de color
//   • _ReticulaItem        — card tappable que abre PdfViewerScreen
//   • _AvisoCard           — card ámbar que advierte sobre el cruce
//                            de datos en el backend del portal
//
// Modelos de datos (privados):
//   • _Reticula    — clave, nombre y URL de una retícula
//   • _Materia     — nombre y URL de un temario en PDF
//   • _Semestre    — número y lista de materias
//                    (sin flag soloInformativo: el 9no semestre
//                    reutiliza _MateriaItem con URL vacía)
//   • _Especialidad — nombre, ícono, función de color y materias
//
// Color de acento:
//   • cs.primary   — color principal de la carrera en toda la pantalla
//   • cs.secondary — acento del Perfil de Ingreso
//   • cs.tertiary  — acento del Perfil de Egreso
//
// Nota de implementación:
//   • A diferencia de LADM e IINF, IAMB no define un flag
//     soloInformativo en _Semestre. Las actividades del 9no semestre
//     (Residencia, Servicio Social, etc.) se modelan como _Materia con
//     url vacía y se renderizan con _MateriaItem, que detecta hasUrl
//     y deshabilita el tap automáticamente.
//   • _AvisoCard es exclusiva de esta pantalla; documenta un error
//     conocido del portal que muestra claves incorrectas en algunos
//     bloques de especialidad. Se coloca antes de las retículas para
//     que el usuario la vea antes de comparar materias.
// ═════════════════════════════════════════════════════════════════

import 'package:aspirantes_itvh_app/drawer/Carreras/pdf_viewer_screen.dart';
import 'package:flutter/material.dart';


// ═════════════════════════════════════════════════════════════════
// PANTALLA PRINCIPAL
// ═════════════════════════════════════════════════════════════════

class IAMBScreen extends StatelessWidget {
  const IAMBScreen({super.key});

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
                  // Fondo con tinte en cs.primary — color de acento de IAMB.
                  Container(color: cs.primary.withValues(alpha: 0.12)),

                  // Ícono decorativo semitransparente en esquina superior derecha.
                  Positioned(
                    right: -30, top: -20,
                    child: Icon(Icons.eco_rounded, size: 220, color: cs.primary.withValues(alpha: 0.07)),
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
                          'Departamento de Química, Bioquímica y Ambiental',
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
                        'Ingeniería Ambiental',
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

                // Objetivo General
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
                    'Formar profesionistas en Ingeniería Ambiental éticos, analíticos, críticos y creativos con las competencias para identificar, proponer y resolver problemas ambientales de manera multidisciplinaria, asegurando la protección, conservación y mejoramiento del ambiente, bajo un marco legal, buscando el desarrollo sustentable en beneficio de la vida en el planeta.',
                    style: TextStyle(fontSize: 14, height: 1.65, color: cs.onSurface.withValues(alpha: 0.8)),
                  ),
                ),

                const SizedBox(height: 28),

                // Perfil de ingreso — subtítulo en itálica indica que
                // es información orientativa, no un requisito formal.
                _SectionTitle(cs: cs, texto: 'Perfil de Ingreso'),
                const SizedBox(height: 4),
                Text(
                  'Información sobre el perfil de ingreso deseable.',
                  style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.45), fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 12),
                // cs.secondary diferencia visualmente ingreso de egreso.
                _PerfilSection(cs: cs, color: cs.secondary, items: const [
                  'Dominio de habilidades básicas como la comprensión de textos.',
                  'El trabajo en equipo.',
                  'Interés sobre el tema de relevancia.',
                  'Iniciativa, capacidad de gestión, de comunicación y creatividad.',
                  'Interés por la investigación de las causas que deterioran el ambiente y respeto a la naturaleza.',
                  'Inclinación por el conocimiento científico-tecnológico e interés en las ciencias básicas y naturales, y en sus aplicaciones para la solución de problemas.',
                ]),

                const SizedBox(height: 28),

                // Perfil de egreso — usa cs.tertiary como tercer acento,
                // distinto al ingreso (secondary) y al principal (primary).
                _SectionTitle(cs: cs, texto: 'Perfil de Egreso'),
                const SizedBox(height: 4),
                Text(
                  'Información del perfil que tendrán los egresados y egresadas al concluir.',
                  style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.45), fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 12),
                _PerfilSection(cs: cs, color: cs.tertiary, items: const [
                  'Vincula el valor de los recursos naturales para promover su uso sustentable de acuerdo a las necesidades de la región, mediante instrumentos de concientización, sensibilización y comunicación.',
                  'Participa en el desarrollo y ejecución de protocolos de investigación básica o aplicada para la resolución de problemas ambientales.',
                  'Elabora, implementa y mantiene sistemas de gestión ambiental.',
                  'Participa en la realización de auditorías ambientales en el sector público y privado.',
                  'Realiza diagnósticos y evaluaciones de impacto y riesgo ambiental sustentados en métodos y procedimientos certificados conforme a criterios nacionales e internacionales.',
                  'Elabora estudios de factibilidad económica y técnica de los procesos para la prevención y control ambiental.',
                  'Propone e innova tecnologías para el manejo de los residuos cumpliendo la legislación ambiental vigente.',
                  'Conoce y aplica criterios de ingeniería básica y aplicada, así como de las ciencias biológicas, para el dimensionamiento, adecuación, operación, mantenimiento y desarrollo de tecnologías de tratamiento, prevención, control y transformación de efluentes sólidos, líquidos y gaseosos contaminados.',
                  "Conoce y aplica las TIC's, así como sistemas computacionales o software especializados en el área ambiental.",
                  'Es analítico, ético, crítico y consciente de la importancia de su entorno para la vida, respetuoso de la misma y promotor del desarrollo sustentable.',
                  'Es capaz de formar recursos humanos, realizar actividades de docencia, investigación y capacitación.',
                  'Tiene una actitud emprendedora y de liderazgo para interactuar con grupos multidisciplinarios e interdisciplinarios en la búsqueda de soluciones a los problemas de deterioro del medio ambiente.',
                ]),

                const SizedBox(height: 28),

                // Campo Laboral — vuelve a cs.primary para cerrar el ciclo
                // de acentos y unificarlo con el color de la carrera.
                _SectionTitle(cs: cs, texto: 'Campo Laboral'),
                const SizedBox(height: 4),
                Text(
                  'Descripción de las posibles opciones laborales al egresar.',
                  style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.45), fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 12),
                _PerfilSection(cs: cs, color: cs.primary, items: const [
                  'Dependencias del gobierno en los ámbitos federal, estatal y municipal; organismos públicos desconcentrados y/o descentralizados.',
                  'Empresas del sector industrial en general, y de los ramos minero-metalúrgico, energético, de obras y proyectos civiles.',
                  'Instituciones educativas de nivel medio o superior, así como de investigación, tanto públicas como privadas.',
                  'Profesional independiente que realiza capacitación para empresas, estudios de impacto ambiental, de riesgo, auditorías ambientales, propuesta de innovaciones tecnológicas, etc.',
                  'Organizaciones no gubernamentales encaminadas a la promoción de cultura ambiental limpia.',
                ]),

                const SizedBox(height: 28),

                // Aviso sobre cruce de datos en el backend del portal.
                // Se ubica antes de las retículas para que el usuario
                // lo vea antes de comparar materias con su plan oficial.
                _AvisoCard(cs: cs),

                const SizedBox(height: 28),

                // Retículas — incluye Plan 2004, Plan 2010 y la
                // especialidad Gestión Integral de Residuos (2023).
                _SectionTitle(cs: cs, texto: 'Retículas'),
                const SizedBox(height: 12),
                ..._reticulas.map((r) => _ReticulaItem(cs: cs, reticula: r)),

                const SizedBox(height: 28),

                // Plan de Estudios — un ExpansionTile por semestre.
                _SectionTitle(cs: cs, texto: 'Plan de Estudios'),
                const SizedBox(height: 12),
                ..._semestres.map((sem) => _SemestreExpansion(cs: cs, semestre: sem)),

                const SizedBox(height: 20),

                // Especialidad — un ExpansionTile por especialidad.
                _SectionTitle(cs: cs, texto: 'Especialidad'),
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

// ── Modelo de retícula ────────────────────────────────────────
class _Reticula {
  final String clave, nombre, url;
  const _Reticula({required this.clave, required this.nombre, required this.url});
}

const _reticulas = [
  _Reticula(clave: 'IAMB-2004-286', nombre: 'Plan 2004',
      url: 'https://pub-f883231412d746839d3a41f6bc354031.r2.dev/IAMB/IAMB-2004-286.pdf'),
  _Reticula(clave: 'IAMB-2010-206', nombre: 'Plan 2010',
      url: 'https://pub-f883231412d746839d3a41f6bc354031.r2.dev/IAMB/IAMB_2010_206.pdf'),
  _Reticula(clave: 'IAMB-2010-206--IAME-GIR-2023-01', nombre: 'Gestión Integral de Residuos',
      url: 'http://cc.villahermosa.tecnm.mx/sys/estpro/reticulas/IAMB-2010-206--IAME-GIR-2023-01.pdf'),
];

// ── Modelo de materia ─────────────────────────────────────────
class _Materia {
  final String nombre, url;
  const _Materia(this.nombre, this.url);
}

// ── Modelo de semestre ────────────────────────────────────────
// No incluye soloInformativo: las actividades del 9no semestre
// se modelan como _Materia con url vacía y _MateriaItem detecta
// hasUrl para deshabilitar el tap automáticamente.
class _Semestre {
  final int numero;
  final List<_Materia> materias;
  const _Semestre(this.numero, this.materias);
}

// URL base de los temarios para no repetirla en cada _Materia.
const _base = 'https://villahermosa.tecnm.mx/docs/oferta/ingambiental/temario2010';
const _esp  = 'https://villahermosa.tecnm.mx/docs/oferta/ingambiental/especialidad';

final _semestres = [
  _Semestre(1, [
    _Materia('Química Inorgánica',            '$_base/1semestre/QuimicaInorganica-AE060.pdf'),
    _Materia('Cálculo Diferencial',            '$_base/1semestre/CalculoDiferencial-AC001.pdf'),
    _Materia('Dibujo Asistido por Computadora','$_base/1semestre/DibujoAsistidoporComputadora.pdf'),
    _Materia('Taller de Ética',                '$_base/1semestre/TallerdeEtica-AC007.pdf'),
    _Materia('Fundamentos de Investigación',   '$_base/1semestre/FundamentosdeInvestigacion-AC006.pdf'),
    _Materia('Biología',                       '$_base/1semestre/Biologia-AE005.pdf'),
  ]),
  _Semestre(2, [
    _Materia('Fundamentos de Química Orgánica',     '$_base/2semestre/FundamentosdeQuimicaOrganica-AE033.pdf'),
    _Materia('Álgebra Lineal',                      '$_base/2semestre/AlgebraLineal-AC003.pdf'),
    _Materia('Física',                              '$_base/2semestre/Fisica.pdf'),
    _Materia('Probabilidad y Estadística Ambiental','$_base/2semestre/ProbabilidadyEstadisticaAmbiental.pdf'),
    _Materia('Cálculo Integral',                    '$_base/2semestre/CalculoIntegral-AC002.pdf'),
    _Materia('Ecología',                            '$_base/2semestre/Ecologia.pdf'),
  ]),
  _Semestre(3, [
    _Materia('Química Analítica',              '$_base/3semestre/QuimicaAnalitica-AE059.pdf'),
    _Materia('Cálculo Vectorial',              '$_base/3semestre/CalculoVectorial-AC004.pdf'),
    _Materia('Diseño de Experimentos Ambientales','$_base/3semestre/DisenodeExperimentosAmbientales.pdf'),
    _Materia('Termodinámica',                  '$_base/3semestre/Termodinamica-AE065.pdf'),
    _Materia('Economía Ambiental',             '$_base/3semestre/EconomiaAmbiental.pdf'),
    _Materia('Bioquímica',                     '$_base/3semestre/Bioquimica-AE007.pdf'),
  ]),
  _Semestre(4, [
    _Materia('Análisis Instrumental',          '$_base/4semestre/AnalisisInstrumental.pdf'),
    _Materia('Ecuaciones Diferenciales',       '$_base/4semestre/EcuacionesDiferenciales-AC005.pdf'),
    _Materia('Balance de Materia y Energía',   '$_base/4semestre/BalanceDeMateriaYEnergia-AE004.pdf'),
    _Materia('Desarrollo Sustentable',         '$_base/4semestre/DesarrolloSustentable-AC008.pdf'),
    _Materia('Fisicoquímica I',                '$_base/4semestre/Fisicoqu%C3%ADmicaI.pdf'),
    _Materia('Microbiología',                  '$_base/4semestre/Microbiologia-AE050.pdf'),
  ]),
  _Semestre(5, [
    _Materia('Fenómenos de Transporte',                '$_base/5semestre/FenomenoDeTransporte-AE027.pdf'),
    _Materia('Sistemas de Información Geográfica',     '$_base/5semestre/SistemasDeInformacionGeografica.pdf'),
    _Materia('Gestión Ambiental I',                    '$_base/5semestre/GestionAmbiental_I.pdf'),
    _Materia('Mecánica de Fluidos',                    '$_base/5semestre/Mec%C3%A1nicaDeFluidos.pdf'),
    _Materia('Fisicoquímica II',                       '$_base/5semestre/Fisicoqu%C3%ADmica_II.pdf'),
    _Materia('Toxicología Ambiental',                  '$_base/5semestre/ToxicologiaAmbiental.pdf'),
  ]),
  _Semestre(6, [
    _Materia('Taller de Investigación I',      '$_base/6semestre/TallerDeInvestigacion-I-AC009.pdf'),
    _Materia('Contaminación Atmosférica',      '$_base/6semestre/ContaminacionAtmosferica.pdf'),
    _Materia('Gestión Ambiental II',           '$_base/6semestre/GestionAmbiental_II.pdf'),
    _Materia('Ingeniería de Costos',           '$_base/6semestre/IngenieriaDeCostos.pdf'),
    _Materia('Gestión de Residuos',            '$_base/6semestre/GestionDeResiduos.pdf'),
    _Materia('Componentes de Equipo Industrial','$_base/6semestre/ComponentesdeEquipoIndustrial.pdf'),
  ]),
  _Semestre(7, [
    _Materia('Taller de Investigación II',     '$_base/7semestre/TallerDeInvestigacion-II-AC010.pdf'),
    _Materia('Potabilización de Agua',         '$_base/7semestre/PotabilizacionDeAgua.pdf'),
    _Materia('Evaluación de Impacto Ambiental','$_base/7semestre/EvaluacionDeImpactoAmbiental.pdf'),
    _Materia('Remediación de Suelos',          '$_base/7semestre/RemediacionDeSuelos.pdf'),
  ]),
  _Semestre(8, [
    _Materia('Seguridad e Higiene Industrial',       '$_base/8semestre/SeguridadeHigieneIndustrial.pdf'),
    _Materia('Fundamentos de Aguas Residuales',      '$_base/8semestre/FundamentosdeAguasResiduales.pdf'),
    _Materia('Formulación y Evaluación de Proyectos','$_base/8semestre/AE029FormulacionyEvaluaciondeProyectos.pdf'),
  ]),
  // 9no semestre: actividades institucionales sin PDF de temario.
  // url vacía → _MateriaItem detecta hasUrl = false y desactiva el tap.
  _Semestre(9, [
    _Materia('Especialidad',             ''),
    _Materia('Residencia Profesional',   ''),
    _Materia('Servicio Social',          ''),
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
    nombre: 'Manejo y Gestión de Residuos',
    icono: Icons.delete_outline_rounded,
    color: (cs) => cs.primary,
    materias: [
      _Materia('Manejo de Residuos de Manejo Especial', '$_esp/ManejodeResiduosdeManejoEspecial.pdf'),
      _Materia('Manejo de Residuos Sólidos Urbanos I',  '$_esp/ManejodeResiduosSolidosUrbanosI.pdf'),
      _Materia('Manejo de Residuos Sólidos Urbanos II', '$_esp/ManejodeResiduosSolidosUrbanosII.pdf'),
      _Materia('Manejo de Residuos Peligrosos',         '$_esp/ManejodeResiduosPeligrosos.pdf'),
      _Materia('Minimización y Valoración de RSU',      '$_esp/MinimizacionyValoraciondeRSU.pdf'),
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

/// Card ámbar que alerta sobre el cruce de datos conocido en el
/// backend del portal institucional. Recuerda al usuario que el
/// PDF oficial de la retícula sellada es el único documento válido.
class _AvisoCard extends StatelessWidget {
  final ColorScheme cs;
  const _AvisoCard({required this.cs});

  @override
  Widget build(BuildContext context) {
    // Color fijo ámbar; no pertenece al ColorScheme de la carrera.
    const aviso = Color(0xFFFFA000);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: aviso.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: aviso.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.search_rounded, color: aviso, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Las materias no coinciden con tu retícula?',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cs.onSurface),
                ),
                const SizedBox(height: 6),
                Text(
                  'Existe un cruce de datos en el backend del portal que muestra claves o nombres de asignaturas incorrectos en los bloques de especialidad de algunas carreras.',
                  style: TextStyle(fontSize: 12.5, height: 1.5, color: cs.onSurface.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 6),
                Text(
                  'Nota: Los PDF oficiales de las retículas selladas son el único documento válido para tu plan de estudios actual.',
                  style: TextStyle(fontSize: 12.5, height: 1.5, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}