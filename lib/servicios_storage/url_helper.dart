// ═════════════════════════════════════════════════════════════════
// url_helper.dart — Aspirantes ITVH
//
// Helper para resolver URLs públicas de medios.
//
// A diferencia de Comunidad ITVH, esta app nace ya con R2 desde el
// día uno — no hay migración desde Supabase Storage, así que no
// existe fallback a bucket viejo. Si en el futuro se requiere,
// se puede portar la lógica de resolverUrl() de Comunidad ITVH.
//
// Uso:
//   final url = resolverUrlPerfil(data);
//   final url = resolverUrlMedio(medio);
// ═════════════════════════════════════════════════════════════════

/// Resuelve la URL de la foto de perfil de un usuario aspirante.
/// Recibe un mapa de la tabla `perfiles_aspirantes`.
String resolverUrlPerfil(Map<String, dynamic> perfil) {
  return perfil['cdn_foto_perfil'] as String? ?? '';
}

/// Resuelve la URL de un medio de publicación.
/// Recibe un mapa de la tabla `publicacion_medios_aspirantes`.
String resolverUrlMedio(Map<String, dynamic> medio) {
  return medio['cdn_url'] as String? ?? '';
}