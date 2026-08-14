import 'package:test/test.dart';
import 'package:my_blogger_theme_project/feeds_get.dart';
import 'package:my_blogger_theme_project/schema_override.dart';

void main() {
  group('FeedsGet Tests', () {
    test('Build posts feed with query params', () {
      FeedsGet.blogHomepageUrl = 'https://myblog.blogspot.com';
      final url = FeedsGet.posts(maxResults: 10, alt: 'json', label: 'Electronics');
      expect(url, equals('https://myblog.blogspot.com/feeds/posts/default/-/Electronics?max-results=10&alt=json'));
    });

    test('Build direct post feed URL with blogId and postId', () {
      final url = FeedsGet.posts(blogId: '118774185466060931', postId: '159915394249811386', alt: 'json');
      expect(url, equals('https://www.blogger.com/feeds/118774185466060931/posts/default/159915394249811386?alt=json'));
    });

    test('Build summary feed URL', () {
      FeedsGet.blogHomepageUrl = 'https://myblog.blogspot.com/';
      final url = FeedsGet.summary(maxResults: 5, alt: 'json');
      expect(url, equals('https://myblog.blogspot.com/feeds/summary?max-results=5&alt=json'));
    });
  });

  group('SchemaOverride Tests', () {
    test('Case A: Relative post ID only', () {
      const base = '118774185466060931/159915394249811386';
      const id = '1234567890';
      final resolved = SchemaOverride.resolveId(base, id);
      expect(resolved.blogId, equals('118774185466060931'));
      expect(resolved.postId, equals('1234567890'));
      expect(resolved.url, isNull);
    });

    test('Case B: blogID/blogpostID', () {
      const base = '118774185466060931/159915394249811386';
      const id = '9999999999/8888888888';
      final resolved = SchemaOverride.resolveId(base, id);
      expect(resolved.blogId, equals('9999999999'));
      expect(resolved.postId, equals('8888888888'));
      expect(resolved.url, isNull);
    });

    test('Case C: Full URL', () {
      const base = '118774185466060931/159915394249811386';
      const id = 'https://anotherblog.blogspot.com/feeds/posts/default/159915394249811386?alt=json';
      final resolved = SchemaOverride.resolveId(base, id);
      expect(resolved.url, equals(id));
      expect(resolved.blogId, isNull);
      expect(resolved.postId, isNull);
    });

    test('Deep Merge and Override logic', () {
      final baseSchema = {
        '@context': 'https://schema.org',
        '@type': 'Product',
        'name': 'I will be Overridden with that name Override',
        'category': 'Electronics',
        'offers': {
          '@type': 'Offer',
          'price': '38851.00',
          'priceCurrency': 'INR',
          'availability': 'https://schema.org/InStock',
        },
        'addOn': [
          {
            '@id': 'addon-1',
            'name': 'Premium Gift Wrapping',
            'price': '499.00',
          },
          {
            '@id': 'addon-2',
            'name': 'Matching Cotton Cap',
            'price': '899.00',
          }
        ]
      };

      final overrideSchema = {
        'name': 'Override',
        'offers': {
          'price': '35000.00',
        },
        'addOn': [
          {
            '@id': 'addon-1',
            'price': '399.00', // Override addon-1 price
          }
        ]
      };

      final merged = SchemaOverride.deepMerge(baseSchema, overrideSchema);

      expect(merged['name'], equals('Override'));
      expect(merged['category'], equals('Electronics'));
      expect(merged['offers']['price'], equals('35000.00'));
      expect(merged['offers']['priceCurrency'], equals('INR')); // Preserved
      expect(merged['offers']['availability'], equals('https://schema.org/InStock')); // Preserved

      final addOns = merged['addOn'] as List;
      expect(addOns.length, equals(1)); // Array overriding as per TS implementation: source list replaces target list!
    });
  });
}
