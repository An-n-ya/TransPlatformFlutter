import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/auth/auth_repository.dart';
import '../../data/services/current_user_provider.dart';
import '../../data/services/token_storage_service.dart';
import '../../domain/models/auth_response.dart';
import '../../utils/result.dart';
import '../home/app_shell.dart';
import '../settings/debug/server_page.dart';
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
          context
              .read<CurrentUserProvider>()
              .setUserId(result.value.user.id);
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
    return Scaffold(
      backgroundColor: const Color(0xFFFEF7FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Server switch entry
          IconButton(
            icon: const Icon(Icons.dns_outlined),
            tooltip: '切换服务器',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ServerPage()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 48),
                    _buildHeader(),
                    const Spacer(),
                    _buildFields(),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFB3261E),
                          ),
                        ),
                      ),
                    const Spacer(),
                    _buildActions(),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo (original asset) inside a primary-container rounded box
        Container(
          width: 80,
          height: 80,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: const Color(0xFFEADDFF),
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: Image.asset(
            'assets/images/logoTP.png',
            width: 80,
            height: 80,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '欢迎回来',
          style: TextStyle(
            fontSize: 32,
            height: 40 / 32,
            color: Color(0xFF1C1B1F),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '登录您的账号以继续',
          style: TextStyle(
            fontSize: 14,
            height: 20 / 14,
            letterSpacing: 0.25,
            color: Color(0xFF49454F),
          ),
        ),
      ],
    );
  }

  Widget _buildFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildField(
          controller: _usernameController,
          hint: '用户名',
          icon: Icons.person_outline,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        _buildField(
          controller: _passwordController,
          hint: '密码',
          icon: Icons.lock_outline,
          obscure: _obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleLogin(),
          suffix: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              size: 20,
              color: const Color(0xFF49454F),
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        // Forgot password link
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6750A4),
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
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
    Widget? suffix,
  }) {
    const borderColor = Color(0xFF79747E);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: borderColor),
    );
    return SizedBox(
      height: 56,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        enabled: !_isLoading,
        style: const TextStyle(fontSize: 16, color: Color(0xFF1D1B20)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 16, color: Color(0xFF49454F)),
          prefixIcon: Icon(icon, size: 20, color: const Color(0xFF49454F)),
          suffixIcon: suffix,
          contentPadding: const EdgeInsets.symmetric(horizontal: 11),
          border: border,
          enabledBorder: border,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFF6750A4), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Login button
        SizedBox(
          height: 40,
          child: FilledButton(
            onPressed: _isLoading ? null : _handleLogin,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6750A4),
              disabledBackgroundColor: const Color(0x806750A4),
              foregroundColor: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    '登录',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        // Divider with hint
        const Row(
          children: [
            Expanded(child: Divider(color: Color(0xFFCAC4D0), height: 1)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '还没有账号?',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 0.4,
                  color: Color(0xFF49454F),
                ),
              ),
            ),
            Expanded(child: Divider(color: Color(0xFFCAC4D0), height: 1)),
          ],
        ),
        const SizedBox(height: 12),
        // Register button
        SizedBox(
          height: 40,
          child: FilledButton(
            onPressed: _isLoading
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE8DEF8),
              disabledBackgroundColor: const Color(0x80E8DEF8),
              foregroundColor: const Color(0xFF1D192B),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            child: const Text(
              '申请注册',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }
}
