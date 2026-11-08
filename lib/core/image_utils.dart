/// MAL's CDN serves every poster as WebP too (much smaller than JPG).
String? optimizedImageUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  final u = Uri.tryParse(url);
  if (u != null && u.host.endsWith('myanimelist.net') && url.endsWith('.jpg')) {
    return '${url.substring(0, url.length - 4)}.webp';
  }
  return url;
}
