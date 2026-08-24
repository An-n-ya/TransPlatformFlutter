import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/auth/auth_repository.dart';
import '../../data/services/current_user_provider.dart';
import '../../data/services/token_storage_service.dart';
import '../../domain/models/auth_response.dart';
import '../../utils/result.dart';
import '../home/app_shell.dart';
import '../settings/debug/server_page.dart';
import '../widgets/app_header_logo.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/error_banner.dart';
import '../widgets/labeled_divider.dart';
import '../widgets/primary_action_button.dart';
import 'password/forgot_password_page.dart';
import 'register_page.dart';

/// Login page with username and password fields.
///
/// On successful login, navigates to [AppShell] (the main app shell).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = '请输入用户名和密码');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await context.read<AuthRepository>().login(
      username: username,
      password: password,
    );

    if (!mounted) return;

    switch (result) {
      case Ok<AuthResponse>():
        {
          // Persist tokens securely
          await context.read<TokenStorageService>().saveTokens(
            accessToken: result.value.accessToken,
            refreshToken: result.value.refreshToken,
          );
          context.read<CurrentUserProvider>().setUserId(result.value.user.id);
          if (!mounted) return;

          // Navigate to main app, replacing login page
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AppShell()),
          );
        }
      case Error<AuthResponse>():
        setState(() {
          _isLoading = false;
          _errorMessage = _extractErrorMessage(result.error);
        });
    }
  }

  String _extractErrorMessage(Exception error) {
    final msg = error.toString();
    if (msg.startsWith('ApiException')) {
      final start = msg.indexOf('): ');
      if (start != -1) return msg.substring(start + 3);
      return msg;
    }
    if (msg.startsWith('Exception: ')) return msg.substring(11);
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AuthScaffold(
      topGap: 48,
      backEnabled: false,
      appBarAction: IconButton(
        icon: const Icon(Icons.dns_outlined),
        tooltip: '切换服务器',
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ServerPage())),
      ),
      header: const AppHeaderLogo(
        imageAsset: 'assets/images/logoTP.png',
        title: '欢迎回来',
        subtitle: '登录您的账号以继续',
      ),
      actions: [
        PrimaryActionButton(
          label: '登录',
          loading: _isLoading,
          onPressed: _handleLogin,
        ),
        const SizedBox(height: 12),
        const LabeledDivider('还没有账号?'),
        const SizedBox(height: 12),
        PrimaryActionButton(
          label: '申请注册',
          onPressed: _isLoading
              ? null
              : () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const RegisterPage())),
          backgroundColor: cs.secondaryContainer,
          disabledBackgroundColor: cs.secondaryContainer.withValues(
            alpha: 0.38,
          ),
          foregroundColor: cs.onSecondaryContainer,
        ),
      ],
      children: [
        AuthTextField(
          controller: _usernameController,
          hint: '用户名',
          icon: Icons.person_outline,
          textInputAction: TextInputAction.next,
          enabled: !_isLoading,
          onChanged: (_) {
            if (_errorMessage != null) {
              setState(() => _errorMessage = null);
            }
          },
        ),
        const SizedBox(height: 16),
        AuthTextField(
          controller: _passwordController,
          hint: '密码',
          icon: Icons.lock_outline,
          obscure: _obscurePassword,
          textInputAction: TextInputAction.done,
          enabled: !_isLoading,
          onSubmitted: (_) => _handleLogin(),
          suffix: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              size: 20,
              color: cs.onSurfaceVariant,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
            ),
            style: TextButton.styleFrom(
              foregroundColor: cs.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              '忘记密码?',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        if (_errorMessage != null)
          ErrorBanner(_errorMessage!, padding: const EdgeInsets.only(top: 16)),
      ],
    );
  }
}
