import 'package:flutter/material.dart';

import '../../widgets/step_progress_indicator.dart';
import '../login_page.dart';

class ResetPasswordSuccessPage extends StatelessWidget {
  const ResetPasswordSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF7FF),
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
                    const StepProgressIndicator(currentStep: 3),
                    const SizedBox(height: 24),
                    _buildHeader(),
                    const Spacer(),
                    _buildActions(context),
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
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFFEADDFF),
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.check_circle_outline, size: 52, color: Color(0xFF6750A4)),
        ),
        const SizedBox(height: 16),
        const Text(
          '密码重置成功',
          style: TextStyle(
            fontSize: 24,
            height: 32 / 24,
            color: Color(0xFF1C1B1F),
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '您的密码已成功重置，请使用新密码登录',
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

  Widget _buildActions(BuildContext context) {
    return SizedBox(
      height: 40,
      child: FilledButton(
        onPressed: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF6750A4),
          foregroundColor: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        child: const Text(
          '返回登录',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}