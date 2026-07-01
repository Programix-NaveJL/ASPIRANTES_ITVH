// ═════════════════════════════════════════════════════════════════
// storage_service.dart — Aspirantes ITVH
//
// Servicio centralizado para subir y eliminar archivos en Cloudflare
// R2. Versión recortada respecto a Comunidad ITVH: esta app solo
// necesita foto de perfil y media de publicaciones (no hay historias
// ni marketplace todavía). Si se agregan esas features después, se
// puede portar el resto de storage_service.dart de Comunidad ITVH.
//
// Flujo general por archivo:
//   1. Comprimir imagen (JPEG q70) o video (calidad media, ffmpeg)
//   2. Subir al bucket R2 correspondiente vía protocolo S3
//   3. Eliminar el archivo temporal generado por la compresión
//   4. Devolver la URL pública CDN del objeto subido
//
// Métodos públicos:
//   • subirFotoPerfil(file, userId)
//       → sube avatar a itvh-aspirantes-perfil/<userId>/avatar.jpg
//
//   • subirMediaPublicacion(file, postId, userId, orden, onProgress?)
//       → sube imagen o video a
//         itvh-aspirantes-publicaciones/<userId>/<postId>/<orden>.[jpg|mp4]
//
//   • eliminarDeR2(bucket, path)
//       → elimina un objeto de cualquier bucket R2
// ═════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:minio/minio.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/statistics.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'r2_config.dart';


/// Firma del callback de progreso. [porcentaje] va de 0.0 a 100.0.
typedef ProgresoCallback = void Function(double porcentaje);


class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  final Minio _r2 = Minio(
    endPoint:  R2Config.endPoint,
    accessKey: R2Config.accessKey,
    secretKey: R2Config.secretKey,
    useSSL:    true,
    region:    'auto',
  );


  // ─────────────────────────────────────────────────────────────
  // FOTO DE PERFIL
  //
  // Bucket : itvh-aspirantes-perfil
  // Path   : <userId>/avatar.jpg
  //
  // Siempre sobreescribe el avatar anterior con el mismo path,
  // por lo que no se acumulan archivos huérfanos en R2.
  // ─────────────────────────────────────────────────────────────
  Future<String> subirFotoPerfil({
    required File   file,
    required String userId,
  }) async {
    final compressed = await _comprimirImagen(file);
    try {
      final path = '$userId/avatar.jpg';
      await _subirAR2(compressed, R2Config.bucketPerfil, path, 'image/jpeg');
      return '${R2Config.dominioPerfil}/$path';
    } finally {
      await _limpiar(compressed);
    }
  }


  // ─────────────────────────────────────────────────────────────
  // MEDIA DE PUBLICACIÓN
  //
  // Bucket : itvh-aspirantes-publicaciones
  // Path   : <userId>/<postId>/<orden>.jpg  |  <orden>.mp4
  //
  // Soporta carrusel — cada archivo recibe un índice de orden
  // para mantener la secuencia correcta en el feed.
  //
  // [onProgress] solo se invoca cuando el archivo es un video
  // (la compresión de imagen es prácticamente instantánea).
  // ─────────────────────────────────────────────────────────────
  Future<String> subirMediaPublicacion({
    required File   file,
    required String postId,
    required String userId,
    required int    orden,
    ProgresoCallback? onProgress,
  }) async {
    if (_esVideo(file.path)) {
      final compressed = await _comprimirVideo(file, onProgress: onProgress);
      try {
        final path = '$userId/$postId/$orden.mp4';
        await _subirAR2(compressed, R2Config.bucketPublicaciones, path, 'video/mp4');
        return '${R2Config.dominioPublicaciones}/$path';
      } finally {
        await _limpiar(compressed);
      }
    } else {
      final compressed = await _comprimirImagen(file);
      try {
        final path = '$userId/$postId/$orden.jpg';
        await _subirAR2(compressed, R2Config.bucketPublicaciones, path, 'image/jpeg');
        return '${R2Config.dominioPublicaciones}/$path';
      } finally {
        await _limpiar(compressed);
      }
    }
  }


  // ─────────────────────────────────────────────────────────────
  // ELIMINAR DE R2
  //
  // Elimina un objeto de cualquier bucket R2.
  // El caller es responsable de proporcionar el bucket y path
  // correctos — no hay validación previa de existencia.
  // ─────────────────────────────────────────────────────────────
  Future<void> eliminarDeR2({
    required String bucket,
    required String path,
  }) async {
    await _r2.removeObject(bucket, path);
  }


  // ─────────────────────────────────────────────────────────────
  // MÉTODOS PRIVADOS
  // ─────────────────────────────────────────────────────────────

  /// Comprime una imagen a JPEG con calidad 70.
  Future<File> _comprimirImagen(File file) async {
    final dir        = await getTemporaryDirectory();
    final targetPath = '${dir.path}/cmp_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70,
      format:  CompressFormat.jpeg,
    );

    if (result == null) throw Exception('Error al comprimir imagen');
    return File(result.path);
  }

  /// Comprime un video conservando el audio, usando FFmpeg
  /// (libx264 + AAC, escalado a 960px de lado mayor).
  ///
  /// Si se proporciona [onProgress], se invoca repetidamente durante
  /// la compresión con el porcentaje de avance (0-100), calculado a
  /// partir de la duración real del video (vía FFprobe) contra el
  /// tiempo ya procesado por FFmpeg.
  Future<File> _comprimirVideo(
      File file, {
        ProgresoCallback? onProgress,
      }) async {
    double duracionMs = 0;
    final probeSession = await FFprobeKit.getMediaInformation(file.path);
    final info = probeSession.getMediaInformation();
    if (info != null) {
      duracionMs = (double.tryParse(info.getDuration() ?? '0') ?? 0) * 1000;
    }

    final dir = await getTemporaryDirectory();
    final outPath = '${dir.path}/cmp_${DateTime.now().millisecondsSinceEpoch}.mp4';

    final cmd = '-y -i "${file.path}" '
        '-vf "scale=\'if(gt(iw,ih),960,-2)\':\'if(gt(iw,ih),-2,960)\'" '
        '-c:v libx264 -preset veryfast -crf 26 '
        '-c:a aac -b:a 128k '
        '"$outPath"';

    final completer = Completer<void>();

    final session = await FFmpegKit.executeAsync(
      cmd,
          (session) async {
        if (!completer.isCompleted) completer.complete();
      },
      null,
          (Statistics stats) {
        if (duracionMs > 0 && onProgress != null) {
          final pct = (stats.getTime() / duracionMs * 100).clamp(0, 100);
          onProgress(pct.toDouble());
        }
      },
    );

    await completer.future;

    final returnCode = await session.getReturnCode();
    if (!ReturnCode.isSuccess(returnCode)) {
      throw Exception('Error al comprimir video (código: $returnCode)');
    }

    final outFile = File(outPath);
    if (!await outFile.exists()) {
      throw Exception('Error al comprimir video: archivo de salida no encontrado');
    }

    return outFile;
  }

  /// Sube un [File] a R2 en el [bucket] y [path] indicados.
  Future<void> _subirAR2(
      File   file,
      String bucket,
      String path,
      String contentType,
      ) async {
    final bytes  = await file.readAsBytes();
    final stream = Stream.value(bytes);

    await _r2.putObject(
      bucket,
      path,
      stream,
      size:     bytes.length,
      metadata: {'Content-Type': contentType},
    );
  }

  bool _esVideo(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith('.mp4') ||
        ext.endsWith('.mov') ||
        ext.endsWith('.avi') ||
        ext.endsWith('.mkv');
  }

  Future<void> _limpiar(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}