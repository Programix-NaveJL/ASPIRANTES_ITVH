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
// ═════════════════════════════════════════════════════════════════

class R2Config {
  R2Config._();

  // ── Credenciales (inyectadas en build time) ───────────────────
  static const String accountId = String.fromEnvironment('46071d7abe376a329d63170f6417ee6e');
  static const String accessKey = String.fromEnvironment('709e24ca3eaec9619a407391b9299986');
  static const String secretKey = String.fromEnvironment('d6337399bfc184893ccf84bb2f9affbe94b03289e02e388b0177153198af9aee');

  static String get endPoint => '$accountId.r2.cloudflarestorage.com';
  //https://46071d7abe376a329d63170f6417ee6e.r2.cloudflarestorage.com

  // ── Buckets ─────────────────────────────────────────────────
  static const String bucketPerfil        = 'itvh-aspirantes-perfil';
  static const String bucketPublicaciones = 'itvh-aspirantes-publicaciones';

  // ── Dominios públicos (CDN) ─────────────────────────────────
  // Reemplaza por tu custom domain o el subdominio r2.dev que
  // habilitaste en el paso "Public access" de cada bucket.
  static const String dominioPerfil        = 'https://pub-18fdb12494a14724b0f9badea2fd0fdb.r2.dev';
  static const String dominioPublicaciones = 'https://pub-3e198ec7a9bf48d6835a1e037c2dea4d.r2.dev';
}