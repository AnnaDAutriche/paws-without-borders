import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:paws_without_borders/providers/auth_provider.dart';
import 'package:paws_without_borders/theme.dart';

class AuthScreen extends StatefulWidget {
  final String? from;
  const AuthScreen({super.key, this.from});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPassword = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _loginEmail.dispose();
    _loginPassword.dispose();
    _regEmail.dispose();
    _regPassword.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await context.read<AuthProvider>().signInWithEmail(_loginEmail.text.trim(), _loginPassword.text);
      if (!mounted) return;
      context.go(widget.from ?? '/dashboard');
    } catch (e) {
      setState(() => _error = 'Login failed. Please check your credentials.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleRegister() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await context.read<AuthProvider>().registerWithEmail(_regEmail.text.trim(), _regPassword.text);
      if (!mounted) return;
      context.go(widget.from ?? '/dashboard');
    } catch (e) {
      setState(() => _error = 'Registration failed. Try a different email/password.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showForgotPasswordSheet() async {
    final emailController = TextEditingController(text: _loginEmail.text.trim());

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ForgotPasswordSheet(
          emailController: emailController,
          onSend: (email) async {
            try {
              await fb.FirebaseAuth.instance.sendPasswordResetEmail(email: email);
              debugPrint('Password reset email sent to: $email');
            } catch (e) {
              debugPrint('Failed to send password reset email to $email: $e');
              rethrow;
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: AppSpacing.paddingLg,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppColors.lightPrimaryText,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Shelter access',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: TabBar(
                controller: _tab,
                dividerColor: Colors.transparent,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: AppColors.lightSecondaryText,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                tabs: const [
                  Tab(text: 'Login'),
                  Tab(text: 'Register'),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                child: Container(
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.20)),
                  ),
                  child: Row(
                    spacing: 10,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.red),
                      Expanded(
                        child: Text(
                          _error!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.lightPrimaryText),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _AuthPane(
                    title: 'Welcome back',
                    subtitle: 'Log in to manage your shelter profile and animals.',
                    emailController: _loginEmail,
                    passwordController: _loginPassword,
                    isLoading: _loading,
                    buttonText: 'Login',
                    onSubmit: _handleLogin,
                    footer: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _loading ? null : _showForgotPasswordSheet,
                        child: const Text('Forgot password?'),
                      ),
                    ),
                  ),
                  _AuthPane(
                    title: 'Create an account',
                    subtitle: 'Register with email/password, then create your shelter profile.',
                    emailController: _regEmail,
                    passwordController: _regPassword,
                    isLoading: _loading,
                    buttonText: 'Register',
                    onSubmit: _handleRegister,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthPane extends StatelessWidget {
  final String title;
  final String subtitle;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final String buttonText;
  final VoidCallback onSubmit;
  final Widget? footer;

  const _AuthPane({
    required this.title,
    required this.subtitle,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.buttonText,
    required this.onSubmit,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.lightSecondaryText)),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.email_rounded), hintText: 'Email'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.lock_rounded), hintText: 'Password'),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onSubmit,
              icon: isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              label: Text(buttonText, style: const TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (footer != null) ...[
            footer!,
            const SizedBox(height: AppSpacing.md),
          ],
          Text(
            'Admin note: if your email matches the admin email, you\'ll see extra controls.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.lightHint),
          ),
        ],
      ),
    );
  }
}

class _ForgotPasswordSheet extends StatefulWidget {
  final TextEditingController emailController;
  final Future<void> Function(String email) onSend;

  const _ForgotPasswordSheet({required this.emailController, required this.onSend});

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  bool _sending = false;
  bool _sent = false;
  String? _error;

  String get _email => widget.emailController.text.trim();

  bool get _canSend {
    final e = _email;
    return e.isNotEmpty && e.contains('@') && e.contains('.') && !_sending;
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      await widget.onSend(_email);
      if (!mounted) return;
      setState(() {
        _sent = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not send reset email. Please double-check the address and try again.';
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          border: Border(top: BorderSide(color: scheme.outline)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Reset password',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: _sending ? null : () => context.pop(),
                      icon: Icon(Icons.close_rounded, color: Theme.of(context).iconTheme.color),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _sent
                      ? 'If an account exists for this email, we\'ve sent a password reset link. Check your inbox (and spam).'
                      : 'Enter the email address you use to sign in and we\'ll email you a reset link.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurface.withValues(alpha: 0.72), height: 1.5),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (!_sent) ...[
                  TextField(
                    controller: widget.emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    enabled: !_sending,
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.email_rounded), hintText: 'Email'),
                    onSubmitted: (_) => _canSend ? _send() : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: AppSpacing.paddingMd,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.20)),
                      ),
                      child: Row(
                        spacing: 10,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.red),
                          Expanded(
                            child: Text(
                              _error!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _canSend ? _send : null,
                      icon: _sending
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.email_outlined, color: Colors.white),
                      label: const Text('Send reset link', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Tip: this can take a minute to arrive.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurface.withValues(alpha: 0.55)),
                  ),
                ] else ...[
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.check_rounded, color: Colors.white),
                      label: const Text('Done', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
