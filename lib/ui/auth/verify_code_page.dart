import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/auth/auth_repository.dart';
import '../../utils/result.dart';
import '../widgets/step_progress_indicator.dart';
import 'reset_password_page.dart';

class VerifyCodePage extends StatefulWidget {
  final String email;

  const VerifyCodePage({super.key, required this.email});

  @override
  State<VerifyCodePage> createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends State<VerifyCodePage> {
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

    final result = await context.read<AuthRepository>().sendPasswordResetCode(
          email: widget.email,
        );

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

  void _handleNext() {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _errorMessage = '请输入6位验证码');
      return;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _errorMessage = '验证码应为6位数字');
      return;
    }

    _countdownTimer?.cancel();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResetPasswordPage(
          email: widget.email,
          code: code,
        ),
      ),
    );
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
          onPressed: _isLoading
              ? null
              : () {
                  _countdownTimer?.cancel();
                  Navigator.of(context).pop();
                },
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
                    const StepProgressIndicator(currentStep: 1),
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
          child: const Icon(Icons.verified_user_outlined, size: 36, color: Color(0xFF6750A4)),
        ),
        const SizedBox(height: 16),
        const Text(
          '验证邮箱',
          style: TextStyle(
            fontSize: 24,
            height: 32 / 24,
            color: Color(0xFF1C1B1F),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '请输入发送到 ${widget.email} 的6位验证码',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            height: 20 / 14,
            letterSpacing: 0.25,
            color: Color(0xFF49454F),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCodeField(),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 16),
            child: Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 12, color: Color(0xFFB3261E)),
            ),
          ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _canResend && !_isLoading ? _handleResend : null,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6750A4),
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
      ],
    );
  }

  Widget _buildCodeField() {
    final hasError = _errorMessage != null;
    final borderColor = hasError ? const Color(0xFFB3261E) : const Color(0xFF79747E);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(color: borderColor),
    );
    return SizedBox(
      height: 56,
      child: TextField(
        controller: _codeController,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        maxLength: 6,
        enabled: !_isLoading,
        onChanged: (_) {
          if (_errorMessage != null) {
            setState(() => _errorMessage = null);
          }
        },
        style: const TextStyle(fontSize: 16, color: Color(0xFF1D1B20)),
        decoration: InputDecoration(
          hintText: '6位验证码',
          hintStyle: const TextStyle(fontSize: 16, color: Color(0xFF49454F)),
          prefixIcon: const Icon(Icons.lock_outline, size: 20, color: Color(0xFF49454F)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 11),
          border: border,
          enabledBorder: border,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(
              color: hasError ? const Color(0xFFB3261E) : const Color(0xFF6750A4),
              width: 1.5,
            ),
          ),
          counterText: '',
        ),
        onSubmitted: (_) => _handleNext(),
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
            onPressed: _isLoading ? null : _handleNext,
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
                    '下一步',
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
                : () {
                    _countdownTimer?.cancel();
                    Navigator.of(context).pop();
                  },
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