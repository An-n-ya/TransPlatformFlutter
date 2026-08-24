import 'package:flutter/material.dart';

import '../../utils/result.dart';
import 'auth_scaffold.dart';
import 'auth_text_field.dart';
import 'error_banner.dart';
import 'primary_action_button.dart';

/// A reusable page for entering an email and sending a verification code.
///
/// Used by both the password reset flow and the email binding flow.
class EmailEntryPage extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final int stepIndex;
  final Future<Result<void>> Function(String email) onSendCode;
  final Widget Function(String email) nextPageBuilder;

  const EmailEntryPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.stepIndex,
    required this.onSendCode,
    required this.nextPageBuilder,
  });

  @override
  State<EmailEntryPage> createState() => _EmailEntryPageState();
}

class _EmailEntryPageState extends State<EmailEntryPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String email) {
    if (email.isEmpty) return null;
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    if (!emailRegex.hasMatch(email)) return '请输入有效的邮箱地址';
    return null;
  }

  Future<void> _handleSendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = '请输入邮箱地址');
      return;
    }
    final emailError = _validateEmail(email);
    if (emailError != null) {
      setState(() => _errorMessage = emailError);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await widget.onSendCode(email);

    if (!mounted) return;

    switch (result) {
      case Ok<void>():
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => widget.nextPageBuilder(email)),
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
    return AuthScaffold(
      currentStep: widget.stepIndex,
      backEnabled: !_isLoading,
      onBack: _isLoading ? null : () => Navigator.of(context).pop(),
      header: _buildHeader(),
      actions: _buildActions(),
      children: _buildFields(),
    );
  }

  Widget _buildHeader() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: Icon(widget.icon, size: 36, color: cs.primary),
        ),
        const SizedBox(height: 16),
        Text(
          widget.title,
          style: TextStyle(fontSize: 24, height: 32 / 24, color: cs.onSurface),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            widget.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 20 / 14,
              letterSpacing: 0.25,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFields() {
    return [
      AuthTextField(
        controller: _emailController,
        hint: '邮箱地址',
        icon: Icons.mail_outline,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        enabled: !_isLoading,
        hasError: _errorMessage != null,
        onChanged: (_) {
          if (_errorMessage != null) {
            setState(() => _errorMessage = null);
          }
        },
        onSubmitted: (_) => _handleSendCode(),
      ),
      if (_errorMessage != null)
        ErrorBanner(
          _errorMessage!,
          padding: const EdgeInsets.only(top: 4, left: 16),
        ),
    ];
  }

  List<Widget> _buildActions() {
    final cs = Theme.of(context).colorScheme;
    return [
      PrimaryActionButton(
        label: '发送验证码',
        loading: _isLoading,
        onPressed: _handleSendCode,
      ),
      const SizedBox(height: 12),
      PrimaryActionButton(
        label: '返回',
        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
        backgroundColor: cs.secondaryContainer,
        disabledBackgroundColor: cs.secondaryContainer.withValues(alpha: 0.38),
        foregroundColor: cs.onSecondaryContainer,
      ),
    ];
  }
}
