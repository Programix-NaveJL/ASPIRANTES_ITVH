// ═════════════════════════════════════════════════════════════════
// r2_config.dart — Aspirantes ITVH
//
// Credenciales y configuración de Cloudflare R2 para esta app.
// Buckets dedicados (independientes de Comunidad ITVH) para aislar
// el contenido de aspirantes.
//
// SEGURIDAD:
//   Las credenciales NO se hardcodean aquí. Se inyectan en tiempo de
//   compilación con --dart-define-from-file para evitar que queden
//   en texto plano dentro del repositorio (esto ya nos mordió una
//   vez en Comunidad ITVH — no lo repetimos aquí).
//
//   Comando de build/run:
//     flutter run --dart-define-from-file=r2_secrets.json
//
//   r2_secrets.json (NO se sube a git, va en .gitignore):
//   {
//     "R2_ACCOUNT_ID": "...",
//     "R2_ACCESS_KEY": "...",
//     "R2_SECRET_KEY": "..."
//   }
//
// ── NOTA IMPORTANTE ─────────────────────────────────────────────
// String.fromEnvironment(name) espera el NOMBRE de la variable de
// entorno definida vía --dart-define, NO el valor en sí. Pasarle
// el valor real como si fuera el nombre (como estaba antes) hace
// que Dart busque una variable inexistente y regrese "" (string
// vacío) silenciosamente — sin error en tiempo de compilación, solo
// falla después, en runtime, al intentar usar credenciales vacías.
// ═════════════════════════════════════════════════════════════════

class R2Config {
  R2Config._();

  // ── Credenciales (inyectadas en build time) ───────────────────
  // El nombre aquí ('R2_ACCOUNT_ID', etc.) debe coincidir EXACTO
  // con la clave usada en r2_secrets.json y con --dart-define.
  static const String accountId = String.fromEnvironment('R2_ACCOUNT_ID');
  static const String accessKey = String.fromEnvironment('R2_ACCESS_KEY');
  static const String secretKey = String.fromEnvironment('R2_SECRET_KEY');

  static String get endPoint => '$accountId.r2.cloudflarestorage.com';

  // ── Buckets ─────────────────────────────────────────────────
  static const String bucketPerfil        = 'itvh-aspirantes-perfil';
  static const String bucketPublicaciones = 'itvh-aspirantes-publicaciones';

  // ── Dominios públicos (CDN) ─────────────────────────────────
  // Reemplaza por tu custom domain o el subdominio r2.dev que
  // habilitaste en el paso "Public access" de cada bucket.
  static const String dominioPerfil        = 'https://pub-18fdb12494a14724b0f9badea2fd0fdb.r2.dev';
  static const String dominioPublicaciones = 'https://pub-3e198ec7a9bf48d6835a1e037c2dea4d.r2.dev';
}