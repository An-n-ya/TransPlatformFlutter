import 'dart:async';

import 'package:flutter/material.dart';

import '../../utils/result.dart';
import 'auth_scaffold.dart';
import 'auth_text_field.dart';
import 'error_banner.dart';
import 'primary_action_button.dart';

/// A reusable page for entering a verification code sent to an email.
///
/// Used by both the password reset flow and the email binding flow.
/// [onResendCode] is called when the user taps "resend".
/// [onCodeEntered] is called when the user enters a valid 6-digit code
/// and taps "next". It returns a [Result] so the page can show errors:
/// - [Ok]: the caller has handled navigation (e.g. pushed next page).
/// - [Error]: verification failed, the error is shown inline.
class CodeVerificationPage extends StatefulWidget {
  final String email;
  final String title;
  final String subtitle;
  final IconData icon;
  final int stepIndex;
  final Future<Result<void>> Function(String email) onResendCode;
  final Future<Result<void>> Function(String email, String code) onCodeEntered;

  const CodeVerificationPage({
    super.key,
    required this.email,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.stepIndex,
    required this.onResendCode,
    required this.onCodeEntered,
  });

  @override
  State<CodeVerificationPage> createState() => _CodeVerificationPageState();
}

class _CodeVerificationPageState extends State<CodeVerificationPage> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  int _resendCountdown = 60;
  bool _canResend = false;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _handleResend() async {
    if (!_canResend) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await widget.onResendCode(widget.email);

    if (!mounted) return;

    switch (result) {
      case Ok<void>():
        setState(() {
          _isLoading = false;
          _canResend = false;
          _resendCountdown = 60;
        });
        _startCountdown();
      case Error<void>():
        setState(() {
          _isLoading = false;
          _errorMessage = _extractErrorMessage(result.error);
        });
    }
  }

  Future<void> _handleNext() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _errorMessage = '请输入6位验证码');
      return;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _errorMessage = '验证码应为6位数字');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _countdownTimer?.cancel();

    final result = await widget.onCodeEntered(widget.email, code);

    if (!mounted) return;

    switch (result) {
      case Ok<void>():
        // Caller handled navigation; nothing more to do.
        break;
      case Error<void>(:final error):
        setState(() {
          _isLoading = false;
          _errorMessage = _extractErrorMessage(error);
        });
        _startCountdown();
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
      onBack: _isLoading
          ? null
          : () {
              _countdownTimer?.cancel();
              Navigator.of(context).pop();
            },
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
        Text(
          widget.subtitle,
          textAlign: TextAlign.center,
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

  List<Widget> _buildFields() {
    final cs = Theme.of(context).colorScheme;
    return [
      AuthTextField(
        controller: _codeController,
        hint: '6位验证码',
        icon: Icons.lock_outline,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        maxLength: 6,
        hideCounter: true,
        enabled: !_isLoading,
        hasError: _errorMessage != null,
        onChanged: (_) {
          if (_errorMessage != null) {
            setState(() => _errorMessage = null);
          }
        },
        onSubmitted: (_) => _handleNext(),
      ),
      if (_errorMessage != null)
        ErrorBanner(
          _errorMessage!,
          padding: const EdgeInsets.only(top: 4, left: 16),
        ),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: _canResend && !_isLoading ? _handleResend : null,
          style: TextButton.styleFrom(
            foregroundColor: cs.primary,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            _canResend ? '重新发送验证码' : '重新发送 (${_resendCountdown}s)',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildActions() {
    final cs = Theme.of(context).colorScheme;
    return [
      PrimaryActionButton(
        label: '下一步',
        loading: _isLoading,
        onPressed: _handleNext,
      ),
      const SizedBox(height: 12),
      PrimaryActionButton(
        label: '返回',
        onPressed: _isLoading
            ? null
            : () {
                _countdownTimer?.cancel();
                Navigator.of(context).pop();
              },
        backgroundColor: cs.secondaryContainer,
        disabledBackgroundColor: cs.secondaryContainer.withValues(alpha: 0.38),
        foregroundColor: cs.onSecondaryContainer,
      ),
    ];
  }
}
