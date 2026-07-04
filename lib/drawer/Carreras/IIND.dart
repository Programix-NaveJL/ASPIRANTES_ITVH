// ═════════════════════════════════════════════════════════════════
// IIND.dart
//
// Pantalla informativa de la Ingeniería Industrial (IIND).
//
// Secciones:
//   • Cards resumen        — Misión y Visión en dos cards lado a lado
//   • Objetivo General     — descripción completa del propósito
//   • Objetivos Específicos — siete competencias numeradas
//   • Perfil de Ingreso    — características deseables del aspirante
//   • Perfil de Egreso     — competencias del profesional al egresar
//   • Campo Laboral        — _CampoLaboralSection: chips con sectores
//                            de inserción laboral
//   • Retícula IIND-2010-227 — un plan con enlace a PDF
//   • Plan de Estudios     — ExpansionTile por semestre (1–9)
//   • Especialidad         — un ExpansionTile con materias
//
// Widgets privados de esta pantalla:
//   • _SemestreExpansion     — tile expandible de un semestre
//   • _EspecialidadExpansion — tile expandible de la especialidad;
//                              usa cs.tertiary como color de acento
//                              para distinguirla de los semestres
//   • _MateriaItem           — fila tappable que abre PdfViewerScreen;
//                              acepta un parámetro opcional [color]
//                              para que la especialidad use cs.tertiary;
//                              si la URL está vacía deshabilita el tap
//                              y cambia el ícono a info
//   • _CampoLaboralSection   — párrafo descriptivo + chips con ícono
//                              y nombre de cada sector laboral
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
//                    (el 9no semestre usa url vacía; _MateriaItem
//                    desactiva el tap automáticamente)
//   • _Especialidad — nombre, clave y lista de materias
//                     (modelo más simple que en otras carreras:
//                     sin función de color ni IconData porque
//                     _EspecialidadExpansion usa color e ícono fijos)
//
// Color de acento:
//   • cs.primary   — color principal de la carrera; semestres,
//                    sección title, objetivo, retícula
//   • cs.secondary — acento del Perfil de Ingreso
//   • cs.tertiary  — acento del Perfil de Egreso, card Visión
//                    y tile de especialidad
//
// Nota de implementación:
//   • _MateriaItem de IIND acepta un parámetro opcional [color]
//     (a diferencia de IAMB e IBQA donde el color siempre es cs.primary).
//     Esto permite que _EspecialidadExpansion pase cs.tertiary para
//     colorear el ícono de PDF coherentemente con el tile padre.
//   • _Especialidad de IIND es un modelo más simple (nombre + clave +
//     materias) sin función de color ni IconData, porque solo hay una
//     especialidad y el color/ícono se definen directamente en
//     _EspecialidadExpansion con cs.tertiary e Icons.workspace_premium.
//   • _CampoLaboralSection es exclusiva de esta pantalla; en IAMB
//     el campo laboral se renderiza con _PerfilSection genérica.
// ═════════════════════════════════════════════════════════════════

import 'package:aspirantes_itvh_app/drawer/Carreras/pdf_viewer_screen.dart';
import 'package:flutter/material.dart';


// ═════════════════════════════════════════════════════════════════
// PANTALLA PRINCIPAL
// ═════════════════════════════════════════════════════════════════

class IINDScreen extends StatelessWidget {
  const IINDScreen({super.key});

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
                  // Fondo con tinte en cs.primary — color de acento de IIND.
                  Container(color: cs.primary.withValues(alpha: 0.12)),

                  // Ícono decorativo semitransparente en esquina superior derecha.
                  Positioned(
                    right: -30, top: -20,
                    child: Icon(Icons.precision_manufacturing_rounded, size: 220, color: cs.primary.withValues(alpha: 0.07)),
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
                          'Departamento de Ingeniería Industrial',
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
                        'Ingeniería Industrial',
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
                    Expanded(child: _InfoCard(
                      cs: cs,
                      icono: Icons.flag_rounded,
                      titulo: 'Misión',
                      contenido: 'Formadora de profesionales en Ingeniería Industrial en el sureste del país, capaces de desarrollar competencias instrumentales, sistémicas y actitudinales con alta responsabilidad.',
                      color: cs.primary,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _InfoCard(
                      cs: cs,
                      icono: Icons.visibility_rounded,
                      titulo: 'Visión',
                      contenido: 'Ser líder en ingeniería industrial en el sureste de México, formando profesionales competitivos con ética y armonía con el medio ambiente.',
                      color: cs.tertiary,
                    )),
                  ],
                ),

                const SizedBox(height: 28),

                // Objetivo General completo.
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
                    'Formar profesionistas en el campo de la ingeniería industrial, líderes, creativos y emprendedores con visión sistémica, capacidad analítica y competitiva que les permita diseñar, implementar, mejorar, innovar, optimizar y administrar sistemas de producción de bienes y servicios en un entorno global, con enfoque sustentable, ético y comprometido con la sociedad.',
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
                  'Capacidad de análisis, síntesis y juicio crítico.',
                  'Capacidad de planeación, organización y coordinación de tareas.',
                  'Liderazgo positivo, capacidad de dirección y de mando.',
                  'Actitud emprendedora e interés por mejorar el entorno.',
                ]),

                const SizedBox(height: 28),

                // Perfil de egreso — cs.tertiary para distinguirlo
                // del perfil de ingreso (secondary).
                _SectionTitle(cs: cs, texto: 'Perfil de Egreso'),
                const SizedBox(height: 12),
                _PerfilSection(cs: cs, color: cs.tertiary, items: const [
                  'Diseña, mejora e integra sistemas productivos de bienes y servicios aplicando tecnologías para su optimización.',
                  'Diseña, implementa y mejora sistemas de trabajo para elevar la productividad.',
                  'Implanta sistemas de calidad utilizando métodos estadísticos para mejorar la competitividad de las organizaciones.',
                  'Administra sistemas de mantenimiento en procesos de bienes y servicios para la optimización en el uso de los recursos.',
                  'Gestiona sistemas de seguridad y salud ocupacional de manera sustentable, atendiendo los lineamientos legales.',
                  'Formula, evalúa y gestiona proyectos de inversión, sociales y de transferencia de tecnología para el desarrollo regional.',
                ]),

                const SizedBox(height: 28),

                // Campo Laboral — chips con ícono y nombre de sector.
                // Se usa _CampoLaboralSection en lugar de _PerfilSection
                // porque el diseño de chips aporta más escaneabilidad
                // a una lista corta de sectores.
                _SectionTitle(cs: cs, texto: 'Campo Laboral'),
                const SizedBox(height: 12),
                _CampoLaboralSection(cs: cs),

                const SizedBox(height: 28),

                // Retícula — un único plan disponible para IIND.
                _SectionTitle(cs: cs, texto: 'Retícula IIND-2010-227'),
                const SizedBox(height: 12),
                _ReticulaItem(cs: cs, reticula: _reticula),

                const SizedBox(height: 28),

                // Plan de Estudios — un ExpansionTile por semestre.
                _SectionTitle(cs: cs, texto: 'Plan de Estudios'),
                const SizedBox(height: 12),
                ..._semestres.map((sem) => _SemestreExpansion(cs: cs, semestre: sem)),

                const SizedBox(height: 20),

                // Especialidad — un único ExpansionTile con cs.tertiary.
                _SectionTitle(cs: cs, texto: 'Especialidad'),
                const SizedBox(height: 12),
                _EspecialidadExpansion(cs: cs, especialidad: _especialidad),

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
  (1, 'Resolver Problemas', 'Desarrolla sistemas productivos de bienes y servicios aplicando tecnologías para su optimización.'),
  (2, 'Saber Diseñar',      'Diseña sistemas de trabajo para elevar la productividad mediante mejora continua.'),
  (3, 'Hacer Experimentos', 'Desarrolla investigación para mejorar los sistemas de trabajo y elevar la productividad.'),
  (4, 'Saber Comunicarse',  'Administra la información de los procesos de bienes y servicios para la optimización de los recursos.'),
  (5, 'Ser Ético',          'Gestiona sistemas productivos de bienes y servicios atendiendo los lineamientos legales.'),
  (6, 'Actualizarse',       'Actualiza sus conocimientos permanentemente para mejorar la competitividad de las organizaciones.'),
  (7, 'Trabajar en Equipo', 'Dirige equipos de trabajo para el desarrollo de proyectos de inversión, sociales y de transferencia de tecnología.'),
];

// ── Modelo de retícula ────────────────────────────────────────
class _Reticula {
  final String clave, nombre, url;
  const _Reticula({required this.clave, required this.nombre, required this.url});
}

const _reticula = _Reticula(
  clave: 'IIND-2010-227',
  nombre: 'Retícula 2010 - IINE-CSP-2023-01 (D)',
  url: 'http://cc.villahermosa.tecnm.mx/sys/estpro/reticulas/IIND-2010-227--IINE-CSP-2023-01.pdf',
);

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
const _base = 'https://villahermosa.tecnm.mx/docs/oferta/ingindustrial/temario2010';

final _semestres = [
  _Semestre(1, [
    _Materia('Fundamentos de Investigación',      '$_base/1semestre/FundamentosdeInvestigacion-ACC-0906.pdf'),
    _Materia('Taller de Ética',                   '$_base/1semestre/TallerdeEtica-ACA-0907.pdf'),
    _Materia('Cálculo Diferencial',               '$_base/1semestre/CalculoDiferencial-AC001.pdf'),
    _Materia('Taller de Herramientas Intelectuales','$_base/1semestre/TALLERDEHERRAMIENTASINTELECTUALESv2.pdf'),
    _Materia('Química',                           '$_base/1semestre/QUIMICAv2.pdf'),
    _Materia('Dibujo Industrial',                 '$_base/1semestre/DIBUJOINDUSTRIALv2.pdf'),
  ]),
  _Semestre(2, [
    _Materia('Electricidad y Electrónica Industrial', '$_base/2semestre/ELECTRICIDADYELECTRONICAINDUSTRIALv2.pdf'),
    _Materia('Propiedad de los Materiales',           '$_base/2semestre/PROPIEDADDELOSMATERIALESv2.pdf'),
    _Materia('Cálculo Integral',                      '$_base/2semestre/CalculoIntegral-ACF%E2%80%930902.pdf'),
    _Materia('Probabilidad y Estadística',            '$_base/2semestre/ProbabilidadyEstadistica-AEC-1053.pdf'),
    _Materia('Análisis de la Realidad Nacional',      '$_base/2semestre/ANALISISDELAREALIDADNACIONALv2.pdf'),
    _Materia('Taller de Liderazgo',                   '$_base/2semestre/TALLERDELIDERAZGO.pdf'),
  ]),
  _Semestre(3, [
    _Materia('Metrología y Normalización', '$_base/3semestre/MetrologiayNormalizacion-AEC-1048.pdf'),
    _Materia('Álgebra Lineal',             '$_base/3semestre/AlgebraLineal-ACF%E2%80%930903.pdf'),
    _Materia('Cálculo Vectorial',          '$_base/3semestre/CalculoVectorial-ACF%E2%80%930904.pdf'),
    _Materia('Economía',                   '$_base/3semestre/Economia-AEC-1018.pdf'),
    _Materia('Estadística Inferencial I',  '$_base/3semestre/EstadisticaInferencial-I-AEF%E2%80%931024.pdf'),
    _Materia('Estudio del Trabajo I',      '$_base/3semestre/ESTUDIODELTRABAJO-I-v2.pdf'),
  ]),
  _Semestre(4, [
    _Materia('Procesos de Fabricación',                '$_base/4semestre/PROCESOSDEFABRICACIONv2.pdf'),
    _Materia('Física',                                 '$_base/4semestre/FISICAv2.pdf'),
    _Materia('Algoritmos y Lenguajes de Programación', '$_base/4semestre/ALGORITMOSYLENGUAJESDEPROGRAMACIONv2.pdf'),
    _Materia('Investigación de Operaciones I',         '$_base/4semestre/INVESTIGACIONDEOPERACIONES-I-v2.pdf'),
    _Materia('Estadística Inferencial II',             '$_base/4semestre/EstadisticaInferencial-II-AEF%E2%80%931025.pdf'),
    _Materia('Estudio del Trabajo II',                 '$_base/4semestre/ESTUDIODELTRABAJOIIv2.pdf'),
    _Materia('Higiene y Seguridad Industrial',         '$_base/4semestre/HIGIENEYSEGURIDADINDUSTRIAL%20.pdf'),
  ]),
  _Semestre(5, [
    _Materia('Administración de Proyectos',       '$_base/5semestre/ADMINISTRACIONDEPROYECTOSv2.pdf'),
    _Materia('Gestión de Costos',                 '$_base/5semestre/GestiondeCostos-AE092.pdf'),
    _Materia('Administración de Operaciones I',   '$_base/5semestre/ADMINISTRACIONDEOPERACIONESIv2.pdf'),
    _Materia('Investigación de Operaciones II',   '$_base/5semestre/INVESTIGACIONDEOPERACIONESIIv2.pdf'),
    _Materia('Control Estadístico de la Calidad', '$_base/5semestre/CONTROLESTADISTICODELACALIDA%20v2.pdf'),
    _Materia('Ergonomía',                         '$_base/5semestre/ERGONOMIAv2.pdf'),
    _Materia('Desarrollo Sustentable',            '$_base/5semestre/DesarrolloSustentable-AC008.pdf'),
  ]),
  _Semestre(6, [
    _Materia('Taller de Investigación I',          '$_base/6semestre/TallerdeInvestigacionIAC009.pdf'),
    _Materia('Ingeniería Económica',               '$_base/6semestre/IngenieriaEconomica-AE037.pdf'),
    _Materia('Administración de las Operaciones II','$_base/6semestre/ADMINISTRACIONDEOPERACIONESIIv2.pdf'),
    _Materia('Simulación',                         '$_base/6semestre/SIMULACIONv2.pdf'),
    _Materia('Administración del Mantenimiento',   '$_base/6semestre/ADMINISTRACIONDELMANTENIMIENTOV2.pdf'),
    _Materia('Mercadotecnia',                      '$_base/6semestre/Mecadotecnia-AE044.pdf'),
  ]),
  _Semestre(7, [
    _Materia('Taller de Investigación II',          '$_base/7semestre/TallerdeInvestigacionII-AC010.pdf'),
    _Materia('Planeación Financiera',               '$_base/7semestre/PLANEACIONFINANCIERAv2.pdf'),
    _Materia('Planeación y Diseño de Instalaciones','$_base/7semestre/PLANEACIONYDISENODEINSTALACIONESv2.pdf'),
    _Materia('Sistemas de Manufactura',             '$_base/7semestre/SISTEMASDEMANUFACTURA.pdf'),
    _Materia('Logística y Cadenas de Suministro',   '$_base/7semestre/LOGISTICAyCADENADESUMINISTROv2.pdf'),
    _Materia('Gestión de los Sistemas de Calidad',  '$_base/7semestre/GESTIONDELOSSITEMASDECALIDADv2.pdf'),
    _Materia('Ingeniería de Sistemas',              '$_base/7semestre/INGENIERIADESISTEMASv2.pdf'),
  ]),
  _Semestre(8, [
    _Materia('Formulación y Evaluación de Proyectos', '$_base/8semestre/FormulacionyEvaluaciondeProyectos-AED-1030.pdf'),
    _Materia('Relaciones Industriales',               '$_base/8semestre/RELACIONESINDUSTRIALESv2.pdf'),
  ]),
  // 9no semestre: actividades institucionales sin PDF de temario.
  // url vacía → _MateriaItem detecta hasUrl = false y desactiva el tap.
  _Semestre(9, [
    _Materia('Especialidad',                ''),
    _Materia('Residencia Profesional',      ''),
    _Materia('Servicio Social',             ''),
    _Materia('Actividades Complementarias', ''),
  ]),
];

// ── Modelo de especialidad ────────────────────────────────────
// Modelo simplificado respecto a IAMB/IBQA: sin función de color
// ni IconData, porque solo hay una especialidad y ambos valores
// se definen directamente en _EspecialidadExpansion.
class _Especialidad {
  final String nombre, clave;
  final List<_Materia> materias;
  const _Especialidad({required this.nombre, required this.clave, required this.materias});
}

// URL base de los temarios de especialidad de IIND.
const _espBase = 'https://villahermosa.tecnm.mx/docs/oferta/ingindustrial';

const _especialidad = _Especialidad(
  nombre: 'Calidad, Seguridad y Productividad',
  clave: 'IINE-CSP-2023-01 (D)',
  materias: [
    _Materia('Investigación y Desarrollo',                   '$_espBase/temario-IINE-CPC-2017-01(B)/01_INVESTIGACION%20Y%20DESARROLLO.pdf'),
    _Materia('Innovación en los Sistemas de Gestión de la Seguridad', '$_espBase/especialidad/INNOVACIONSEGURIDAD.pdf'),
    _Materia('Métodos de Análisis de Riesgo para la Seguridad',       '$_espBase/especialidad/METODOSRIESGOSSEGURIDAD.pdf'),
    _Materia('Ingeniería de Calidad',                        '$_espBase/especialidad/INGENIERIACALIDAD.pdf'),
    _Materia('Administración de la Calidad',                 '$_espBase/especialidad/ADMINISTRACIONCALIDAD.pdf'),
    _Materia('Dirección Estratégica',                        '$_espBase/especialidad/DIRECCIONESTRATEGICA.pdf'),
    _Materia('Productividad y Competitividad',               '$_espBase/especialidad/PRODUCTIVIDADCOMPETITIVIDAD.pdf'),
    _Materia('Herramientas Aplicadas a la Calidad',          '$_espBase/especialidad/HERRAMIENTASCALIDAD.pdf'),
  ],
);


// ═════════════════════════════════════════════════════════════════
// WIDGETS PRIVADOS
// ═════════════════════════════════════════════════════════════════

/// Párrafo descriptivo + chips con ícono para cada sector laboral.
/// Se prefiere este widget sobre _PerfilSection porque la lista de
/// sectores es corta y los chips permiten escanearlo de un vistazo.
class _CampoLaboralSection extends StatelessWidget {
  final ColorScheme cs;
  const _CampoLaboralSection({required this.cs});

  // Cada tupla contiene el ícono y el nombre del sector.
  static const _sectores = [
    (Icons.account_balance_rounded,   'Sector Público'),
    (Icons.factory_rounded,           'Sector Industrial'),
    (Icons.store_rounded,             'Comercio y Servicios'),
    (Icons.school_rounded,            'Instituciones Educativas'),
    (Icons.handshake_rounded,         'Consultoría'),
    (Icons.volunteer_activism_rounded,'Org. sin fines de lucro'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Los egresados pueden desempeñarse en sectores públicos, privados y sociales, tanto en la industria como en instituciones educativas, consultorías y organizaciones sin fines de lucro.',
          style: TextStyle(fontSize: 13, height: 1.6, color: cs.onSurface.withValues(alpha: 0.75)),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _sectores.map((e) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(e.$1, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Text(e.$2, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary)),
            ]),
          )).toList(),
        ),
      ],
    );
  }
}

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

/// Tile expandible que muestra las materias de la especialidad.
/// Usa cs.tertiary como color de acento e Icons.workspace_premium
/// como ícono fijo, a diferencia de otras carreras donde el color
/// se recibe como función y el ícono como parámetro.
class _EspecialidadExpansion extends StatelessWidget {
  final ColorScheme cs;
  final _Especialidad especialidad;
  const _EspecialidadExpansion({required this.cs, required this.especialidad});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            backgroundColor: cs.tertiary.withValues(alpha: 0.05),
            collapsedBackgroundColor: cs.tertiary.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.tertiary.withValues(alpha: 0.15)),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outline.withValues(alpha: 0.12)),
            ),
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: cs.tertiary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.workspace_premium_rounded, color: cs.tertiary, size: 20),
            ),
            title: Text(especialidad.nombre,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
            // La clave se muestra en el subtítulo en lugar del conteo de
            // materias, para identificar el plan directamente desde el tile.
            subtitle: Text(especialidad.clave,
                style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.40))),
            // Se pasa cs.tertiary al color opcional de _MateriaItem para
            // que el ícono de PDF sea coherente con el color del tile.
            children: especialidad.materias.map((m) => _MateriaItem(cs: cs, materia: m, color: cs.tertiary)).toList(),
          ),
        ),
      ),
    );
  }
}

/// Fila tappable que navega a PdfViewerScreen con el temario de la materia.
/// Si la materia no tiene URL (hasUrl = false), se deshabilita el tap
/// y el ícono cambia a info para indicar que no hay PDF disponible.
/// El parámetro opcional [color] permite que la especialidad use
/// cs.tertiary en lugar del cs.primary predeterminado.
class _MateriaItem extends StatelessWidget {
  final ColorScheme cs;
  final _Materia materia;
  final Color? color;
  const _MateriaItem({required this.cs, required this.materia, this.color});

  @override
  Widget build(BuildContext context) {
    final hasUrl = materia.url.isNotEmpty;
    final c = color ?? cs.primary;
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
          child: Row(children: [
            Icon(
              hasUrl ? Icons.picture_as_pdf_rounded : Icons.info_outline_rounded,
              size: 18,
              color: c.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(materia.nombre,
                style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.8)))),
            if (hasUrl)
              Icon(Icons.chevron_right_rounded, size: 18, color: cs.onSurface.withValues(alpha: 0.25)),
          ]),
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
  const _InfoCard({required this.cs, required this.icono, required this.titulo,
    required this.contenido, required this.color});

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
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(width: 6, height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          ),
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