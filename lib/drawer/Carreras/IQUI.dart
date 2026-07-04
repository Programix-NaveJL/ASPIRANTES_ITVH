// ═════════════════════════════════════════════════════════════════
// IQUI.dart
//
// Pantalla informativa de la Ingeniería Química (IQUI).
//
// Secciones:
//   • Objetivo General      — descripción del propósito de la carrera
//   • Propósitos Específicos — siete competencias numeradas
//   • Perfil de Ingreso     — características deseables del aspirante
//   • Perfil de Egreso      — competencias del profesional al egresar
//   • Campo Laboral         — sectores e industrias de inserción
//   • Retículas             — tres planes (2005, 2010, 2023) con PDF
//   • Plan de Estudios      — ExpansionTile por semestre (1–9)
//   • Especialidad          — un único ExpansionTile (Procesos Químicos)
//
// Widgets privados de esta pantalla:
//   • _SemestreExpansion     — tile expandible de un semestre
//   • _EspecialidadExpansion — tile expandible de la especialidad única
//   • _MateriaItem           — fila tappable que abre PdfViewerScreen
//   • _MateriaInfoItem       — fila de texto (sin PDF; 9no semestre)
//   • _SectionTitle          — título con barra de acento naranja fijo
//   • _ObjetivoItem          — fila numerada con título y descripción
//   • _PerfilSection         — lista de bullets con punto de color
//   • _ReticulaItem          — card tappable que abre PdfViewerScreen
//
// Modelos de datos (privados):
//   • _Reticula    — clave, nombre y URL de una retícula
//   • _Materia     — nombre y URL de un temario en PDF
//   • _Semestre    — número, lista de materias y flag soloInformativo
//   • _Especialidad — nombre, clave y lista de materias (sin ícono
//                     dinámico: el tile usa Icons.biotech_rounded fijo)
//
// Colores de acento:
//   • _naranja       (#E65100) — color principal de la carrera
//   • _naranjaOscuro (#BF360C) — variante oscura para perfil de egreso
//                                y tile de especialidad
//
// Notas de implementación:
//   • A diferencia de ISC e ITIC, los colores de acento son constantes
//     fijas en lugar de derivarse del ColorScheme, igual que en LADM.
//   • IQUI ofrece tres retículas de distintos años (2005, 2010, 2023);
//     las demás carreras solo tienen retículas del plan 2010.
//   • La especialidad es única (Procesos Químicos), por lo que se usa
//     una instancia const en lugar de una lista.
//   • El 9no semestre usa soloInformativo: true y renderiza
//     _MateriaInfoItem en lugar de _MateriaItem.
// ═════════════════════════════════════════════════════════════════

import 'package:aspirantes_itvh_app/drawer/Carreras/pdf_viewer_screen.dart';
import 'package:flutter/material.dart';

class IQUIScreen extends StatelessWidget {
  const IQUIScreen({super.key});

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
              'Ing. Química',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cs.onSurface),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Fondo con tinte naranja muy suave.
                  Container(color: _naranja.withValues(alpha:0.12)),

                  // Ícono decorativo semitransparente en esquina superior derecha.
                  Positioned(
                    right: -30, top: -20,
                    child: Icon(Icons.science_rounded, size: 220, color: _naranja.withValues(alpha:0.07)),
                  ),

                  // Chip del departamento al que pertenece la carrera.
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 56),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _naranja.withValues(alpha:0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Departamento Química, Bioquímica y Ambiental',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _naranja),
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
                        'Ing. Química',
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
                _SectionTitle(texto: 'Objetivo General'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _naranja.withValues(alpha:0.07),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _naranja.withValues(alpha:0.15)),
                  ),
                  child: Text(
                    'Formar profesionistas en Ingeniería Química competentes para investigar, generar y aplicar el conocimiento científico y tecnológico, que le permita identificar y resolver problemas de diseño, operación, adaptación, optimización y administración en industrias químicas y de servicios, con calidad, seguridad, economía, usando racional y eficientemente los recursos naturales, conservando el medio ambiente, cumpliendo el código ético de la profesión y participando en el bienestar de la sociedad.',
                    style: TextStyle(fontSize: 14, height: 1.65, color: cs.onSurface.withValues(alpha:0.8)),
                  ),
                ),

                const SizedBox(height: 28),

                // Propósitos Específicos — nombrados "Propósitos" en IQUI
                // en lugar de "Objetivos" como en las demás carreras.
                _SectionTitle(texto: 'Propósitos Específicos'),
                const SizedBox(height: 12),
                ..._propositos.map((p) => _ObjetivoItem(cs: cs, numero: p.$1, titulo: p.$2, descripcion: p.$3)),

                const SizedBox(height: 28),

                // Perfil de ingreso — usa _naranja como acento.
                _SectionTitle(texto: 'Perfil de Ingreso'),
                const SizedBox(height: 12),
                _PerfilSection(cs: cs, color: _naranja, items: const [
                  'Capacidad para expresarse correctamente en forma oral y escrita.',
                  'Capacidades de razonamiento verbal y numérico.',
                  'Capacidad de análisis, síntesis, identificación y resolución de problemas.',
                  'Habilidades para realizar trabajo en equipo.',
                  'Ser creativo, innovador, responsable, disciplinado y con vocación.',
                  'Preferentemente con bachillerato en ciencias físico-matemáticas, químico-biológico, único o equivalente.',
                ]),

                const SizedBox(height: 28),

                // Perfil de egreso — usa _naranjaOscuro para diferenciarlo
                // visualmente del perfil de ingreso.
                _SectionTitle(texto: 'Perfil de Egreso'),
                const SizedBox(height: 12),
                _PerfilSection(cs: cs, color: _naranjaOscuro, items: const [
                  'Diseña, selecciona, opera, optimiza y controla procesos en industrias químicas y de servicios con base en el desarrollo tecnológico, de manera sustentable.',
                  'Colabora en equipos interdisciplinarios y multiculturales, con actitud innovadora, espíritu crítico, disposición al cambio y apego a la ética profesional.',
                  'Planea e implementa sistemas de gestión de calidad, ambiente e higiene y seguridad conforme a normas nacionales e internacionales.',
                  'Utiliza las TIC como herramientas en la construcción de soluciones a problemas de ingeniería y difusión del conocimiento científico.',
                  'Realiza innovación y adaptación de tecnología en procesos aplicando la metodología científica con respeto a la propiedad intelectual.',
                  'Utiliza un segundo idioma en su ámbito laboral según los requerimientos del entorno.',
                  'Se comunica de forma oral y escrita en el ámbito laboral de manera expedita y concisa.',
                  'Demuestra actitud creativa, emprendedora y liderazgo para impulsar y crear empresas que contribuyan al progreso nacional.',
                  'Administra recursos humanos, materiales y financieros para los sectores público y privado, acorde a modelos administrativos vigentes.',
                  'Demuestra actitudes de superación continua para lograr metas personales y profesionales con pertenencia y competitividad.',
                ]),

                const SizedBox(height: 28),

                // Campo Laboral — lista de bullets con _naranja como acento.
                _SectionTitle(texto: 'Campo Laboral'),
                const SizedBox(height: 12),
                _PerfilSection(cs: cs, color: _naranja, items: const [
                  'Industrias de extracción y transformación.',
                  'Sector público (IMP, PEMEX, SE, CFE, SEDESOL) y sector privado de la industria química.',
                  'Industrias relacionadas con planeación y diseño de plantas químicas: alcoholera, jabonera, azucarera, del papel, textil y otras.',
                  'Empresas o compañías de servicio: firmas de ingeniería y consultoras.',
                  'Fábricas que producen fibras sintéticas para la industria textil.',
                  'Instituciones educativas.',
                  'Ingeniería Bioquímica y Biomédica.',
                  'Protección ambiental, seguridad y materiales peligrosos.',
                ]),

                const SizedBox(height: 28),

                // Retículas — IQUI es la única carrera con tres planes de
                // distintos años: 2005, 2010 y 2023.
                _SectionTitle(texto: 'Retículas'),
                const SizedBox(height: 12),
                ..._reticulas.map((r) => _ReticulaItem(cs: cs, reticula: r)),

                const SizedBox(height: 28),

                // Plan de Estudios — un ExpansionTile por semestre.
                _SectionTitle(texto: 'Plan de Estudios'),
                const SizedBox(height: 12),
                ..._semestres.map((sem) => _SemestreExpansion(cs: cs, semestre: sem)),

                const SizedBox(height: 28),

                // Especialidad — única en IQUI; se pasa directamente
                // la instancia const en lugar de iterar una lista.
                _SectionTitle(texto: 'Especialidad'),
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
// COLORES DE ACENTO
// ═════════════════════════════════════════════════════════════════

// Constantes a nivel de archivo para que todos los widgets privados
// puedan usarlos sin recibirlos como parámetro.
const _naranja       = Color(0xFFE65100);
const _naranjaOscuro = Color(0xFFBF360C);


// ═════════════════════════════════════════════════════════════════
// DATOS
// ═════════════════════════════════════════════════════════════════

// ── Propósitos específicos ────────────────────────────────────
// Cada registro es una tupla (número, título corto, descripción).
const _propositos = [
  (1, 'Resolver Problemas',     'Identificar y resolver problemas de ingeniería aplicando los principios de las ciencias básicas e ingeniería.'),
  (2, 'Saber Diseñar',          'Aplicar y sintetizar procesos de diseño de ingeniería que resulten en proyectos que cumplen las necesidades especificadas.'),
  (3, 'Hacer Experimentos',     'Desarrollar experimentaciones adecuadas; analizar e interpretar datos y utilizar el juicio de ingeniería para establecer conclusiones.'),
  (4, 'Saber Comunicarse',      'Comunicarse efectivamente con diferentes audiencias.'),
  (5, 'Ser Ético',              'Reconoce sus responsabilidades éticas y profesionales en situaciones relevantes para la ingeniería, considerando el impacto de las soluciones en los contextos global, económico, ambiental y social.'),
  (6, 'Actualizarse',           'Reconoce la necesidad permanente de conocimiento adicional y tiene la habilidad para localizarlo, evaluarlo, integrarlo y aplicarlo adecuadamente.'),
  (7, 'Trabajar en Equipo',     'Trabaja efectivamente en equipos que establecen metas, planean tareas, cumplen fechas límite y analizan riesgos e incertidumbre.'),
];

// ── Modelo de retícula ────────────────────────────────────────
class _Reticula {
  final String clave, nombre, url;
  const _Reticula({required this.clave, required this.nombre, required this.url});
}

const _reticulas = [
  _Reticula(
    clave: 'IQUI-2005-299',
    nombre: 'Retícula 2005',
    url: 'https://pub-f883231412d746839d3a41f6bc354031.r2.dev/IQUI/IQUI-2005-299.pdf',
  ),
  _Reticula(
    clave: 'IQUI-2010-232',
    nombre: 'Retícula 2010',
    url: 'https://pub-f883231412d746839d3a41f6bc354031.r2.dev/IQUI/IQUI-2010-232.pdf',
  ),
  // La retícula 2023 comparte clave con la de 2010 porque es una
  // actualización de especialidad sobre el mismo plan base.
  _Reticula(
    clave: 'IQUI-2010-232',
    nombre: 'Retícula 2023',
    url: 'http://cc.villahermosa.tecnm.mx/sys/estpro/reticulas/IQUI-2010-232--IQUE-PRQ-2023-01.pdf',
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
  final bool soloInformativo;
  const _Semestre(this.numero, this.materias, {this.soloInformativo = false});
}

// URL base de los temarios para no repetirla en cada _Materia.
const _base = 'https://villahermosa.tecnm.mx/docs/oferta/ingquimica/temario2010';

final _semestres = [
  _Semestre(1, [
    _Materia('Taller de Ética',                  '$_base/1ERSEMESTRE/TallerdeEtica-ACA-0907.pdf'),
    _Materia('Fundamentos de Investigación',      '$_base/1ERSEMESTRE/FundamentosdeInvestigacion-ACC-0906.pdf'),
    _Materia('Cálculo Diferencial',               '$_base/1ERSEMESTRE/CalculoDiferencial-ACF-0901.pdf'),
    _Materia('Química Inorgánica',                '$_base/1ERSEMESTRE/QuimicaInorganica-AEF-1060.pdf'),
    _Materia('Programación',                      '$_base/1ERSEMESTRE/Programacion.pdf'),
    _Materia('Dibujo Asistido por Computadora',   '$_base/1ERSEMESTRE/DibujoAsistidoporComputadora-AEO-1012.pdf'),
  ]),
  _Semestre(2, [
    // Álgebra Lineal reutiliza el PDF de la carrera de Ing. Ambiental
    // porque IQUI no tiene su propia versión en servidor.
    _Materia('Álgebra Lineal',    'https://villahermosa.tecnm.mx/docs/oferta/ingambiental/temario2010/2semestre/AlgebraLineal-AC003.pdf'),
    _Materia('Mecánica Clásica',              '$_base/2DOSEMESTRE/MecanicaClasica-AEF-1042.pdf'),
    _Materia('Cálculo Integral',              '$_base/2DOSEMESTRE/CalculoIntegral-ACF-0902.pdf'),
    _Materia('Química Orgánica I',            '$_base/2DOSEMESTRE/QumicaorganicaI.pdf'),
    _Materia('Termodinámica',                 '$_base/2DOSEMESTRE/Termodinamica-AEF-1065.pdf'),
    _Materia('Química Analítica',             '$_base/2DOSEMESTRE/QuimicaAnalitica-AEG-1059.pdf'),
  ]),
  _Semestre(3, [
    _Materia('Análisis de Datos Experimentales',     '$_base/3ERSEMESTRE/AnalisisdeDatosExperimentales.pdf'),
    _Materia('Electricidad, Magnetismo y Óptica',    '$_base/3ERSEMESTRE/Electricidad,MagnetismoyOptica.pdf'),
    _Materia('Cálculo Vectorial',                    '$_base/3ERSEMESTRE/CalculoVectorial-ACF%E2%80%930904.pdf'),
    _Materia('Química Orgánica II',                  '$_base/3ERSEMESTRE/QuimicaOrganicaII.pdf'),
    _Materia('Balance de Materia y Energía',         '$_base/3ERSEMESTRE/BalancedeMateriayEnergia-AEF-1004.pdf'),
    _Materia('Gestión de la Calidad',                '$_base/3ERSEMESTRE/GestiondelaCalidad.pdf'),
  ]),
  _Semestre(4, [
    _Materia('Métodos Numéricos',             '$_base/4semestre/MetodosNumericos.pdf'),
    _Materia('Ecuaciones Diferenciales',      '$_base/4semestre/EcuacionesDiferenciales-ACF%E2%80%930905.pdf'),
    _Materia('Mecanismos de Transferencia',   '$_base/4semestre/MecanismosdeTransferencia.pdf'),
    _Materia('Ingeniería Ambiental',          '$_base/4semestre/IngenieriaAmbiental.pdf'),
    _Materia('Fisicoquímica I',               '$_base/4semestre/Fisicoqu%C3%ADmicaI.pdf'),
    _Materia('Análisis Instrumental',         '$_base/4semestre/AnalisisInstrumental-AEF-1003.pdf'),
  ]),
  _Semestre(5, [
    _Materia('Desarrollo Sustentable',             '$_base/5semestre/DesarrolloSustentable-ACD-0908.pdf'),
    _Materia('Ingeniería de Costos',               '$_base/5semestre/IngenieriadeCostos.pdf'),
    _Materia('Balance de Momento, Calor y Masa',   '$_base/5semestre/BalancedeMomento,CaloryMasa.pdf'),
    _Materia('Procesos de Separación I',           '$_base/5semestre/ProcesosdeSeparacionI.pdf'),
    _Materia('Fisicoquímica II',                   '$_base/5semestre/Fisicoqu%C3%ADmicaII.pdf'),
  ]),
  _Semestre(6, [
    _Materia('Taller de Investigación I',    '$_base/6semestre/TallerdeInvestigacionI-ACA-0909.pdf'),
    _Materia('Procesos de Separación II',    '$_base/6semestre/ProcesosdeseparacinII.pdf'),
    _Materia('Laboratorio Integral I',       '$_base/6semestre/LaboratorioIntegralI.pdf'),
    _Materia('Reactores Químicos',           '$_base/6semestre/ReactoresQuimicos.pdf'),
  ]),
  _Semestre(7, [
    _Materia('Taller de Administración Gerencial',  '$_base/7semestre/TallerdeAdministracionGerencial.pdf'),
    _Materia('Taller de Investigación II',           '$_base/7semestre/TallerdeInvestigacionII-ACA-0910.pdf'),
    _Materia('Procesos de Separación III',           '$_base/7semestre/ProcesosdeSeparacionIII.pdf'),
    _Materia('Síntesis y Optimización de Procesos',  '$_base/7semestre/SintesisyOptimizaciondeProcesos.pdf'),
    _Materia('Salud y Seguridad en el Trabajo',      '$_base/7semestre/Saludyseguridadeneltrabajo.pdf'),
    _Materia('Laboratorio Integral II',              '$_base/7semestre/LaboratorioIntegralII.pdf'),
  ]),
  _Semestre(8, [
    _Materia('Laboratorio Integral III',    '$_base/8semestre/LaboratorioIntegralIII.pdf'),
    _Materia('Instrumentación y Control',   '$_base/8semestre/InstrumentacionyControl-AEF-1039.pdf'),
    _Materia('Ingeniería de Proyectos',     '$_base/8semestre/IngenieriadeProyectos.pdf'),
    _Materia('Simulación de Procesos',      '$_base/8semestre/SimulaciondeProcesos.pdf'),
  ]),
  // 9no semestre: actividades institucionales sin PDF de temario.
  _Semestre(9, [
    _Materia('Especialidad',               ''),
    _Materia('Residencia Profesional',     ''),
    _Materia('Servicio Social',            ''),
    _Materia('Actividades Complementarias',''),
  ], soloInformativo: true),
];

// ── Modelo de especialidad ────────────────────────────────────
// IQUI tiene una única especialidad; no necesita ícono dinámico
// porque el tile usa Icons.biotech_rounded directamente.
class _Especialidad {
  final String nombre, clave;
  final List<_Materia> materias;
  const _Especialidad({required this.nombre, required this.clave, required this.materias});
}

// URL base de los temarios de la especialidad.
const _espBase = 'https://villahermosa.tecnm.mx/docs/oferta/ingquimica/especialidad';

const _especialidad = _Especialidad(
  nombre: 'Procesos Químicos',
  clave: 'IQUI-2010-232',
  materias: [
    _Materia('Ciencia y Tecnología de Materiales',            '$_espBase/CienciayTecnologiadeMateriales.pdf'),
    _Materia('Control de Calidad en Productos',               '$_espBase/ControldeCalidadenProductos.pdf'),
    _Materia('Diseño y Caracterización de Fluidos de Perforación', '$_espBase/DisennoyCaracterizaciondeFluidosdePerforacion.pdf'),
    _Materia('Optimización de Procesos Industriales',         '$_espBase/OptimizaciondeProcesosIndustriales.pdf'),
    _Materia('Tecnologías y Tratamientos de Residuos',        '$_espBase/TecnologiasyTratamientosdeResiduos.pdf'),
  ],
);


// ═════════════════════════════════════════════════════════════════
// WIDGETS PRIVADOS
// ═════════════════════════════════════════════════════════════════

/// Tile expandible que muestra las materias de un semestre.
/// Si [semestre.soloInformativo] es true, renderiza _MateriaInfoItem
/// en lugar de _MateriaItem para indicar que no hay PDF disponible.
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
          // Eliminar el Divider que Flutter agrega por defecto al expandir.
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            backgroundColor: _naranja.withValues(alpha:0.05),
            collapsedBackgroundColor: _naranja.withValues(alpha:0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: _naranja.withValues(alpha:0.12)),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outline.withValues(alpha:0.12)),
            ),
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: _naranja.withValues(alpha:0.12), shape: BoxShape.circle),
              child: Center(
                child: Text('${semestre.numero}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _naranja)),
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

/// Tile expandible para la especialidad única de IQUI.
/// Usa _naranjaOscuro como acento para diferenciarlo de los semestres.
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
            backgroundColor: _naranjaOscuro.withValues(alpha:0.05),
            collapsedBackgroundColor: _naranjaOscuro.withValues(alpha:0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: _naranjaOscuro.withValues(alpha:0.15)),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outline.withValues(alpha:0.12)),
            ),
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: _naranjaOscuro.withValues(alpha:0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.biotech_rounded, color: _naranjaOscuro, size: 20),
            ),
            title: Text(especialidad.nombre,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
            subtitle: Text('${especialidad.materias.length} materias  ·  ${especialidad.clave}',
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
            builder: (_) => PdfViewerScreen(titulo: materia.nombre, url: materia.url)))
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(children: [
            Icon(
              hasUrl ? Icons.picture_as_pdf_rounded : Icons.info_outline_rounded,
              size: 18, color: _naranja.withValues(alpha:0.5),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(materia.nombre,
                style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha:0.8)))),
            if (hasUrl)
              Icon(Icons.chevron_right_rounded, size: 18, color: cs.onSurface.withValues(alpha:0.25)),
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
  final String nombre;
  const _MateriaInfoItem({required this.cs, required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(children: [
        Icon(Icons.info_outline_rounded, size: 18, color: _naranja.withValues(alpha:0.45)),
        const SizedBox(width: 12),
        Expanded(child: Text(nombre,
            style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha:0.7)))),
      ]),
    );
  }
}


// ═════════════════════════════════════════════════════════════════
// WIDGETS REUTILIZABLES
// ═════════════════════════════════════════════════════════════════

/// Título de sección con barra vertical de acento naranja de 4 × 18 px.
class _SectionTitle extends StatelessWidget {
  final String texto;
  const _SectionTitle({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 4, height: 18,
          decoration: BoxDecoration(color: _naranja, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Text(texto, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface)),
    ]);
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
          decoration: BoxDecoration(color: _naranja.withValues(alpha:0.12), shape: BoxShape.circle),
          child: Center(child: Text('$numero',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _naranja))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cs.onSurface)),
          const SizedBox(height: 3),
          Text(descripcion, style: TextStyle(fontSize: 13, height: 1.55, color: cs.onSurface.withValues(alpha:0.65))),
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
              style: TextStyle(fontSize: 13, height: 1.6, color: cs.onSurface.withValues(alpha:0.75)))),
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
              border: Border.all(color: cs.outline.withValues(alpha:0.15)),
            ),
            child: Row(children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: _naranja.withValues(alpha:0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.grid_view_rounded, color: _naranja, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(reticula.nombre,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                const SizedBox(height: 3),
                Text(reticula.clave,
                    style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha:0.4), letterSpacing: 0.2)),
              ])),
              Icon(Icons.picture_as_pdf_rounded, color: _naranja.withValues(alpha:0.5), size: 20),
            ]),
          ),
        ),
      ),
    );
  }
}