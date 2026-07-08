// ═════════════════════════════════════════════════════════════════
// storage_service.dart — Aspirantes ITVH
//
// Servicio centralizado para subir y eliminar archivos en Cloudflare
// R2. Versión recortada respecto a Comunidad ITVH: esta app solo
// necesita foto de perfil y media de publicaciones (no hay historias
// ni marketplace todavía). Si se agregan esas features después, se
// puede portar el resto de storage_service.dart de Comunidad ITVH.
//
// FIX DE SEGURIDAD (jul 2026): esta versión YA NO usa el paquete
// `minio` con credenciales de R2 embebidas en el cliente. Ese
// enfoque exponía accessKey/secretKey con permisos de
// lectura/escritura/borrado dentro del propio APK (extraíbles con
// solo descompilarlo). Ahora TODA subida pasa por la Edge Function
// `generar-url-subida`, que:
//   1. Verifica que quien pide la URL es un usuario autenticado real.
//   2. Verifica que el bucket esté en la lista blanca permitida.
//   3. Verifica que el path empiece con el userId del usuario (nadie
//      puede sobreescribir archivos de otra persona).
//   4. Devuelve una URL PUT firmada de corta duración.
// El cliente Flutter nunca ve accessKey/secretKey — solo hace un
// PUT HTTP directo a la URL firmada que le entrega la función.
//
// El borrado (eliminarDeR2) sigue el mismo patrón: llama a una
// segunda Edge Function, `eliminar-objeto-r2`, que valida el mismo
// tipo de reglas antes de borrar. Ver nota al final de este archivo
// con el código sugerido para esa función si aún no existe.
//
// Flujo general por archivo:
//   1. Comprimir imagen (JPEG q70) o video (calidad media, ffmpeg)
//   2. Pedir URL firmada a la Edge Function `generar-url-subida`
//   3. Subir el archivo comprimido con un PUT directo a esa URL
//   4. Eliminar el archivo temporal generado por la compresión
//   5. Devolver la URL pública CDN del objeto subido
//
// Métodos públicos (misma firma que la versión anterior, ningún
// caller necesita cambios):
//   • subirFotoPerfil(file, userId)
//       → sube avatar a itvh-aspirantes-perfil/<userId>/avatar_<ts>.jpg
//
//   • subirMediaPublicacion(file, postId, userId, orden, onProgress?)
//       → sube imagen o video a
//         itvh-aspirantes-publicaciones/<userId>/<postId>/<orden>.[jpg|mp4]
//
//   • eliminarDeR2(bucket, path)
//       → elimina un objeto de cualquier bucket R2
// ═════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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


  // ─────────────────────────────────────────────────────────────
  // FOTO DE PERFIL
  //
  // Bucket : itvh-aspirantes-perfil
  // Path   : <userId>/avatar_<timestamp>.jpg
  //
  // NOTA (actualizada): el path incluye un timestamp, así que YA NO
  // sobreescribe el avatar anterior con el mismo nombre — esto es
  // intencional, para evitar que el CDN siga sirviendo en caché la
  // foto vieja justo después de que el usuario la cambia (mismo path
  // = misma URL cacheada = avatar "atorado" visualmente).
  //
  // Contraparte de ese cache-busting: cada cambio de foto deja el
  // avatar anterior huérfano en R2 (nadie lo borra automáticamente
  // desde aquí). Si esto importa a mediano plazo (costo de storage,
  // limpieza), la forma de resolverlo es que quien llama a este
  // método guarde el path anterior (ya disponible en
  // perfiles_aspirantes.cdn_foto_perfil antes de sobreescribirlo) y
  // llame a eliminarDeR2() con ese path justo después de que esta
  // función regrese la nueva URL.
  // ─────────────────────────────────────────────────────────────
  Future<String> subirFotoPerfil({
    required File   file,
    required String userId,
  }) async {
    final compressed = await _comprimirImagen(file);
    try {
      final version = DateTime.now().millisecondsSinceEpoch;
      final path = '$userId/avatar_$version.jpg';
      await _subirViaUrlFirmada(
        file:        compressed,
        bucket:      R2Config.bucketPerfil,
        path:        path,
        contentType: 'image/jpeg',
      );
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
  // [onProgress] solo se invoca durante la COMPRESIÓN del video
  // (igual que antes); la subida en sí vía PUT firmado no reporta
  // progreso incremental.
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
        await _subirViaUrlFirmada(
          file:        compressed,
          bucket:      R2Config.bucketPublicaciones,
          path:        path,
          contentType: 'video/mp4',
        );
        return '${R2Config.dominioPublicaciones}/$path';
      } finally {
        await _limpiar(compressed);
      }
    } else {
      final compressed = await _comprimirImagen(file);
      try {
        final path = '$userId/$postId/$orden.jpg';
        await _subirViaUrlFirmada(
          file:        compressed,
          bucket:      R2Config.bucketPublicaciones,
          path:        path,
          contentType: 'image/jpeg',
        );
        return '${R2Config.dominioPublicaciones}/$path';
      } finally {
        await _limpiar(compressed);
      }
    }
  }


  // ─────────────────────────────────────────────────────────────
  // ELIMINAR DE R2
  //
  // Elimina un objeto de cualquier bucket R2, vía la Edge Function
  // `eliminar-objeto-r2` (requiere sesión activa; la función valida
  // bucket permitido y que el path pertenezca al usuario, igual que
  // `generar-url-subida`).
  // ─────────────────────────────────────────────────────────────
  Future<void> eliminarDeR2({
    required String bucket,
    required String path,
  }) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      throw Exception('Tu sesión expiró, vuelve a iniciar sesión');
    }

    final response = await http.post(
      Uri.parse('${R2Config.edgeFunctionsUrl}/eliminar-objeto-r2'),
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type':  'application/json',
      },
      body: jsonEncode({'bucket': bucket, 'path': path}),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar archivo (${response.statusCode}): ${response.body}');
    }
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
  ///
  /// Si FFmpeg falla después de haber escrito parcialmente el
  /// archivo de salida, ese archivo temporal se borra antes de
  /// relanzar el error (evita dejar restos a medio escribir en la
  /// carpeta temporal).
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
      // Limpieza defensiva: si FFmpeg alcanzó a escribir algo del
      // archivo de salida antes de fallar, lo borramos para no dejar
      // basura a medio comprimir en la carpeta temporal.
      await _limpiar(File(outPath));
      throw Exception('Error al comprimir video (código: $returnCode)');
    }

    final outFile = File(outPath);
    if (!await outFile.exists()) {
      throw Exception('Error al comprimir video: archivo de salida no encontrado');
    }

    return outFile;
  }

  /// Sube un [File] a R2 en dos pasos:
  ///   1. Pide una URL PUT firmada a la Edge Function
  ///      `generar-url-subida` (requiere sesión activa).
  ///   2. Hace el PUT directo del archivo a esa URL firmada.
  ///
  /// El cliente nunca maneja credenciales de R2 — solo el token de
  /// sesión de Supabase, que la Edge Function usa para validar al
  /// usuario antes de firmar la URL.
  Future<void> _subirViaUrlFirmada({
    required File   file,
    required String bucket,
    required String path,
    required String contentType,
  }) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      throw Exception('Tu sesión expiró, vuelve a iniciar sesión');
    }

    // 1. Pedir la URL firmada.
    final urlResponse = await http.post(
      Uri.parse('${R2Config.edgeFunctionsUrl}/generar-url-subida'),
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type':  'application/json',
      },
      body: jsonEncode({
        'bucket':      bucket,
        'path':        path,
        'contentType': contentType,
      }),
    );

    if (urlResponse.statusCode != 200) {
      throw Exception(
        'No se pudo generar la URL de subida (${urlResponse.statusCode}): ${urlResponse.body}',
      );
    }

    final urlFirmada = (jsonDecode(urlResponse.body) as Map<String, dynamic>)['url'] as String?;
    if (urlFirmada == null || urlFirmada.isEmpty) {
      throw Exception('La Edge Function no devolvió una URL de subida válida');
    }

    // 2. Subir el archivo directo a R2 con esa URL firmada.
    final bytes = await file.readAsBytes();
    final putResponse = await http.put(
      Uri.parse(urlFirmada),
      headers: {'Content-Type': contentType},
      body: bytes,
    );

    if (putResponse.statusCode != 200 && putResponse.statusCode != 204) {
      throw Exception('Error al subir a R2 (${putResponse.statusCode}): ${putResponse.body}');
    }
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

// ═════════════════════════════════════════════════════════════════
// PENDIENTES para que esta versión funcione end-to-end:
//
// 1. r2_config.dart necesita un campo nuevo con la URL base de tus
//    Edge Functions (ya NO necesita endPoint/accessKey/secretKey,
//    esos ahora solo existen del lado del servidor):
//
//      class R2Config {
//        static const edgeFunctionsUrl =
//            'https://<tu-project-ref>.supabase.co/functions/v1';
//
//        static const bucketPerfil        = 'itvh-aspirantes-perfil';
//        static const dominioPerfil       = 'https://pub-xxxx.r2.dev';
//        static const bucketPublicaciones = 'itvh-aspirantes-publicaciones';
//        static const dominioPublicaciones= 'https://pub-yyyy.r2.dev';
//      }
//
// 2. pubspec.yaml: quitar la dependencia `minio`, ya no se usa.
//    Confirmar que `http` esté como dependencia (probablemente ya
//    la tienes por otras partes de la app).
//
// 3. Falta crear la Edge Function `eliminar-objeto-r2` (hermana de
//    `generar-url-subida`, mismo patrón de validación). Ejemplo:
//
//      // supabase/functions/eliminar-objeto-r2/index.ts
//      import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'
//      import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
//      import { AwsClient } from 'https://esm.sh/aws4fetch@1.0.17'
//
//      const R2_ACCOUNT_ID        = Deno.env.get('R2_ACCOUNT_ID')!
//      const R2_ACCESS_KEY_ID     = Deno.env.get('R2_ACCESS_KEY_ID')!
//      const R2_SECRET_ACCESS_KEY = Deno.env.get('R2_SECRET_ACCESS_KEY')!
//
//      const BUCKETS_PERMITIDOS = new Set([
//        'itvh-aspirantes-perfil',
//        'itvh-aspirantes-publicaciones',
//      ])
//
//      serve(async (req) => {
//        if (req.method !== 'POST') {
//          return new Response('Método no permitido', { status: 405 })
//        }
//
//        const authHeader = req.headers.get('Authorization')
//        if (!authHeader) return new Response('No autorizado', { status: 401 })
//
//        const supabase = createClient(
//          Deno.env.get('SUPABASE_URL')!,
//          Deno.env.get('SUPABASE_ANON_KEY')!,
//          { global: { headers: { Authorization: authHeader } } },
//        )
//
//        const { data: { user }, error } = await supabase.auth.getUser()
//        if (error || !user) return new Response('No autorizado', { status: 401 })
//
//        const { bucket, path } = await req.json()
//
//        if (!BUCKETS_PERMITIDOS.has(bucket)) {
//          return new Response('Bucket no permitido', { status: 400 })
//        }
//        if (!path.startsWith(`${user.id}/`)) {
//          return new Response('Ruta no autorizada para este usuario', { status: 403 })
//        }
//
//        const client = new AwsClient({
//          accessKeyId:     R2_ACCESS_KEY_ID,
//          secretAccessKey: R2_SECRET_ACCESS_KEY,
//          service: 's3',
//          region:  'auto',
//        })
//
//        const endpoint = `https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com/${bucket}/${path}`
//
//        const respuesta = await client.fetch(endpoint, { method: 'DELETE' })
//
//        if (!respuesta.ok) {
//          return new Response('Error al eliminar en R2', { status: 502 })
//        }
//
//        return new Response('OK', { status: 200 })
//      })
//
//    Desplegar con: supabase functions deploy eliminar-objeto-r2
// ═════════════════════════════════════════════════════════════════