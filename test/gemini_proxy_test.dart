import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:riyal/services/gemini_api.dart';

void main() {
  test('Proxy requests never forward a client API key', () async {
    final client = MockClient((request) async {
      expect(request.url, Uri.parse('https://example.test/api/gemini'));
      expect(request.headers.containsKey('x-goog-api-key'), isFalse);
      expect(request.body, isNot(contains('must-not-leave-client')));
      expect(jsonDecode(request.body)['context'], 'Budget: 750 SAR');
      expect(
        jsonDecode(request.body).containsKey('systemInstruction'),
        isFalse,
      );
      expect(
        jsonDecode(request.body)['contents'][0]['parts'][0]['text'],
        'Hello',
      );
      return http.Response(
        jsonEncode({
          'candidates': [
            {
              'finishReason': 'STOP',
              'content': {
                'parts': [
                  {'text': 'Welcome'},
                ],
              },
            },
          ],
        }),
        200,
      );
    });
    final api = GeminiApi(
      endpoint: Uri.parse('https://example.test/api/gemini'),
      apiKey: 'must-not-leave-client',
      model: 'server-selected',
      client: client,
      contextProvider: () async => 'Budget: 750 SAR',
    );
    expect(await api.sendMessage('Hello'), 'Welcome');
    api.dispose();
    client.close();
  });
}
