import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'gemini_api.dart';
import 'riyal_bot_context.dart';
import 'riyal_bot_prompt.dart';

class RiyalBotConfig {
  static String _value(String name) =>
      dotenv.isInitialized ? (dotenv.env[name] ?? '').trim() : '';

  // Direct keys are allowed only for optional native development runs.
  static String get _developmentKey => kIsWeb || kReleaseMode
      ? ''
      : const String.fromEnvironment('GEMINI_API_KEY');

  static Uri? get _endpoint {
    if (kIsWeb) return Uri.base.resolve('/api/gemini');
    final url = _value('GEMINI_PROXY_URL');
    return url.isEmpty ? null : Uri.tryParse(url);
  }

  static bool get isConfigured =>
      _endpoint != null || _developmentKey.isNotEmpty;
  static GeminiApi create() {
    if (!isConfigured) throw StateError('Gemini is not configured');
    final configuredModel = _value('GEMINI_MODEL');
    return GeminiApi(
      endpoint: _endpoint,
      apiKey: _developmentKey,
      // The server selects its own model for proxy requests.
      model: configuredModel.isEmpty ? 'gemini-3.8-flash' : configuredModel,
      systemInstruction: riyalBotPrompt,
      contextProvider: buildRiyalBotContext,
    );
  }
}
