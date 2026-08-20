import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../widgets/email_entry_page.dart';
import 'verify_code_page.dart';

/// Password reset step 1: enter email and send reset code.
class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return EmailEntryPage(
      title: '重置密码',
      subtitle: '请输入您的注册邮箱，我们将向您发送验证码',
      icon: Icons.mail_outline,
      stepIndex: 0,
      onSendCode: (email) =>
          context.read<AuthRepository>().sendPasswordResetCode(email: email),
      nextPageBuilder: (email) => VerifyCodePage(email: email),
    );
  }
}