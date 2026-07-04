// ═════════════════════════════════════════════════════════════════
// IINF.dart
//
// Pantalla informativa de la Ingeniería Informática (IINF).
//
// Secciones:
//   • Cards resumen        — Objetivo General y Campo Laboral en dos
//                            cards lado a lado (vista rápida)
//   • Objetivo General     — descripción completa del propósito
//   • Perfil de Ingreso    — características deseables del aspirante
//   • Perfil de Egreso     — competencias del profesional al egresar
//   • Campo Laboral        — sectores de inserción profesional
//   • Retícula IINF-2010-220 — tres especialidades con enlace a PDF
//   • Plan de Estudios     — ExpansionTile por semestre (1–9)
//   • Especialidades       — ExpansionTile por especialidad con materias
//
// Widgets privados de esta pantalla:
//   • _SemestreExpansion     — tile expandible de un semestre;
//                              usa cs.tertiary como acento (distinto
//                              al cs.primary de la mayoría de carreras)
//   • _EspecialidadExpansion — tile expandible de una especialidad
//   • _MateriaItem           — fila tappable que abre PdfViewerScreen
//   • _MateriaInfoItem       — fila de texto (sin PDF; 9no semestre)
//   • _EspecialidadInfoCard  — card informativa sobre el 9no semestre
//                              (declarada pero no instanciada en build)
//   • _SectionTitle          — título con barra de acento cs.tertiary
//   • _InfoCard              — card de resumen con ícono y color
//   • _PerfilSection         — lista de bullets con punto de color
//   • _ReticulaItem          — card tappable que abre PdfViewerScreen
//
// Modelos de datos (privados):
//   • _Reticula    — clave, nombre y URL de una retícula
//   • _Materia     — nombre y URL de un temario en PDF
//   • _Semestre    — número, lista de materias y flag soloInformativo
//   • _Especialidad — nombre, ícono, función de color y materias
//
// Notas de implementación:
//   • IINF usa cs.tertiary como acento principal (semestres y barra de
//     sección), a diferencia de ISC e ITIC que usan cs.primary/secondary.
//     Esto le da identidad visual propia dentro del mismo departamento.
//   • Las especialidades comparten temarios con ISC.dart; la URL base
//     _esp apunta a la carpeta de ISC en el servidor del campus.
//   • El widget _EspecialidadInfoCard está definido pero no se usa en
//     el build actual; fue parte de un diseño alternativo para el 9no
//     semestre que quedó disponible para uso futuro.
//   • El campo soloInformativo en _Semestre controla si los ítems del
//     9no semestre se renderizan como _MateriaInfoItem (solo texto).
// ═════════════════════════════════════════════════════════════════

import 'package:aspirantes_itvh_app/drawer/Carreras/pdf_viewer_screen.dart';
import 'package:flutter/material.dart';

class IINFScreen extends StatelessWidget {
  const IINFScreen({super.key});

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
                  // Fondo con tinte en cs.tertiary — color de acento de IINF.
                  Container(color: cs.tertiary.withValues(alpha:0.12)),

                  // Ícono decorativo semitransparente en esquina superior derecha.
                  Positioned(
                    right: -30, top: -20,
                    child: Icon(Icons.memory_rounded, size: 220, color: cs.tertiary.withValues(alpha:0.07)),
                  ),

                  // Chip del departamento al que pertenece la carrera.
                  // padding bottom: 64 porque el nombre de carrera es
                  // más corto y el chip queda más separado del título.
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 64),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.tertiary.withValues(alpha:0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Departamento de Sistemas y Computación',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.tertiary),
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
                        'Ing. Informática',
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

                // Cards resumen lado a lado: Objetivo General y Campo Laboral.
                // Igual al patrón de ISC (Misión/Visión) e IIND (Misión/Visión),
                // pero aquí muestra resúmenes de secciones en lugar de misión/visión.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _InfoCard(
                      cs: cs,
                      icono: Icons.flag_rounded,
                      titulo: 'Objetivo General',
                      contenido: 'Formar profesionales competentes en el diseño, desarrollo, implementación y administración de proyectos informáticos con una visión sistemática, tecnológica y estratégica.',
                      color: cs.tertiary,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _InfoCard(
                      cs: cs,
                      icono: Icons.work_rounded,
                      titulo: 'Campo Laboral',
                      contenido: 'Empresas nacionales e internacionales en áreas de TI, sector público, instituciones educativas y consultoría independiente.',
                      color: cs.primary,
                    )),
                  ],
                ),

                const SizedBox(height: 28),

                // Objetivo General completo — repite el objetivo de la
                // card resumen pero con el texto íntegro del plan de estudios.
                _SectionTitle(cs: cs, texto: 'Objetivo General'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.tertiary.withValues(alpha:0.07),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.tertiary.withValues(alpha:0.15)),
                  ),
                  child: Text(
                    'Formar profesionales competentes en el diseño, desarrollo, implementación y administración de proyectos informáticos con una visión sistemática, tecnológica y estratégica; ofreciendo soluciones innovadoras e integrales a las organizaciones de acuerdo con las necesidades actuales; comprometidos con su entorno, desempeñándose con actitud ética, emprendedora y de liderazgo.',
                    style: TextStyle(fontSize: 14, height: 1.65, color: cs.onSurface.withValues(alpha:0.8)),
                  ),
                ),

                const SizedBox(height: 28),

                // Perfil de ingreso — usa cs.tertiary como acento,
                // el color principal de IINF.
                _SectionTitle(cs: cs, texto: 'Perfil de Ingreso'),
                const SizedBox(height: 12),
                _PerfilSection(cs: cs, color: cs.tertiary, items: const [
                  'Gusto por la Informática, capacidad de lógica para plantear y resolver problemas en base al razonamiento, síntesis, abstracción y creatividad.',
                  'Espíritu emprendedor.',
                  'Capacidad de adaptación.',
                  'Creatividad e innovación.',
                  'Comprometido con su entorno.',
                  'Capacidad de trabajo en equipo y de conquistar metas y objetivos.',
                ]),

                const SizedBox(height: 28),

                // Perfil de egreso — usa cs.primary para diferenciarlo
                // visualmente del perfil de ingreso.
                _SectionTitle(cs: cs, texto: 'Perfil de Egreso'),
                const SizedBox(height: 12),
                _PerfilSection(cs: cs, color: cs.primary, items: const [
                  'Aplica conocimientos científicos y tecnológicos en el área informática para la solución de problemas con un enfoque multidisciplinario.',
                  'Formula, desarrolla y gestiona el desarrollo de proyectos de software para incrementar la competitividad en las organizaciones, considerando las normas de calidad vigentes.',
                  'Aplica herramientas computacionales actuales y emergentes para optimizar los procesos en las organizaciones.',
                  'Diseña e implementa Bases de Datos para el almacenamiento, recuperación, distribución, visualización y manejo de la información en las organizaciones.',
                  'Crea y administra redes de computadoras, considerando el diseño, selección, instalación y mantenimiento para la operación eficiente de los recursos informáticos.',
                  'Realiza consultorías relacionadas con la función informática para la mejora continua de la organización.',
                  'Se desempeña profesionalmente con ética, respetando el marco legal, la pluralidad y la conservación del medio ambiente.',
                  'Participa y dirige grupos de trabajo interdisciplinarios para el desarrollo de proyectos que requieran soluciones innovadoras basadas en tecnologías y sistemas de información.',
                ]),

                const SizedBox(height: 28),

                // Campo Laboral — usa cs.secondary como tercer acento,
                // diferente al perfil de ingreso (tertiary) y de egreso (primary).
                _SectionTitle(cs: cs, texto: 'Campo Laboral'),
                const SizedBox(height: 12),
                _PerfilSection(cs: cs, color: cs.secondary, items: const [
                  'Empresas de producción y servicios nacionales e internacionales en áreas de TI, administración de redes y sistemas, reingeniería de procesos y desarrollo de productos y servicios de TI.',
                  'Sector Público e Instituciones Educativas.',
                  'Empresario o empresaria independiente, integrando tecnologías de vanguardia para optimizar procesos y gestión en el diseño, ejecución y mantenimiento de sistemas de telecomunicación.',
                ]),

                const SizedBox(height: 28),

                // Retículas — las tres comparten la clave raíz IINF-2010-220
                // con sufijo de especialidad distinto en la URL.
                _SectionTitle(cs: cs, texto: 'Retícula IINF-2010-220'),
                const SizedBox(height: 12),
                ..._reticulas.map((r) => _ReticulaItem(cs: cs, reticula: r)),

                const SizedBox(height: 28),

                // Plan de Estudios — un ExpansionTile por semestre.
                _SectionTitle(cs: cs, texto: 'Plan de Estudios'),
                const SizedBox(height: 12),
                ..._semestres.map((sem) => _SemestreExpansion(cs: cs, semestre: sem)),

                const SizedBox(height: 28),

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

const _reticulas = [
  _Reticula(
    clave: 'IINF-2010-220',
    nombre: 'Gestión De Datos',
    url: 'http://cc.villahermosa.tecnm.mx/sys/estpro/reticulas/IINF-2010-220--IINE-GDD-2023-01.pdf',
  ),
  _Reticula(
    clave: 'IINF-2010-220',
    nombre: 'Desarrollo de Aplicaciones Multiplataforma',
    url: 'http://cc.villahermosa.tecnm.mx/sys/estpro/reticulas/IINF-2010-220--IINE-DAM-2023-02.pdf',
  ),
  _Reticula(
    clave: 'IINF-2010-220',
    nombre: 'Infraestructura y Seguridad en Redes',
    url: 'http://cc.villahermosa.tecnm.mx/sys/estpro/reticulas/IINF-2010-220--IINE-ISR-2023-03.pdf',
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
  final int numero;
  final List<_Materia> materias;
  /// Si es true, se muestran las entradas como texto informativo sin tap a PDF.
  final bool soloInformativo;
  const _Semestre(this.numero, this.materias, {this.soloInformativo = false});
}

// URL base de los temarios de IINF; las especialidades reutilizan
// la carpeta de ISC porque los planes de especialidad son compartidos.
const _base = 'https://villahermosa.tecnm.mx/docs/oferta/inginformatica/temario2010';
const _esp  = 'https://villahermosa.tecnm.mx/docs/oferta/ingsistemas/especialidades';

final _semestres = [
  _Semestre(1, [
    _Materia('Administración para Informática',   '$_base/1semestre/Administracionparainformatica.pdf'),
    _Materia('Fundamentos de Investigación',       '$_base/1semestre/FundamentosdeInvestigacion-AC006.pdf'),
    _Materia('Fundamentos de Programación',        '$_base/1semestre/FundamentosdeProgramacion-AE032.pdf'),
    _Materia('Taller de Ética',                    '$_base/1semestre/TallerdeEtica-AC007.pdf'),
    _Materia('Cálculo Diferencial',                '$_base/1semestre/CalculoDiferencial-AC001.pdf'),
    _Materia('Desarrollo Sustentable',             '$_base/1semestre/DesarrolloSustentable-AC008.pdf'),
  ]),
  _Semestre(2, [
    _Materia('Administración de los Recursos y Función Informática', '$_base/2semestre/Administracion_de_los_recursos_y_funcion_informatica.pdf'),
    _Materia('Física para Informática',            '$_base/2semestre/FisicaparaInformatica.pdf'),
    _Materia('Programación Orientada a Objetos',   '$_base/2semestre/ProgramacionOrientadaaObjetos-AE054.pdf'),
    _Materia('Contabilidad Financiera',            '$_base/2semestre/ContabilidadFinanciera-AE008.pdf'),
    _Materia('Cálculo Integral',                   '$_base/2semestre/CalculaIntegral-AC002.pdf'),
    _Materia('Matemáticas Discretas',              '$_base/2semestre/MatematicasDiscretas-AE041.pdf'),
  ]),
  _Semestre(3, [
    _Materia('Fundamentos de Sistemas de Información', '$_base/3semestre/FundamentosdeSistemasdeInformacion.pdf'),
    _Materia('Sistemas Electrónicos para Informática', '$_base/3semestre/Sistemaselectronicosparainformatica.pdf'),
    _Materia('Estructura de Datos',                '$_base/3semestre/EstructuradeDatos-AE026.pdf'),
    _Materia('Costos Empresariales',               '$_base/3semestre/Costosempresariales..pdf'),
    _Materia('Álgebra Lineal',                     '$_base/3semestre/AlgebraLineal-AC003.pdf'),
    _Materia('Probabilidad y Estadística',         '$_base/3semestre/ProbabilidadyEstadistica-AE052.pdf'),
  ]),
  _Semestre(4, [
    _Materia('Taller de Investigación I',                 '$_base/4semestre/TallerdeInvestigacion-I-AC009.pdf'),
    _Materia('Arquitectura de Computadoras',              '$_base/4semestre/ArquitecturadeComputadoras.pdf'),
    _Materia('Administración y Organización de Datos',    '$_base/4semestre/Administracionyorganizaciondedatos.pdf'),
    _Materia('Fundamentos de Telecomunicaciones',         '$_base/4semestre/FundamentosdeTelecomunicaciones-AE034.pdf'),
    _Materia('Sistemas Operativos I',                     '$_base/4semestre/SistemasOperativos-I-AE061.pdf'),
    _Materia('Investigación de Operaciones',              '$_base/4semestre/InvestigaciondeOperaciones.pdf'),
  ]),
  _Semestre(5, [
    _Materia('Análisis y Modelado de Sistemas de Información', '$_base/5semestre/AnalisisymodeladodeSistemasdeInformacion.pdf'),
    _Materia('Tecnologías e Interfaces de Computadoras',       '$_base/5semestre/TecnologiaseInterfacesdeComputadoras.pdf'),
    _Materia('Fundamentos de Base de Datos',                   '$_base/5semestre/FundamentosdeBasedeDatos-AE031.pdf'),
    _Materia('Redes de Computadoras',                          '$_base/5semestre/Redesdecomputadoras.pdf'),
    _Materia('Sistemas Operativos II',                         '$_base/5semestre/SistemasOperativos-II-AE062.pdf'),
    _Materia('Taller de Legislación Informática',              '$_base/5semestre/TallerdeLegislacionInformatica.pdf'),
  ]),
  _Semestre(6, [
    _Materia('Desarrollo e Implementación de Sistemas de Información', '$_base/6semestre/DesarrolloeimplementaciondeSistemasdeInformacion.pdf'),
    _Materia('Auditoría Informática',              '$_base/6semestre/AuditoriaInformatica.pdf'),
    _Materia('Taller de Base de Datos',            '$_base/6semestre/TallerdeBasedeDatos-AE063.pdf'),
    _Materia('Interconectividad de Redes',         '$_base/6semestre/Interconectividadderedes..pdf'),
    _Materia('Desarrollo de Aplicaciones Web',     '$_base/6semestre/DesarrollodeAplicaciones%20eb.pdf'),
  ]),
  _Semestre(7, [
    _Materia('Calidad en los Sistemas de Información',        '$_base/7semestre/CalidadenlosSistemasdeInformacion.pdf'),
    _Materia('Fundamentos de Gestión de Servicios de TI',    '$_base/7semestre/Fundamentosgestionserviciostecnologiasinformacion.pdf'),
    _Materia('Tópicos de Base de Datos',                     '$_base/7semestre/Topicosdebasededatos.pdf'),
    _Materia('Administración de Servidores',                 '$_base/7semestre/Administraciondeservidores.pdf'),
    _Materia('Programación en Ambiente Cliente Servidor',    '$_base/7semestre/ProgramacionenambienteclienteServidor.pdf'),
    _Materia('Taller de Investigación II',                   '$_base/7semestre/TallerdeInvestigacion-II-AC010.pdf'),
  ]),
  _Semestre(8, [
    _Materia('Taller de Emprendedores',                           '$_base/8semestre/Tallerdeemprendedores.pdf'),
    _Materia('Estrategias de Gestión de Servicios de TI',         '$_base/8semestre/Estrategiasdegestiondeserviciosdetecnologiasdeinformacion.pdf'),
    _Materia('Inteligencia de Negocios',                          '$_base/8semestre/InteligenciadeNegocios.pdf'),
    _Materia('Desarrollo de Aplicaciones para Dispositivos Móviles', '$_base/8semestre/DesarrolloAplicacionesDispositivosMoviles-AEB-1011.pdf'),
    _Materia('Seguridad Informática',                             '$_base/8semestre/SeguridadInformatica.pdf'),
  ]),
  // 9no semestre: contenido institucional sin PDFs de temario.
  _Semestre(9, [
    _Materia('Especialidad',               ''),
    _Materia('Residencia Profesional',     ''),
    _Materia('Servicio Social',            ''),
    _Materia('Actividades Complementarias',''),
  ], soloInformativo: true),
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
    nombre: 'Infraestructura y Seguridad en Redes',
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
    nombre: 'Gestión De Datos',
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
    nombre: 'Desarrollo de Aplicaciones Multiplataforma',
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

/// Tile expandible que muestra las materias de un semestre.
/// Usa cs.tertiary como acento, a diferencia de ISC (cs.primary)
/// e ITIC (cs.secondary), para distinguir visualmente las tres
/// carreras del mismo departamento.
class _SemestreExpansion extends StatelessWidget {
  final ColorScheme cs;
  final _Semestre semestre;
  const _SemestreExpansion({required this.cs, required this.semestre});

  // Ordinales en español para el título del tile.
  static const _ordinal = ['', '1er', '2do', '3er', '4to', '5to', '6to', '7mo', '8vo', '9no'];

  @override
  Widget build(BuildContext context) {
    final ord = _ordinal[semestre.numero];
    // El color de acento se extrae a variable local para reutilizarlo
    // en background, borde y leading sin repetir cs.tertiary.
    final accent = cs.tertiary;
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
            backgroundColor: accent.withValues(alpha:0.05),
            collapsedBackgroundColor: accent.withValues(alpha:0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: accent.withValues(alpha:0.12)),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outline.withValues(alpha:0.12)),
            ),
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: accent.withValues(alpha:0.12), shape: BoxShape.circle),
              child: Center(
                child: Text('${semestre.numero}',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: accent)),
              ),
            ),
            title: Text('$ord Semestre',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
            subtitle: Text(
              semestre.soloInformativo
                  ? '${semestre.materias.length} actividades'
                  : '${semestre.materias.length} materias',
              style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha:0.45)),
            ),
            children: semestre.soloInformativo
                ? semestre.materias.map((m) => _MateriaInfoItem(cs: cs, nombre: m.nombre)).toList()
                : semestre.materias.map((m) => _MateriaItem(cs: cs, materia: m)).toList(),
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
              decoration: BoxDecoration(color: color.withValues(alpha:0.12), borderRadius: BorderRadius.circular(10)),
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
/// Nota: en IINF.dart esta versión de _MateriaItem no valida hasUrl
/// antes de navegar; todas las materias del plan tienen PDF disponible
/// excepto las del 9no semestre, que se renderizan con _MateriaInfoItem.
class _MateriaItem extends StatelessWidget {
  final ColorScheme cs;
  final _Materia materia;
  const _MateriaItem({required this.cs, required this.materia});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => PdfViewerScreen(titulo: materia.nombre, url: materia.url),
        )),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf_rounded, size: 18, color: cs.tertiary.withValues(alpha:0.5)),
              const SizedBox(width: 12),
              Expanded(child: Text(materia.nombre,
                  style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha:0.8)))),
              Icon(Icons.chevron_right_rounded, size: 18, color: cs.onSurface.withValues(alpha:0.25)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila de solo texto para el 9no semestre, donde las entradas
/// son actividades institucionales sin PDF de temario asociado.
class _MateriaInfoItem extends StatelessWidget {
  final ColorScheme cs;
  final String nombre;
  const _MateriaInfoItem({required this.cs, required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: cs.tertiary.withValues(alpha:0.45)),
          const SizedBox(width: 12),
          Expanded(child: Text(nombre,
              style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha:0.7)))),
        ],
      ),
    );
  }
}

/// Card informativa expandible sobre el 9no semestre de IINF.
/// Definida para uso futuro; actualmente no se instancia en el build.
class _EspecialidadInfoCard extends StatelessWidget {
  final ColorScheme cs;
  const _EspecialidadInfoCard({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.tertiary.withValues(alpha:0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.tertiary.withValues(alpha:0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.school_rounded, color: cs.tertiary, size: 22),
            const SizedBox(width: 10),
            Text('Plan IINF-2010-220',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cs.tertiary)),
          ]),
          const SizedBox(height: 12),
          Text(
            'La especialidad se cursa en el 9° semestre junto con la Residencia Profesional, el Servicio Social y las Actividades Complementarias. El alumno elige una línea de profundización acorde a su perfil profesional.',
            style: TextStyle(fontSize: 13, height: 1.6, color: cs.onSurface.withValues(alpha:0.75)),
          ),
          const SizedBox(height: 14),
          Divider(color: cs.tertiary.withValues(alpha:0.15), height: 1),
          const SizedBox(height: 14),
          Text('Actividades del 9° semestre',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha:0.5), letterSpacing: 0.3)),
          const SizedBox(height: 10),
          ...[
            (Icons.emoji_events_rounded,    'Especialidad',                'Línea de profundización elegida por el alumno.'),
            (Icons.business_center_rounded, 'Residencia Profesional',      'Proyecto aplicado en una empresa u organización real.'),
            (Icons.volunteer_activism_rounded,'Servicio Social',            'Contribución a la comunidad como requisito de titulación.'),
            (Icons.event_available_rounded, 'Actividades Complementarias', 'Actividades extracurriculares que enriquecen el perfil de egreso.'),
          ].map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(item.$1, size: 18, color: cs.tertiary.withValues(alpha:0.7)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.$2,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: cs.onSurface.withValues(alpha:0.85))),
                const SizedBox(height: 2),
                Text(item.$3,
                    style: TextStyle(fontSize: 12, height: 1.5,
                        color: cs.onSurface.withValues(alpha:0.5))),
              ])),
            ]),
          )),
        ],
      ),
    );
  }
}


// ═════════════════════════════════════════════════════════════════
// WIDGETS REUTILIZABLES
// ═════════════════════════════════════════════════════════════════

/// Título de sección con barra vertical de acento (4 × 18 px).
/// Usa cs.tertiary como color de acento, coherente con los
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
        decoration: BoxDecoration(color: cs.tertiary, borderRadius: BorderRadius.circular(2)),
      ),
      const SizedBox(width: 10),
      Text(texto, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: cs.onSurface)),
    ]);
  }
}

/// Card compacta con ícono, título y texto para las secciones de resumen.
/// El color se pasa como parámetro para soportar distintos acentos
/// en la misma fila de cards (Objetivo General en tertiary,
/// Campo Laboral en primary).
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
        color: color.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha:0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icono, color: color, size: 22),
        const SizedBox(height: 8),
        Text(titulo, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 6),
        Text(contenido, style: TextStyle(fontSize: 12, height: 1.55, color: cs.onSurface.withValues(alpha:0.7))),
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
                  color: cs.tertiary.withValues(alpha:0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.grid_view_rounded, color: cs.tertiary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(reticula.nombre,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                const SizedBox(height: 3),
                Text(reticula.clave,
                    style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha:0.4), letterSpacing: 0.2)),
              ])),
              Icon(Icons.picture_as_pdf_rounded, color: cs.tertiary.withValues(alpha:0.5), size: 20),
            ]),
          ),
        ),
      ),
    );
  }
}