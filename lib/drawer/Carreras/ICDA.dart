// ═════════════════════════════════════════════════════════════════
// ICDA.dart
//
// Pantalla informativa de la Ingeniería en Ciencias de Datos (ICDA).
//
// Secciones:
//   • Objetivo General     — descripción del propósito de la carrera
//   • Perfil de Ingreso    — características deseables del aspirante
//   • Perfil de Egreso     — competencias del profesional al egresar
//   • Retícula ICDA-2024-247 — un plan con enlace a PDF
//   • Plan de Estudios     — ExpansionTile por semestre (1–9)
//
// Widgets privados de esta pantalla:
//   • _SemestreExpansion — tile expandible de un semestre;
//                          usa cs.tertiary como acento, al igual que
//                          IINF, para distinguirse de ISC (primary) e
//                          ITIC (secondary) dentro del mismo departamento
//   • _MateriaItem       — fila tappable que abre PdfViewerScreen;
//                          si la URL está vacía deshabilita el tap
//                          y cambia el ícono a info
//   • _SectionTitle      — título de sección con barra de acento cs.tertiary
//   • _PerfilSection     — lista de bullets con punto de color
//   • _ReticulaItem      — card tappable que abre PdfViewerScreen
//
// Modelos de datos (privados):
//   • _Reticula  — clave, nombre y URL de una retícula (instancia única)
//   • _Materia   — nombre y URL de un temario en PDF
//   • _Semestre  — número y lista de materias
//
// Color de acento:
//   • cs.tertiary — color principal de la carrera en toda la pantalla
//   • cs.primary  — acento del Perfil de Egreso (contraste con ingreso)
//
// Notas de implementación:
//   • ICDA es la carrera más nueva del campus (plan 2024); no tiene
//     especialidades definidas aún, por lo que la pantalla omite esa
//     sección a diferencia del resto de carreras.
//   • Los temarios apuntan al servidor de Acapulco TecNM (_base),
//     no al de Villahermosa, porque el plan 2024 es nacional y los
//     PDFs aún no tienen espejo local.
//   • El header incluye un segundo chip "Nueva carrera" además del
//     chip de departamento, lo que requiere un Row en lugar del
//     Align simple de otras pantallas; el padding bottom es 84 en
//     vez de 56 para dar espacio a la fila de dos chips.
//   • El título del SliverAppBar tiene padding right: 60 (en vez de
//     20) para evitar que el texto largo colisione con los botones
//     de la AppBar al estar expandido.
// ═════════════════════════════════════════════════════════════════

import 'package:aspirantes_itvh_app/drawer/Carreras/pdf_viewer_screen.dart';
import 'package:flutter/material.dart';


// ═════════════════════════════════════════════════════════════════
// PANTALLA PRINCIPAL
// ═════════════════════════════════════════════════════════════════

class ICDAScreen extends StatelessWidget {
  const ICDAScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [

          // SliverAppBar expandible: colapsa al hacer scroll y
          // muestra solo el título fijo en la barra superior.
          // expandedHeight: 220 (vs 200 del resto) por la fila de dos chips.
          SliverAppBar(
            expandedHeight: 220,
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
                  // Fondo con tinte en cs.tertiary — color de acento de ICDA.
                  Container(color: cs.tertiary.withValues(alpha: 0.12)),

                  // Ícono decorativo semitransparente en esquina superior derecha.
                  Positioned(
                    right: -30, top: -20,
                    child: Icon(Icons.bar_chart_rounded, size: 220, color: cs.tertiary.withValues(alpha: 0.07)),
                  ),

                  // Fila de chips: departamento + "Nueva carrera".
                  // padding bottom: 84 para separar la fila del título.
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 84),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: cs.tertiary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Departamento de Sistemas y Computación',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.tertiary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Chip sólido en cs.tertiary para destacar que
                          // es la carrera más nueva del campus.
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: cs.tertiary.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Nueva carrera',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.onTertiary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Título grande visible solo cuando el SliverAppBar está expandido.
                  // padding right: 60 para evitar colisión con botones de la AppBar.
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 60, 20),
                      child: Text(
                        'Ing. en Ciencias de Datos',
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
                    color: cs.tertiary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.tertiary.withValues(alpha: 0.15)),
                  ),
                  child: Text(
                    'Formar ingenieros competentes que modelan, implementan y evalúan datos provenientes de entornos complejos, utilizando técnicas de vanguardia que le permitan la identificación, visualización y comprensión de patrones, que facilitan la toma de decisiones estratégicas en los sectores educativo, empresarial, social e industrial a través de equipos multidisciplinarios con enfoque ético y sostenible.',
                    style: TextStyle(fontSize: 14, height: 1.65, color: cs.onSurface.withValues(alpha: 0.8)),
                  ),
                ),

                const SizedBox(height: 28),

                // Perfil de ingreso — cs.tertiary como acento principal de ICDA.
                _SectionTitle(cs: cs, texto: 'Perfil de Ingreso'),
                const SizedBox(height: 12),
                _PerfilSection(cs: cs, color: cs.tertiary, items: const [
                  'Habilidades lógico-matemáticas, de programación, pensamiento crítico, comunicación y curiosidad y disposición para el aprendizaje.',
                  'Capacidad creativa, analítica, de resolución de problemas y emprendedora.',
                  'Liderazgo y capacidad de trabajo en equipos multidisciplinarios.',
                  'Razonamiento cuantitativo y pensamiento analítico.',
                  'Conciencia ética y social.',
                  'Compromiso con el desarrollo sostenible.',
                  'Habilidades de aprendizaje autónomo y capacidad de síntesis.',
                  'Capacidad para reconocer y valorar el diseño estético y funcional de productos tecnológicos.',
                ]),

                const SizedBox(height: 28),

                // Perfil de egreso — cs.primary para diferenciarlo
                // visualmente del perfil de ingreso (tertiary).
                _SectionTitle(cs: cs, texto: 'Perfil de Egreso'),
                const SizedBox(height: 12),
                _PerfilSection(cs: cs, color: cs.primary, items: const [
                  'Domina técnicas de recolección, limpieza y preparación de datos para garantizar la confiabilidad de los usuarios elevando su productividad y competitividad.',
                  'Implementa estrategias tecnológicas para la administración, almacenamiento y gobernanza de los datos considerando las implicaciones éticas y legales.',
                  'Diseña y desarrolla arquitecturas de datos escalables, procesos de extracción, transformación y carga (ETL) así como secuencias de datos para gestionar grandes volúmenes de información con responsabilidad social.',
                  'Construye modelos de aprendizaje máquina y aprendizaje profundo en el desarrollo de soluciones de alta especialidad para entornos complejos, respetando el marco legal internacional con responsabilidad social y respeto a los derechos humanos.',
                  'Aplica la lógica de los lenguajes de programación para generar código y funciones que permitan la manipulación y análisis de datos con excelencia.',
                  'Implementa y gestiona sistemas embebidos en dispositivos de internet de las cosas para garantizar la recopilación y transmisión de datos de manera eficiente y confiable.',
                  'Planifica, ejecuta y gestiona proyectos de ciencia de datos para asegurar soluciones que cumplan con los objetivos y requisitos de la organización con sentido ético.',
                ]),

                const SizedBox(height: 28),

                // Retícula — un único plan disponible para ICDA (2024).
                _SectionTitle(cs: cs, texto: 'Retícula ICDA-2024-247'),
                const SizedBox(height: 12),
                _ReticulaItem(cs: cs, reticula: _reticula),

                const SizedBox(height: 28),

                // Plan de Estudios — un ExpansionTile por semestre.
                // No hay sección de Especialidades: el plan 2024 aún
                // no las tiene definidas en el campus.
                _SectionTitle(cs: cs, texto: 'Plan de Estudios'),
                const SizedBox(height: 12),
                ..._semestres.map((sem) => _SemestreExpansion(cs: cs, semestre: sem)),

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

// Instancia única: ICDA solo tiene un plan de estudios disponible.
const _reticula = _Reticula(
  clave: 'ICDA-2024-247',
  nombre: 'Retícula 2024',
  url: 'https://pub-f883231412d746839d3a41f6bc354031.r2.dev/ICDA/ICDA-2024-247P.pdf',
);

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

// URL base en el servidor de Acapulco TecNM: el plan 2024 es nacional
// y los PDFs de temarios aún no tienen espejo en el servidor de Villahermosa.
const _base = 'https://acapulco.tecnm.mx/wp-content/uploads/carreras/ingenieria_en_ciencias_de_datos';

final _semestres = [
  _Semestre(1, [
    _Materia('Cálculo Diferencial',                        '$_base/01/ACF-2301-Calculo-diferencial.pdf'),
    _Materia('Fundamentos de Investigación',               '$_base/01/ACC-0906-Fundamentos-de-investigacion.pdf'),
    _Materia('Química',                                    '$_base/01/AEC-1058-Quimica.pdf'),
    _Materia('Fundamentos de Programación',                '$_base/01/CDB-2408-Fundamentos-de-programacion.pdf'),
    _Materia('Matemáticas Discretas',                      '$_base/01/CDF-2416-Matematicas-discretas.pdf'),
    _Materia('Introducción a la Ing. en Ciencia de Datos', '$_base/01/CDI-2413-Introduccion-a-la-ingenieria-en-ciencia-de-datos.pdf'),
  ]),
  _Semestre(2, [
    _Materia('Cálculo Integral',                              '$_base/02/ACF-0902-Calculo-integral.pdf'),
    _Materia('Programación Orientada a Objetos',              '$_base/02/CDD-2421-Programacion-orientada-a-objetos.pdf'),
    _Materia('Principios Eléctricos y Aplicaciones Digitales','$_base/02/CDF-2418-Principios-electricos-y-aplicaciones-digitales.pdf'),
    _Materia('Taller de Ética',                               '$_base/02/ACH-2307-Taller-de-etica.pdf'),
    _Materia('Desarrollo Sustentable',                        '$_base/02/ACD-0908-Desarrollo-sustentable.pdf'),
    _Materia('Física General',                                '$_base/02/AEF-24129-Fisica-General.pdf'),
  ]),
  _Semestre(3, [
    _Materia('Cálculo Vectorial',          '$_base/03/ACF-0904-Calculo-vectorial.pdf'),
    _Materia('Estructura de Datos',        '$_base/03/CDD-2407-Estructura-de-datos.pdf'),
    _Materia('Álgebra Lineal',             '$_base/03/ACF-0903-Algebra-lineal.pdf'),
    _Materia('Arquitectura de Computadoras','$_base/03/AEE-24123-Arquitectura-de-computadoras.pdf'),
    _Materia('Probabilidad y Estadística', '$_base/03/AEF-24126-Probabilidad-y-estadistica.pdf'),
    _Materia('Taller de Liderazgo',        '$_base/03/AEC-24130-Taller-de-liderazgo.pdf'),
  ]),
  _Semestre(4, [
    _Materia('Ecuaciones Diferenciales',                  '$_base/04/ACF-0905-Ecuaciones-diferenciales.pdf'),
    _Materia('Métodos Numéricos',                         '$_base/04/AEC-24128-Metodos-numericos.pdf'),
    _Materia('Fundamentos de Redes',                      '$_base/04/CDJ-2409-Fundamentos-de-redes.pdf'),
    _Materia('Programación Avanzada para Ciencia de Datos','$_base/04/CDC-2420-Programacion-avanzada-para-ciencia-de-datos.pdf'),
    _Materia('Fundamentos de Bases de Datos',             '$_base/04/AEF-24124-Fundamentos-de-bases-de-datos.pdf'),
    _Materia('Estadística Inferencial',                   '$_base/04/AEF-24121-Estadistica-inferencial.pdf'),
  ]),
  _Semestre(5, [
    _Materia('Lenguajes y Autómatas',            '$_base/05/CDD-2415-Lenguajes-y-automatas.pdf'),
    _Materia('Inteligencia Artificial',          '$_base/05/CDC-2411-Inteligencia-artificial.pdf'),
    _Materia('Ciberseguridad',                   '$_base/05/CDH-2405-Ciberseguridad.pdf'),
    _Materia('Adquisición de Datos',             '$_base/05/CDD-2401-Adquisicion-de-datos.pdf'),
    _Materia('Bases de Datos No Relacionales',   '$_base/05/AEC-24125-Bases-de-datos-no-relacionales.pdf'),
    _Materia('Estadística para Ciencia de Datos','$_base/05/CDD-2406-Estadistica-para-ciencia-de-datos.pdf'),
  ]),
  _Semestre(6, [
    _Materia('Inteligencia de Negocios',   '$_base/06/CDC-2412-Inteligencia-de-negocios.pdf'),
    _Materia('Investigación de Operaciones','$_base/06/CDD-2414-Investigacion-de-operaciones.pdf'),
    _Materia('Aprendizaje Automático',     '$_base/06/CDF-2402-Aprendizaje-automatico.pdf'),
    _Materia('Internet de las Cosas',      '$_base/06/AED-2A122-Internet-de-las-cosas.pdf'),
    _Materia('Ingeniería de Software',     '$_base/06/CDC-2410-Ingenieria-software.pdf'),
    _Materia('Taller de Investigación I',  '$_base/06/AC009-Taller-de-investigacion-I.pdf'),
  ]),
  _Semestre(7, [
    _Materia('Taller de Investigación II',        '$_base/07/AC010-Taller-de-investigacion-II.pdf'),
    _Materia('Visión Artificial',                 '$_base/07/CDF-2424-Vision-artificial.pdf'),
    _Materia('Procesamiento de Lenguaje Natural', '$_base/07/CDF-2419-Procesamiento-de-lenguaje-natural.pdf'),
    _Materia('Taller de Desarrollo Ágil',         '$_base/07/CDD-2422-Taller-de-desarrollo-agil.pdf'),
    _Materia('Arquitectura de Datos en la Nube',  '$_base/07/CDC-2403-Arquitectura-de-datos-en-la-nube.pdf'),
  ]),
  _Semestre(8, [
    _Materia('Tópicos Selectos para Ciencia de Datos','$_base/08/CDA-2423-Topicos-selectos-para-ciencia-de-datos.pdf'),
    _Materia('Big Data',                              '$_base/08/CDD-2404-Big-Data.pdf'),
    _Materia('Visualización de Datos',                '$_base/08/CDF-2425-Visualizacion-de-datos.pdf'),
  ]),
  // 9no semestre: mezcla una materia con PDF real y tres sin URL.
  // _MateriaItem detecta hasUrl y maneja ambos casos automáticamente.
  _Semestre(9, [
    _Materia('Metodologías para Proyectos en Ciencia de Datos','$_base/09/CDH-2417-Metodologias-para-proyectos-en-ciencia-de-datos.pdf'),
    _Materia('Residencia Profesional',  ''),
    _Materia('Servicio Social',         ''),
    _Materia('Actividades Complementarias', ''),
  ]),
];


// ═════════════════════════════════════════════════════════════════
// WIDGETS PRIVADOS
// ═════════════════════════════════════════════════════════════════

/// Tile expandible que muestra las materias de un semestre.
/// Usa cs.tertiary como acento, igual que IINF, para distinguir
/// ICDA de ISC (cs.primary) e ITIC (cs.secondary) dentro del
/// mismo departamento.
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
            backgroundColor: cs.tertiary.withValues(alpha: 0.05),
            collapsedBackgroundColor: cs.tertiary.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.tertiary.withValues(alpha: 0.12)),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outline.withValues(alpha: 0.12)),
            ),
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: cs.tertiary.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Center(
                child: Text('${semestre.numero}',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.tertiary)),
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
                color: cs.tertiary.withValues(alpha: 0.5),
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
/// Usa cs.tertiary como color de acento, coherente con los tiles
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
        decoration: BoxDecoration(color: cs.tertiary, borderRadius: BorderRadius.circular(2)),
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
                  color: cs.tertiary.withValues(alpha: 0.12),
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
                    style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4), letterSpacing: 0.2)),
              ])),
              Icon(Icons.picture_as_pdf_rounded, color: cs.tertiary.withValues(alpha: 0.5), size: 20),
            ]),
          ),
        ),
      ),
    );
  }
}