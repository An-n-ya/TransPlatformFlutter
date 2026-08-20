import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/user/user_repository.dart';
import '../../domain/models/user.dart';
import '../../utils/result.dart';
import '../widgets/code_verification_page.dart';

/// Email binding step 2: verify the code and bind the email.
class VerifyEmailCodePage extends StatelessWidget {
  final String email;

  const VerifyEmailCodePage({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return CodeVerificationPage(
      email: email,
      title: '验证邮箱',
      subtitle: '请输入发送到 $email 的6位验证码',
      icon: Icons.verified_user_outlined,
      stepIndex: 1,
      onResendCode: (email) =>
          context.read<UserRepository>().sendEmailVerificationCode(email: email),
      onCodeEntered: (email, code) async {
        final result = await context.read<UserRepository>().verifyEmail(
              email: email,
              code: code,
            );
        if (!context.mounted) return const Result.ok(null);
        switch (result) {
          case Ok<User>():
            // Pop VerifyEmailCodePage + ResetEmailPage, return true to profile.
            Navigator.of(context).pop();
            Navigator.of(context).pop(true);
            return const Result.ok(null);
          case Error<User>():
            return Result.error(result.error);
        }
      },
    );
  }
}