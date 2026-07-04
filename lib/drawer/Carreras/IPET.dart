// ═════════════════════════════════════════════════════════════════
// IPET.dart
//
// Pantalla informativa de la Ingeniería Petrolera (IPET).
//
// Secciones:
//   • Objetivo General     — descripción del propósito de la carrera
//   • Perfil de Ingreso    — características deseables del aspirante
//   • Perfil de Egreso     — competencias del profesional al egresar
//   • Campo Laboral        — sectores de inserción profesional
//   • Retícula 2010        — un único plan con enlace a PDF
//   • Plan de Estudios     — ExpansionTile por semestre (1–9)
//   • Especialidades       — un único ExpansionTile (Productividad
//                            en el Sector Petrolero)
//
// Widgets privados de esta pantalla:
//   • _SemestreExpansion     — tile expandible de un semestre
//   • _EspecialidadExpansion — tile expandible de la especialidad única
//   • _MateriaItem           — fila tappable que abre PdfViewerScreen
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
//   • Los colores de acento se toman del ColorScheme (cs.primary,
//     cs.secondary, cs.tertiary), igual que ISC e ITIC.
//   • IPET solo ofrece una retícula y una especialidad; ambas se
//     pasan como instancia directa en lugar de lista.
//   • El 9no semestre lista actividades institucionales sin PDF
//     (url vacía); el flag hasUrl en _MateriaItem maneja ambos casos.
//   • Los temarios de la especialidad se alojan bajo la misma
//     URL base que el plan de estudios (_base/Especialidad/).
// ═════════════════════════════════════════════════════════════════

import 'package:aspirantes_itvh_app/drawer/Carreras/pdf_viewer_screen.dart';
import 'package:flutter/material.dart';

class IPETScreen extends StatelessWidget {
  const IPETScreen({super.key});

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
                  Container(color: cs.primary.withValues(alpha:0.12)),

                  // Ícono decorativo semitransparente en esquina superior derecha.
                  Positioned(
                    right: -30, top: -20,
                    child: Icon(Icons.oil_barrel_rounded, size: 220, color: cs.primary.withValues(alpha:0.07)),
                  ),

                  // Chip del departamento al que pertenece la carrera.
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 56),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha:0.15),
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
                        'Ingeniería Petrolera',
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
                    color: cs.primary.withValues(alpha:0.07),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.primary.withValues(alpha:0.15)),
                  ),
                  child: Text(
                    'Formar profesionales con la capacidad para desarrollar la programación, ejecución y la dirección de los procesos de explotación de hidrocarburos, aprovechando de manera sustentable los recursos naturales, atendiendo la preservación del medio ambiente, aplicando para ello las nuevas tecnologías, con habilidades, actitudes, aptitudes analíticas y creativas, de liderazgo y calidad humana, con un espíritu de superación permanente para investigar, desarrollar y aplicar el conocimiento científico y tecnológico.',
                    style: TextStyle(fontSize: 14, height: 1.65, color: cs.onSurface.withValues(alpha:0.8)),
                  ),
                ),

                const SizedBox(height: 28),

                // Perfil de ingreso — usa cs.secondary como acento.
                _SectionTitle(cs: cs, texto: 'Perfil de Ingreso'),
                const SizedBox(height: 12),
                _PerfilSection(cs: cs, color: cs.secondary, items: const [
                  'Dominio de habilidades básicas como la comprensión de textos.',
                  'El trabajo en equipo.',
                  'Interés sobre el tema de relevancia.',
                  'Iniciativa, capacidad de gestión, de comunicación y creatividad.',
                  'Interés por la investigación de las causas que deterioran el ambiente y respeto a la naturaleza.',
                  'Inclinación por el conocimiento científico-tecnológico e interés en las ciencias básicas y naturales, y en sus aplicaciones para la solución de problemas.',
                ]),

                const SizedBox(height: 28),

                // Perfil de egreso — usa cs.tertiary para diferenciarlo
                // visualmente del perfil de ingreso.
                _SectionTitle(cs: cs, texto: 'Perfil de Egreso'),
                const SizedBox(height: 12),
                _PerfilSection(cs: cs, color: cs.tertiary, items: const [
                  'Identifica las características geológicas, petrofísicas y dinámicas que controlan la capacidad de almacenamiento de hidrocarburos y la producción de yacimientos, aplicando tecnología de punta.',
                  'Mejora, diseña, implementa y evalúa los sistemas y modelos de exploración, producción y distribución para la optimización de los recursos con un enfoque de calidad y competitividad.',
                  'Aplica técnicas de exploración y producción que ayuden en la interpretación y evaluación de las posibilidades de localización de yacimientos petroleros, así como pozos acuíferos.',
                  'Maneja software para el diseño, simulación y operación de los sistemas de exploración y producción de hidrocarburos.',
                  'Gestiona proyectos y realiza programas de investigación y desarrollo tecnológico para la solución de problemas en la industria petrolera.',
                  'Se desempeña con una actitud ética y emprendedora en su ámbito profesional, comprometido con el desarrollo sustentable del entorno.',
                  'Emplea adecuadamente las técnicas y procedimientos de campo con base en las leyes, reglamentos y códigos vigentes inherentes a su ejercicio profesional.',
                  'Programa, organiza, dirige, ejecuta y controla las actividades relacionadas con la producción del petróleo y gas para su almacenamiento, procesamiento, transporte, distribución y comercialización, aplicando los principios de gestión de la calidad ambiental hacia la mejora continua.',
                  'Propone soluciones integrales y estrategias a los problemas ambientales y de seguridad.',
                  'Participa en equipos de trabajo multi e interdisciplinario para la toma de decisiones y solución de problemas.',
                  'Administra e integra recursos humanos, materiales, financieros y económicos en el diseño, operación, evaluación, control y optimización de los procesos de perforación de pozos petroleros y acuíferos, así como su terminación y mantenimiento.',
                ]),

                const SizedBox(height: 28),

                // Campo Laboral — usa cs.primary como acento,
                // igual que el objetivo general y los semestres.
                _SectionTitle(cs: cs, texto: 'Campo Laboral'),
                const SizedBox(height: 12),
                _PerfilSection(cs: cs, color: cs.primary, items: const [
                  'Dependencias del gobierno en los ámbitos federal, estatal y municipal; organismos públicos desconcentrados y/o descentralizados.',
                  'Empresas del sector industrial en general, y de los ramos minero-metalúrgico, energético, de obras y proyectos civiles.',
                  'Instituciones educativas de nivel medio o superior, así como de investigación, tanto públicas como privadas.',
                  'Profesional independiente que realiza capacitación para empresas, estudios de impacto ambiental, de riesgo, auditorías ambientales, propuesta de innovaciones tecnológicas para empresas, etc.',
                  'Organizaciones no gubernamentales encaminadas a la promoción de Cultura Ambiental Limpia.',
                ]),

                const SizedBox(height: 28),

                // Retícula — IPET solo tiene un plan vigente (2010).
                _SectionTitle(cs: cs, texto: 'Retícula 2010'),
                const SizedBox(height: 12),
                ..._reticulas.map((r) => _ReticulaItem(cs: cs, reticula: r)),

                const SizedBox(height: 28),

                // Plan de Estudios — un ExpansionTile por semestre.
                _SectionTitle(cs: cs, texto: 'Plan de Estudios'),
                const SizedBox(height: 12),
                ..._semestres.map((sem) => _SemestreExpansion(cs: cs, semestre: sem)),

                const SizedBox(height: 20),

                // Especialidades — única especialidad; se itera la lista
                // de una sola entrada para mantener la misma estructura
                // que el resto de las pantallas de carrera.
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
  _Reticula(clave: 'IPET-2010', nombre: 'Productividad en el Sector Petrolero',
      url: 'https://villahermosa.tecnm.mx/docs/oferta/ingpetrolera/reticula/RETICULA_PETROLERA_PRODUCTIVIDAD.pdf'),
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

// URL base de los temarios para no repetirla en cada _Materia.
// Los temarios de la especialidad también viven bajo esta misma base.
const _base = 'https://villahermosa.tecnm.mx/docs/oferta/ingpetrolera/temario2010';

final _semestres = [
  _Semestre(1, [
    _Materia('Química Inorgánica',                  '$_base/1semestre/QuimicaInorganica.pdf'),
    _Materia('Geología Petrolera',                  '$_base/1semestre/GEOLOGIAPETROLERA.pdf'),
    _Materia('Computación para Ingeniería Petrolera','$_base/1semestre/COMPUTACIONPARAINGENIERIAPETROLERA.pdf'),
    _Materia('Taller de Ética',                     '$_base/1semestre/TallerdeEtica-AC007.pdf'),
    _Materia('Fundamentos de Investigación',        '$_base/1semestre/FundamentosdeInvestigacion-AC006.pdf'),
    _Materia('Cálculo Diferencial',                 '$_base/1semestre/CalculoDiferencial-AC001.pdf'),
  ]),
  _Semestre(2, [
    _Materia('Química Orgánica',        '$_base/2semestre/QuimicaOrganica.pdf'),
    _Materia('Cálculo Integral',        '$_base/2semestre/CalculoIntegral-AC002.pdf'),
    _Materia('Álgebra Lineal',          '$_base/2semestre/AlgebraLineal-AC003.pdf'),
    _Materia('Geología de Yacimientos', '$_base/2semestre/GEOLOGIADEYACIMIENTOS.pdf'),
    _Materia('Estática',                '$_base/2semestre/ESTATICA.pdf'),
    _Materia('Economía',                '$_base/2semestre/Economia.pdf'),
  ]),
  _Semestre(3, [
    _Materia('Análisis Numérico',                          '$_base/3semestre/AnalisisNumerico.pdf'),
    _Materia('Geología de Explotación del Petróleo',       '$_base/3semestre/GEOLOGIADEEXPLOTACIONDELPETROLEO.pdf'),
    _Materia('Dinámica',                                   '$_base/3semestre/DINAMICA.pdf'),
    _Materia('Cálculo Vectorial',                          '$_base/3semestre/CalculoVectorial-AC004.pdf'),
    _Materia('Administración',                             '$_base/3semestre/Administracion.pdf'),
    _Materia('Termodinámica',                              '$_base/3semestre/TERMODINAMICA.pdf'),
  ]),
  _Semestre(4, [
    _Materia('Probabilidad y Estadística Aplicada al Campo Petrolero', '$_base/4semestre/probyestadaplicadalcampopetrolero.pdf'),
    _Materia('Administración de la Seguridad y Protección Ambiental', '$_base/4semestre/AdministraciondelaSegyProtAmbiental.pdf'),
    _Materia('Electricidad y Magnetismo',                              '$_base/4semestre/electricidadymagnetismo.pdf'),
    _Materia('Mecánica de Fluidos',                                    '$_base/4semestre/mecanicadefluidos.pdf'),
    _Materia('Ecuaciones Diferenciales',                               '$_base/4semestre/EcuacionesDiferenciales-AC005.pdf'),
    _Materia('Desarrollo Sustentable',                                 '$_base/4semestre/DesarrolloSustentable-AC008.pdf'),
  ]),
  _Semestre(5, [
    _Materia('Métodos Eléctricos',                            '$_base/5semestre/metodoselectricos.pdf'),
    _Materia('Calidad en la Industria Petrolera',             '$_base/5semestre/Calidadenlaindustriapetrolera.pdf'),
    _Materia('Análisis e Interpretación de Planos y Diseño',  '$_base/5semestre/ANALISISEINTERPRETACIONDEPLANOSYDISENODEINGENIERIA.pdf'),
    _Materia('Propiedades de los Fluidos Petroleros',         '$_base/5semestre/Propiedadesdelosfluidospetroleros.pdf'),
    _Materia('Petrofísica y Registro de Pozos',               '$_base/5semestre/petrofisicayregistrosdepozos.pdf'),
    _Materia('Taller de Investigación I',                     '$_base/5semestre/TallerdeInvestigacionI-ACA-0909.pdf'),
  ]),
  _Semestre(6, [
    _Materia('Flujo Multifásico en Tuberías',                '$_base/6semestre/FlujoMultifasicoenTuberias.pdf'),
    _Materia('Sistemas de Bombeo en la Industria Petrolera', '$_base/6semestre/SistemasdeBombeoenlaIndustriaPetrolera.pdf'),
    _Materia('Legislación de la Industria Petrolera',        '$_base/6semestre/legislacionenlaindustriapetrolera.pdf'),
    _Materia('Productividad de Pozos',                       '$_base/6semestre/Productividaddepozos.pdf'),
    _Materia('Instrumentación',                              '$_base/6semestre/Instrumentacion-AEF-1038.pdf'),
    _Materia('Hidráulica',                                   '$_base/6semestre/Hidraulica.pdf'),
  ]),
  _Semestre(7, [
    _Materia('Ingeniería de Perforación de Pozos',     '$_base/7semestre/Ing.deperforaciondepozos.pdf'),
    _Materia('Taller de Investigación II',             '$_base/7semestre/TallerdeInvestigacionII-ACA-0910.pdf'),
    _Materia('Conducción y Manejo de Hidrocarburos',   '$_base/7semestre/ConduccionyManejodeHidrocarburos.pdf'),
  ]),
  _Semestre(8, [
    _Materia('Formulación y Evaluación de Proyectos',    '$_base/8semestre/FormulacionyEvaluaciondeProyectos-AEF-1029.pdf'),
    _Materia('Terminación y Mantenimiento de Pozos',     '$_base/8semestre/Terminacionymantenimientodepozos.pdf'),
    _Materia('Recuperación Secundaria y Mejorada',       '$_base/8semestre/RecuperacionSecundariayMejorada_OK.pdf'),
    _Materia('Sistemas Artificiales',                    '$_base/8semestre/SistemasArtificiales.pdf'),
  ]),
  // 9no semestre: actividades institucionales sin PDF de temario.
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
    nombre: 'Productividad en el Sector Petrolero',
    icono: Icons.oil_barrel_rounded,
    color: (cs) => cs.primary,
    materias: [
      // Los nombres de archivo incluyen el número de semestre al final
      // (7 u 8) porque estas materias se cursan en esos semestres específicos.
      _Materia('Caracterización Estática de Yacimientos',  '$_base/Especialidad/PSG-1801_Caracterizacion_Estatica_de_Yacimientos_7.pdf'),
      _Materia('Análisis de Pruebas de Presión I',          '$_base/Especialidad/PSF-1802_Analisis_de_Pruebas_de_Presion_I_7.pdf'),
      _Materia('Análisis de Pruebas de Presión II',         '$_base/Especialidad/PSD-1803_Analisis_de_Pruebas_de_Presion_II_8.pdf'),
      _Materia('Administración de Datos de Pozos',          '$_base/Especialidad/PSG-1804_Administracion_de_Datos_de_Pozos_8.pdf'),
      _Materia('Perforación de Pozos No Convencional',      '$_base/Especialidad/PSF-1805_Perforacion_de_Pozos_No_Convencional_9.pdf'),
      _Materia('Administración Integral de Yacimientos',    '$_base/Especialidad/PSJ-1806_Administracion_Integral_de_Yacimientos_9.pdf'),
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
            backgroundColor: cs.primary.withValues(alpha:0.05),
            collapsedBackgroundColor: cs.primary.withValues(alpha:0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.primary.withValues(alpha:0.12)),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outline.withValues(alpha:0.12)),
            ),
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: cs.primary.withValues(alpha:0.12), shape: BoxShape.circle),
              child: Center(
                child: Text('${semestre.numero}',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.primary)),
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
                color: cs.primary.withValues(alpha:0.5),
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
/// Usa cs.primary como color de acento, coherente con los
/// tiles de semestre de esta pantalla.
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
                decoration: BoxDecoration(color: cs.primary.withValues(alpha:0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.grid_view_rounded, color: cs.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(reticula.nombre,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                const SizedBox(height: 3),
                Text(reticula.clave,
                    style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha:0.4), letterSpacing: 0.2)),
              ])),
              Icon(Icons.picture_as_pdf_rounded, color: cs.primary.withValues(alpha:0.5), size: 20),
            ]),
          ),
        ),
      ),
    );
  }
}


