// ═════════════════════════════════════════════════════════════════
// pdf_viewer_screen.dart
//
// Pantalla de visualización de PDFs mediante Google Docs Viewer
// embebido en un WebView.
//
// Estrategia de carga:
//   • Construye una URL de Google Docs Viewer a partir de la URL
//     del PDF original y la carga en un WebViewController.
//   • Si la página no termina de cargar en _timeout segundos,
//     reintenta automáticamente hasta _maxIntentos veces.
//   • Tras agotar los reintentos muestra una pantalla de error
//     con botón de reintento manual.
//
// Acciones disponibles desde la AppBar:
//   • Compartir  — descarga el PDF a un archivo temporal y abre
//                  el selector de apps del sistema vía share_plus.
//   • Descargar  — copia el archivo temporal a
//                  /storage/emulated/0/Download/ (Android).
//
// Widgets internos: ninguno (pantalla autocontenida).
// ═════════════════════════════════════════════════════════════════

import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart';

class PdfViewerScreen extends StatefulWidget {
  /// Título que se muestra en la AppBar y se usa como nombre del
  /// archivo al guardar o compartir.
  final String titulo;

  /// URL pública del PDF que se desea visualizar.
  final String url;

  const PdfViewerScreen({super.key, required this.titulo, required this.url});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late final WebViewController _webController;

  bool    _cargando = true;
  bool    _error    = false;

  // Ruta local del PDF descargado. Si es null, el archivo aún no
  // se ha descargado; se usa para evitar descargas duplicadas.
  String? _rutaLocal;

  Timer?  _timeoutTimer;
  int     _intentos = 0;

  // Número máximo de reintentos automáticos antes de mostrar error.
  static const _maxIntentos = 3;

  // Tiempo de espera por intento antes de asumir que la carga falló.
  static const _timeout = Duration(seconds: 4);

  // URL de Google Docs Viewer. Se reconstruye cada vez que se accede
  // para incluir siempre la URL del PDF codificada correctamente.
  String get _viewerUrl =>
      'https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(widget.url)}';


  // ─────────────────────────────────────────────────────────────
  // CICLO DE VIDA
  // ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  @override
  void dispose() {
    // Cancelar el timer para evitar callbacks sobre un widget desmontado.
    _timeoutTimer?.cancel();
    super.dispose();
  }


  // ─────────────────────────────────────────────────────────────
  // WEBVIEW
  // ─────────────────────────────────────────────────────────────

  /// Configura el WebViewController con JavaScript habilitado,
  /// fondo blanco y los tres callbacks del NavigationDelegate.
  void _initWebView() {
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: _onPageStarted,
        onPageFinished: _onPageFinished,
        onWebResourceError: _onWebResourceError,
      ))
      ..loadRequest(Uri.parse(_viewerUrl));
  }

  /// Callback cuando el WebView empieza a cargar una página.
  /// Reinicia el overlay de carga y lanza el timer de timeout.
  void _onPageStarted(String url) {
    if (mounted) setState(() { _cargando = true; _error = false; });

    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(_timeout, () {
      if (!mounted || !_cargando) return;

      // Si quedan intentos, recargar; si no, mostrar error.
      if (_intentos < _maxIntentos) {
        _intentos++;
        _webController.loadRequest(Uri.parse(_viewerUrl));
      } else {
        setState(() { _cargando = false; _error = true; });
      }
    });
  }

  /// Callback cuando la página termina de cargar correctamente.
  /// Cancela el timer y oculta el overlay de carga.
  void _onPageFinished(String url) {
    _timeoutTimer?.cancel();
    _intentos = 0;
    if (mounted) setState(() => _cargando = false);
  }

  /// Callback para errores de recursos web.
  /// Solo actúa en errores del frame principal para no fallar
  /// por recursos secundarios (fuentes, analytics, etc.).
  void _onWebResourceError(WebResourceError e) {
    if (e.isForMainFrame ?? false) {
      _timeoutTimer?.cancel();
      if (mounted) setState(() { _cargando = false; _error = true; });
    }
  }


  // ─────────────────────────────────────────────────────────────
  // DESCARGA Y COMPARTIR
  // ─────────────────────────────────────────────────────────────

  /// Descarga el PDF a un directorio temporal y abre el selector
  /// de apps para compartirlo. Si ya existe la descarga previa,
  /// omite la descarga y va directo a compartir.
  ///
  /// Muestra un SnackBar de "Descargando…" durante la operación
  /// y uno de error si falla la petición HTTP.
  Future<void> _descargar() async {
    if (_rutaLocal != null) return _compartir();

    final snack = ScaffoldMessenger.of(context);
    snack.showSnackBar(SnackBar(
      content:  const Text('Descargando…'),
      behavior: SnackBarBehavior.floating,
      shape:    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // Duración larga para que persista hasta que la descarga termine o falle.
      duration: const Duration(seconds: 60),
    ));

    try {
      // HttpClient manual con badCertificateCallback permisivo para
      // soportar servidores con certificados autofirmados o vencidos
      // (algunos PDF del ITVH están en subdominios con SSL inconsistente).
      final httpClient = HttpClient()
        ..badCertificateCallback = (cert, host, port) => true;

      final request  = await httpClient.getUrl(Uri.parse(widget.url));
      final response = await request.close();
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final bytes = await consolidateHttpClientResponseBytes(response);

      // Sanitizar el título para usarlo como nombre de archivo:
      // se eliminan caracteres que no son letras, números, espacios
      // ni vocales acentuadas.
      final nombre = widget.titulo
          .replaceAll(RegExp(r'[^\w\sáéíóúÁÉÍÓÚñÑ]'), '')
          .trim();

      final dir  = await getTemporaryDirectory();
      final file = File('${dir.path}/$nombre.pdf');
      await file.writeAsBytes(bytes);
      _rutaLocal = file.path;

      snack.hideCurrentSnackBar();
      _compartir();
    } catch (e) {
      snack.hideCurrentSnackBar();
      snack.showSnackBar(SnackBar(
        content:         Text('Error: $e'),
        backgroundColor: Colors.red.shade700,
        behavior:        SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  /// Abre el selector de apps del sistema para compartir el PDF
  /// previamente descargado en _rutaLocal.
  Future<void> _compartir() async {
    if (_rutaLocal == null) return;
    await SharePlus.instance.share(
      ShareParams(
        files:   [XFile(_rutaLocal!)],
        subject: widget.titulo,
      ),
    );
  }

  /// Copia el archivo temporal a la carpeta de Descargas de Android.
  /// Si aún no se ha descargado, delega primero a _descargar().
  ///
  /// Nota: solo funciona en Android; en iOS el flujo de _compartir
  /// es el mecanismo equivalente para guardar en Files.
  Future<void> _guardarEnDescargas() async {
    if (_rutaLocal == null) { await _descargar(); return; }

    try {
      final nombre  = '${widget.titulo.replaceAll(RegExp(r'[^\w\s]'), '')}.pdf';
      final destino = File('/storage/emulated/0/Download/$nombre');
      await File(_rutaLocal!).copy(destino.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         Text('Guardado en Descargas/$nombre'),
          backgroundColor: Colors.green.shade700,
          behavior:        SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         Text('Error: $e'),
          backgroundColor: Colors.red.shade700,
          behavior:        SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }


  // ─────────────────────────────────────────────────────────────
  // RECARGA MANUAL
  // ─────────────────────────────────────────────────────────────

  /// Reinicia los contadores y recarga el viewer desde cero.
  /// Se llama desde el botón "Reintentar" en la pantalla de error.
  void _recargar() {
    _intentos = 0;
    setState(() { _cargando = true; _error = false; });
    _webController.loadRequest(Uri.parse(_viewerUrl));
  }


  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          widget.titulo,
          style:    const TextStyle(fontSize: 14),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor:        cs.surface,
        surfaceTintColor:       Colors.transparent,
        actions: [
          IconButton(
            icon:     const Icon(Icons.share_rounded),
            tooltip:  'Compartir',
            onPressed: _descargar,
          ),
          IconButton(
            icon:     const Icon(Icons.download_rounded),
            tooltip:  'Guardar en Descargas',
            onPressed: _guardarEnDescargas,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [

          // El WebView se mantiene en el árbol aunque haya error,
          // para no perder el estado de carga si el usuario reintenta.
          if (!_error) WebViewWidget(controller: _webController),

          // ── Pantalla de error ───────────────────────────────
          if (_error)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 52, color: cs.error),
                    const SizedBox(height: 16),
                    Text(
                      'No se pudo cargar el PDF',
                      style: TextStyle(
                          fontSize:   16,
                          fontWeight: FontWeight.bold,
                          color:      cs.onSurface),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Verifica tu conexión e intenta de nuevo.',
                      style: TextStyle(
                          fontSize: 13,
                          color:    cs.onSurface.withValues(alpha:0.5)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _recargar,
                      icon:  const Icon(Icons.refresh_rounded),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),

          // ── Overlay de carga ────────────────────────────────
          // Cubre el WebView mientras Google Docs Viewer renderiza
          // el PDF para evitar mostrar flashes en blanco.
          if (_cargando)
            Container(
              color: cs.surface,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: cs.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Cargando PDF…',
                      style: TextStyle(
                          color: cs.onSurface.withValues(alpha:0.6)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}