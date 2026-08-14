import 'dart:convert';
import 'package:http/http.dart' as http;
import 'schema_override.dart';

class BloggerDataService {
  final http.Client _client;

  BloggerDataService({http.Client? client}) : _client = client ?? http.Client();

  /// Decodes common HTML entities like &quot;, &amp;, &#39;, &lt;, &gt;
  static String decodeEntities(String text) {
    if (text.isEmpty) return "";
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#91;', '[')
        .replaceAll('&#93;', ']');
  }

  /// Extracts JSON-LD from a post body string (with or without script tags).
  Map<String, dynamic>? extractJsonLd(String content) {
    if (content.isEmpty) return null;

    try {
      // Hex code \x27 represents single quote '
      final scriptRegex = RegExp(
        r'<script[^>]*type=["\x27]application/ld\+json["\x27][^>]*>([\s\S]*?)</script>',
        caseSensitive: false,
      );
      final match = scriptRegex.firstMatch(content);
      var jsonContent = match != null ? match.group(1)! : content;

      jsonContent = decodeEntities(jsonContent).trim();

      // Basic sanitizer for JSON-LD comments
      final cleaned = jsonContent
          .replaceAll(RegExp(r'\/\*[\s\S]*?\*\/'), '') // Remove /* css-like */ comments
          .trim();

      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      // If direct parsing failed, try finding a substring starting with { and ending with }
      try {
        final start = content.indexOf('{');
        final end = content.lastIndexOf('}');
        if (start != -1 && end != -1 && end > start) {
          final candidate = decodeEntities(content.substring(start, end + 1));
          return jsonDecode(candidate) as Map<String, dynamic>;
        }
      } catch (_) {}

      print('Failed to extract JSON-LD: $e');
      return null;
    }
  }

  /// Fetches a Blogger post's JSON feed and extracts its JSON-LD schema.
  Future<Map<String, dynamic>?> fetchPostSchema({required String blogId, required String postId}) async {
    final url = Uri.parse('https://www.blogger.com/feeds/$blogId/posts/default/$postId?alt=json');
    try {
      final response = await _client.get(url);
      if (response.statusCode != 200) {
        print('HTTP error fetching post: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final entry = data['entry'];
      if (entry == null) return null;

      final contentMap = entry['content'];
      final content = contentMap != null ? contentMap['\$t'] as String : '';
      return extractJsonLd(content);
    } catch (e) {
      print('Error fetching post schema for $blogId/$postId: $e');
      return null;
    }
  }

  /// Recursively resolves all `@id` references in a schema, fetches them, and merges overrides.
  /// `@base` is used as the context for relative `@id` values (e.g. "blogID/blogpostID").
  Future<Map<String, dynamic>> resolveAndLoadSchema(Map<String, dynamic> schema, {required String base}) async {
    final resolved = Map<String, dynamic>.from(schema);

    // Recursively traverse and resolve Maps/Lists
    await _traverseAndResolve(resolved, base: base);

    return resolved;
  }

  Future<void> _traverseAndResolve(dynamic node, {required String base}) async {
    if (node is Map) {
      // If this map is a reference (has @id and we are overriding it or fetching it)
      final idValue = node['@id'] ?? node['id'];

      // Let's check if it's a valid reference that we can fetch
      if (idValue is String && idValue.isNotEmpty) {
        final resolvedId = SchemaOverride.resolveId(base, idValue);
        final blogId = resolvedId['blogId'];
        final postId = resolvedId['postId'];
        final fullUrl = resolvedId['url'];

        Map<String, dynamic>? fetchedSchema;

        if (blogId != null && postId != null) {
          fetchedSchema = await fetchPostSchema(blogId: blogId, postId: postId);
        } else if (fullUrl != null) {
          // If it is a full URL, we fetch the URL which responds with JSON-LD
          try {
            final res = await _client.get(Uri.parse(fullUrl));
            if (res.statusCode == 200) {
              fetchedSchema = extractJsonLd(res.body);
            }
          } catch (e) {
            print('Error fetching from full URL $fullUrl: $e');
          }
        }

        if (fetchedSchema != null) {
          // Recursively resolve references inside the fetched schema first!
          final nestedBase = (blogId != null && postId != null) ? '$blogId/$postId' : base;
          fetchedSchema = await resolveAndLoadSchema(fetchedSchema, base: nestedBase);

          // Merge the fetched schema with the local overriding properties of this node
          // To make it safe, convert the node to Map<String, dynamic> for deepMerge
          final nodeAsMapDynamic = Map<String, dynamic>.from(node);
          final merged = SchemaOverride.deepMerge(fetchedSchema, nodeAsMapDynamic);

          // Update the node's properties in place dynamically without addAll type issues
          node.clear();
          merged.forEach((k, v) => node[k] = v);
          return;
        }
      }

      // Traversal for other keys
      for (final key in node.keys.toList()) {
        final val = node[key];
        if (val is Map) {
          await _traverseAndResolve(val, base: base);
        } else if (val is List) {
          await _traverseAndResolve(val, base: base);
        }
      }
    } else if (node is List) {
      for (var i = 0; i < node.length; i++) {
        final item = node[i];
        if (item is Map) {
          await _traverseAndResolve(item, base: base);
        } else if (item is List) {
          await _traverseAndResolve(item, base: base);
        }
      }
    }
  }
}
