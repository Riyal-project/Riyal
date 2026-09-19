import 'package:flutter/material.dart';
import '../services/gemini_api.dart';
import '../services/riyal_bot_config.dart';
import '../widgets/coin_back_button.dart';
import '../widgets/riyal_coin_painter.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

class RiyalBotScreen extends StatefulWidget {
  const RiyalBotScreen({super.key, this.api});
  final GeminiApi? api;
  @override
  State<RiyalBotScreen> createState() => _RiyalBotScreenState();
}

class _RiyalBotScreenState extends State<RiyalBotScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <GeminiMessage>[];
  GeminiApi? _api;
  bool _sending = false;
  String? _error;
  bool _errorArabic = false;
  bool get _arabic => Localizations.localeOf(context).languageCode == 'ar';
  String _t(String ar, String en) => _arabic ? ar : en;
  @override
  void initState() {
    super.initState();
    try {
      _api =
          widget.api ??
          (RiyalBotConfig.isConfigured ? RiyalBotConfig.create() : null);
    } catch (_) {
      _api = null;
    }
  }

  @override
  void dispose() {
    if (widget.api == null) _api?.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool _isArabic(String text) => RegExp(r'[\u0600-\u06ff]').hasMatch(text);
  void _bottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && _scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  });
  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending || _api == null) return;
    final ar = _isArabic(text);
    setState(() {
      _sending = true;
      _error = null;
      _messages.add(GeminiMessage.user(text));
    });
    _input.clear();
    _bottom();
    try {
      final answer = await _api!.sendMessage(text);
      if (!mounted) return;
      setState(() => _messages.add(GeminiMessage.model(answer)));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.removeLast();
        _input.text = text;
        _errorArabic = ar;
        _error = error is GeminiApiException && error.statusCode == 429
            ? (ar
                  ? 'وصلنا لحد الاستخدام. جربي لاحقًا.'
                  : 'Usage limit reached. Please try again later.')
            : (ar
                  ? 'تعذّر الحصول على رد. تحققي من الاتصال وإعداد الخدمة ثم أعيدي المحاولة.'
                  : 'Could not get a reply. Check your connection and service configuration, then retry.');
      });
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _bottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      leading: const CoinBackButton(),
      title: Text(
        _t('ريال', 'Riyal'),
        style: AppTypography.wordmark(
          color: AppColors.gold,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      ),
      actions: [
        IconButton(
          tooltip: _t('محادثة جديدة', 'New chat'),
          onPressed: _sending || _messages.isEmpty
              ? null
              : () {
                  _api?.clearHistory();
                  setState(() {
                    _messages.clear();
                    _error = null;
                  });
                },
          icon: const Icon(Icons.refresh_rounded, color: AppColors.gold),
        ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            children: [
              if (_api == null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.goldDark),
                    ),
                    child: Text(
                      _t(
                        'ريال غير متصل بعد. أكملي إعداد الخدمة لتفعيل المحادثة.',
                        'Riyal is not connected yet. Complete the service setup to enable chat.',
                      ),
                      style: const TextStyle(color: AppColors.gold),
                    ),
                  ),
                ),
              Expanded(
                child: _messages.isEmpty && !_sending
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const SizedBox(height: 32),
                            const SizedBox(
                              width: 90,
                              height: 90,
                              child: CustomPaint(
                                painter: RiyalCoinPainter(),
                                child: Center(
                                  child: Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    color: AppColors.gold,
                                    size: 38,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _t('أهلًا، أنا ريال', 'Hi, I am Riyal'),
                              style: const TextStyle(
                                fontSize: 26,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _t(
                                'اسأليني عن ميزانيتك واشتراكاتك والتزامات الدفع، بالعربي أو الإنجليزي.',
                                'Ask about budgeting, subscriptions and payment commitments, in Arabic or English.',
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                for (final prompt in [
                                  _t(
                                    'كيف أقلل مصروف اشتراكاتي؟',
                                    'How can I reduce subscription spending?',
                                  ),
                                  _t(
                                    'ساعدني أرتب ميزانيتي',
                                    'Help me plan my budget',
                                  ),
                                  _t(
                                    'كيف أنظم دفعات العمالة؟',
                                    'How can I organize household staff payments?',
                                  ),
                                ])
                                  GestureDetector(
                                    onTap: _api == null
                                        ? null
                                        : () {
                                            _input.text = prompt;
                                            _send();
                                          },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: AppColors.cardBorder,
                                        ),
                                      ),
                                      child: Text(
                                        prompt,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(20),
                        itemCount: _messages.length + (_sending ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length) {
                            return const Padding(
                              padding: EdgeInsets.all(18),
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.gold,
                                  ),
                                ),
                              ),
                            );
                          }
                          final message = _messages[index];
                          final user = message.role == 'user';
                          return Align(
                            alignment: user
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.sizeOf(context).width * 0.78,
                              ),
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: user
                                    ? AppColors.gold
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: user
                                    ? null
                                    : Border.all(color: AppColors.cardBorder),
                              ),
                              child: SelectableText(
                                message.text,
                                textDirection: _isArabic(message.text)
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                                style: TextStyle(
                                  color: user
                                      ? AppColors.background
                                      : AppColors.textPrimary,
                                  height: 1.6,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Text(
                    _error!,
                    textDirection: _errorArabic
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    style: const TextStyle(color: AppColors.gold),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        enabled: !_sending && _api != null,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: 4000,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        onChanged: (_) => setState(() {}),
                        textDirection: _isArabic(_input.text)
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        cursorColor: AppColors.gold,
                        decoration: InputDecoration(
                          counterText: '',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 11,
                          ),
                          hintText: _t('اكتبي رسالتك…', 'Type your message…'),
                          hintStyle: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                              color: AppColors.cardBorder,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                              color: AppColors.cardBorder,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                              color: AppColors.goldDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Builder(
                      builder: (context) {
                        final enabled =
                            !(_sending || _api == null || _input.text.trim().isEmpty);
                        return Tooltip(
                          message: _t('إرسال', 'Send'),
                          child: GestureDetector(
                            onTap: enabled ? _send : null,
                            child: Opacity(
                              opacity: enabled ? 1 : 0.4,
                              child: const SizedBox(
                                width: 44,
                                height: 44,
                                child: CustomPaint(
                                  painter: RiyalCoinPainter(),
                                  child: Center(
                                    child: Icon(
                                      Icons.arrow_upward_rounded,
                                      color: AppColors.gold,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
