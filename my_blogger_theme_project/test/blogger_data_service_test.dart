import 'dart:convert';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_blogger_theme_project/blogger_data_service.dart';

void main() {
  group('BloggerDataService Tests', () {
    test('Extract JSON-LD from raw content', () {
      final service = BloggerDataService();
      const content = '{"@type": "Service", "name": "Premium Gift Wrapping"}';
      final json = service.extractJsonLd(content);
      expect(json, isNotNull);
      expect(json!['name'], equals('Premium Gift Wrapping'));
    });

    test('Extract JSON-LD from script tag with decoded entities', () {
      final service = BloggerDataService();
      const content = '''
        <div>Some HTML</div>
        <script type="application/ld+json">
          {
            "name": "Price &amp; Quality",
            "escaped_brackets": "&#91;value&#93;"
          }
        </script>
      ''';
      final json = service.extractJsonLd(content);
      expect(json, isNotNull);
      expect(json!['name'], equals('Price & Quality'));
      expect(json['escaped_brackets'], equals('[value]'));
    });

    test('Fetch post schema over Mock Client', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), contains('feeds/118774185466060931/posts/default/159915394249811386'));

        final mockBloggerResponse = {
          'entry': {
            'content': {
              '\$t': '<script type="application/ld+json">{"@type": "Product", "name": "Midnight Blue T-Shirt"}</script>'
            }
          }
        };

        return http.Response(jsonEncode(mockBloggerResponse), 200);
      });

      final service = BloggerDataService(client: mockClient);
      final schema = await service.fetchPostSchema(blogId: '118774185466060931', postId: '159915394249811386');

      expect(schema, isNotNull);
      expect(schema!['name'], equals('Midnight Blue T-Shirt'));
    });

    test('Recursively resolve and deep merge overrides with Base context', () async {
      final mockClient = MockClient((request) async {
        // Request for referenced add-on
        if (request.url.toString().contains('159915394249811386')) {
          final response = {
            'entry': {
              'content': {
                '\$t': '{"@type": "Product", "name": "Base Product Name", "category": "Clothing", "offers": {"price": "100.00"}}'
              }
            }
          };
          return http.Response(jsonEncode(response), 200);
        }
        return http.Response('Not found', 404);
      });

      final service = BloggerDataService(client: mockClient);

      // Local container post contains reference with overrides
      final localContainerSchema = {
        '@context': 'https://schema.org',
        '@base': '118774185466060931/9999999999',
        'productReference': {
          '@id': '159915394249811386', // Relative reference (Case A)
          'name': 'Override Name', // Local Override property
          'offers': {
            'price': '85.00' // Local price override
          }
        }
      };

      final resolved = await service.resolveAndLoadSchema(localContainerSchema, base: '118774185466060931/9999999999');

      expect(resolved['productReference'], isNotNull);
      final ref = resolved['productReference'] as Map;

      // Verified overrides are merged successfully
      expect(ref['name'], equals('Override Name'));
      expect(ref['offers']['price'], equals('85.00'));

      // Verified original properties are preserved
      expect(ref['category'], equals('Clothing'));
    });
  });
}
