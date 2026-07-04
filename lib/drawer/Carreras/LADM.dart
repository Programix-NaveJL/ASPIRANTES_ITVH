// ═════════════════════════════════════════════════════════════════
// LADM.dart
//
// Pantalla informativa de la Licenciatura en Administración (LADM).
//
// Secciones:
//   • Objetivo General     — descripción del propósito de la carrera
//   • Objetivos Específicos — siete competencias numeradas
//   • Perfil de Ingreso    — características deseables del aspirante
//   • Perfil de Egreso     — competencias del profesional al egresar
//   • Campo Laboral        — sectores y ámbitos de inserción
//   • Retículas 2010       — tres especialidades con enlace a PDF
//   • Plan de Estudios     — ExpansionTile por semestre (1–9)
//   • Especialidades       — ExpansionTile por especialidad con materias
//
// Widgets privados de esta pantalla:
//   • _SemestreExpansion   — tile expandible de un semestre
//   • _EspecialidadExpansion — tile expandible de una especialidad
//   • _MateriaItem         — fila tappable que abre PdfViewerScreen
//   • _MateriaInfoItem     — fila solo de texto (sin PDF disponible)
//   • _SectionTitle        — título de sección con barra de acento verde
//   • _ObjetivoItem        — fila numerada con título y descripción
//   • _PerfilSection       — lista de bullets con punto de color
//   • _ReticulaItem        — card tappable que abre PdfViewerScreen
//
// Modelos de datos (privados):
//   • _Reticula            — clave, nombre y URL de una retícula
//   • _Materia             — nombre y URL de un temario en PDF
//   • _Semestre            — número, lista de materias y flag soloInformativo
//   • _Especialidad        — nombre, clave, ícono, color y materias
//
// Colores de acento:
//   • _verde       (#4CAF50) — color principal de la carrera
//   • _verdeOscuro (#2E7D32) — variante oscura para perfil de egreso
// ═════════════════════════════════════════════════════════════════

import 'package:aspirantes_itvh_app/drawer/Carreras/pdf_viewer_screen.dart';
import 'package:flutter/material.dart';


// ═════════════════════════════════════════════════════════════════
// PANTALLA PRINCIPAL
// ═════════════════════════════════════════════════════════════════

class LADMScreen extends StatelessWidget {
  const LADMScreen({super.key});

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
            pinned:          true,
            backgroundColor: cs.surface,
            title: Text(
              'Lic. en Administración',
              style: TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.bold,
                  color:      cs.onSurface),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Fondo con tinte verde muy suave.
                  Container(color: _verde.withValues(alpha: 0.12)),

                  // Ícono decorativo semitransparente en esquina superior derecha.
                  Positioned(
                    right: -30, top: -20,
                    child: Icon(Icons.account_balance_rounded,
                        size:  220,
                        color: _verde.withValues(alpha: 0.07)),
                  ),

                  // Chip del departamento al que pertenece la carrera.
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 56),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color:        _verde.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Departamento Económico Administrativo',
                          style: TextStyle(
                              fontSize:   11,
                              fontWeight: FontWeight.w600,
                              color:      _verde),
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
                        'Lic. en Administración',
                        style: TextStyle(
                            fontSize:   22,
                            fontWeight: FontWeight.bold,
                            color:      cs.onSurface),
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
                _SectionTitle(texto: 'Objetivo General'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:        _verde.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(16),
                    border:       Border.all(color: _verde.withValues(alpha: 0.15)),
                  ),
                  child: Text(
                    'Formar profesionales de la administración capaces de actuar como agentes de cambio, a través del diseño, innovación y dirección en organizaciones, sensibles a las demandas sociales y oportunidades del entorno, con capacidad de intervención en ámbitos globales y con un firme propósito de observar las normas y los valores universales.',
                    style: TextStyle(
                        fontSize: 14,
                        height:   1.65,
                        color:    cs.onSurface.withValues(alpha: 0.8)),
                  ),
                ),

                const SizedBox(height: 28),

                // Objetivos específicos
                _SectionTitle(texto: 'Objetivos Específicos'),
                const SizedBox(height: 12),
                ..._objetivos.map((obj) => _ObjetivoItem(
                    cs:          cs,
                    numero:      obj.$1,
                    titulo:      obj.$2,
                    descripcion: obj.$3)),

                const SizedBox(height: 28),

                // Perfil de ingreso
                _SectionTitle(texto: 'Perfil de Ingreso'),
                const SizedBox(height: 12),
                _PerfilSection(cs: cs, color: _verde, items: const [
                  'Capacidad de liderazgo.',
                  'Trabajo en equipo.',
                  'Toma de decisiones.',
                  'Adaptación al cambio.',
                  'Capacidad de expresión verbal y escritura.',
                  'Capacidad de adaptación al trabajo, ética y valores.',
                ]),

                const SizedBox(height: 28),

                // Perfil de egreso — usa _verdeOscuro para diferenciarlo
                // visualmente del perfil de ingreso.
                _SectionTitle(texto: 'Perfil de Egreso'),
                const SizedBox(height: 12),
                _PerfilSection(cs: cs, color: _verdeOscuro, items: const [
                  'Integrar los procesos gerenciales, de administración, de innovación y las estrategias de dirección para la competitividad y productividad de las organizaciones.',
                  'Aplicar los conocimientos modernos de la gestión de negocios a las fases del proceso administrativo para la optimización de recursos y el manejo de los cambios organizacionales.',
                  'Desarrollar las habilidades directivas y de vinculación basadas en la ética y la responsabilidad social, que le permitan integrar y coordinar equipos interdisciplinarios.',
                  'Crear y desarrollar proyectos sustentables aplicando herramientas administrativas y métodos de investigación de vanguardia, con un enfoque estratégico, multicultural y humanista.',
                  'Conducir la organización hacia la consecución de sus objetivos mediante un esfuerzo coordinado y espíritu emprendedor.',
                  'Crear organizaciones que contribuyan a la transformación económica y social, identificando las oportunidades de negocios en un contexto global.',
                  'Conocer y aplicar el marco legal vigente nacional e internacional de las organizaciones.',
                  'Analizar e interpretar información financiera y económica para la toma de decisiones en las organizaciones.',
                  'Ser un agente de cambio con la habilidad de potenciar el capital humano para la solución de los problemas y la toma de decisiones.',
                  'Implementar y administrar sistemas de gestión de calidad orientados a la mejora continua y productividad de la organización.',
                  'Aplicar las tecnologías de la información y comunicación para optimizar el trabajo y desarrollo de la organización.',
                  'Actualizar conocimientos permanentemente para responder a los cambios globales.',
                  'Diseñar sistemas de organización considerando alternativas estratégicas que generen cadenas productivas en beneficio de la sociedad.',
                  'Tener visión multidisciplinaria para generar propuestas y desarrollar acciones ante escenarios de contingencia.',
                  'Diseñar estrategias de mercadotecnia basadas en el análisis de la información interna y del entorno global.',
                ]),

                const SizedBox(height: 28),

                // Campo Laboral
                _SectionTitle(texto: 'Campo Laboral'),
                const SizedBox(height: 12),
                _PerfilSection(cs: cs, color: _verde, items: const [
                  'Sector público federal, estatal y municipal.',
                  'Sector privado industrial, comercial o de servicios.',
                  'Ejercicio en forma independiente de la profesión en consultorías o asesorías.',
                  'Instituciones educativas públicas o privadas, desempeñando funciones administrativas o docentes.',
                ]),

                const SizedBox(height: 28),

                // Retículas 2010
                _SectionTitle(texto: 'Retículas 2010'),
                const SizedBox(height: 12),
                ..._reticulas.map((r) => _ReticulaItem(cs: cs, reticula: r)),

                const SizedBox(height: 28),

                // Plan de Estudios — un ExpansionTile por semestre.
                _SectionTitle(texto: 'Plan de Estudios'),
                const SizedBox(height: 12),
                ..._semestres.map((sem) => _SemestreExpansion(
                    cs: cs, semestre: sem)),

                const SizedBox(height: 28),

                // Especialidades — un ExpansionTile por especialidad.
                _SectionTitle(texto: 'Especialidades'),
                const SizedBox(height: 12),
                ..._especialidades.map((esp) => _EspecialidadExpansion(
                    cs: cs, especialidad: esp)),

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
// COLORES DE ACENTO
// ═════════════════════════════════════════════════════════════════

// Constantes a nivel de archivo para que todos los widgets privados
// puedan usarlos sin recibirlos como parámetro.
const _verde       = Color(0xFF4CAF50);
const _verdeOscuro = Color(0xFF2E7D32);


// ═════════════════════════════════════════════════════════════════
// DATOS
// ═════════════════════════════════════════════════════════════════

// ── Objetivos específicos ─────────────────────────────────────
// Cada registro es una tupla (número, título corto, descripción).
const _objetivos = [
  (1, 'Resolver Problemas',  'Identifica y resuelve problemas aplicando estrategias de dirección para la competitividad y productividad de las organizaciones.'),
  (2, 'Saber Diseñar',       'Diseña estrategias mediante decisiones basadas en el análisis de la información interna y del entorno global que aseguren el éxito de la comercialización de productos y servicios.'),
  (3, 'Hacer Experimentos',  'Desarrolla proyectos sustentables aplicando herramientas administrativas y métodos de investigación.'),
  (4, 'Saber Comunicarse',   'Comunicarse efectivamente para conducir la organización hacia la consecución de sus objetivos mediante un esfuerzo coordinado y espíritu emprendedor.'),
  (5, 'Ser Ético',           'Reconoce sus responsabilidades éticas y profesionales en situaciones relevantes para la administración, considerando el impacto de las soluciones en los contextos global, económico, ambiental y social.'),
  (6, 'Actualizarse',        'Actualiza sus conocimientos permanentemente para responder a los cambios globales.'),
  (7, 'Trabajar en Equipo',  'Integrar y coordinar equipos interdisciplinarios para favorecer el crecimiento de la organización y su entorno global.'),
];

// ── Modelo de retícula ────────────────────────────────────────
class _Reticula {
  final String clave, nombre, url;
  const _Reticula({required this.clave, required this.nombre, required this.url});
}

const _reticulas = [
  _Reticula(
    clave:  'INTE-AFI-2018-01',
    nombre: 'Administración y Finanzas',
    url:    'https://villahermosa.tecnm.mx/docs/oferta/licadministracion/reticula/LAE_CON_ADMON_Y_FINANZAS_RETICULA.pdf',
  ),
  _Reticula(
    clave:  'LADE-PES-2017-01',
    nombre: 'Proyectos Empresariales Sustentables',
    url:    'https://villahermosa.tecnm.mx/docs/oferta/licadministracion/reticula/LAE_CON_PROYECTOS_EMPRESARIALES_RETICULA.pdf',
  ),
  _Reticula(
    clave:  'LADE-CHT-2023-02',
    nombre: 'Capital Humano y Transformación Digital',
    url:    'http://cc.villahermosa.tecnm.mx/sys/estpro/reticulas/LADM-2010-234--LADE-CHT-2023-02.pdf',
  ),
];

// ── Modelo de materia ─────────────────────────────────────────
class _Materia {
  final String nombre, url;
  const _Materia(this.nombre, this.url);
}

// ── Modelo de semestre ────────────────────────────────────────
// soloInformativo: true en el 9no semestre, donde no hay PDFs
// de temarios sino actividades institucionales (residencia, etc.).
class _Semestre {
  final int           numero;
  final List<_Materia> materias;
  final bool           soloInformativo;
  const _Semestre(this.numero, this.materias, {this.soloInformativo = false});
}

// URL base de los temarios para no repetirla en cada _Materia.
const _base = 'https://villahermosa.tecnm.mx/docs/oferta/licadministracion/temario2010';
const _esp  = 'https://villahermosa.tecnm.mx/docs/oferta/licadministracion/temario2010/Especialidad';

final _semestres = [
  _Semestre(1, [
    _Materia('Teoría General de la Administración',       '$_base/1semestre/LAC-1035TeoriaGeneraldelaAdministracion_OK_2016.pdf'),
    _Materia('Informática para la Administración',        '$_base/1semestre/LAV-1025InformaticaparalaAdministracion_OK_2016.pdf'),
    _Materia('Taller de Ética',                           '$_base/1semestre/TallerdeEtica-ACA-0907.pdf'),
    _Materia('Fundamentos de Investigación',              '$_base/1semestre/FundamentosdeInvestigacion-ACC-0906.pdf'),
    _Materia('Matemáticas Aplicadas a la Administración', '$_base/1semestre/LAD-1027MatematicasAplicadasalaAdministracion_OK_2016.pdf'),
    _Materia('Contabilidad General',                      '$_base/1semestre/LAD-1006ContabilidadGeneral_OK_2016.pdf'),
  ]),
  _Semestre(2, [
    _Materia('Función Administrativa I',                  '$_base/2semestre/LAF-1019FuncionAdministrativa%20I_OK_2016.pdf'),
    _Materia('Estadística para la Administración I',      '$_base/2semestre/LAD-1016EstadisticaparalaAdministraci%C3%B3n%20I_OK_2016.pdf'),
    _Materia('Derecho Laboral y Seguridad Social',        '$_base/2semestre/LAF-1010DerechoLaboralSeguridadSocial_OK_2016.pdf'),
    _Materia('Comunicación Corporativa',                  '$_base/2semestre/LAC-1004ComunicacionCorporativa_OK_2016.pdf'),
    _Materia('Taller de Desarrollo Humano',               '$_base/2semestre/LAC-1034TallerdeDesarrolloHumano_OK_2016.pdf'),
    _Materia('Costos de Manufactura',                     'https://villahermosa.tecnm.mx/site/oferta.jsp?view=Licenciaturaadministracion'),
  ]),
  _Semestre(3, [
    _Materia('Función Administrativa II',                 '$_base/3semestre/LAD-1020FuncionAdministrativaII_OK_2016.pdf'),
    _Materia('Estadística para la Administración II',     '$_base/3semestre/LAD-1017EstadisticaparalaadministracionII_OK_2016.pdf'),
    _Materia('Derecho Empresarial',                       '$_base/3semestre/LAD-1009DerechoEmpresarial_OK_2016.pdf'),
    _Materia('Comportamiento Organizacional',             '$_base/3semestre/LAD-1003ComportamientoOrganizacional_OK_2016.pdf'),
    _Materia('Dinámica Social',                           '$_base/3semestre/LAC-1013DinamicaSocial_OK_2016.pdf'),
    _Materia('Contabilidad Gerencial',                    '$_base/3semestre/LAD-1007ContabilidadGerencial_OK_2016.pdf'),
  ]),
  _Semestre(4, [
    _Materia('Gestión Estratégica del Capital Humano I',  '$_base/4semestre/LAD-1023GestionEstrategicadelCapitalHumanoI_OK_2016.pdf'),
    _Materia('Procesos Estructurales',                    '$_base/4semestre/LAD-1031ProcesosEstructurales_OK_2016.pdf'),
    _Materia('Métodos Cuantitativos para la Administración', '$_base/4semestre/LAD-1028MetodosCuantitativosparalaAdministracion_OK_2016.pdf'),
    _Materia('Fundamentos de Mercadotecnia',              '$_base/4semestre/LAF-1021FundamentosdeMercadotecnia_OK_2016.pdf'),
    _Materia('Economía Empresarial',                      '$_base/4semestre/LAD-1014EconomiaEmpresarial_OK_2016.pdf'),
    _Materia('Matemáticas Financieras',                   '$_base/4semestre/MatematicasFinancieras-AEC-1079.pdf'),
  ]),
  _Semestre(5, [
    _Materia('Gestión Estratégica del Capital Humano II', '$_base/5semestre/LAD-1024GestionEstrategicaCapitalHumanoII_OK_2016.pdf'),
    _Materia('Derecho Fiscal',                            '$_base/5semestre/DerechoFiscal-AEC-1070.pdf'),
    _Materia('Mezcla de Mercadotecnia',                   '$_base/5semestre/MezcladeMercadotecnia-AEC-1080.pdf'),
    _Materia('Macroeconomía',                             '$_base/5semestre/Macroeconomia-AEC-1077.pdf'),
    _Materia('Administración Financiera I',               '$_base/5semestre/AdministracionFinancieraI-AED-1068.pdf'),
    _Materia('Desarrollo Sustentable',                    '$_base/5semestre/DesarrolloSustentable-ACD-0908.pdf'),
  ]),
  _Semestre(6, [
    _Materia('Gestión de la Retribución',                 '$_base/6semestre/LAM-1022GestiondelaRetribucion_OK_2016.pdf'),
    _Materia('Producción',                                '$_base/6semestre/LAF-1032Produccion_OK_2016.pdf'),
    _Materia('Taller de Investigación I',                 '$_base/6semestre/TallerdeInvestigacionI-ACA-0909.pdf'),
    _Materia('Sistemas de Información de Mercadotecnia',  '$_base/6semestre/LAD-1033SistemasdeInformaciondeMercadotecnia_OK_2016.pdf'),
    _Materia('Innovación y Emprendedurismo',              '$_base/6semestre/LAA-1026InnovacionyEmprendedurismo_OK_2016.pdf'),
    _Materia('Administración Financiera II',              '$_base/6semestre/LAD-1002AdministracionFinancieraII_OK_2016.pdf'),
  ]),
  _Semestre(7, [
    _Materia('Plan de Negocios',                          '$_base/7semestre/LAB-1029PlandeNegocios_OK_2016.pdf'),
    _Materia('Procesos de Dirección',                     '$_base/7semestre/LAC-1030ProcesosdeDireccion_OK_2016.pdf'),
    _Materia('Taller de Investigación II',                '$_base/7semestre/TallerdeInvestigacionII-ACA-0910.pdf'),
    _Materia('Administración de la Calidad',              '$_base/7semestre/LAD-1001AdministraciondelaCalidad_OK_2016.pdf'),
    _Materia('Economía Internacional',                    '$_base/7semestre/LAC-1015EconomiaInternacional_OK_2016.pdf'),
    _Materia('Diagnóstico y Evaluación Empresarial',      '$_base/7semestre/LAD-1012DiagnosticoyEvaluacionEmpresarial_OK_2016.pdf'),
  ]),
  _Semestre(8, [
    _Materia('Consultoría Empresarial',                   '$_base/8semestre/LAC-1005ConsultoriaEmpresarial_OK_2016.pdf'),
    _Materia('Formulación y Evaluación de Proyectos',     '$_base/8semestre/LAD-1018FormulacionyEvaluaciondeProyectos_OK_2016.pdf'),
    _Materia('Desarrollo Organizacional',                 '$_base/8semestre/LAD-1011DesarrolloOrganizacional_OK_2016.pdf'),
  ]),
  // 9no semestre: actividades institucionales sin PDF de temario.
  _Semestre(9, [
    _Materia('Residencia Profesional', ''),
  ], soloInformativo: true),
];

// ── Modelo de especialidad ────────────────────────────────────
class _Especialidad {
  final String   nombre, clave;
  final IconData icono;
  final Color    color;
  final List<_Materia> materias;
  const _Especialidad({
    required this.nombre,
    required this.clave,
    required this.icono,
    required this.color,
    required this.materias,
  });
}

final _especialidades = [
  _Especialidad(
    nombre: 'Proyectos Empresariales Sustentables',
    clave:  'INTE-PES-2017-03',
    icono:  Icons.eco_rounded,
    color:  _verde,
    materias: [
      _Materia('Normas de Calidad y su Aplicación',          '$_esp/INTE-PES-2017-03/NormasdeCalidadysuAplicacion-PEF-1701.pdf'),
      _Materia('Estrategias Corporativas y Sustentabilidad', '$_esp/INTE-PES-2017-03/EstrategiasCorporativasySustentabilidad-PEF-1703.pdf'),
      _Materia('Comercio Exterior',                          '$_esp/INTE-PES-2017-03/ComercioExterior-PEF-1704.pdf'),
      _Materia('Marketing Ecológico',                        '$_esp/INTE-PES-2017-03/MarketingEcologico-PED-1705.pdf'),
      _Materia('Modelo de Negocios Sustentables',            '$_esp/INTE-PES-2017-03/ModelosdeNegociosSustentables-PED-1706.pdf'),
    ],
  ),
  _Especialidad(
    nombre: 'Administración y Finanzas',
    clave:  'INTE-AFI-2018-01',
    icono:  Icons.savings_rounded,
    color:  _verdeOscuro,
    materias: [
      _Materia('Mercados Financieros I',                     '$_esp/INTE-AFI-2018-01/MercadosFinancierosI-AFD-1801.pdf'),
      _Materia('Modelo de Negocios Sustentables',            '$_esp/INTE-AFI-2018-01/ModelodeNegociosSustentables-AFD-1802.pdf'),
      _Materia('Estrategias Corporativas y Sustentabilidad', '$_esp/INTE-AFI-2018-01/EstrategiasCorporativasySustentabilidad-AFF-1803.pdf'),
      _Materia('Comercio Exterior',                          '$_esp/INTE-AFI-2018-01/ComercioExterior-AFF-1804.pdf'),
      _Materia('Auditoría Interna',                          '$_esp/INTE-AFI-2018-01/AuditoriaInterna-AFD-1805.pdf'),
      _Materia('Mercados Financieros II',                    '$_esp/INTE-AFI-2018-01/MercadosFinancieros%20II-AFD-1806.pdf'),
    ],
  ),
  _Especialidad(
    nombre: 'Capital Humano y Transformación Digital',
    clave:  'LADE-CHT-2023-02',
    icono:  Icons.people_rounded,
    color:  const Color(0xFF1B5E20),
    materias: [
      _Materia('Productividad y Competitividad del Talento Humano',       '$_esp/INTE-CHT-2017-03/ProductividadyCompetitividaddelTalentoHumano-CHC-1701.pdf'),
      _Materia('Nuevas Herramientas como Apoyo a la Gestión del Talento', '$_esp/INTE-CHT-2017-03/NuevasHerramientascomoApoyoalaGestiondelTalentoHumano-CHH-1702.pdf'),
      _Materia('Capital Humano en la Era Digital',                        '$_esp/INTE-CHT-2017-03/CapitalHumanoenlaEraDigital-CHC-1703.pdf'),
      _Materia('Taller de Valoración de Empresas por Simulación',         '$_esp/INTE-CHT-2017-03/TallerdeValoraciondeEmpresasporsimulacion-CHC-1704.pdf'),
      _Materia('Seminario de Gestión del Talento Humano',                 '$_esp/INTE-CHT-2017-03/SeminariodeGestiondelTalentoHumano-CHB-1705.pdf'),
      _Materia('Nómina Electrónica',                                      '$_esp/INTE-CHT-2017-03/NominaelectronicaCHC1706.pdf'),
    ],
  ),
];


// ═════════════════════════════════════════════════════════════════
// WIDGETS PRIVADOS
// ═════════════════════════════════════════════════════════════════

/// Tile expandible que muestra las materias de un semestre.
/// Si [semestre.soloInformativo] es true, renderiza _MateriaInfoItem
/// en lugar de _MateriaItem para indicar que no hay PDF disponible.
class _SemestreExpansion extends StatelessWidget {
  final ColorScheme cs;
  final _Semestre   semestre;
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
            tilePadding:     const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            backgroundColor:          _verde.withValues(alpha: 0.05),
            collapsedBackgroundColor: _verde.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: _verde.withValues(alpha: 0.12)),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outline.withValues(alpha: 0.12)),
            ),
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: _verde.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('${semestre.numero}',
                    style: const TextStyle(
                        fontSize:   15,
                        fontWeight: FontWeight.bold,
                        color:      _verde)),
              ),
            ),
            title: Text('$ord Semestre',
                style: TextStyle(
                    fontSize:   14,
                    fontWeight: FontWeight.w600,
                    color:      cs.onSurface)),
            subtitle: Text(
              semestre.soloInformativo
                  ? '${semestre.materias.length} actividad'
                  : '${semestre.materias.length} materias',
              style: TextStyle(
                  fontSize: 11,
                  color:    cs.onSurface.withValues(alpha: 0.45)),
            ),
            children: semestre.soloInformativo
                ? semestre.materias
                .map((m) => _MateriaInfoItem(cs: cs, nombre: m.nombre))
                .toList()
                : semestre.materias
                .map((m) => _MateriaItem(cs: cs, materia: m))
                .toList(),
          ),
        ),
      ),
    );
  }
}

/// Tile expandible que muestra las materias de una especialidad.
class _EspecialidadExpansion extends StatelessWidget {
  final ColorScheme   cs;
  final _Especialidad especialidad;
  const _EspecialidadExpansion(
      {required this.cs, required this.especialidad});

  @override
  Widget build(BuildContext context) {
    final color = especialidad.color;
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
                color:        color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(especialidad.icono, color: color, size: 20),
            ),
            title: Text(especialidad.nombre,
                style: TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w600,
                    color:      cs.onSurface)),
            subtitle: Text(
              '${especialidad.materias.length} materias  ·  ${especialidad.clave}',
              style: TextStyle(
                  fontSize: 11,
                  color:    cs.onSurface.withValues(alpha: 0.45)),
            ),
            children: especialidad.materias
                .map((m) => _MateriaItem(cs: cs, materia: m))
                .toList(),
          ),
        ),
      ),
    );
  }
}

/// Fila tappable que navega a PdfViewerScreen con el temario de la materia.
/// Si la materia no tiene URL, se deshabilita el tap y cambia el ícono
/// a info para indicar que el PDF no está disponible.
class _MateriaItem extends StatelessWidget {
  final ColorScheme cs;
  final _Materia    materia;
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
            builder: (_) => PdfViewerScreen(
                titulo: materia.nombre, url: materia.url)))
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(children: [
            Icon(
              hasUrl
                  ? Icons.picture_as_pdf_rounded
                  : Icons.info_outline_rounded,
              size:  18,
              color: _verde.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(materia.nombre,
                  style: TextStyle(
                      fontSize: 13,
                      color:    cs.onSurface.withValues(alpha: 0.8))),
            ),
            if (hasUrl)
              Icon(Icons.chevron_right_rounded,
                  size:  18,
                  color: cs.onSurface.withValues(alpha: 0.25)),
          ]),
        ),
      ),
    );
  }
}

/// Fila de solo texto para el 9no semestre, donde las entradas
/// son actividades institucionales sin PDF de temario asociado.
class _MateriaInfoItem extends StatelessWidget {
  final ColorScheme cs;
  final String      nombre;
  const _MateriaInfoItem({required this.cs, required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(children: [
        Icon(Icons.info_outline_rounded,
            size:  18,
            color: _verde.withValues(alpha: 0.45)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(nombre,
              style: TextStyle(
                  fontSize: 13,
                  color:    cs.onSurface.withValues(alpha: 0.7))),
        ),
      ]),
    );
  }
}

/// Título de sección con barra vertical de acento verde de 4 × 18 px.
class _SectionTitle extends StatelessWidget {
  final String texto;
  const _SectionTitle({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 4, height: 18,
        decoration: BoxDecoration(
          color:        _verde,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 10),
      Text(texto,
          style: TextStyle(
              fontSize:   17,
              fontWeight: FontWeight.bold,
              color:      Theme.of(context).colorScheme.onSurface)),
    ]);
  }
}

/// Fila numerada con círculo de acento, título en negrita
/// y descripción en texto secundario.
class _ObjetivoItem extends StatelessWidget {
  final ColorScheme cs;
  final int         numero;
  final String      titulo, descripcion;
  const _ObjetivoItem({
    required this.cs,
    required this.numero,
    required this.titulo,
    required this.descripcion,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: _verde.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text('$numero',
                style: const TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.bold,
                    color:      _verde)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo,
                  style: TextStyle(
                      fontSize:   13,
                      fontWeight: FontWeight.bold,
                      color:      cs.onSurface)),
              const SizedBox(height: 3),
              Text(descripcion,
                  style: TextStyle(
                      fontSize: 13,
                      height:   1.55,
                      color:    cs.onSurface.withValues(alpha: 0.65))),
            ],
          ),
        ),
      ]),
    );
  }
}

/// Lista de bullets con un punto circular de color
/// seguido del texto del ítem.
class _PerfilSection extends StatelessWidget {
  final ColorScheme    cs;
  final Color          color;
  final List<String>   items;
  const _PerfilSection({
    required this.cs,
    required this.color,
    required this.items,
  });

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
                style: TextStyle(
                    fontSize: 13,
                    height:   1.6,
                    color:    cs.onSurface.withValues(alpha: 0.75))),
          ),
        ]),
      )).toList(),
    );
  }
}

/// Card tappable que abre PdfViewerScreen con la retícula correspondiente.
/// Muestra el nombre de la especialidad, la clave y un ícono de PDF.
class _ReticulaItem extends StatelessWidget {
  final ColorScheme cs;
  final _Reticula   reticula;
  const _ReticulaItem({required this.cs, required this.reticula});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color:        cs.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => PdfViewerScreen(
                titulo: reticula.nombre, url: reticula.url),
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
                  color:        _verde.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.grid_view_rounded,
                    color: _verde, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reticula.nombre,
                        style: TextStyle(
                            fontSize:   14,
                            fontWeight: FontWeight.w600,
                            color:      cs.onSurface)),
                    const SizedBox(height: 3),
                    Text(reticula.clave,
                        style: TextStyle(
                            fontSize:      11,
                            color:         cs.onSurface.withValues(alpha: 0.4),
                            letterSpacing: 0.2)),
                  ],
                ),
              ),
              Icon(Icons.picture_as_pdf_rounded,
                  color: _verde.withValues(alpha: 0.5), size: 20),
            ]),
          ),
        ),
      ),
    );
  }
}