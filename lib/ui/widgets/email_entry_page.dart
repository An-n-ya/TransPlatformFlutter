import 'package:flutter/material.dart';

import '../../utils/result.dart';
import 'step_progress_indicator.dart';

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
          MaterialPageRoute(
            builder: (_) => widget.nextPageBuilder(email),
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
                    StepProgressIndicator(currentStep: widget.stepIndex),
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
          child: Icon(widget.icon, size: 36, color: const Color(0xFF6750A4)),
        ),
        const SizedBox(height: 16),
        Text(
          widget.title,
          style: const TextStyle(
            fontSize: 24,
            height: 32 / 24,
            color: Color(0xFF1C1B1F),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            widget.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildEmailField(),
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

  Widget _buildEmailField() {
    final hasError = _errorMessage != null;
    final borderColor =
        hasError ? const Color(0xFFB3261E) : const Color(0xFF79747E);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(color: borderColor),
    );
    return SizedBox(
      height: 56,
      child: TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        enabled: !_isLoading,
        onChanged: (_) {
          if (_errorMessage != null) {
            setState(() => _errorMessage = null);
          }
        },
        style: const TextStyle(fontSize: 16, color: Color(0xFF1D1B20)),
        decoration: InputDecoration(
          hintText: '邮箱地址',
          hintStyle: const TextStyle(fontSize: 16, color: Color(0xFF49454F)),
          prefixIcon: const Icon(Icons.mail_outline,
              size: 20, color: Color(0xFF49454F)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 11),
          border: border,
          enabledBorder: border,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(
              color: hasError
                  ? const Color(0xFFB3261E)
                  : const Color(0xFF6750A4),
              width: 1.5,
            ),
          ),
        ),
        onSubmitted: (_) => _handleSendCode(),
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
            onPressed: _isLoading ? null : _handleSendCode,
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
                    '发送验证码',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: FilledButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
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