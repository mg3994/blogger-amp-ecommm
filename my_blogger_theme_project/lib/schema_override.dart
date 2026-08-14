import 'dart:convert';

/// A class that handles building Blogger feed URLs for posts and summaries.
class FeedsGet {
  static String blogHomepageUrl = '';

  /// Builds a feed URL for blog posts with optional query parameters.
  static String posts({
    int? maxResults,
    String? orderBy,
    String? alt,
    String? label,
    String? postId,
    String? blogId,
  }) {
    // If we have both blogId and postId, we can use the direct blogger.com/feeds endpoint
    if (blogId != null && postId != null) {
      final params = <String>[];
      if (alt != null) params.add('alt=$alt');
      final query = params.isNotEmpty ? '?${params.join("&")}' : '';
      return 'https://www.blogger.com/feeds/$blogId/posts/default/$postId$query';
    }

    // Otherwise use blogHomepageUrl or path-relative feeds
    var path = 'feeds/posts/default';
    if (postId != null) {
      path += '/$postId';
    } else if (label != null) {
      path += '/-/$label';
    }

    final params = <String>[];
    if (maxResults != null) params.add('max-results=$maxResults');
    if (orderBy != null) params.add('orderby=$orderBy');
    if (alt != null) params.add('alt=$alt');
    final query = params.isNotEmpty ? '?${params.join("&")}' : '';

    final base = blogHomepageUrl.endsWith('/') ? blogHomepageUrl : '$blogHomepageUrl/';
    return '$base$path$query';
  }

  /// Builds a feed URL for summary with optional query parameters.
  static String summary({int? maxResults, String? alt}) {
    final params = <String>[];
    if (maxResults != null) params.add('max-results=$maxResults');
    if (alt != null) params.add('alt=$alt');
    final query = params.isNotEmpty ? '?${params.join("&")}' : '';
    final base = blogHomepageUrl.endsWith('/') ? blogHomepageUrl : '$blogHomepageUrl/';
    return '${base}feeds/summary$query';
  }
}

/// Helper class for resolving `@base` and `@id` references and merging JSON-LD schemas.
class SchemaOverride {
  /// Resolves an `@id` reference against a given `@base` context.
  /// `@base` is expected to be in the format of `blogID/blogpostID` (e.g. `118774185466060931/159915394249811386`).
  ///
  /// Returns a Map with 'blogId' and 'postId' keys.
  static Map<String, String> resolveId(String base, String id) {
    // If id is a full URL, we can treat it as a URL (Case C)
    if (id.startsWith('http://') || id.startsWith('https://')) {
      return {'url': id};
    }

    final baseParts = base.split('/');
    final defaultBlogId = baseParts.isNotEmpty ? baseParts[0] : '';
    final defaultPostId = baseParts.length > 1 ? baseParts[1] : '';

    final idParts = id.split('/');

    if (idParts.length == 1) {
      // Case A: The @id is a post ID only. We assume the blogID is the same as the one in @base.
      return {
        'blogId': defaultBlogId,
        'postId': idParts[0],
      };
    } else if (idParts.length >= 2) {
      // Case B: The @id is blogID/blogpostID.
      return {
        'blogId': idParts[0],
        'postId': idParts[1],
      };
    }

    return {
      'blogId': defaultBlogId,
      'postId': defaultPostId,
    };
  }

  /// Deep merges two JSON-LD maps. Override properties will override base properties.
  /// If lists of objects contain matching `@id` properties, they are recursively merged.
  static Map<String, dynamic> deepMerge(Map<String, dynamic> baseSchema, Map<String, dynamic> overrideSchema) {
    final merged = Map<String, dynamic>.from(baseSchema);

    overrideSchema.forEach((key, overrideValue) {
      final baseValue = merged[key];

      if (overrideValue is Map<String, dynamic> && baseValue is Map<String, dynamic>) {
        merged[key] = deepMerge(baseValue, overrideValue);
      } else if (overrideValue is List && baseValue is List) {
        merged[key] = _mergeLists(baseValue, overrideValue);
      } else {
        merged[key] = overrideValue;
      }
    });

    return merged;
  }

  /// Helper to merge lists of objects, matching them by `@id` if available.
  static List<dynamic> _mergeLists(List<dynamic> baseList, List<dynamic> overrideList) {
    final result = List<dynamic>.from(baseList);

    for (final overrideItem in overrideList) {
      if (overrideItem is Map<String, dynamic>) {
        final overrideId = overrideItem['@id'] ?? overrideItem['id'];
        if (overrideId != null) {
          // Find matching item in base list
          final index = result.indexWhere((baseItem) {
            if (baseItem is Map<String, dynamic>) {
              final baseId = baseItem['@id'] ?? baseItem['id'];
              return baseId == overrideId;
            }
            return false;
          });

          if (index != -1 && index >= 0) {
            // Found matching item: deep merge it
            result[index] = deepMerge(result[index] as Map<String, dynamic>, overrideItem);
          } else {
            // Not found: append
            result.add(overrideItem);
          }
        } else {
          // If no ID, append or replace depending on custom logic, here we append
          result.add(overrideItem);
        }
      } else {
        // Non-map types: append if not already present
        if (!result.contains(overrideItem)) {
          result.add(overrideItem);
        }
      }
    }

    return result;
  }
}
