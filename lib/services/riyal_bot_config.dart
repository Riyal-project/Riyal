import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'gemini_api.dart';
import 'riyal_bot_context.dart';
import 'riyal_bot_prompt.dart';

class RiyalBotConfig {
  static String get _key =>
      dotenv.isInitialized ? (dotenv.env['GEMINI_API_KEY'] ?? '').trim() : '';
  static bool get isConfigured =>
      _key.isNotEmpty &&
      !_key.toUpperCase().contains('YOUR') &&
      !_key.toUpperCase().contains('PUT_') &&
      !_key.contains('هنا');
  static GeminiApi create() {
    if (!isConfigured) throw StateError('Gemini is not configured');
    final configuredModel = dotenv.env['GEMINI_MODEL']?.trim();
    return GeminiApi(
      apiKey: _key,
      model: configuredModel == null || configuredModel.isEmpty
          ? 'gemini-3.8-flash'
          : configuredModel,
      systemInstruction: riyalBotPrompt,
      contextProvider: buildRiyalBotContext,
    );
  }
}
