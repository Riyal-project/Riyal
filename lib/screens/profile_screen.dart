import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/auth_store.dart';
import '../data/profile_store.dart';
import '../data/profile_validation.dart';
import '../data/user_bank_accounts_store.dart';
import '../l10n/strings.dart';
import '../widgets/action_confirmation.dart';
import '../widgets/account_section.dart';
import '../theme/app_theme.dart';
import '../widgets/coin_back_button.dart';
import '../widgets/riyal_coin_painter.dart';
import 'change_password_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _store = ProfileStore.instance;
  bool _loading = true;
  bool _saving = false;
  static const _editable = ['Full name', 'Email', 'Phone number'];
  List<String> get _missing => _editable
      .where(
        (field) => !isProfileFieldComplete(field, _store.values[field] ?? ''),
      )
      .toList();
  String _display(String field) {
    final value = _store.values[field] ?? '';
    if (field == 'Joined on') {
      final date = DateTime.tryParse(value);
      return date == null
          ? Strings.t('not_available')
          : MaterialLocalizations.of(context).formatMediumDate(date);
    }
    return isProfileFieldComplete(field, value)
        ? value
        : Strings.f('add_your_field', profileFieldLabel(field).toLowerCase());
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await _store.load().timeout(const Duration(seconds: 5));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Strings.t('profile_load_failed'))),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _edit(String field) async {
    if (_saving || field == 'Joined on') return;
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _EditProfileDialog(
        field: field,
        value: isProfileFieldComplete(field, _store.values[field]!)
            ? _store.values[field]!
            : '',
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _saving = true);
    try {
      await _store.save(field, result).timeout(const Duration(seconds: 5));
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Strings.f('profile_field_updated', profileFieldLabel(field)),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Strings.t('profile_save_failed'))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // Data is device-scoped rather than backed by a deletable server-side
  // account (see profile_local_note) — "deleting the account" here means
  // wiping every local key, so re-launching regenerates a fresh device_id
  // and none of this device's previous data is reachable again.
  Future<void> _deleteAccount() async {
    final firstConfirm = await showActionConfirmation(
      context,
      title: Strings.t('delete_account_confirm_title'),
      message: Strings.t('delete_account_confirm_message'),
      confirmLabel: Strings.t('delete_account_action'),
    );
    if (firstConfirm != true || !mounted) return;
    final finalConfirm = await showActionConfirmation(
      context,
      title: Strings.t('delete_account_final_title'),
      message: Strings.t('delete_account_final_message'),
      confirmLabel: Strings.t('delete_account_action'),
    );
    if (finalConfirm != true || !mounted) return;
    await AuthStore.instance.signOut();
    UserBankAccountsStore.instance.clear();
    await SharedPreferencesAsync().clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      leading: const CoinBackButton(),
      title: Text(Strings.t('profile_title')),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    const SizedBox(
                      width: 112,
                      height: 112,
                      child: CustomPaint(
                        painter: RiyalCoinPainter(),
                        child: Center(
                          child: Icon(
                            Icons.person_outline_rounded,
                            size: 56,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      isProfileFieldComplete(
                            'Full name',
                            _store.values['Full name']!,
                          )
                          ? _store.values['Full name']!
                          : Strings.t('your_profile'),
                      style: const TextStyle(
                        fontSize: 24,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Strings.t('your_personal_details'),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 28),
                    AccountSection(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _missing.isEmpty
                                ? Strings.t('details_complete')
                                : Strings.t('complete_your_profile'),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            Strings.f(
                              'details_added_count',
                              '${3 - _missing.length}',
                            ),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: (3 - _missing.length) / 3,
                              minHeight: 7,
                              color: AppColors.gold,
                              backgroundColor: AppColors.trackBackground,
                            ),
                          ),
                          if (_missing.isNotEmpty)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _saving
                                    ? null
                                    : () => _edit(_missing.first),
                                child: Text(
                                  Strings.f(
                                    'add_field',
                                    profileFieldLabel(
                                      _missing.first,
                                    ).toLowerCase(),
                                  ),
                                  style: const TextStyle(color: AppColors.gold),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_saving)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: LinearProgressIndicator(color: AppColors.gold),
                      ),
                    for (final entry in const [
                      ('Full name', Icons.person_outline),
                      ('Email', Icons.email_outlined),
                      ('Phone number', Icons.phone_outlined),
                      ('Joined on', Icons.calendar_month_outlined),
                    ])
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          leading: Icon(entry.$2, color: AppColors.gold),
                          title: Text(
                            profileFieldLabel(entry.$1),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _display(entry.$1),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          trailing: entry.$1 == 'Joined on'
                              ? null
                              : IconButton(
                                  tooltip: Strings.f(
                                    'edit_field_tooltip',
                                    profileFieldLabel(entry.$1),
                                  ),
                                  onPressed: _saving
                                      ? null
                                      : () => _edit(entry.$1),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: AppColors.gold,
                                    size: 20,
                                  ),
                                ),
                        ),
                      ),
                    AccountSection(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            color: AppColors.gold,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              Strings.t('profile_local_note'),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                height: 1.5,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: AppColors.cardBorder),
                      ),
                      tileColor: AppColors.surface,
                      leading: const Icon(
                        Icons.lock_outline,
                        color: AppColors.gold,
                      ),
                      title: Text(
                        Strings.t('change_password'),
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.gold,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ChangePasswordScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: AppColors.cardBorder),
                      ),
                      tileColor: AppColors.surface,
                      leading: const Icon(
                        Icons.delete_outline,
                        color: AppColors.statusCancelled,
                      ),
                      title: Text(
                        Strings.t('delete_account_menu_item'),
                        style: const TextStyle(
                          color: AppColors.statusCancelled,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: _deleteAccount,
                    ),
                  ],
                ),
              ),
            ),
          ),
  );
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.field, required this.value});
  final String field, value;
  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _form = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: widget.value);
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AppColors.surface,
    title: Text(Strings.f('edit_field_title', profileFieldLabel(widget.field))),
    content: Form(
      key: _form,
      child: TextFormField(
        controller: _controller,
        autofocus: true,
        keyboardType: widget.field == 'Email'
            ? TextInputType.emailAddress
            : widget.field == 'Phone number'
            ? TextInputType.phone
            : TextInputType.name,
        decoration: InputDecoration(
          labelText: profileFieldLabel(widget.field),
          border: const OutlineInputBorder(),
        ),
        validator: (value) => validateProfileField(widget.field, value ?? ''),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(Strings.t('cancel')),
      ),
      TextButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(
              context,
              widget.field == 'Phone number'
                  ? normalizeProfilePhone(_controller.text)
                  : _controller.text.trim(),
            );
          }
        },
        child: Text(Strings.t('save')),
      ),
    ],
  );
}
