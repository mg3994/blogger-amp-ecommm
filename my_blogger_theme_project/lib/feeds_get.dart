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
