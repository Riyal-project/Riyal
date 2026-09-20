import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiApiException implements Exception {
  const GeminiApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class GeminiMessage {
  const GeminiMessage.user(this.text) : role = 'user';
  const GeminiMessage.model(this.text) : role = 'model';
  final String role;
  final String text;
  Map<String, Object> toJson() => {
    'role': role,
    'parts': [
      {'text': text},
    ],
  };
}

/// Text chat using Google's generateContent REST API.
/// https://ai.google.dev/api/generate-content
///
/// final api = GeminiApi(apiKey: key, model: 'your-enabled-model-id');
/// final reply = await api.sendMessage('Hello');
/// api.clearHistory();
/// api.dispose();
///
/// Direct keys are for local development only. A Flutter/web bundle cannot
/// keep an API key secret, including .env assets or dart-define values.
/// For deployment, call Gemini through a server that holds the key.
/// The service itself reads no app data; the caller can pass
/// [contextProvider] to append a fresh snapshot of the user's data to the
/// system instruction on every message (it is not stored in the history).
class GeminiApi {
  GeminiApi({
    String apiKey = '',
    this.endpoint,
    required this.model,
    this.systemInstruction =
        'You are Riyal assistant. Reply in the user language. '
        'Help explain subscriptions, bills and household payments. '
        'Do not invent account data or claim to change payments. '
        'Ask for missing information when necessary.',
    this.contextProvider,
    this.timeout = const Duration(seconds: 45),
    http.Client? client,
  }) : _apiKey = apiKey.trim(),
       _client = client ?? http.Client(),
       _ownsClient = client == null {
    if (endpoint == null && _apiKey.isEmpty) {
      throw ArgumentError('A Gemini endpoint or API key is required.');
    }
    if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(model)) {
      throw ArgumentError('Pass a model ID without the models/ prefix.');
    }
    if (timeout <= Duration.zero) {
      throw ArgumentError('Timeout must be positive.');
    }
  }

  final String _apiKey;
  final Uri? endpoint;
  final String model;
  final String systemInstruction;
  final Future<String> Function()? contextProvider;
  final Duration timeout;
  final http.Client _client;
  final bool _ownsClient;
  final List<GeminiMessage> _history = [];
  bool _busy = false;
  bool _disposed = false;
  List<GeminiMessage> get history => List.unmodifiable(_history);
  bool get isSending => _busy;

  /// Returns the complete response. Failed turns are not added to history.
  Future<String> sendMessage(String message) async {
    if (_disposed) throw StateError('GeminiApi has been disposed.');
    if (_busy) {
      throw StateError('Wait for the current reply before sending again.');
    }
    final text = message.trim();
    if (text.isEmpty) throw ArgumentError('Message cannot be empty.');
    _busy = true;
    try {
      var system = systemInstruction;
      var userContext = '';
      if (contextProvider != null) {
        try {
          final context = (await contextProvider!()).trim();
          userContext = context;
          if (context.isNotEmpty) system = '$system\n\n$context';
        } catch (_) {
          // Answer without the snapshot rather than failing the message.
        }
      }
      final response = await _client
          .post(
            endpoint ??
                Uri.https(
                  'generativelanguage.googleapis.com',
                  '/v1beta/models/$model:generateContent',
                ),
            headers: {
              'Content-Type': 'application/json',
              if (endpoint == null) 'x-goog-api-key': _apiKey,
            },
            body: jsonEncode({
              'contents': [
                ...(_history.length > 40 && endpoint != null
                        ? _history.sublist(_history.length - 40)
                        : _history)
                    .map((m) => m.toJson()),
                GeminiMessage.user(text).toJson(),
              ],
              if (endpoint != null && userContext.isNotEmpty)
                'context': userContext,
              if (endpoint == null && system.trim().isNotEmpty)
                'systemInstruction': {
                  'parts': [
                    {'text': system},
                  ],
                },
            }),
          )
          .timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        // Never expose raw server errors: they can echo credentials or prompts.
        final error = switch (response.statusCode) {
          400 =>
            'Gemini rejected the request. Check the key, model and request configuration.',
          401 ||
          403 => 'Gemini access denied. Check the API key and its permissions.',
          404 => 'Gemini model not found. Check your enabled model ID.',
          429 => 'Gemini quota or rate limit reached. Please try again later.',
          >= 500 =>
            'Gemini is temporarily unavailable. Please try again later.',
          _ => 'Gemini request failed.',
        };
        throw GeminiApiException(error, statusCode: response.statusCode);
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      final feedback = decoded['promptFeedback'];
      if (feedback is Map && feedback['blockReason'] != null) {
        throw const GeminiApiException(
          'Gemini could not answer this message. Try rephrasing it.',
        );
      }
      final candidates = decoded['candidates'];
      if (candidates is! List ||
          candidates.isEmpty ||
          candidates.first is! Map) {
        throw const GeminiApiException(
          'Gemini returned no answer. Please try again.',
        );
      }
      final candidate = candidates.first as Map;
      final finish = candidate['finishReason'];
      if (finish != null && finish != 'STOP' && finish != 'MAX_TOKENS') {
        throw const GeminiApiException(
          'Gemini could not complete this answer. Try rephrasing your message.',
        );
      }
      final content = candidate['content'];
      final parts = content is Map ? content['parts'] : null;
      final reply = parts is List
          ? parts
                .whereType<Map>()
                .where((p) => p['thought'] != true && p['text'] is String)
                .map((p) => p['text'] as String)
                .join()
                .trim()
          : '';
      if (reply.isEmpty) {
        throw const GeminiApiException(
          'Gemini returned an empty text response.',
        );
      }
      if (finish == 'MAX_TOKENS') {
        throw const GeminiApiException(
          'The answer exceeded the response limit. Try a shorter question.',
        );
      }
      if (_disposed) {
        throw StateError('GeminiApi was disposed during the request.');
      }
      _history.addAll([GeminiMessage.user(text), GeminiMessage.model(reply)]);
      return reply;
    } on TimeoutException {
      throw const GeminiApiException(
        'The request timed out. Please try again.',
      );
    } on http.ClientException {
      throw const GeminiApiException(
        'Could not connect to Gemini. Check your internet connection.',
      );
    } on FormatException {
      throw const GeminiApiException('Gemini returned an invalid response.');
    } finally {
      _busy = false;
    }
  }

  void clearHistory() {
    if (_busy) {
      throw StateError('Wait for the current reply before clearing history.');
    }
    _history.clear();
  }

  void dispose() {
    _disposed = true;
    if (_ownsClient) _client.close();
  }
}
