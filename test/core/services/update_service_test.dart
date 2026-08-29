import 'package:enmesh/core/services/update_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _FakeClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest request) handler;

  _FakeClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
      request: request,
    );
  }
}

void main() {
  test('fetches the selected channel and returns a newer update', () async {
    Uri? requestedUri;
    final client = _FakeClient((request) async {
      requestedUri = request.url;
      return http.Response(
        '{"schemaVersion":1,"data":${_updateJson('beta')}}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final result =
        await UpdateChecker(
          client: client,
          baseUri: Uri.parse('https://updates.example/api/v1'),
          channelProvider: () => 'beta',
          currentVersionProvider: () => '3.0.0-alpha.4+abcdef0',
        ).check();

    expect(requestedUri?.queryParameters['channel'], 'beta');
    expect(result?.kind, UpdateCheckKind.updateAvailable);
    expect(result?.update?.pageUrl.host, 'github.com');
  });

  test('accepts the selected alpha channel', () async {
    Uri? requestedUri;
    final client = _FakeClient((request) async {
      requestedUri = request.url;
      return http.Response(
        '{"schemaVersion":1,"data":${_updateJson('alpha')}}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final result =
        await UpdateChecker(
          client: client,
          channelProvider: () => 'alpha',
          currentVersionProvider: () => '2.0.0',
        ).check();

    expect(requestedUri?.queryParameters['channel'], 'alpha');
    expect(result?.update?.channel, 'alpha');
  });

  test('does not trust an arbitrary page URL', () async {
    final client = _FakeClient((request) async {
      return http.Response(
        '{"schemaVersion":1,"data":${_updateJson('stable', pageUrl: 'https://evil.example/update')}}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final result =
        await UpdateChecker(
          client: client,
          channelProvider: () => 'stable',
          currentVersionProvider: () => '2.0.0',
        ).check();

    expect(result?.kind, UpdateCheckKind.failed);
  });

  test(
    'treats an unavailable beta channel separately from a request failure',
    () async {
      final client = _FakeClient((_) async => http.Response('{}', 404));

      final result =
          await UpdateChecker(
            client: client,
            channelProvider: () => 'beta',
            currentVersionProvider: () => '3.0.0-alpha.1+abcdef0',
          ).check();

      expect(result?.kind, UpdateCheckKind.unavailable);
    },
  );
}

String _updateJson(String channel, {String? pageUrl}) {
  return '{'
      '"channel":"$channel",'
      '"stage":"${channel == 'stable' ? 'stable' : channel}",'
      '"version":"3.0.0",'
      '"title":"Release v3.0.0",'
      '"highlights":{"en":"A safer update."},'
      '"publishedAt":"2026-08-14T00:00:00Z",'
      '"expiresAt":null,'
      '"pageUrl":"${pageUrl ?? 'https://github.com/ttimasdf/enmesh/releases/tag/v3.0.0'}"'
      '}';
}
