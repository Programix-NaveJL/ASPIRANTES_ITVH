// ═════════════════════════════════════════════════════════════════
// ITIC.dart
//
// Pantalla informativa de la Ingeniería en Tecnologías de la
// Información y Comunicaciones (ITIC).
//
// Secciones:
//   • Objetivo General     — descripción del propósito de la carrera
//   • Perfil de Ingreso    — características deseables del aspirante
//   • Perfil de Egreso     — competencias del profesional al egresar
//   • Campo Laboral        — descripción con chips de empresas destacadas
//   • Retícula ITIC-2010-225 — tres especialidades con enlace a PDF
//   • Plan de Estudios     — ExpansionTile por semestre (1–9)
//   • Especialidades       — ExpansionTile por especialidad con materias
//
// Widgets privados de esta pantalla:
//   • _SemestreExpansion     — tile expandible de un semestre
//   • _EspecialidadExpansion — tile expandible de una especialidad
//   • _MateriaItem           — fila tappable que abre PdfViewerScreen
//   • _CampoLaboralSection   — texto + chips de empresas/sectores
//   • _SectionTitle          — título con barra de acento del ColorScheme
//   • _PerfilSection         — lista de bullets con punto de color
//   • _ReticulaItem          — card tappable que abre PdfViewerScreen
//
// Modelos de datos (privados):
//   • _Reticula    — clave, nombre y URL de una retícula
//   • _Materia     — nombre y URL de un temario en PDF
//   • _Semestre    — número y lista de materias
//   • _Especialidad — nombre, ícono, función de color y materias
//
// Notas de implementación:
//   • Los colores de acento se toman del ColorScheme del tema
//     (cs.secondary para semestres, cs.primary/cs.tertiary para perfiles)
//     para respetar el tema dinámico de la app.
//   • Las especialidades comparten temarios con ISC.dart; la URL base
//     _esp apunta a la carpeta de ISC en el servidor del campus.
//   • El 9no semestre lista actividades institucionales sin PDF
//     (url vacía) que se renderizan igual que en ISC y LADM.
//   • A diferencia de LADM e IQUI, esta pantalla no tiene un widget
//     _MateriaInfoItem separado: el flag hasUrl en _MateriaItem
//     maneja ambos casos (PDF disponible / no disponible).
// ═════════════════════════════════════════════════════════════════

import 'package:aspirantes_itvh_app/drawer/Carreras/pdf_viewer_screen.dart';
import 'package:flutter/material.dart';

class ITICScreen extends StatelessWidget {
  const ITICScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [

          // SliverAppBar expandible: colapsa al hacer scroll y
          // muestra solo el título fijo en la barra superior.
          // expandedHeight aumentado a 240 porque el nombre de la
          // carrera es más largo y necesita más espacio vertical.
          SliverAppBar(
            expandedHeight: 240,
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
                  Container(color: cs.secondary.withValues(alpha:0.12)),

                  // Ícono decorativo semitransparente en esquina superior derecha.
                  Positioned(
                    right: -30, top: -20,
                    child: Icon(Icons.wifi_rounded, size: 220, color: cs.secondary.withValues(alpha:0.07)),
                  ),

                  // Chip del departamento al que pertenece la carrera.
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      // padding bottom: 84 porque el título ocupa más
                      // líneas que en otras carreras con nombre más corto.
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 84),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.secondary.withValues(alpha:0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Departamento de Sistemas y Computación',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.secondary),
                        ),
                      ),
                    ),
                  ),

                  // Título grande visible solo cuando el SliverAppBar está expandido.
                  // right: 60 deja margen para evitar que el texto largo
                  // choque con la flecha de retroceso colapsada.
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 60, 20),
                      child: Text(
                        'Ing. en Tecnologías de la Información y Comunicaciones',
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: cs.onSurface),
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
                    color: cs.secondary.withValues(alpha:0.07),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.secondary.withValues(alpha:0.15)),
                  ),
                  child: Text(
                    'Formar profesionistas capaces de desarrollar, integrar y administrar tecnologías de la información y comunicaciones que contribuyan a la productividad y al logro de los objetivos estratégicos de las organizaciones en un entorno globalizado; caracterizándose por ser líderes, críticos, competentes, éticos y con visión emprendedora, comprometidos con el desarrollo sustentable.',
                    style: TextStyle(fontSize: 14, height: 1.65, color: cs.onSurface.withValues(alpha:0.8)),
                  ),
                ),

                const SizedBox(height: 28),

                // Perfil de ingreso — usa cs.secondary como acento.
                _SectionTitle(cs: cs, texto: 'Perfil de Ingreso'),
                const SizedBox(height: 12),
                _PerfilSection(cs: cs, color: cs.secondary, items: const [
                  'Tener habilidades para programar en un lenguaje de computadora.',
                  'Interés por el uso de nuevas tecnologías.',
                  'Tener gusto y creatividad para el desarrollo de nuevas tecnologías.',
                  'Personalidad emprendedora.',
                ]),

                const SizedBox(height: 28),

                // Perfil de egreso — usa cs.primary para diferenciarlo
                // visualmente del perfil de ingreso.
                _SectionTitle(cs: cs, texto: 'Perfil de Egreso'),
                const SizedBox(height: 12),
                _PerfilSection(cs: cs, color: cs.primary, items: const [
                  'Diseña, implementa y administra redes de cómputo y comunicaciones para satisfacer las necesidades de información de las organizaciones, con base en modelos y estándares internacionales.',
                  'Administra proyectos que involucren Tecnologías de la Información y Comunicaciones para el logro de los objetivos organizacionales conforme a requerimientos establecidos.',
                  'Desarrolla e implementa sistemas de información para la gestión de procesos y apoyo en la toma de decisiones, utilizando metodologías basadas en estándares internacionales.',
                  'Diseña, desarrolla y gestiona sistemas de bases de datos para garantizar la integridad, disponibilidad y confidencialidad de la información.',
                  'Integra soluciones de sistemas de comunicación con diferentes tecnologías, plataformas o dispositivos.',
                  'Desempeña funciones de consultoría y auditoría para validar procesos y garantizar la calidad en el uso de las Tecnologías de la Información y Comunicaciones.',
                  'Crea empresas en el ámbito de las Tecnologías de la Información y Comunicaciones para contribuir al desarrollo del entorno.',
                  'Integra las diferentes arquitecturas de hardware y administra plataformas de software para incrementar la productividad en las organizaciones.',
                  'Implementa sistemas de seguridad acorde a políticas internas de las organizaciones basados en estándares establecidos, con la finalidad de garantizar la integridad y consistencia de la información.',
                  'Aplica los aspectos de legislación informática para regular el uso y explotación de las Tecnologías de la Información y Comunicaciones.',
                  'Diseña e implementa dispositivos con software embebido para aplicaciones de propósito específico.',
                  'Utiliza tecnologías emergentes y herramientas actuales para atender necesidades acordes al entorno.',
                  'Diseña e implementa interfaces gráficas de usuario para facilitar la interacción entre el ser humano, los equipos y sistemas electrónicos.',
                  'Posee habilidades metodológicas de investigación que fortalezcan el desarrollo cultural, científico y tecnológico en el ámbito de sistemas computacionales y disciplinas afines.',
                  'Selecciona y aplica herramientas matemáticas para el modelado, diseño y desarrollo de tecnología computacional.',
                  'Desempeña sus actividades profesionales considerando los aspectos legales, éticos, sociales y de desarrollo sustentable.',
                ]),

                const SizedBox(height: 28),

                // Campo Laboral — widget especializado con chips de empresas.
                _SectionTitle(cs: cs, texto: 'Campo Laboral'),
                const SizedBox(height: 12),
                _CampoLaboralSection(cs: cs),

                const SizedBox(height: 28),

                // Retículas — las tres especialidades comparten la clave
                // raíz ITIC-2010-225 con sufijo de especialidad distinto.
                _SectionTitle(cs: cs, texto: 'Retícula ITIC-2010-225'),
                const SizedBox(height: 12),
                ..._reticulas.map((r) => _ReticulaItem(cs: cs, reticula: r)),

                const SizedBox(height: 28),

                // Plan de Estudios — un ExpansionTile por semestre.
                _SectionTitle(cs: cs, texto: 'Plan de Estudios'),
                const SizedBox(height: 12),
                ..._semestres.map((sem) => _SemestreExpansion(cs: cs, semestre: sem)),

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

// ── Modelo de retícula ────────────────────────────────────────
class _Reticula {
  final String clave, nombre, url;
  const _Reticula({required this.clave, required this.nombre, required this.url});
}

// Las tres retículas comparten la clave base ITIC-2010-225;
// cada URL apunta a la especialidad concreta en el servidor del campus.
const _reticulas = [
  _Reticula(
    clave: 'ITIC-2010-225',
    nombre: 'Gestión de Datos',
    url: 'http://cc.villahermosa.tecnm.mx/sys/estpro/reticulas/ITIC-2010-225--ITIE-GDD-2023-01.pdf',
  ),
  _Reticula(
    clave: 'ITIC-2010-225',
    nombre: 'Desarrollo de Aplicaciones Multiplataforma',
    url: 'http://cc.villahermosa.tecnm.mx/sys/estpro/reticulas/ITIC-2010-225--ITIE-DAM-2023-02.pdf',
  ),
  _Reticula(
    clave: 'ITIC-2010-225',
    nombre: 'Infraestructura y Seguridad en Redes',
    url: 'http://cc.villahermosa.tecnm.mx/sys/estpro/reticulas/ITIC-2010-225--ITIE-ISR-2023-03.pdf',
  ),
];

// ── Modelo de materia ─────────────────────────────────────────
class _Materia {
  final String nombre, url;
  const _Materia(this.nombre, this.url);
}

// ── Modelo de semestre ────────────────────────────────────────
class _Semestre {
  final int numero;
  final List<_Materia> materias;
  const _Semestre(this.numero, this.materias);
}

// URL base de los temarios de ITIC; las especialidades reutilizan
// la carpeta de ISC porque los planes de especialidad son compartidos.
const _base = 'https://villahermosa.tecnm.mx/docs/oferta/ingtic/temario2010';
const _esp  = 'https://villahermosa.tecnm.mx/docs/oferta/ingsistemas/especialidades';

final _semestres = [
  _Semestre(1, [
    _Materia('Cálculo Diferencial',          '$_base/1semestre/CalculoDiferencial-AC001.pdf'),
    _Materia('Fundamentos de Programación',  '$_base/1semestre/FundamentosdeProgramacion-AEF-1032.pdf'),
    _Materia('Matemáticas Discretas I',      '$_base/1semestre/MatematicasDiscretas-I.pdf'),
    _Materia('Introducción a las TIC\'s',    '$_base/1semestre/IntroduccionalasTICs.pdf'),
    _Materia('Taller de Ética',              '$_base/1semestre/TallerdeEtica-AC007.pdf'),
    _Materia('Fundamentos de Investigación', '$_base/1semestre/FundamentosdeInvestigacion-AC006.pdf'),
  ]),
  _Semestre(2, [
    _Materia('Cálculo Integral',               '$_base/2semestre/CalculoIntegral-AC002.pdf'),
    _Materia('Programación Orientada a Objetos','$_base/2semestre/ProgramacionOrientadaaObjetos-AE054.pdf'),
    _Materia('Matemáticas Discretas II',       '$_base/2semestre/MatematicasDiscretas-II.pdf'),
    _Materia('Álgebra Lineal',                 '$_base/2semestre/AlgebraLineal-AC003.pdf'),
    _Materia('Probabilidad y Estadística',     '$_base/2semestre/ProbabilidadyEstadistica-AE052.pdf'),
    _Materia('Contabilidad y Costos',          '$_base/2semestre/ContabilidadyCostos.pdf'),
  ]),
  _Semestre(3, [
    _Materia('Estructuras y Organización de Datos',    '$_base/3semestre/EstructurasyOrganizaciondeDatos.pdf'),
    _Materia('Matemáticas para la Toma de Decisiones', '$_base/3semestre/MatematicasparalaTomadeDecisiones.pdf'),
    _Materia('Fundamentos de Base de Datos',           '$_base/3semestre/FundamentosdeBasedeDatos-AE031.pdf'),
    _Materia('Electricidad y Magnetismo',              '$_base/3semestre/ElectricidadyMagnetismo.pdf'),
    _Materia('Administración Gerencial',               '$_base/3semestre/AdministracionGerencial.pdf'),
  ]),
  _Semestre(4, [
    _Materia('Matemáticas Aplicadas a Comunicaciones', '$_base/4semestre/MatematicasAplicadasaComunicaciones.pdf'),
    _Materia('Programación II',                        '$_base/4semestre/Programacion-II.pdf'),
    _Materia('Fundamentos de Redes',                   '$_base/4semestre/FundamentosdeRedes.pdf'),
    _Materia('Taller de Base de Datos',                '$_base/4semestre/TallerdeBasedeDatos-AE063.pdf'),
    _Materia('Circuitos Eléctricos y Electrónicos',    '$_base/4semestre/CircuitosElectricosyElectronicos.pdf'),
    _Materia('Ingeniería de Software',                 '$_base/4semestre/IngenieriadeSoftware.pdf'),
  ]),
  _Semestre(5, [
    _Materia('Análisis de Señales y Sistemas de Comunicación', '$_base/5semestre/AnalisisdeSenalesySistemasdeComunicacion.pdf'),
    _Materia('Administración de Proyectos',                    '$_base/5semestre/AdministraciOndeProyectos.pdf'),
    _Materia('Redes de Computadoras',                          '$_base/5semestre/RedesdeComputadoras.pdf'),
    _Materia('Base de Datos Distribuidas',                     '$_base/5semestre/BasesdeDatosDistribuidas.pdf'),
    _Materia('Arquitectura de Computadoras',                   '$_base/5semestre/ArquitecturadeComputadoras.pdf'),
    _Materia('Taller de Ingeniería de Software',               '$_base/5semestre/TallerdeIngenieriadeSoftware.pdf'),
  ]),
  _Semestre(6, [
    _Materia('Telecomunicaciones',         '$_base/6semestre/Telecomunicaciones.pdf'),
    _Materia('Programación Web',           '$_base/6semestre/ProgramacionWeb-AE055.pdf'),
    _Materia('Desarrollo de Emprendedores','$_base/6semestre/Desarrollo%20de%20Emprendedores.pdf'),
    _Materia('Sistemas Operativos I',      '$_base/6semestre/SistemasOperativos-I-AE061.pdf'),
    _Materia('Desarrollo Sustentable',     '$_base/6semestre/DesarrolloSustentable-AC008.pdf'),
    _Materia('Tecnologías Inalámbricas',   '$_base/6semestre/TecnologiasInalambricas.pdf'),
  ]),
  _Semestre(7, [
    _Materia('Redes Emergentes',                             '$_base/7semestre/RedesEmergentes.pdf'),
    _Materia('Desarrollo de Apps para Disp. Móviles',        '$_base/7semestre/DesarrolloAplicacionesDispositivosMoviles-AE011.pdf'),
    _Materia('Taller de Investigación I',                    '$_base/7semestre/TallerdeInvestigacion-I-AC009.pdf'),
    _Materia('Sistemas Operativos II',                       '$_base/7semestre/SistemasOperativos-II-AE062.pdf'),
    _Materia('Negocios Electrónicos I',                      '$_base/7semestre/NegociosElectronicos%20I.pdf'),
    _Materia('Interacción Humano Computadora',               '$_base/7semestre/InteraccionHumanoComputadora.pdf'),
  ]),
  _Semestre(8, [
    _Materia('Administración y Seguridad de Redes',        '$_base/8semestre/AdministracionySeguridaddeRedes.pdf'),
    _Materia('Auditoría en Tecnologías de la Información', '$_base/8semestre/AuditoriaenTecnologiasdelaInformacion.pdf'),
    _Materia('Taller de Investigación II',                 '$_base/8semestre/TallerdeInvestigacionII-AC010.pdf'),
    _Materia('Ingeniería del Conocimiento',                '$_base/8semestre/IngenieriadelConocimiento.pdf'),
    _Materia('Negocios Electrónicos II',                   '$_base/8semestre/NegociosElectronicos-II.pdf'),
  ]),
  // 9no semestre: actividades institucionales sin PDF de temario.
  // La entrada 'Especialidad' tampoco tiene URL porque se elige
  // en función de la retícula seleccionada por el alumno.
  _Semestre(9, [
    _Materia('Especialidad',                ''),
    _Materia('Residencia Profesional',      ''),
    _Materia('Servicio Social',             ''),
    _Materia('Actividades Complementarias', ''),
  ]),
];


// ── Modelo de especialidad ────────────────────────────────────
// El color se recibe como función (ColorScheme) → Color para
// poder resolverse en tiempo de build con el tema activo.
class _Especialidad {
  final String nombre;
  final IconData icono;
  final Color Function(ColorScheme) color;
  final List<_Materia> materias;
  const _Especialidad({required this.nombre, required this.icono, required this.color, required this.materias});
}

final _especialidades = [
  _Especialidad(
    nombre: 'Gestión de Redes y Mejoramiento de la Seguridad',
    icono: Icons.router_rounded,
    color: (cs) => cs.primary,
    materias: [
      _Materia('Infraestructura de Telecomunicaciones', '$_esp/GESTION_DE_REDES_Y_MEJORAMIENTO_DE_LA_SEGURIDAD/Infraestructura_de_Telecomunicaciones.pdf'),
      _Materia('Redes Convergentes',                   '$_esp/GESTION_DE_REDES_Y_MEJORAMIENTO_DE_LA_SEGURIDAD/Redes_Convergentes.pdf'),
      _Materia('Redes Inalámbricas',                   '$_esp/GESTION_DE_REDES_Y_MEJORAMIENTO_DE_LA_SEGURIDAD/Redes_Inalambricas.pdf'),
      _Materia('Seguridad en Redes',                   '$_esp/GESTION_DE_REDES_Y_MEJORAMIENTO_DE_LA_SEGURIDAD/Seguridad_en_Redes.pdf'),
      _Materia('Tópicos Selectos de Seguridad',        '$_esp/GESTION_DE_REDES_Y_MEJORAMIENTO_DE_LA_SEGURIDAD/Topicos_Selectos.pdf'),
    ],
  ),
  _Especialidad(
    nombre: 'Tecnologías de Base de Datos',
    icono: Icons.storage_rounded,
    color: (cs) => cs.secondary,
    materias: [
      _Materia('Nuevos Paradigmas de Base de Datos',     '$_esp/TECNOLOGIAS_DE_BASE_DE_DATOS/Nuevos_Paradigmas_de_Base_de_Datos.pdf'),
      _Materia('Base de Datos NoSQL',                    '$_esp/TECNOLOGIAS_DE_BASE_DE_DATOS/Base_de_Datos_NoSQL.pdf'),
      _Materia('Tecnologías de Big Data',                '$_esp/TECNOLOGIAS_DE_BASE_DE_DATOS/Tecnologias_de_Big_Data.pdf'),
      _Materia('Tratamiento de Datos',                   '$_esp/TECNOLOGIAS_DE_BASE_DE_DATOS/Tratamiento_de_Datos.pdf'),
      _Materia('Diseño y Construcción de Data Warehouse','$_esp/TECNOLOGIAS_DE_BASE_DE_DATOS/Diseno_y_Construccion_de_Data_WareHouse.pdf'),
    ],
  ),
  _Especialidad(
    nombre: 'Tecnologías y Aplicaciones Multiplataforma',
    icono: Icons.devices_rounded,
    color: (cs) => cs.tertiary,
    materias: [
      _Materia('Tópicos de Desarrollo de Aplicaciones', '$_esp/TECNOLOGIAS_Y_APLICACIONES_MULTIPLATAFORMA/Topicos_de_Desarrollo_de_Aplicaciones.pdf'),
      _Materia('Desarrollo de Apps para Móviles',       '$_esp/TECNOLOGIAS_Y_APLICACIONES_MULTIPLATAFORMA/Desarrollo_de_Aplicaciones_para_Dispositivos_Moviles.pdf'),
      _Materia('Arquitectura Orientada a Servicios',    '$_esp/TECNOLOGIAS_Y_APLICACIONES_MULTIPLATAFORMA/Arquitectura_Orientada_a_Servicios.pdf'),
      _Materia('Nuevas Tecnologías para Aplicaciones',  '$_esp/TECNOLOGIAS_Y_APLICACIONES_MULTIPLATAFORMA/Nuevas_Tecnologias_para_Desarrollo_de_Aplicaciones.pdf'),
      _Materia('Seguridad, Producción y Despliegue',    '$_esp/TECNOLOGIAS_Y_APLICACIONES_MULTIPLATAFORMA/Seguridad_Produccion_y_Despliegue_de_Aplicaciones.pdf'),
      _Materia('Diseño de Interfaces',                  '$_esp/TECNOLOGIAS_Y_APLICACIONES_MULTIPLATAFORMA/Diseno_de_Interfaces.pdf'),
      _Materia('Metodologías para Desarrollo Ágil',     '$_esp/TECNOLOGIAS_Y_APLICACIONES_MULTIPLATAFORMA/Metodologias_para_el_Desarrollo_Agil.pdf'),
    ],
  ),
];


// ═════════════════════════════════════════════════════════════════
// WIDGETS PRIVADOS
// ═════════════════════════════════════════════════════════════════

/// Chips de empresas/sectores relevantes para el egresado de ITIC.
/// Usa cs.secondary como acento para mantener coherencia con el
/// resto de la pantalla.
class _CampoLaboralSection extends StatelessWidget {
  final ColorScheme cs;
  const _CampoLaboralSection({required this.cs});

  // Tuplas (ícono, etiqueta) para los chips de empresas destacadas.
  static const _empresas = [
    (Icons.window_rounded,  'Microsoft'),
    (Icons.search_rounded,  'Google'),
    (Icons.dns_rounded,     'NIC México'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Egresados con perfil para integrarse a empresas tecnológicas de nivel mundial y organizaciones del sector TI en áreas de desarrollo, redes, seguridad, consultoría y emprendimiento.',
          style: TextStyle(fontSize: 13, height: 1.6, color: cs.onSurface.withValues(alpha:0.75)),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _empresas.map((e) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: cs.secondary.withValues(alpha:0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cs.secondary.withValues(alpha:0.2)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(e.$1, size: 16, color: cs.secondary),
              const SizedBox(width: 6),
              Text(e.$2,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.secondary)),
            ]),
          )).toList(),
        ),
      ],
    );
  }
}

/// Tile expandible que muestra las materias de un semestre.
/// Las materias sin URL renderizan con ícono de info en lugar
/// de PDF para no generar navegación vacía.
class _SemestreExpansion extends StatelessWidget {
  final ColorScheme cs;
  final _Semestre semestre;
  const _SemestreExpansion({required this.cs, required this.semestre});

  static const _ordinal = ['', '1er', '2do', '3er', '4to', '5to', '6to', '7mo', '8vo', '9no'];

  @override
  Widget build(BuildContext context) {
    final ord = _ordinal[semestre.numero];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Theme(
          // Eliminar el Divider que Flutter agrega por defecto al expandir.
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            backgroundColor: cs.secondary.withValues(alpha:0.05),
            collapsedBackgroundColor: cs.secondary.withValues(alpha:0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.secondary.withValues(alpha:0.12)),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outline.withValues(alpha:0.12)),
            ),
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: cs.secondary.withValues(alpha:0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('${semestre.numero}',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.secondary)),
              ),
            ),
            title: Text('$ord Semestre',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
            subtitle: Text('${semestre.materias.length} materias',
                style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha:0.45))),
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
            backgroundColor: color.withValues(alpha:0.05),
            collapsedBackgroundColor: color.withValues(alpha:0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: color.withValues(alpha:0.15)),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outline.withValues(alpha:0.12)),
            ),
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha:0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(especialidad.icono, color: color, size: 20),
            ),
            title: Text(especialidad.nombre,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
            subtitle: Text('${especialidad.materias.length} materias',
                style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha:0.45))),
            children: especialidad.materias.map((m) => _MateriaItem(cs: cs, materia: m)).toList(),
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
                color: cs.secondary.withValues(alpha:0.5),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(materia.nombre,
                  style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha:0.8)))),
              if (hasUrl)
                Icon(Icons.chevron_right_rounded, size: 18, color: cs.onSurface.withValues(alpha:0.25)),
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
/// Usa cs.secondary como color de acento, coherente con los
/// tiles de semestre de esta pantalla.
class _SectionTitle extends StatelessWidget {
  final ColorScheme cs;
  final String texto;
  const _SectionTitle({required this.cs, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 4, height: 18,
        decoration: BoxDecoration(color: cs.secondary, borderRadius: BorderRadius.circular(2)),
      ),
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
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(width: 6, height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(item,
              style: TextStyle(fontSize: 13, height: 1.6, color: cs.onSurface.withValues(alpha:0.75)))),
        ]),
      )).toList(),
    );
  }
}

/// Card tappable que abre PdfViewerScreen con la retícula correspondiente.
/// Muestra el nombre de la especialidad, la clave y un ícono de PDF.
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
              border: Border.all(color: cs.outline.withValues(alpha:0.15)),
            ),
            child: Row(children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: cs.secondary.withValues(alpha:0.12),
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
                    style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha:0.4), letterSpacing: 0.2)),
              ])),
              Icon(Icons.picture_as_pdf_rounded, color: cs.secondary.withValues(alpha:0.5), size: 20),
            ]),
          ),
        ),
      ),
    );
  }
}