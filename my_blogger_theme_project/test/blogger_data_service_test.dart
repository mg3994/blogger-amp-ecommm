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

    test('Fetch post schema over Mock Client with Exact Blogger Live Feed format', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), equals('https://www.blogger.com/feeds/118774185466060931/posts/default/159915394249811386?alt=json'));

        final liveBloggerFeed = {
          "version": "1.0",
          "encoding": "UTF-8",
          "entry": {
            "xmlns": "http://www.w3.org/1999/Atom",
            "xmlns\$blogger": "http://schemas.google.com/blogger/2008",
            "xmlns\$georss": "http://www.georss.org/georss",
            "xmlns\$gd": "http://schemas.google.com/g/2005",
            "xmlns\$thr": "http://purl.org/syndication/thread/1.0",
            "id": {
              "\$t": "tag:blogger.com,1999:blog-118774185466060931.post-159915394249811386"
            },
            "published": {
              "\$t": "2026-06-23T02:51:19.485-07:00"
            },
            "updated": {
              "\$t": "2026-06-27T23:24:26.936-07:00"
            },
            "category": [
              {
                "scheme": "http://www.blogger.com/atom/ns#",
                "term": "Business"
              }
            ],
            "title": {
              "type": "text",
              "\$t": "Downtown Threads - New Delhi Flagship"
            },
            "content": {
              "type": "html",
              "\$t": "{\n  \"@context\": \"https://schema.org\",\n  \"@type\": \"LocalBusiness\",\n  \"name\": \"Downtown Threads - New Delhi Flagship\",\n  \"telephone\": \"+91-11-23456789\",\n  \"email\": \"contact@antinna-industrial.com\",\n  \"image\": [\n    \"https://example.com/images/storefront-delhi.jpg\",\n    \"https://example.com/images/store-inside.jpg\"\n  ],\n  \"address\": {\n    \"@type\": \"PostalAddress\",\n    \"streetAddress\": \"123 Connaught Place\",\n    \"addressLocality\": \"New Delhi\",\n    \"addressCountry\": \"IN\"\n  },\n  \"geo\": {\n    \"@type\": \"GeoCoordinates\",\n    \"latitude\": \"28.6315\",\n    \"longitude\": \"77.2167\"\n  },\n  \"sameAs\": [\n    \"https://www.facebook.com/antinnapro\",\n    \"https://www.instagram.com/antinnapro\",\n    \"https://linkedin.com/company/antinna\"\n  ],\n  \"hasOfferCatalog\": {\n    \"@type\": \"OfferCatalog\",\n    \"name\": \"Personalization Services\",\n    \"itemListElement\": [\n      {\n        \"@type\": \"Offer\",\n        \"itemOffered\": {\n          \"@type\": \"Service\",\n          \"name\": \"Custom Embroidery\",\n          \"description\": \"Premium custom embroidery services for apparel and accessories.\",\n          \"image\": \"https://picsum.dev/800/600?blur=5\"\n        },\n        \"price\": \"3589.00\",\n        \"priceCurrency\": \"INR\",\n        \"availability\": \"https://schema.org/InStock\",\n        \"eligibleQuantity\": {\n          \"@type\": \"QuantitativeValue\",\n          \"value\": 1,\n          \"minValue\": 0,\n          \"maxValue\": 1,\n          \"unitCode\": \"C62\"\n        },\n        \"advanceBookingRequirement\": {\n          \"@type\": \"QuantitativeValue\",\n          \"value\": \"24\",\n          \"unitCode\": \"HUR\"\n        }\n      }\n    ]\n  }\n}"
            },
            "link": [
              {
                "rel": "edit",
                "type": "application/atom+xml",
                "href": "https://www.blogger.com/feeds/118774185466060931/posts/default/159915394249811386"
              },
              {
                "rel": "self",
                "type": "application/atom+xml",
                "href": "https://www.blogger.com/feeds/118774185466060931/posts/default/159915394249811386"
              },
              {
                "rel": "alternate",
                "type": "text/html",
                "href": "https://mg3994.blogspot.com/2026/06/custom-embroidery.html",
                "title": "Downtown Threads - New Delhi Flagship"
              }
            ],
            "author": [
              {
                "name": {
                  "\$t": "mg3994"
                },
                "uri": {
                  "\$t": "http://www.blogger.com/profile/02949392009900018502"
                },
                "email": {
                  "\$t": "noreply@blogger.com"
                },
                "gd\$image": {
                  "rel": "http://schemas.google.com/g/2005#thumbnail",
                  "width": "16",
                  "height": "16",
                  "src": "https://img1.blogblog.com/img/b16-rounded.gif"
                }
              }
            ]
          }
        };

        return http.Response(jsonEncode(liveBloggerFeed), 200);
      });

      final service = BloggerDataService(client: mockClient);
      final schema = await service.fetchPostSchema(blogId: '118774185466060931', postId: '159915394249811386');

      expect(schema, isNotNull);
      expect(schema!['@type'], equals('LocalBusiness'));
      expect(schema['name'], equals('Downtown Threads - New Delhi Flagship'));
      expect(schema['telephone'], equals('+91-11-23456789'));
      expect(schema['email'], equals('contact@antinna-industrial.com'));
      expect(schema['address']['addressLocality'], equals('New Delhi'));

      final offersList = schema['hasOfferCatalog']['itemListElement'] as List;
      expect(offersList.length, equals(1));
      expect(offersList[0]['itemOffered']['name'], equals('Custom Embroidery'));
      expect(offersList[0]['price'], equals('3589.00'));
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

    test('toGraphDocument pure schema.org context merging', () {
      final service = BloggerDataService();

      final schema1 = {
        '@context': 'https://schema.org/',
        '@type': 'Product',
        '@id': 'prod-1',
        'name': 'AuraGlow Thermostat'
      };

      final schema2 = {
        '@context': {
          '@vocab': 'https://schema.org/'
        },
        '@type': 'Product',
        '@id': 'prod-2',
        'name': 'Smart Sensor'
      };

      final graphDoc = service.toGraphDocument([schema1, schema2]);

      // When only schema.org is present anywhere, output clean URL string
      expect(graphDoc['@context'], equals('https://schema.org'));

      final graph = graphDoc['@graph'] as List;
      expect(graph.length, equals(2));
    });

    test('toGraphDocument mixed contexts with schema.org and custom prefixes', () {
      final service = BloggerDataService();

      final schema1 = {
        '@context': 'https://schema.org',
        '@type': 'Product',
        '@id': 'prod-1',
        'name': 'AuraGlow Thermostat',
        'offers': {
          '@context': {
            'co': 'https://custom-ontology.org/'
          },
          '@type': 'Offer',
          'price': '38851.00',
        }
      };

      final schema2 = {
        '@context': 'https://schema.org',
        '@type': 'Product',
        '@id': 'prod-1', // Duplicate ID to test node merging
        'category': 'Smart Home',
        'brand': {
          '@type': 'Brand',
          'name': 'Antinna Pro'
        }
      };

      final graphDoc = service.toGraphDocument([schema1, schema2]);

      // 1. Verify unified @context is built correctly containing both @vocab and schema pointing to schema.org/
      final context = graphDoc['@context'];
      expect(context, isA<Map>());
      final mapContext = context as Map;
      expect(mapContext['@vocab'], equals('https://schema.org/'));
      expect(mapContext['schema'], equals('https://schema.org/'));
      expect(mapContext['co'], equals('https://custom-ontology.org/'));

      // 2. Verify duplicate nodes are merged and deduplicated in the flat @graph list
      final graph = graphDoc['@graph'] as List;
      expect(graph.length, equals(1)); // Deduplicated to 1 node

      final entity = graph[0] as Map;
      expect(entity['@id'], equals('prod-1'));
      expect(entity['name'], equals('AuraGlow Thermostat')); // Preserved from schema1
      expect(entity['category'], equals('Smart Home')); // Preserved from schema2
      expect(entity['brand']['name'], equals('Antinna Pro')); // Preserved from schema2
      expect(entity['offers']['price'], equals('38851.00')); // Preserved from schema1

      // 3. Verify @context is completely stripped from all nested levels of the nodes inside @graph
      expect(entity.containsKey('@context'), isFalse);
      expect(entity['offers'].containsKey('@context'), isFalse);
    });
  });
}
