/// Parses [raw] and returns it only if it is a well-formed `https` URL with a
/// host and no embedded credentials, query string or fragment.
///
/// Used for the API base URL and for every URL the app is asked to open, so
/// cleartext (`http://`), `javascript:`, `file:` and custom schemes are refused.
Uri? parseHttpsUrl(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final uri = Uri.tryParse(raw.trim());
  if (uri == null) return null;
  if (uri.scheme != 'https') return null;
  if (uri.host.isEmpty) return null;
  if (uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment) return null;
  return uri;
}

/// Like [parseHttpsUrl] but allows a query string; for image URLs supplied by
/// the API (avatars), where signed URLs commonly carry a query.
Uri? parseHttpsImageUrl(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final uri = Uri.tryParse(raw.trim());
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
  if (uri.userInfo.isNotEmpty) return null;
  return uri;
}
