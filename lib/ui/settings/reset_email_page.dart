import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/user/user_repository.dart';
import '../widgets/email_entry_page.dart';
import 'verify_email_code_page.dart';

/// Email binding step 1: enter email and send verification code.
class ResetEmailPage extends StatelessWidget {
  final bool isUpdate;

  const ResetEmailPage({super.key, this.isUpdate = false});

  @override
  Widget build(BuildContext context) {
    return EmailEntryPage(
      title: isUpdate ? '修改邮箱' : '绑定邮箱',
      subtitle: '请输入您的邮箱，我们将向您发送验证码',
      icon: Icons.alternate_email,
      stepIndex: 0,
      onSendCode: (email) =>
          context.read<UserRepository>().sendEmailVerificationCode(email: email),
      nextPageBuilder: (email) => VerifyEmailCodePage(email: email),
    );
  }
}