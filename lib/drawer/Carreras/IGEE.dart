// ═════════════════════════════════════════════════════════════════
// IGEE.dart
//
// Pantalla informativa de la Ingeniería en Gestión Empresarial (IGEE).
//
// Secciones:
//   • Objetivo General     — descripción completa del propósito
//   • Objetivos Específicos — siete competencias numeradas
//   • Perfil de Ingreso    — características deseables del aspirante
//   • Perfil de Egreso     — competencias del profesional al egresar
//   • Campo Laboral        — lista de empresas/organizaciones de ejemplo
//   • Retículas 2009       — tres planes con enlace a PDF
//   • Plan de Estudios     — ExpansionTile por semestre (1–9)
//   • Especialidades       — tres ExpansionTile, uno por especialidad
//
// Widgets privados de esta pantalla:
//   • _SemestreExpansion     — tile expandible de un semestre;
//                              usa cs.secondary como color de acento
//                              (color principal de IGEE en toda la pantalla)
//   • _EspecialidadExpansion — tile expandible de una especialidad;
//                              el color se resuelve en build desde la
//                              función almacenada en _Especialidad
//   • _MateriaItem           — fila tappable que abre PdfViewerScreen;
//                              si la URL está vacía deshabilita el tap
//                              y cambia el ícono a info
//   • _SectionTitle          — título de sección con barra de acento cs.secondary
//   • _ObjetivoItem          — fila numerada con título y descripción;
//                              usa cs.secondary coherente con la pantalla
//   • _PerfilSection         — lista de bullets con punto de color
//   • _ReticulaItem          — card tappable que abre PdfViewerScreen;
//                              usa cs.secondary como color de acento
//
// Modelos de datos (privados):
//   • _Reticula    — clave, nombre y URL de una retícula
//   • _Materia     — nombre y URL de un temario en PDF
//   • _Semestre    — número y lista de materias
//                    (el 9no semestre usa url vacía; _MateriaItem
//                    desactiva el tap automáticamente)
//   • _Especialidad — nombre, ícono, función de color y materias
//
// Color de acento:
//   • cs.secondary — color principal de IGEE en toda la pantalla:
//                    SliverAppBar, semestres, sección title, retícula,
//                    _ObjetivoItem y Perfil de Ingreso
//   • cs.primary   — acento del Perfil de Egreso
//   • cs.tertiary  — acento del Campo Laboral y especialidad "Capital Humano"
//
// Nota de implementación:
//   • IGEE es la única carrera de este conjunto que usa cs.secondary
//     (en lugar de cs.primary) como color dominante en toda la pantalla.
//     Esto se refleja en el SliverAppBar, los tiles de semestre, el
//     _SectionTitle y el _ReticulaItem, que en otras carreras usan primary.
//   • _MateriaItem de IGEE no acepta parámetro [color] opcional (a diferencia
//     de IIND). El ícono de PDF siempre usa cs.secondary, que es el color
//     dominante de la pantalla, incluso dentro de las especialidades.
//   • El Campo Laboral lista ejemplos de empresas/organizaciones concretas
//     (Avar Corporation, Pemex, Secretaría de Gobierno) en lugar de sectores
//     genéricos como en IIND, por eso se renderiza con _PerfilSection y
//     cs.tertiary en lugar de _CampoLaboralSection con chips.
// ═════════════════════════════════════════════════════════════════

import 'package:aspirantes_itvh_app/drawer/Carreras/pdf_viewer_screen.dart';
import 'package:flutter/material.dart';


// ═════════════════════════════════════════════════════════════════
// PANTALLA PRINCIPAL
// ═════════════════════════════════════════════════════════════════

class IGEEScreen extends StatelessWidget {
  const IGEEScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [

          // SliverAppBar expandible: colapsa al hacer scroll y
          // muestra solo el título fijo en la barra superior.
          // IGEE usa cs.secondary como color de acento, no cs.primary.
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
                  // Fondo con tinte en cs.secondary — color de acento de IGEE.
                  Container(color: cs.secondary.withValues(alpha: 0.12)),

                  // Ícono decorativo semitransparente en esquina superior derecha.
                  Positioned(
                    right: -30, top: -20,
                    child: Icon(Icons.business_center_rounded, size: 220, color: cs.secondary.withValues(alpha: 0.07)),
                  ),

                  // Chip del departamento al que pertenece la carrera.
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 56),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Departamento Económico Administrativo',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.secondary),
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
                        'Ing. en Gestión Empresarial',
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

                // Objetivo General completo.
                // IGEE no muestra cards de Misión/Visión al inicio;
                // va directo al objetivo general.
                _SectionTitle(cs: cs, texto: 'Objetivo General'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.secondary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.secondary.withValues(alpha: 0.15)),
                  ),
                  child: Text(
                    'Formar profesionales que contribuyan a la gestión de empresas e innovación de procesos; así como al diseño, implementación y desarrollo de sistemas estratégicos de negocios, optimizando recursos en un entorno global, con ética y responsabilidad social.',
                    style: TextStyle(fontSize: 14, height: 1.65, color: cs.onSurface.withValues(alpha: 0.8)),
                  ),
                ),

                const SizedBox(height: 28),

                // Objetivos específicos — siete competencias numeradas.
                _SectionTitle(cs: cs, texto: 'Objetivos Específicos'),
                const SizedBox(height: 12),
                ..._objetivos.map((obj) => _ObjetivoItem(cs: cs, numero: obj.$1, titulo: obj.$2, descripcion: obj.$3)),

                const SizedBox(height: 28),

                // Perfil de ingreso — usa cs.secondary coherente con
                // el color dominante de la pantalla.
                _SectionTitle(cs: cs, texto: 'Perfil de Ingreso'),
                const SizedBox(height: 12),
                _PerfilSection(cs: cs, color: cs.secondary, items: const [
                  'Capacidad de razonamiento.',
                  'Sentido de la organización y el método.',
                  'Planificador.',
                ]),

                const SizedBox(height: 28),

                // Perfil de egreso — cs.primary para distinguirlo
                // del ingreso (secondary) y del campo laboral (tertiary).
                _SectionTitle(cs: cs, texto: 'Perfil de Egreso'),
                const SizedBox(height: 12),
                _PerfilSection(cs: cs, color: cs.primary, items: const [
                  'Aplica habilidades directivas y de ingeniería en el diseño, gestión, fortalecimiento e innovación de las organizaciones para la toma de decisiones en forma efectiva, con una orientación sistémica y sustentable.',
                  'Diseña e innova estructuras administrativas y procesos, con base en las necesidades de las organizaciones para competir eficientemente en mercados globales.',
                  'Gestiona eficientemente los recursos de la organización con visión compartida, con el fin de suministrar bienes y servicios de calidad.',
                  'Aplica métodos cuantitativos y cualitativos en el análisis e interpretación de datos y modelado de sistemas en los procesos organizacionales, para la mejora continua atendiendo estándares de calidad mundial.',
                  'Diseña, y emprende nuevos negocios y proyectos empresariales sustentables en mercados competitivos, para promover el desarrollo.',
                  'Diseña e implementa estrategias de mercadotecnia basadas en información recopilada de fuentes primarias y secundarias, para incrementar la competitividad de las organizaciones.',
                  'Implementa planes y programas de seguridad e higiene para el fortalecimiento del entorno laboral.',
                  'Gestiona sistemas integrales de calidad para la mejora de los procesos, ejerciendo un liderazgo estratégico y un compromiso ético.',
                  'Aplica las normas legales para la creación y desarrollo de las organizaciones.',
                  'Dirige equipos de trabajo para la mejora continua y el crecimiento integral de las organizaciones.',
                  'Interpreta la información financiera para detectar oportunidades de mejora e inversión en un mundo global, que propicien la rentabilidad del negocio.',
                  'Utiliza las nuevas tecnologías de información y comunicación en la organización, para optimizar los procesos y la eficaz toma de decisiones.',
                  'Promueve el desarrollo del capital humano, para la realización de los objetivos organizacionales, dentro de un marco ético y un contexto multicultural.',
                  'Aplica métodos de investigación para desarrollar e innovar modelos, sistemas, procesos y productos en las diferentes dimensiones de la organización.',
                  'Gestiona la cadena de suministro de las organizaciones con un enfoque orientado a procesos para incrementar la productividad.',
                  'Analiza las variables económicas para facilitar la toma estratégica de decisiones en la organización.',
                  'Actúa como agente de cambio para facilitar la mejora continua y el desempeño de las organizaciones.',
                  'Aplica métodos, técnicas y herramientas para la solución de problemas en la gestión empresarial con una visión estratégica.',
                ]),

                const SizedBox(height: 28),

                // Campo Laboral — lista de ejemplos concretos de empleadores.
                // Se usa _PerfilSection con cs.tertiary en lugar de chips
                // porque los ítems son nombres específicos, no sectores genéricos.
                _SectionTitle(cs: cs, texto: 'Campo Laboral'),
                const SizedBox(height: 12),
                _PerfilSection(cs: cs, color: cs.tertiary, items: const [
                  'Avar Corporation.',
                  'Pemex.',
                  'Secretaría de Gobierno.',
                ]),

                const SizedBox(height: 28),

                // Retículas — tres planes disponibles para IGEE.
                _SectionTitle(cs: cs, texto: 'Retículas 2009'),
                const SizedBox(height: 12),
                ..._reticulas.map((r) => _ReticulaItem(cs: cs, reticula: r)),

                const SizedBox(height: 28),

                // Plan de Estudios — un ExpansionTile por semestre.
                _SectionTitle(cs: cs, texto: 'Plan de Estudios'),
                const SizedBox(height: 12),
                ..._semestres.map((sem) => _SemestreExpansion(cs: cs, semestre: sem)),

                const SizedBox(height: 28),

                // Especialidades — un ExpansionTile por especialidad.
                // Cada una tiene su propio color via función en _Especialidad.
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
  (1, 'Resolver Problemas',   'Aplica métodos, técnicas y herramientas para la solución de problemas en la gestión empresarial con una visión estratégica.'),
  (2, 'Saber Diseñar',        'Aplica habilidades directivas y de ingeniería en el diseño, gestión, fortalecimiento e innovación de las organizaciones para la toma de decisiones en forma efectiva, con una orientación sistémica y sustentable.'),
  (3, 'Hacer Experimentos',   'Aplica métodos de investigación para desarrollar e innovar modelos, sistemas, procesos y productos en las diferentes dimensiones de la organización.'),
  (4, 'Saber Comunicarse',    'Utiliza las nuevas tecnologías de información y comunicación en la organización, para optimizar los procesos y la eficaz toma de decisiones.'),
  (5, 'Ser Ético',            'Promueve el desarrollo del capital humano, para la realización de los objetivos organizacionales, dentro de un marco ético y un contexto multicultural.'),
  (6, 'Actualizarse',         'Actualiza sus conocimientos permanentemente para responder a los cambios globales.'),
  (7, 'Trabajar en Equipo',   'Dirige equipos de trabajo para la mejora continua y el crecimiento integral de las organizaciones.'),
];

// ── Modelo de retícula ────────────────────────────────────────
class _Reticula {
  final String clave, nombre, url;
  const _Reticula({required this.clave, required this.nombre, required this.url});
}

const _reticulas = [
  _Reticula(
    clave: 'IGEE-PES-2017-01',
    nombre: 'Proyectos Empresariales Sustentables',
    url: 'https://pub-f883231412d746839d3a41f6bc354031.r2.dev/IGEE/IGEE_CON_PROYECTOS_EMPRESARIALES_RETICULA.pdf',
  ),
  _Reticula(
    clave: 'INTE-AFI-2018-01',
    nombre: 'Administración y Finanzas',
    url: 'https://pub-f883231412d746839d3a41f6bc354031.r2.dev/IGEE/IGEE_CON_%20ADMON_Y_FINANZAS_RETICULA.pdf',
  ),
  _Reticula(
    clave: 'IGEE-CHT-2017-01',
    nombre: 'Capital Humano y Tic\'s',
    url: 'http://cc.villahermosa.tecnm.mx/sys/estpro/reticulas/IGEM-2009-201--IGEE-CHT-2023-02.pdf',
  ),
];

// ── Modelo de materia ─────────────────────────────────────────
class _Materia {
  final String nombre, url;
  const _Materia(this.nombre, this.url);
}

// ── Modelo de semestre ────────────────────────────────────────
// Sin flag soloInformativo: el 9no semestre usa url vacía y
// _MateriaItem desactiva el tap automáticamente.
class _Semestre {
  final int numero;
  final List<_Materia> materias;
  const _Semestre(this.numero, this.materias);
}

// URL base de los temarios para no repetirla en cada _Materia.
const _base = 'https://villahermosa.tecnm.mx/docs/oferta/inggestion/temario2009';

final _semestres = [
  _Semestre(1, [
    _Materia('Fundamentos de Investigación',       '$_base/1semestre/FundamentosdeInvestigacion-ACC-0906.pdf'),
    _Materia('Cálculo Diferencial',                '$_base/1semestre/CalculoDiferencial-ACF-0901.pdf'),
    _Materia('Desarrollo Humano',                  '$_base/1semestre/DesarrolloHumano.pdf'),
    _Materia('Fundamentos de Gestión Empresarial', '$_base/1semestre/FundamentosdeGestionEmpresarial-AEF-1074.pdf'),
    _Materia('Fundamentos de Física',              '$_base/1semestre/FundamentosdeFisica.pdf'),
    _Materia('Fundamentos de Química',             '$_base/1semestre/FundamentosdeQuimica.pdf'),
  ]),
  _Semestre(2, [
    _Materia('Software de Aplicación Ejecutivo',       '$_base/2semestre/SoftwaredeAplicacionEjecutivo-AEB-1082.pdf'),
    _Materia('Cálculo Integral',                       '$_base/2semestre/CalculoIntegral-ACF-0902.pdf'),
    _Materia('Contabilidad Orientada a los Negocios',  '$_base/2semestre/ContabilidadorientadaalosNegocios.pdf'),
    _Materia('Dinámica Social',                        '$_base/2semestre/DinamicaSocial-AEC-1014.pdf'),
    _Materia('Taller de Ética',                        '$_base/2semestre/TallerdeEtica-ACA-0907.pdf'),
    _Materia('Legislación Laboral',                    '$_base/2semestre/LegislacionLaboral.pdf'),
  ]),
  _Semestre(3, [
    _Materia('Marco Legal de las Organizaciones',       '$_base/3semestre/MarcoLegaldelasOrganizaciones-AE078.pdf'),
    _Materia('Probabilidad y Estadística Descriptiva',  '$_base/3semestre/ProbabilidadyEstadisticaDescriptiva.pdf'),
    _Materia('Costos Empresariales',                    '$_base/3semestre/CostosEmpresariales.pdf'),
    _Materia('Habilidades Directivas I',                '$_base/3semestre/HabilidadesDirectivas-I.pdf'),
    _Materia('Economía Empresarial',                    '$_base/3semestre/EconomiaEmpresarial-AEF-1071.pdf'),
    _Materia('Álgebra Lineal',                          '$_base/3semestre/AlgebraLineal-ACF%E2%80%930903.pdf'),
  ]),
  _Semestre(4, [
    _Materia('Ingeniería Económica',                        '$_base/4semestre/IngenieriaEconomica.pdf'),
    _Materia('Estadística Inferencial I',                   '$_base/4semestre/EstadisticaInferencial-I.pdf'),
    _Materia('Instrumentos de Presupuestación Empresarial', '$_base/4semestre/InstrumentosdePresupuestacionEmpresarial.pdf'),
    _Materia('Habilidades Directivas II',                   '$_base/4semestre/HabilidadesDirectivas-II.pdf'),
    _Materia('Entorno Macroeconómico',                      '$_base/4semestre/EntornoMacroeconomico.pdf'),
    _Materia('Investigación de Operaciones',                '$_base/4semestre/InvestigaciondeOperaciones-AEF-1076.pdf'),
  ]),
  _Semestre(5, [
    _Materia('Finanzas en las Organizaciones', '$_base/5semestre/FinanzasdelasOrganizaciones-AEF-1073.pdf'),
    _Materia('Estadística Inferencial II',     '$_base/5semestre/EstadisticaInferencial-II.pdf'),
    _Materia('Ingeniería de Procesos',         '$_base/5semestre/IngenieriadeProcesos.pdf'),
    _Materia('Gestión del Capital Humano',     '$_base/5semestre/GestiondelCapitalHumano-AEG-1075.pdf'),
    _Materia('Taller de Investigación I',      '$_base/5semestre/TallerdeInvestigacion-I-ACA-0909.pdf'),
    _Materia('Mercadotecnia',                  '$_base/5semestre/Mercadotecnia.pdf'),
  ]),
  _Semestre(6, [
    _Materia('Administración de la Salud y Seguridad Ocupacional', '$_base/6semestre/AdministraciondelaSaludySeguridadOcupacional.pdf'),
    _Materia('El Emprendedor y la Innovación',                     '$_base/6semestre/ElemprendedorylaInnovacion-AED-1072.pdf'),
    _Materia('Gestión de la Producción I',                         '$_base/6semestre/GestiondelaProduccion-I.pdf'),
    _Materia('Diseño Organizacional',                              '$_base/6semestre/DisenoOrganizacional-AED-1015.pdf'),
    _Materia('Taller de Investigación II',                         '$_base/6semestre/TallerdeInvestigacion-II-ACA-0910.pdf'),
    _Materia('Sistemas de Información de Mercadotecnia',           '$_base/6semestre/SistemasdeInformaciondeMercadotecnia.pdf'),
  ]),
  _Semestre(7, [
    _Materia('Calidad Aplicada a la Gestión Empresarial', '$_base/7semestre/CalidadAplicadaalaGestionEmpresarial-AED-1069.pdf'),
    _Materia('Plan de Negocios',                          '$_base/7semestre/PlandeNegocios.pdf'),
    _Materia('Gestión de la Producción II',               '$_base/7semestre/GestiondelaProduccion-II.pdf'),
    _Materia('Gestión Estratégica',                       '$_base/7semestre/GestionEstrategica-AED-1035.pdf'),
    _Materia('Desarrollo Sustentable',                    '$_base/7semestre/DesarrolloSustentable-ACD-0908.pdf'),
    _Materia('Mercadotecnia Electrónica',                 '$_base/7semestre/MercadotecniaElectronica-AEB-1045.pdf'),
  ]),
  _Semestre(8, [
    _Materia('Cadena de Suministros', '$_base/8semestre/CadenadeSumunistros.pdf'),
  ]),
  // 9no semestre: actividades institucionales sin PDF de temario.
  // url vacía → _MateriaItem detecta hasUrl = false y desactiva el tap.
  _Semestre(9, [
    _Materia('Especialidad',               ''),
    _Materia('Residencia Profesional',     ''),
    _Materia('Servicio Social',            ''),
    _Materia('Actividades Complementarias',''),
  ]),
];

// ── Modelo de especialidad ────────────────────────────────────
// El color se recibe como función (ColorScheme) → Color para
// resolverse en tiempo de build con el tema activo.
// IGEE tiene tres especialidades, cada una con su propio color de acento:
// primary, secondary y tertiary respectivamente.
class _Especialidad {
  final String nombre;
  final IconData icono;
  final Color Function(ColorScheme) color;
  final List<_Materia> materias;
  const _Especialidad({required this.nombre, required this.icono, required this.color, required this.materias});
}

// URL base de los temarios de especialidad de IGEE.
const _baseEsp = 'https://villahermosa.tecnm.mx/docs/oferta/inggestion/temario2009/Especialidad';

final _especialidades = [
  _Especialidad(
    nombre: 'Proyectos Empresariales Sustentables',
    icono: Icons.eco_rounded,
    color: (cs) => cs.primary,
    materias: [
      _Materia('Normas de Calidad y su Aplicación',              '$_baseEsp/INTE-PES-2017-03/NormasdeCalidadysuAplicacion-PEF-1701.pdf'),
      _Materia('Estrategias Corporativas y Sustentabilidad',     '$_baseEsp/INTE-PES-2017-03/EstrategiasCorporativasySustentabilidad-PEF-1703.pdf'),
      _Materia('Comercio Exterior',                              '$_baseEsp/INTE-PES-2017-03/ComercioExterior-PEF-1704.pdf'),
      _Materia('Marketing Ecológico',                            '$_baseEsp/INTE-PES-2017-03/MarketingEcologico-PED-1705.pdf'),
      _Materia('Modelo de Negocios Sustentables',                '$_baseEsp/INTE-PES-2017-03/ModelosdeNegociosSustentables-PED-1706.pdf'),
    ],
  ),
  _Especialidad(
    nombre: 'Administración y Finanzas',
    icono: Icons.account_balance_rounded,
    color: (cs) => cs.secondary,
    materias: [
      _Materia('Mercados Financieros I',                         '$_baseEsp/INTE-AFI-2018-01/MercadosFinancierosI-AFD-1801.pdf'),
      _Materia('Modelo de Negocios Sustentables',                '$_baseEsp/INTE-AFI-2018-01/ModelodeNegociosSustentables-AFD-1802.pdf'),
      _Materia('Estrategias Corporativas y Sustentabilidad',     '$_baseEsp/INTE-AFI-2018-01/EstrategiasCorporativasySustentabilidad-AFF-1803.pdf'),
      _Materia('Comercio Exterior',                              '$_baseEsp/INTE-AFI-2018-01/ComercioExterior-AFF-1804.pdf'),
      _Materia('Auditoría Interna',                              '$_baseEsp/INTE-AFI-2018-01/AuditoriaInterna-AFD-1805.pdf'),
      _Materia('Mercados Financieros II',                        '$_baseEsp/INTE-AFI-2018-01/MercadosFinancieros%20II-AFD-1806.pdf'),
    ],
  ),
  _Especialidad(
    nombre: 'Capital Humano y Tic\'s',
    icono: Icons.people_alt_rounded,
    color: (cs) => cs.tertiary,
    materias: [
      _Materia('Productividad y Competitividad del Talento Humano',            '$_baseEsp/INTE-CHT-2017-03/ProductividadyCompetitividaddelTalentoHumano-CHC-1701.pdf'),
      _Materia('Nuevas Herramientas como Apoyo a la Gestión del Talento Humano','$_baseEsp/INTE-CHT-2017-03/NuevasHerramientascomoApoyoalaGestiondelTalentoHumano-CHH-1702.pdf'),
      _Materia('Capital Humano en la Era Digital: Oportunidades y Desafíos',   '$_baseEsp/INTE-CHT-2017-03/CapitalHumanoenlaEraDigital-CHC-1703.pdf'),
      _Materia('Taller de Valoración de Empresas por Simulación',              '$_baseEsp/INTE-CHT-2017-03/TallerdeValoraciondeEmpresasporsimulacion-CHC-1704.pdf'),
      _Materia('Seminario de Gestión del Talento Humano',                      '$_baseEsp/INTE-CHT-2017-03/SeminariodeGestiondelTalentoHumano-CHB-1705.pdf'),
      _Materia('Nómina Electrónica',                                           '$_baseEsp/INTE-CHT-2017-03/NominaelectronicaCHC1706.pdf'),
    ],
  ),
];


// ═════════════════════════════════════════════════════════════════
// WIDGETS PRIVADOS
// ═════════════════════════════════════════════════════════════════

/// Tile expandible que muestra las materias de un semestre.
/// Usa cs.secondary como color de acento, coherente con el color
/// dominante de IGEE en toda la pantalla (a diferencia de otras
/// carreras que usan cs.primary para los semestres).
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
            backgroundColor: cs.secondary.withValues(alpha: 0.05),
            collapsedBackgroundColor: cs.secondary.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.secondary.withValues(alpha: 0.12)),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outline.withValues(alpha: 0.12)),
            ),
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: cs.secondary.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Center(
                child: Text('${semestre.numero}',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.secondary)),
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
/// El color se resuelve en build con el ColorScheme activo,
/// permitiendo que cada especialidad use un color distinto
/// (primary, secondary o tertiary).
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
/// El ícono de PDF usa cs.secondary (color dominante de IGEE) en todos
/// los contextos, incluidas las especialidades.
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
                color: cs.secondary.withValues(alpha: 0.5),
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
/// Usa cs.secondary como color de acento, coherente con el color
/// dominante de IGEE (a diferencia de otras carreras que usan primary).
class _SectionTitle extends StatelessWidget {
  final ColorScheme cs;
  final String texto;
  const _SectionTitle({required this.cs, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 4, height: 18,
          decoration: BoxDecoration(color: cs.secondary, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Text(texto, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: cs.onSurface)),
    ]);
  }
}

/// Fila numerada con círculo de acento, título en negrita
/// y descripción en texto secundario.
/// Usa cs.secondary para el círculo, coherente con el resto de IGEE.
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
          decoration: BoxDecoration(color: cs.secondary.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Center(child: Text('$numero',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cs.secondary))),
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
/// Usa cs.secondary como color de acento, coherente con IGEE.
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
                  color: cs.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.grid_view_rounded, color: cs.secondary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(reticula.nombre,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                const SizedBox(height: 3),
                Text(reticula.clave,
                    style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4), letterSpacing: 0.2)),
              ])),
              Icon(Icons.picture_as_pdf_rounded, color: cs.secondary.withValues(alpha: 0.5), size: 20),
            ]),
          ),
        ),
      ),
    );
  }
}