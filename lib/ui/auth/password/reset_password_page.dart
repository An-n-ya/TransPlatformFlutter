import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../utils/result.dart';
import '../../widgets/step_progress_indicator.dart';
import 'reset_password_success_page.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  final String code;

  const ResetPasswordPage({
    super.key,
    required this.email,
    required this.code,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  int _calculateStrength(String password) {
    if (password.isEmpty) return 0;
    int strength = 0;
    if (password.length >= 8) strength++;
    if (RegExp(r'[A-Za-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password)) {
      strength++;
    }
    if (RegExp(r'[!@#$%^&*(),.?{}|<>_\-+=\[\]\\;`~]').hasMatch(password)) {
      strength++;
    }
    return strength;
  }

  String _strengthLabel(int strength) {
    switch (strength) {
      case 0:
        return '';
      case 1:
        return '弱';
      case 2:
        return '中';
      case 3:
        return '强';
      default:
        return '';
    }
  }

  Color _strengthColor(int strength) {
    switch (strength) {
      case 1:
        return const Color(0xFFB3261E);
      case 2:
        return const Color(0xFFFF9800);
      case 3:
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFFE7E0EC);
    }
  }

  String? _validatePassword(String password) {
    if (password.isEmpty) return null;
    if (password.length < 8) return '密码至少需要 8 位';
    if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
        !RegExp(r'[0-9]').hasMatch(password)) {
      return '密码需同时包含字母和数字';
    }
    return null;
  }

  Future<void> _handleReset() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password.isEmpty) {
      setState(() => _errorMessage = '请输入新密码');
      return;
    }
    final passwordError = _validatePassword(password);
    if (passwordError != null) {
      setState(() => _errorMessage = passwordError);
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = '两次输入的密码不一致');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await context.read<AuthRepository>().resetPassword(
          email: widget.email,
          code: widget.code,
          newPassword: password,
        );

    if (!mounted) return;

    switch (result) {
      case Ok<void>():
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const ResetPasswordSuccessPage(),
          ),
        );
      case Error<void>():
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
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
                    const StepProgressIndicator(currentStep: 2),
                    const SizedBox(height: 24),
                    _buildHeader(),
                    const Spacer(),
                    _buildForm(),
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
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFEADDFF),
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.lock_outline, size: 36, color: Color(0xFF6750A4)),
        ),
        const SizedBox(height: 16),
        const Text(
          '设置新密码',
          style: TextStyle(
            fontSize: 24,
            height: 32 / 24,
            color: Color(0xFF1C1B1F),
          ),
        ),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '新密码须与旧密码不同，且至少8位字符',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 20 / 14,
              letterSpacing: 0.25,
              color: Color(0xFF49454F),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    final strength = _calculateStrength(_passwordController.text);
    final strengthLabel = _strengthLabel(strength);
    final strengthColor = _strengthColor(strength);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPasswordField(
          controller: _passwordController,
          hint: '新密码',
          obscure: _obscurePassword,
          onToggleObscure: () =>
              setState(() => _obscurePassword = !_obscurePassword),
          onChanged: (_) {
            if (_errorMessage != null) {
              setState(() => _errorMessage = null);
            }
            setState(() {});
          },
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: List.generate(3, (index) {
                    final isActive = index < strength;
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
                        height: 4,
                        decoration: BoxDecoration(
                          color: isActive
                              ? strengthColor
                              : const Color(0xFFE7E0EC),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                strengthLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: strength > 0
                      ? strengthColor
                      : const Color(0xFF49454F),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildPasswordField(
          controller: _confirmController,
          hint: '确认新密码',
          obscure: _obscureConfirm,
          onToggleObscure: () =>
              setState(() => _obscureConfirm = !_obscureConfirm),
          onChanged: (_) {
            if (_errorMessage != null) {
              setState(() => _errorMessage = null);
            }
          },
        ),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 16),
            child: Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 12, color: Color(0xFFB3261E)),
            ),
          ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggleObscure,
    ValueChanged<String>? onChanged,
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
        textInputAction: TextInputAction.done,
        enabled: !_isLoading,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 16, color: Color(0xFF1D1B20)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 16, color: Color(0xFF49454F)),
          prefixIcon: const Icon(Icons.lock_outline, size: 20, color: Color(0xFF49454F)),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              size: 20,
              color: const Color(0xFF49454F),
            ),
            onPressed: onToggleObscure,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 11),
          border: border,
          enabledBorder: border,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFF6750A4), width: 1.5),
          ),
        ),
        onSubmitted: (_) => _handleReset(),
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 40,
          child: FilledButton(
            onPressed: _isLoading ? null : _handleReset,
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
                    '确认重置',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: FilledButton(
            onPressed: _isLoading
                ? null
                : () => Navigator.of(context).pop(),
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
              '返回',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }
}