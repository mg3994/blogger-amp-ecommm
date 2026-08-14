import 'dart:convert';
import 'package:http/http.dart' as http;
import 'schema_override.dart';

class BloggerDataService {
  final http.Client _client;

  BloggerDataService({http.Client? client}) : _client = client ?? http.Client();

  /// Decodes common HTML entities found in post bodies.
  static String decodeEntities(String text) {
    if (text.isEmpty) return '';
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

  /// Extracts JSON-LD from a post content string (with or without script tags).
  Map<String, dynamic>? extractJsonLd(String content) {
    if (content.isEmpty) return null;

    try {
      // Regex matches <script type="application/ld+json">...</script>
      final scriptRegex = RegExp(
        r'<script[^>]*type=["\x27]application/ld\+json["\x27][^>]*>([\s\S]*?)</script>',
        caseSensitive: false,
      );
      final match = scriptRegex.firstMatch(content);
      var jsonContent = match != null ? match.group(1)! : content;

      jsonContent = decodeEntities(jsonContent).trim();

      // Basic sanitizer for JSON-LD comments /* css-like */
      final cleaned = jsonContent.replaceAll(RegExp(r'\/\*[\s\S]*?\*\/'), '').trim();

      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      // Substring fallback for direct JSON starting with { and ending with }
      try {
        final start = content.indexOf('{');
        final end = content.lastIndexOf('}');
        if (start != -1 && end != -1 && end > start) {
          final candidate = decodeEntities(content.substring(start, end + 1));
          return jsonDecode(candidate) as Map<String, dynamic>;
        }
      } catch (_) {
        // Fallback catch ignored
      }

      print('Failed to extract JSON-LD: $e');
      return null;
    }
  }

  /// Fetches a Blogger post's JSON feed using native http and extracts its JSON-LD.
  Future<Map<String, dynamic>?> fetchPostSchema({
    required String blogId,
    required String postId,
  }) async {
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
      final content = contentMap != null ? contentMap['\$t'] as String? ?? '' : '';
      return extractJsonLd(content);
    } catch (e) {
      print('Error fetching post schema for $blogId/$postId: $e');
      return null;
    }
  }

  /// Recursively resolves all `@id` references in a schema, fetches remote references,
  /// and merges local overrides.
  Future<Map<String, dynamic>> resolveAndLoadSchema(
    Map<String, dynamic> schema, {
    required String base,
  }) async {
    final resolved = jsonDecode(jsonEncode(schema)) as Map<String, dynamic>;

    await _traverseAndResolve(resolved, base);

    return resolved;
  }

  Future<void> _traverseAndResolve(dynamic node, String base) async {
    if (node is Map) {
      final idValue = node['@id'] ?? node['id'];

      if (idValue is String && idValue.trim().isNotEmpty) {
        final resolvedId = SchemaOverride.resolveId(base, idValue);
        final blogId = resolvedId.blogId;
        final postId = resolvedId.postId;
        final fullUrl = resolvedId.url;

        Map<String, dynamic>? fetchedSchema;

        if (blogId != null && postId != null) {
          fetchedSchema = await fetchPostSchema(blogId: blogId, postId: postId);
        } else if (fullUrl != null) {
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
          final nestedBase = (blogId != null && postId != null) ? '$blogId/$postId' : base;

          fetchedSchema = await resolveAndLoadSchema(fetchedSchema, base: nestedBase);

          final nodeAsMapDynamic = Map<String, dynamic>.from(node);
          final merged = SchemaOverride.deepMerge(fetchedSchema, nodeAsMapDynamic);

          node.clear();
          merged.forEach((k, v) => node[k] = v);
          return;
        }
      }

      for (final key in node.keys.toList()) {
        final val = node[key];
        if (val is Map || val is List) {
          await _traverseAndResolve(val, base);
        }
      }
    } else if (node is List) {
      for (var i = 0; i < node.length; i++) {
        final item = node[i];
        if (item is Map || item is List) {
          await _traverseAndResolve(item, base);
        }
      }
    }
  }

  /// Collects all resolved schemas, extracts and merges ALL `@context` definitions
  /// (URLs, object maps with @vocab/prefixes, and arrays), strips inner `@context` from all nodes,
  /// deduplicates entities by `@id`, and builds a single unified `@graph` document.
  Map<String, dynamic> toGraphDocument(dynamic schemas) {
    final List<dynamic> inputList = schemas is List ? schemas : [schemas];

    final contextUrls = <String>{};
    final Map<String, dynamic> combinedContextMap = {};

    final entityMap = <String, Map<String, dynamic>>{};
    final standaloneNodes = <Map<String, dynamic>>[];

    // Recursively extracts & merges @context from a node and strips @context from all entity levels.
    dynamic extractAndStripContext(dynamic node) {
      if (node == null) return null;

      if (node is List) {
        return node.map((item) => extractAndStripContext(item)).toList();
      }

      if (node is Map) {
        final Map<String, dynamic> nodeAsMapDynamic = Map<String, dynamic>.from(node);

        // Extract context if present at this node level
        if (nodeAsMapDynamic.containsKey('@context') && nodeAsMapDynamic['@context'] != null) {
          _mergeContextValue(nodeAsMapDynamic['@context'], contextUrls, combinedContextMap);
        }

        final cleaned = <String, dynamic>{};

        nodeAsMapDynamic.forEach((key, value) {
          // Strip out @context key so nodes inside @graph stay clean
          if (key == '@context') return;
          cleaned[key] = extractAndStripContext(value);
        });

        return cleaned;
      }

      return node;
    }

    // 1. Process and clean all schemas passed in
    for (final schema in inputList) {
      if (schema is Map<String, dynamic>) {
        final cleanedSchema = extractAndStripContext(schema);

        if (cleanedSchema is Map && cleanedSchema.containsKey('@graph') && cleanedSchema['@graph'] is List) {
          for (final item in cleanedSchema['@graph']) {
            if (item is Map) {
              _registerEntity(Map<String, dynamic>.from(item), entityMap, standaloneNodes);
            }
          }
        } else if (cleanedSchema is Map) {
          _registerEntity(Map<String, dynamic>.from(cleanedSchema), entityMap, standaloneNodes);
        }
      }
    }

    // 2. Build top-level unified @context
    final finalContext = _buildUnifiedContext(contextUrls, combinedContextMap);

    return {
      '@context': finalContext,
      '@graph': [...entityMap.values, ...standaloneNodes],
    };
  }

  /// Recursively parses context strings, array lists, and mapping objects
  /// (capturing @vocab, @base, @language, prefixes, and detailed term definitions).
  void _mergeContextValue(
    dynamic contextVal,
    Set<String> contextUrls,
    Map<String, dynamic> combinedMap,
  ) {
    if (contextVal == null) return;

    if (contextVal is String) {
      contextUrls.add(contextVal);
    } else if (contextVal is List) {
      for (final item in contextVal) {
        _mergeContextValue(item, contextUrls, combinedMap);
      }
    } else if (contextVal is Map) {
      contextVal.forEach((k, v) {
        if (v == null) return;

        if (v is Map) {
          // Complex term definition: e.g. "author": { "@id": "schema:author", "@type": "@id" }
          final existing = combinedMap[k];
          if (existing is Map<String, dynamic>) {
            combinedMap[k] = SchemaOverride.deepMerge(existing, Map<String, dynamic>.from(v));
          } else {
            combinedMap[k] = SchemaOverride.deepMerge({}, Map<String, dynamic>.from(v));
          }
        } else {
          // Prefixes, @vocab, @base, @language, or string mappings
          combinedMap[k] = v;
        }
      });
    }
  }

  /// Assembles top-level @context dynamically based on all collected contexts.
  dynamic _buildUnifiedContext(
    Set<String> contextUrls,
    Map<String, dynamic> combinedMap,
  ) {
    final hasMap = combinedMap.isNotEmpty;
    final urls = contextUrls.toList();

    // Default fallback if no context was found
    if (urls.isEmpty && !hasMap) {
      return 'https://schema.org';
    }

    // Case 1: Only a mapping object exists (e.g. huge prefix map, @vocab)
    if (urls.isEmpty && hasMap) {
      return combinedMap;
    }

    // Case 2: Only 1 string URL exists and no object mappings
    if (urls.length == 1 && !hasMap) {
      return urls[0];
    }

    // Case 3: Mixed (URLs + prefix mapping object)
    final result = <dynamic>[...urls];
    if (hasMap) {
      result.add(combinedMap);
    }

    return result;
  }

  /// Deduplicates entities by @id. Merges duplicate nodes with the same ID.
  void _registerEntity(
    Map<String, dynamic> node,
    Map<String, Map<String, dynamic>> entityMap,
    List<Map<String, dynamic>> standaloneNodes,
  ) {
    final id = node['@id'] ?? node['id'];

    if (id is String) {
      if (entityMap.containsKey(id)) {
        final existing = entityMap[id]!;
        entityMap[id] = SchemaOverride.deepMerge(existing, node);
      } else {
        entityMap[id] = node;
      }
    } else {
      standaloneNodes.add(node);
    }
  }
}
