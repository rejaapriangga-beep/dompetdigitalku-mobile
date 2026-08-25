// lib/screens/register_screen.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../api/auth_api.dart';
import '../l10n/app_strings.dart';
import '../theme.dart';
import '../urls.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _householdCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _agreed = false;
  bool _loading = false;
  String? _error;
  String? _success;

  Future<void> _submit() async {
    if (!_agreed) {
      setState(() => _error = S.t.mustAgreeError);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    try {
      await AuthApi.register(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        householdName: _householdCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() => _success = S.t.registerSuccessMessage);
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = S.t.registerFailedGeneric);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _householdCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.t.registerTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  S.t.registerSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(labelText: S.t.yourNameLabel),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _householdCtrl,
                  decoration: InputDecoration(
                    labelText: S.t.householdNameLabel,
                    hintText: S.t.householdNameHint,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: S.t.emailLabel),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: InputDecoration(labelText: S.t.passwordLabel),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreed,
                      onChanged: (v) => setState(() => _agreed = v ?? false),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.inkSoft,
                            ),
                            children: [
                              TextSpan(text: S.t.agreeConsentPrefix),
                              TextSpan(
                                text: S.t.privacyPolicyLink,
                                style: TextStyle(
                                  color: AppColors.primary,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => openExternalUrl(kPrivacyUrl),
                              ),
                              TextSpan(text: S.t.googleConsentMiddle),
                              TextSpan(
                                text: S.t.termsLink,
                                style: TextStyle(
                                  color: AppColors.primary,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => openExternalUrl(kTermsUrl),
                              ),
                              TextSpan(text: S.t.agreeConsentSuffix),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(color: AppColors.coral, fontSize: 13),
                  ),
                ],
                if (_success != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _success!,
                    style: TextStyle(color: AppColors.primary, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(S.t.registerButton),
                ),
                const SizedBox(height: 16),
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
                      children: [
                        TextSpan(text: S.t.alreadyHaveAccountPrefix),
                        TextSpan(
                          text: S.t.signInButton,
                          style: TextStyle(
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
