// ═════════════════════════════════════════════════════════════════
// ISC.dart
//
// Pantalla informativa de la Ingeniería en Sistemas Computacionales.
//
// Secciones:
//   • Misión y Visión      — dos cards lado a lado
//   • Objetivo General     — descripción del propósito de la carrera
//   • Objetivos Específicos — siete competencias numeradas
//   • Perfil de Ingreso    — características deseables del aspirante
//   • Perfil de Egreso     — competencias del profesional al egresar
//   • Retículas 2010-224   — tres especialidades con enlace a PDF
//   • Plan de Estudios     — ExpansionTile por semestre (1–9)
//   • Especialidades       — ExpansionTile por especialidad con materias
//
// Widgets privados de esta pantalla:
//   • _SemestreExpansion     — tile expandible de un semestre
//   • _EspecialidadExpansion — tile expandible de una especialidad
//   • _MateriaItem           — fila tappable que abre PdfViewerScreen
//   • _SectionTitle          — título con barra de acento del ColorScheme
//   • _InfoCard              — card de Misión/Visión con ícono y color
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
// Nota: los colores de acento se toman del ColorScheme del tema
// (cs.primary, cs.secondary, cs.tertiary) para respetar el tema
// dinámico de la app, a diferencia de carreras con color fijo.
// ═════════════════════════════════════════════════════════════════

import 'package:aspirantes_itvh_app/drawer/Carreras/pdf_viewer_screen.dart';
import 'package:flutter/material.dart';

class ISCScreen extends StatelessWidget {
  const ISCScreen({super.key});

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
            title: Text('',
                style: TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.bold,
                    color:      cs.onSurface)),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: cs.primary.withValues(alpha: 0.12)),
                  Positioned(
                    right: -30, top: -20,
                    child: Icon(Icons.computer_rounded,
                        size:  220,
                        color: cs.primary.withValues(alpha: 0.07)),
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
                          color:        cs.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Departamento de Sistemas y Computación',
                          style: TextStyle(
                              fontSize:   11,
                              fontWeight: FontWeight.w600,
                              color:      cs.primary),
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
                        'Ing. en Sistemas Computacionales',
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

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // Misión y Visión en dos cards lado a lado.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _InfoCard(
                      cs:       cs,
                      icono:    Icons.flag_rounded,
                      titulo:   'Misión',
                      contenido: 'Formar Ingenieros en Sistemas Computacionales que desarrollen e impulsen soluciones innovadoras para los desafíos tecnológicos de la región.',
                      color:    cs.primary,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _InfoCard(
                      cs:       cs,
                      icono:    Icons.visibility_rounded,
                      titulo:   'Visión',
                      contenido: 'Ser una carrera reconocida en Tabasco y en un entorno global, por su excelencia profesional y aportación al desarrollo tecnológico computacional.',
                      color:    cs.tertiary,
                    )),
                  ],
                ),

                const SizedBox(height: 28),

                _SectionTitle(cs: cs, texto: 'Objetivo General'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:        cs.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(16),
                    border:       Border.all(
                        color: cs.primary.withValues(alpha: 0.15)),
                  ),
                  child: Text(
                    'Formar profesionistas líderes con visión estratégica y amplio sentido ético; capaces de diseñar, desarrollar, implementar y administrar tecnología computacional para aportar soluciones innovadoras en beneficio de la sociedad; en un contexto global, multidisciplinario y sostenible.',
                    style: TextStyle(
                        fontSize: 14,
                        height:   1.65,
                        color:    cs.onSurface.withValues(alpha: 0.8)),
                  ),
                ),

                const SizedBox(height: 28),

                _SectionTitle(cs: cs, texto: 'Objetivos Específicos'),
                const SizedBox(height: 12),
                ..._objetivos.map((obj) => _ObjetivoItem(
                    cs: cs, numero: obj.$1, titulo: obj.$2, descripcion: obj.$3)),

                const SizedBox(height: 28),

                _SectionTitle(cs: cs, texto: 'Perfil de Ingreso'),
                const SizedBox(height: 12),
                _PerfilSection(cs: cs, color: cs.secondary, items: const [
                  'Capacidad para la investigación, análisis y síntesis de información.',
                  'Interés en las ciencias básicas y tecnologías de cómputo.',
                  'Gusto por las tecnologías de información y comunicación.',
                  'Disposición para la interacción y el trabajo en equipo.',
                  'Habilidad para la toma de decisiones.',
                  'Conocimientos de inglés.',
                ]),

                const SizedBox(height: 28),

                _SectionTitle(cs: cs, texto: 'Perfil de Egreso'),
                const SizedBox(height: 12),
                _PerfilSection(cs: cs, color: cs.tertiary, items: const [
                  'Implementa aplicaciones computacionales integrando diferentes tecnologías, plataformas o dispositivos.',
                  'Diseña, desarrolla y aplica modelos computacionales mediante herramientas matemáticas.',
                  'Diseña e implementa interfaces para automatización de sistemas de hardware y software.',
                  'Coordina equipos multidisciplinarios para aplicar soluciones innovadoras.',
                  'Diseña, implementa y administra bases de datos conforme a normas de seguridad.',
                  'Desarrolla y administra software cumpliendo estándares de calidad.',
                  'Evalúa tecnologías de hardware para soportar aplicaciones de manera efectiva.',
                  'Detecta áreas de oportunidad con visión empresarial aplicando TIC.',
                  'Diseña, configura y administra redes de computadoras aplicando normas vigentes.',
                ]),

                const SizedBox(height: 28),

                _SectionTitle(cs: cs, texto: 'Retículas 2010-224'),
                const SizedBox(height: 12),
                ..._reticulas.map((r) => _ReticulaItem(cs: cs, reticula: r)),

                const SizedBox(height: 28),

                _SectionTitle(cs: cs, texto: 'Plan de Estudios'),
                const SizedBox(height: 12),
                ..._semestres.map((sem) => _SemestreExpansion(
                    cs: cs, semestre: sem)),

                const SizedBox(height: 20),

                _SectionTitle(cs: cs, texto: 'Especialidades'),
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
// DATOS
// ═════════════════════════════════════════════════════════════════

const _objetivos = [
  (1, 'Resolver Problemas', 'Desarrollar e implementar aplicaciones computacionales para solucionar problemas de diversos contextos, integrando diferentes tecnologías, plataformas o dispositivos.'),
  (2, 'Saber Diseñar',      'Analizar, diseñar y aplicar modelos computacionales para solucionar problemas, mediante la selección y uso de herramientas tecnológicas.'),
  (3, 'Hacer Experimentos', 'Desarrollar y administrar recursos tecnológicos para incrementar la productividad y competitividad de las organizaciones cumpliendo con normas nacionales e internacionales.'),
  (4, 'Saber Comunicarse',  'Construir proyectos innovadores aplicando las TIC con una visión emprendedora e intercultural.'),
  (5, 'Ser Ético',          'Desarrollar conciencia sobre el significado y sentido de la ética para orientar un comportamiento armónico en el contexto comunitario y profesional.'),
  (6, 'Actualizarse',       'Actualizar conocimientos profesionales para responder a las demandas de los cambios globales.'),
  (7, 'Trabajar en Equipo', 'Participar en equipos multidisciplinarios para el desarrollo de soluciones innovadoras y sostenibles en diferentes contextos.'),
];

class _Reticula {
  final String clave, nombre, url;
  const _Reticula({required this.clave, required this.nombre, required this.url});
}

const _reticulas = [
  _Reticula(clave: 'ISIC-2010-224--ISIE-GDD-2023-01', nombre: 'Gestión de Datos',
      url: 'https://pub-f883231412d746839d3a41f6bc354031.r2.dev/ISIC/ISIC-2010-224--ISIE-GDD-2023-01.pdf'),
  _Reticula(clave: 'ISIC-2010-224--ISIE-DAM-2023-02', nombre: 'Desarrollo de Aplicaciones Multiplataforma',
      url: 'https://pub-f883231412d746839d3a41f6bc354031.r2.dev/ISIC/ISIC-2010-224--ISIE-DAM-2023-02.pdf'),
  _Reticula(clave: 'ISIC-2010-224--ISIE-ISR-2023-03', nombre: 'Infraestructura y Seguridad en Redes',
      url: 'https://pub-f883231412d746839d3a41f6bc354031.r2.dev/ISIC/ISIC-2010-224--ISIE-ISR-2023-03.pdf'),
];

class _Materia {
  final String nombre, url;
  const _Materia(this.nombre, this.url);
}

class _Semestre {
  final int            numero;
  final List<_Materia> materias;
  const _Semestre(this.numero, this.materias);
}

// URL base de los temarios para no repetirla en cada _Materia.
const _base = 'https://villahermosa.tecnm.mx/docs/oferta/ingsistemas/temario2010';
const _esp  = 'https://villahermosa.tecnm.mx/docs/oferta/ingsistemas/especialidades';

final _semestres = [
  _Semestre(1, [
    _Materia('Cálculo Diferencial',         '$_base/1semestre/CalculoDiferencial-AC001.pdf'),
    _Materia('Fundamentos de Programación', '$_base/1semestre/FundamentosdeProgramacion-AED-1285.pdf'),
    _Materia('Taller de Ética',             '$_base/1semestre/TallerdeEtica-AC007.pdf'),
    _Materia('Matemáticas Discretas',       '$_base/1semestre/MatematicasDiscretas-AE041.pdf'),
    _Materia('Taller de Administración',    '$_base/1semestre/TallerdeAdministracion.pdf'),
    _Materia('Fundamentos de Investigación','$_base/1semestre/FundamentosdeInvestigacion-AC006.pdf'),
  ]),
  _Semestre(2, [
    _Materia('Cálculo Integral',               '$_base/2semestre/CalculoIntegral-AC002.pdf'),
    _Materia('Programación Orientada a Objetos','$_base/2semestre/ProgramacionOrientadaaObjetos-AED-1286.pdf'),
    _Materia('Contabilidad Financiera',        '$_base/2semestre/ContabilidadFinanciera-AE008.pdf'),
    _Materia('Química',                        '$_base/2semestre/Quimica-AE058.pdf'),
    _Materia('Álgebra Lineal',                 '$_base/2semestre/AlgebraLineal-AC003.pdf'),
    _Materia('Probabilidad y Estadística',     '$_base/2semestre/ProbabilidadyEstadistica-AE052.pdf'),
  ]),
  _Semestre(3, [
    _Materia('Cálculo Vectorial',           '$_base/3semestre/CalculoVectorial-AC004.pdf'),
    _Materia('Estructura de Datos',         '$_base/3semestre/EstructuradeDatos-AE026.pdf'),
    _Materia('Cultura Empresarial',         '$_base/3semestre/CulturaEmpresarial.pdf'),
    _Materia('Investigación de Operaciones','$_base/3semestre/Investigaciondeoperaciones.pdf'),
    _Materia('Desarrollo Sustentable',      '$_base/3semestre/DesarrolloSustentable-AC008.pdf'),
    _Materia('Física General',              '$_base/3semestre/FisicaGeneral.pdf'),
  ]),
  _Semestre(4, [
    _Materia('Ecuaciones Diferenciales',                '$_base/4semestre/EcuacionesDiferenciales-AC005.pdf'),
    _Materia('Métodos Numéricos',                       '$_base/4semestre/Metodosnumericos.pdf'),
    _Materia('Tópicos Avanzados de Programación',       '$_base/4semestre/TopicosAvanzadosdeProgramacion.pdf'),
    _Materia('Fundamentos de Bases de Datos',           '$_base/4semestre/FundamentosdeBasedeDatos-AE031.pdf'),
    _Materia('Simulación',                              '$_base/4semestre/Simulacion.pdf'),
    _Materia('Principios Eléctricos y Aplic. Digitales','$_base/4semestre/PrincipiosElectricosyAplicacionesDigitales.pdf'),
  ]),
  _Semestre(5, [
    _Materia('Graficación',                       '$_base/5semestre/Graficacion.pdf'),
    _Materia('Fundamentos de Telecomunicaciones', '$_base/5semestre/FundamentosdeTelecomunicaciones-AE034.pdf'),
    _Materia('Sistemas Operativos',               '$_base/5semestre/SistemasOperativosI-AE061.pdf'),
    _Materia('Taller de Bases de Datos',          '$_base/5semestre/Tallerdebasededatos.pdf'),
    _Materia('Fundamentos de Ing. de Software',   '$_base/5semestre/FundamentosdeIngenieriadeSoftware.pdf'),
    _Materia('Arquitectura de Computadoras',      '$_base/5semestre/ArquitecturadeComputadoras.pdf'),
  ]),
  _Semestre(6, [
    _Materia('Lenguajes y Autómatas I',         '$_base/6semestre/LenguajesyAutomatasI.pdf'),
    _Materia('Redes de Computadoras',           '$_base/6semestre/RedesdeComputadoras.pdf'),
    _Materia('Taller de Sistemas Operativos',   '$_base/6semestre/TallerdeSistemasOperativos.pdf'),
    _Materia('Administración de Bases de Datos','$_base/6semestre/AdministraciondeBasedeDatos.pdf'),
    _Materia('Ingeniería de Software',          '$_base/6semestre/IngenieriadeSoftware.pdf'),
    _Materia('Lenguajes de Interfaz',           '$_base/6semestre/LenguajesdeInterfaz.pdf'),
  ]),
  _Semestre(7, [
    _Materia('Lenguajes y Autómatas II',            '$_base/7semestre/LenguajesyAutomatasII.pdf'),
    _Materia('Conmutación y Enrutamiento de Redes', '$_base/7semestre/ConmutacionyEnrutamientoenRedesdeDatos.pdf'),
    _Materia('Taller de Investigación I',           '$_base/7semestre/TallerdeInvestigacionI-AC009.pdf'),
    _Materia('Gestión de Proyectos de Software',    '$_base/7semestre/GestiondeProyectosdeSoftware.pdf'),
    _Materia('Sistemas Programables',               '$_base/7semestre/SistemasProgramables.pdf'),
  ]),
  _Semestre(8, [
    _Materia('Programación Lógica y Funcional', '$_base/8semestre/ProgramacionLogicayFuncional.pdf'),
    _Materia('Administración de Redes',         '$_base/8semestre/Administracionderedes.pdf'),
    _Materia('Taller de Investigación II',      '$_base/8semestre/TallerdeInvestigacionII-AC010.pdf'),
    _Materia('Programación Web',                '$_base/8semestre/AE055ProgramacionWeb.pdf'),
  ]),
  // 9no semestre: Inteligencia Artificial tiene PDF; el resto son
  // actividades institucionales sin temario descargable.
  _Semestre(9, [
    _Materia('Inteligencia Artificial',     '$_base/9semestre/InteligenciaArtificial.pdf'),
    _Materia('Residencia Profesional',      ''),
    _Materia('Servicio Social',             ''),
    _Materia('Actividades Complementarias', ''),
  ]),
];

// ── Modelo de especialidad ────────────────────────────────────
// El color se recibe como función (ColorScheme) → Color para
// poder resolverse en tiempo de build con el tema activo.
class _Especialidad {
  final String                     nombre;
  final IconData                   icono;
  final Color Function(ColorScheme) color;
  final List<_Materia>             materias;
  const _Especialidad({
    required this.nombre,
    required this.icono,
    required this.color,
    required this.materias,
  });
}

final _especialidades = [
  _Especialidad(
    nombre: 'Gestión de Redes y Mejoramiento de la Seguridad',
    icono:  Icons.router_rounded,
    color:  (cs) => cs.primary,
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
    icono:  Icons.storage_rounded,
    color:  (cs) => cs.secondary,
    materias: [
      _Materia('Nuevos Paradigmas de Base de Datos',      '$_esp/TECNOLOGIAS_DE_BASE_DE_DATOS/Nuevos_Paradigmas_de_Base_de_Datos.pdf'),
      _Materia('Base de Datos NoSQL',                     '$_esp/TECNOLOGIAS_DE_BASE_DE_DATOS/Base_de_Datos_NoSQL.pdf'),
      _Materia('Tecnologías de Big Data',                 '$_esp/TECNOLOGIAS_DE_BASE_DE_DATOS/Tecnologias_de_Big_Data.pdf'),
      _Materia('Tratamiento de Datos',                    '$_esp/TECNOLOGIAS_DE_BASE_DE_DATOS/Tratamiento_de_Datos.pdf'),
      _Materia('Diseño y Construcción de Data Warehouse', '$_esp/TECNOLOGIAS_DE_BASE_DE_DATOS/Diseno_y_Construccion_de_Data_WareHouse.pdf'),
    ],
  ),
  _Especialidad(
    nombre: 'Tecnologías y Aplicaciones Multiplataforma',
    icono:  Icons.devices_rounded,
    color:  (cs) => cs.tertiary,
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

/// Tile expandible que muestra las materias de un semestre.
/// Las materias sin URL renderizan con ícono de info en lugar
/// de PDF para no generar navegación vacía.
class _SemestreExpansion extends StatelessWidget {
  final ColorScheme cs;
  final _Semestre   semestre;
  const _SemestreExpansion({required this.cs, required this.semestre});

  static const _ordinal = ['','1er','2do','3er','4to','5to','6to','7mo','8vo','9no'];

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
                    style: TextStyle(
                        fontSize:   15,
                        fontWeight: FontWeight.bold,
                        color:      cs.primary)),
              ),
            ),
            title: Text('$ord Semestre',
                style: TextStyle(
                    fontSize:   14,
                    fontWeight: FontWeight.w600,
                    color:      cs.onSurface)),
            subtitle: Text('${semestre.materias.length} materias',
                style: TextStyle(
                    fontSize: 11,
                    color:    cs.onSurface.withValues(alpha: 0.45))),
            children: semestre.materias
                .map((m) => _MateriaItem(cs: cs, materia: m))
                .toList(),
          ),
        ),
      ),
    );
  }
}

/// Tile expandible que muestra las materias de una especialidad.
/// El color se resuelve en build con el ColorScheme activo.
class _EspecialidadExpansion extends StatelessWidget {
  final ColorScheme   cs;
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
            subtitle: Text('${especialidad.materias.length} materias',
                style: TextStyle(
                    fontSize: 11,
                    color:    cs.onSurface.withValues(alpha: 0.45))),
            children: especialidad.materias
                .map((m) => _MateriaItem(cs: cs, materia: m))
                .toList(),
          ),
        ),
      ),
    );
  }
}

/// Fila tappable que navega a PdfViewerScreen con el temario.
/// Si la materia no tiene URL, deshabilita el tap y cambia el ícono.
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
              hasUrl ? Icons.picture_as_pdf_rounded : Icons.info_outline_rounded,
              size:  18,
              color: cs.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(materia.nombre,
                style: TextStyle(
                    fontSize: 13,
                    color:    cs.onSurface.withValues(alpha: 0.8)))),
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

/// Título de sección con barra vertical de acento (4 × 18 px).
class _SectionTitle extends StatelessWidget {
  final ColorScheme cs;
  final String      texto;
  const _SectionTitle({required this.cs, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 4, height: 18,
        decoration: BoxDecoration(
          color:        cs.primary,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 10),
      Text(texto,
          style: TextStyle(
              fontSize:   17,
              fontWeight: FontWeight.bold,
              color:      cs.onSurface)),
    ]);
  }
}

/// Card compacta para Misión y Visión con ícono, título y texto.
class _InfoCard extends StatelessWidget {
  final ColorScheme cs;
  final IconData    icono;
  final String      titulo, contenido;
  final Color       color;
  const _InfoCard({
    required this.cs,
    required this.icono,
    required this.titulo,
    required this.contenido,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icono, color: color, size: 22),
        const SizedBox(height: 8),
        Text(titulo,
            style: TextStyle(
                fontSize:   14,
                fontWeight: FontWeight.bold,
                color:      color)),
        const SizedBox(height: 6),
        Text(contenido,
            style: TextStyle(
                fontSize: 12,
                height:   1.55,
                color:    cs.onSurface.withValues(alpha: 0.7))),
      ]),
    );
  }
}

/// Fila numerada con círculo de acento, título en negrita y descripción.
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
            color: cs.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(child: Text('$numero',
              style: TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.bold,
                  color:      cs.primary))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
        ])),
      ]),
    );
  }
}

/// Lista de bullets con punto circular de color seguido del texto.
class _PerfilSection extends StatelessWidget {
  final ColorScheme  cs;
  final Color        color;
  final List<String> items;
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
          // padding top: 5 alinea el punto con la primera línea del texto.
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 6, height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(item,
              style: TextStyle(
                  fontSize: 13,
                  height:   1.6,
                  color:    cs.onSurface.withValues(alpha: 0.75)))),
        ]),
      )).toList(),
    );
  }
}

/// Card tappable que abre PdfViewerScreen con la retícula.
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
                  color:        cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.grid_view_rounded,
                    color: cs.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
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
              )),
              Icon(Icons.picture_as_pdf_rounded,
                  color: cs.primary.withValues(alpha: 0.5), size: 20),
            ]),
          ),
        ),
      ),
    );
  }
}