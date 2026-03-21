import 'package:flutter_test/flutter_test.dart';
import 'package:openlynk_sdk/openlynk_sdk.dart';

void main() {
  group('RestoredLink.fromJson', () {
    test('parses complete JSON', () {
      final json = {
        'pending_link_id': 'pl_1',
        'original_url': 'https://app.openlynk.io/slug123',
        'destination_url': 'https://myapp.com/product/456',
        'destination_path': '/product/456',
        'destination': '/product/456?utm_source=email',
        'parameters': {'utm_source': 'email'},
        'metadata': {
          'utm_source': 'email',
          'utm_campaign': 'summer',
          'utm_medium': 'cpc',
          'utm_term': 'shoes',
          'utm_content': 'banner',
        },
        'link_id': 'link_abc',
      };

      final link = RestoredLink.fromJson(json);

      expect(link.pendingLinkId, 'pl_1');
      expect(link.originalUrl, 'https://app.openlynk.io/slug123');
      expect(link.destinationUrl, 'https://myapp.com/product/456');
      expect(link.destinationPath, '/product/456');
      expect(link.destination, '/product/456?utm_source=email');
      expect(link.parameters, {'utm_source': 'email'});
      expect(link.linkId, 'link_abc');
      expect(link.utmSource, 'email');
      expect(link.utmCampaign, 'summer');
      expect(link.utmMedium, 'cpc');
      expect(link.utmTerm, 'shoes');
      expect(link.utmContent, 'banner');
    });

    test('handles missing optional fields', () {
      final json = {
        'pending_link_id': 'pl_2',
        'original_url': 'https://app.openlynk.io/slug456',
        'destination_url': 'https://myapp.com/home',
        'metadata': {},
        'link_id': 'link_def',
      };

      final link = RestoredLink.fromJson(json);

      expect(link.destinationPath, isNull);
      expect(link.destination, isNull);
      expect(link.parameters, isNull);
      expect(link.utmSource, isNull);
    });

    test('handles null values gracefully', () {
      final json = <String, dynamic>{};
      final link = RestoredLink.fromJson(json);

      expect(link.pendingLinkId, '');
      expect(link.originalUrl, '');
      expect(link.destinationUrl, '');
      expect(link.linkId, '');
    });
  });

  group('CreatedLink.fromJson', () {
    test('parses complete JSON', () {
      final json = {
        'id': 'link_xyz',
        'slug': '1705326000-abc',
        'url': 'https://app.openlynk.io/1705326000-abc',
        'destination': '/product/123',
        'metadata': {'utm_source': 'share'},
      };

      final link = CreatedLink.fromJson(json);

      expect(link.id, 'link_xyz');
      expect(link.slug, '1705326000-abc');
      expect(link.url, 'https://app.openlynk.io/1705326000-abc');
      expect(link.destination, '/product/123');
      expect(link.metadata, {'utm_source': 'share'});
    });

    test('handles missing fields with defaults', () {
      final json = <String, dynamic>{};
      final link = CreatedLink.fromJson(json);

      expect(link.id, '');
      expect(link.slug, '');
      expect(link.url, '');
      expect(link.destination, '');
      expect(link.metadata, isEmpty);
    });

    test('toJson round-trips', () {
      final json = {
        'id': 'link_1',
        'slug': 'slug_1',
        'url': 'https://example.com/slug_1',
        'destination': '/page',
        'metadata': {'key': 'value'},
      };

      final link = CreatedLink.fromJson(json);
      final output = link.toJson();

      expect(output['id'], json['id']);
      expect(output['slug'], json['slug']);
      expect(output['url'], json['url']);
      expect(output['destination'], json['destination']);
      expect(output['metadata'], json['metadata']);
    });
  });

  group('LinkDetails.fromJson', () {
    test('parses complete JSON', () {
      final json = {
        'id': 'link_1',
        'slug': 'slug_1',
        'destination_web_url': 'https://example.com',
        'destination_path': '/product/123',
        'destination': '/product/123?utm_source=share',
        'parameters': {'utm_source': 'share'},
        'metadata': {'destination_path': '/product/123'},
      };

      final details = LinkDetails.fromJson(json);

      expect(details.id, 'link_1');
      expect(details.slug, 'slug_1');
      expect(details.destinationWebUrl, 'https://example.com');
      expect(details.destinationPath, '/product/123');
      expect(details.destination, '/product/123?utm_source=share');
      expect(details.parameters, {'utm_source': 'share'});
    });

    test('handles missing parameters', () {
      final json = {
        'id': 'link_2',
        'slug': 'slug_2',
      };

      final details = LinkDetails.fromJson(json);

      expect(details.destinationWebUrl, '');
      expect(details.destinationPath, '');
      expect(details.destination, '');
      expect(details.parameters, isEmpty);
      expect(details.metadata, isEmpty);
    });
  });

  group('ParsedDeepLink.fromPushPayload', () {
    test('parses payload with map metadata', () {
      final data = {
        'destinationPath': '/product/456',
        'metadata': {'utm_source': 'push', 'promo': 'yes'},
        'notificationId': 'notif_1',
      };

      final parsed = ParsedDeepLink.fromPushPayload(data);

      expect(parsed.destinationPath, '/product/456');
      expect(parsed.parameters['utm_source'], 'push');
      expect(parsed.parameters['promo'], 'yes');
      expect(parsed.linkId, 'notif_1');
      expect(parsed.slug, 'push');
      expect(parsed.destination, contains('/product/456'));
      expect(parsed.destination, contains('utm_source=push'));
    });

    test('parses payload with JSON string metadata', () {
      final data = {
        'destinationPath': '/page',
        'metadata': '{"key":"value"}',
      };

      final parsed = ParsedDeepLink.fromPushPayload(data);

      expect(parsed.destinationPath, '/page');
      expect(parsed.parameters['key'], 'value');
    });

    test('handles missing fields with defaults', () {
      final data = <String, dynamic>{};

      final parsed = ParsedDeepLink.fromPushPayload(data);

      expect(parsed.destinationPath, '/');
      expect(parsed.destination, '/');
      expect(parsed.parameters, isEmpty);
      expect(parsed.linkId, '');
      expect(parsed.slug, 'push');
    });

    test('handles invalid JSON metadata string', () {
      final data = {
        'destinationPath': '/test',
        'metadata': 'not valid json',
      };

      final parsed = ParsedDeepLink.fromPushPayload(data);

      expect(parsed.parameters, isEmpty);
      expect(parsed.destinationPath, '/test');
    });
  });

  group('OpenlynkRateLimitException', () {
    test('has correct default message', () {
      final ex = OpenlynkRateLimitException();
      expect(ex.message, 'Too many requests');
      expect(ex.toString(), contains('Too many requests'));
    });
  });

  group('OpenlynkLinkLimitException', () {
    test('exposes plan details', () {
      final ex = OpenlynkLinkLimitException(
        message: 'Limit reached',
        currentCount: 10,
        limit: 10,
        plan: 'free',
        upgradeRequired: 'starter',
      );

      expect(ex.currentCount, 10);
      expect(ex.limit, 10);
      expect(ex.plan, 'free');
      expect(ex.upgradeRequired, 'starter');
      expect(ex.toString(), contains('free'));
      expect(ex.toString(), contains('10/10'));
    });
  });
}
