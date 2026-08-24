import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/auth/auth_repository.dart';
import '../../data/repositories/user/user_repository.dart';
import '../../data/services/current_user_provider.dart';
import '../../data/services/token_storage_service.dart';
import '../../domain/models/auth_response.dart';
import '../../utils/result.dart';
import '../welcome/welcome_setting1_page.dart';
import 'login_page.dart';

/// Register page — invitation code, username and password.
///
/// On successful registration, saves tokens and enters the app shell.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _invitationController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isCheckingUsername = false;
  String? _errorMessage;
  String? _usernameError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    // Validate the username when the field loses focus.
    _usernameFocusNode.addListener(() {
      if (!_usernameFocusNode.hasFocus) _checkUsernameAvailable();
    });
    // Validate the password when the field loses focus.
    _passwordFocusNode.addListener(() {
      if (!_passwordFocusNode.hasFocus) {
        setState(() {
          _passwordError = _validatePassword(_passwordController.text);
        });
      }
    });
  }

  @override
  void dispose() {
    _invitationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  /// Validates a password against the strength rules, or null when valid.
  String? _validatePassword(String password) {
    if (password.isEmpty) return null;
    if (password.length < 8) return '密码至少需要 8 位';
    if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
        !RegExp(r'[0-9]').hasMatch(password)) {
      return '密码需同时包含字母和数字';
    }
    return null;
  }

  /// Checks with the backend whether the username is still available.
  Future<void> _checkUsernameAvailable() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) return;

    setState(() => _isCheckingUsername = true);
    final result = await context
        .read<UserRepository>()
        .checkUsername(username);
    if (!mounted) return;
    // Ignore stale results if the input changed meanwhile.
    if (_usernameController.text.trim() != username) return;

    setState(() {
      _isCheckingUsername = false;
      _usernameError = switch (result) {
        Ok<bool>(:final value) => value ? null : '用户名已被占用',
        Error<bool>() => '用户名校验失败，请稍后重试',
      };
    });
  }

  /// Validates inputs, returning an error message or null.
  String? _validate() {
    if (_invitationController.text.trim().isEmpty) return '请输入邀请码';
    if (_usernameController.text.trim().isEmpty) return '请输入用户名';
    final password = _passwordController.text;
    final passwordError = _validatePassword(password);
    if (passwordError != null) return passwordError;
    return null;
  }

  Future<void> _handleRegister() async {
    final validationError = _validate();
    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return;
    }
    // Re-check username availability right before submitting.
    await _checkUsernameAvailable();
    if (!mounted) return;
    if (_usernameError != null) {
      setState(() => _errorMessage = _usernameError);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final username = _usernameController.text.trim();
    // The design has no nickname field, so reuse the username.
    final result = await context.read<AuthRepository>().register(
          username: username,
          nickname: username,
          password: _passwordController.text,
          invitationCode: _invitationController.text.trim(),
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

          // Enter the onboarding flow, replacing login/register page.
          // After onboarding completes, the welcome page opens the app shell.
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const WelcomeSetting1Page(),
            ),
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
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
                    const SizedBox(height: 36),
                    _buildHeader(),
                    const Spacer(),
                    _buildForm(),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.error,
                          ),
                        ),
                      ),
                    const Spacer(),
                    _buildActions(),
                    const SizedBox(height: 40),
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
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        // Logo (original asset) inside a primary-container rounded box
        Container(
          width: 80,
          height: 80,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
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
        Text(
          '创建账号',
          style: TextStyle(
            fontSize: 32,
            height: 40 / 32,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '受邀用户专属注册通道',
          style: TextStyle(
            fontSize: 14,
            height: 20 / 14,
            letterSpacing: 0.25,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Invitation code section ──
        _buildSectionLabel(Icons.confirmation_number_outlined, '邀请码验证'),
        const SizedBox(height: 8),
        _buildField(
          controller: _invitationController,
          hint: '邀请码',
          icon: Icons.confirmation_number_outlined,
          textInputAction: TextInputAction.next,
        ),
        Padding(
          padding: EdgeInsets.only(left: 16, top: 4),
          child: Text(
            '请输入您收到的邀请码',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 24),
        // ── Divider ──
        Row(
          children: [
            Expanded(child: Divider(color: cs.outlineVariant, height: 1)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '账号信息',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 0.4,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(child: Divider(color: cs.outlineVariant, height: 1)),
          ],
        ),
        const SizedBox(height: 16),
        // ── Account info section ──
        _buildField(
          controller: _usernameController,
          hint: '用户名',
          icon: Icons.person_outline,
          focusNode: _usernameFocusNode,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() => _usernameError = null),
          suffix: _isCheckingUsername
              ? Padding(
                  padding: const EdgeInsets.all(18),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.primary,
                    ),
                  ),
                )
              : null,
        ),
        _buildFieldError(_usernameError),
        const SizedBox(height: 16),
        _buildField(
          controller: _passwordController,
          hint: '设置密码',
          icon: Icons.lock_outline,
          focusNode: _passwordFocusNode,
          obscure: _obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleRegister(),
          onChanged: (_) => setState(() => _passwordError = null),
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
        _buildFieldError(_passwordError),
        Padding(
          padding: EdgeInsets.only(left: 16, top: 4),
          child: Text(
            '使用 8 位以上字符，包含数字与字母',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldError(String? error) {
    final cs = Theme.of(context).colorScheme;
    if (error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 4),
      child: Text(
        error,
        style: TextStyle(fontSize: 12, color: cs.error),
      ),
    );
  }

  Widget _buildSectionLabel(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF625B71)),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            color: Color(0xFF625B71),
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    FocusNode? focusNode,
    bool obscure = false,
    TextInputAction? textInputAction,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    Widget? suffix,
  }) {
    final cs = Theme.of(context).colorScheme;
    final borderColor = cs.outline;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(color: borderColor),
    );
    return SizedBox(
      height: 56,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscure,
        textInputAction: textInputAction,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        enabled: !_isLoading,
        style: TextStyle(fontSize: 16, color: cs.onSurface),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 16, color: cs.onSurfaceVariant),
          prefixIcon: Icon(icon, size: 20, color: cs.onSurfaceVariant),
          suffixIcon: suffix,
          contentPadding: const EdgeInsets.symmetric(horizontal: 11),
          border: border,
          enabledBorder: border,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: cs.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Submit button
        SizedBox(
          height: 40,
          child: FilledButton(
            onPressed: _isLoading ? null : _handleRegister,
            style: FilledButton.styleFrom(
              backgroundColor: cs.primary,
              disabledBackgroundColor: cs.primary.withValues(alpha: 0.38),
              foregroundColor: cs.onPrimary,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.onPrimary,
                    ),
                  )
                : const Text(
                    '完成注册',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        // Back to login
        Center(
          child: TextButton(
            onPressed: _isLoading
                ? null
                : () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '已有账号，去登录',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: cs.primary,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 16, color: cs.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
