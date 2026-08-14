import 'feeds_get.dart'; // Export/import compatibility

class ResolvedId {
  final String? blogId;
  final String? postId;
  final String? url;

  const ResolvedId({this.blogId, this.postId, this.url});
}

class SchemaOverride {
  /// Resolves an `@id` value relative to a base path or as an absolute URL.
  static ResolvedId resolveId(String base, String idValue) {
    if (idValue.isEmpty) return const ResolvedId();

    // 1. Full absolute HTTP/HTTPS URL
    if (idValue.startsWith('http://') || idValue.startsWith('https://')) {
      return ResolvedId(url: idValue);
    }

    // 2. Direct "blogId/postId" path string
    final parts = idValue.split('/');
    if (parts.length == 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return ResolvedId(blogId: parts[0], postId: parts[1]);
    }

    // 3. Relative ID against a base "blogId/postId" context
    if (base.isNotEmpty && base.contains('/')) {
      final baseParts = base.split('/');
      if (baseParts.isNotEmpty && baseParts[0].isNotEmpty) {
        return ResolvedId(blogId: baseParts[0], postId: idValue);
      }
    }

    return ResolvedId(url: idValue);
  }

  /// Deep merges two JSON objects. Source properties override Target properties.
  static Map<String, dynamic> deepMerge(
    Map<String, dynamic> target,
    Map<String, dynamic> source,
  ) {
    final Map<String, dynamic> output = Map<String, dynamic>.from(target);

    source.forEach((key, sourceVal) {
      final targetVal = output[key];

      if (sourceVal is Map<String, dynamic> && targetVal is Map<String, dynamic>) {
        output[key] = SchemaOverride.deepMerge(targetVal, sourceVal);
      } else {
        output[key] = sourceVal;
      }
    });

    return output;
  }
}
