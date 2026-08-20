import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../utils/result.dart';
import '../../widgets/code_verification_page.dart';
import 'reset_password_page.dart';

/// Password reset step 2: verify the code sent to the email.
class VerifyCodePage extends StatelessWidget {
  final String email;

  const VerifyCodePage({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return CodeVerificationPage(
      email: email,
      title: '验证邮箱',
      subtitle: '请输入发送到 $email 的6位验证码',
      icon: Icons.verified_user_outlined,
      stepIndex: 1,
      onResendCode: (email) =>
          context.read<AuthRepository>().sendPasswordResetCode(email: email),
      onCodeEntered: (email, code) async {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResetPasswordPage(email: email, code: code),
          ),
        );
        return const Result.ok(null);
      },
    );
  }
}