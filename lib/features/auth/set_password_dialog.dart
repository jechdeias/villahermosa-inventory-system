import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/auth/auth_service.dart';

/// Asks for a new password and sets it on the signed-in account via
/// [AuthService.setPassword] (Supabase Auth + local bcrypt hash).
///
/// Returns true if a password was set, false/null if the user backed out.
Future<bool?> showSetPasswordDialog(BuildContext context, {AuthService? auth}) =>
    showDialog<bool>(
      context: context,
      builder: (_) => _SetPasswordDialog(auth: auth ?? AuthService.instance),
    );

String _promptShownKey(String userUuid) => 'password_prompt_shown_$userUuid';

/// The optional, once-only prompt shown right after a Google sign-in.
///
/// Shows only when the signed-in account has no password
/// ([AuthService.currentUserNeedsPassword]) and has not been asked before. It is
/// never forced: "Not now" just continues, and the same action stays available
/// from the profile screen. Safe to call from anywhere — failures reading
/// preferences are swallowed (worst case: the user is asked once more).
Future<void> maybePromptToSetPassword(BuildContext context, {AuthService? auth}) async {
  final service = auth ?? AuthService.instance;
  final user = service.getCurrentUser();
  if (user == null || !AuthService.needsPassword(user)) return;

  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_promptShownKey(user.uuid)) == true) return;
    await prefs.setBool(_promptShownKey(user.uuid), true);
  } catch (_) {}
  if (!context.mounted) return;

  final wantsToSet = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Set a password?'),
      content: const Text(
        'You signed in with Google. Add a password too, and you can sign in with '
        'your email on other devices — including the Windows app — without Google.\n\n'
        'You can do this later from your profile.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not now')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Set password')),
      ],
    ),
  );
  if (wantsToSet == true && context.mounted) {
    await showSetPasswordDialog(context, auth: service);
  }
}

class _SetPasswordDialog extends StatefulWidget {
  const _SetPasswordDialog({required this.auth});
  final AuthService auth;

  @override
  State<_SetPasswordDialog> createState() => _SetPasswordDialogState();
}

class _SetPasswordDialogState extends State<_SetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.auth.setPassword(_password.text);
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password set. You can now sign in with your email and password.')));
    } on PasswordSetException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = "Couldn't set the password: $e");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Set a password'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'New password',
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'Show password' : 'Hide password',
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) => (v ?? '').length < AuthService.minPasswordLength ? 'At least ${AuthService.minPasswordLength} characters' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirm,
                obscureText: _obscure,
                decoration: const InputDecoration(labelText: 'Confirm password'),
                validator: (v) => v != _password.text ? "Passwords don't match" : null,
                onFieldSubmitted: (_) => _save(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: _saving ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Set password'),
          ),
        ],
      );
}
