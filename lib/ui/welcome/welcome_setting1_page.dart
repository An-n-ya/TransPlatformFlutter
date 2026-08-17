import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/user/user_repository.dart';
import '../../domain/models/user.dart';
import '../../utils/result.dart';
import 'welcome_setting2_page.dart';

/// Welcome step 1/2 — ask the user for a nickname.
///
/// Persists the nickname via `PUT /api/v1/users/me` before continuing.
class WelcomeSetting1Page extends StatefulWidget {
  const WelcomeSetting1Page({super.key});

  @override
  State<WelcomeSetting1Page> createState() => _WelcomeSetting1PageState();
}

class _WelcomeSetting1PageState extends State<WelcomeSetting1Page> {
  final _nicknameController = TextEditingController();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nicknameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  bool get _canProceed => _nicknameController.text.trim().isNotEmpty;

  void _skip() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const WelcomeSetting2Page()),
    );
  }

  Future<void> _next() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final result = await context
        .read<UserRepository>()
        .updateUser(nickname: nickname);
    if (!mounted) return;

    switch (result) {
      case Ok<User>():
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const WelcomeSetting2Page()),
        );
      case Error<User>():
        setState(() {
          _isSaving = false;
          _errorMessage = _extractError(result.error);
        });
    }
  }

  String _extractError(Exception e) {
    final s = e.toString();
    final idx = s.indexOf('): ');
    return idx != -1 ? s.substring(idx + 3) : s;
  }

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
                    const SizedBox(height: 32),
                    _buildTopBar(),
                    const SizedBox(height: 40),
                    _buildContent(),
                    const Spacer(),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFB3261E),
                          ),
                        ),
                      ),
                    _buildNextButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Step indicator: 1/2
        const Row(
          children: [
            _StepBar(active: true),
            SizedBox(width: 8),
            _StepBar(active: false),
            SizedBox(width: 8),
            Text(
              '1 / 2',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 0.4,
                color: Color(0xFF49454F),
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: _isSaving ? null : _skip,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF49454F),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            '跳过',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Logo in a primary-container rounded box
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFFEADDFF),
            borderRadius: BorderRadius.circular(36),
          ),
          alignment: Alignment.center,
          child: Image.asset(
            'assets/images/logoTP.png',
            width: 64,
            height: 64,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          '您想被怎么称呼?',
          style: TextStyle(fontSize: 28, height: 36 / 28, color: Color(0xFF1C1B1F)),
        ),
        const SizedBox(height: 8),
        const Text(
          '设置一个昵称，让其他用户认识您。昵称可以随时修改。',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 20 / 14,
            letterSpacing: 0.25,
            color: Color(0xFF49454F),
          ),
        ),
        const SizedBox(height: 40),
        _buildNicknameField(),
        const SizedBox(height: 4),
        // Helper + counter row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  '支持中文、英文、数字及常用符号',
                  style: TextStyle(fontSize: 12, color: Color(0xFF49454F)),
                ),
              ),
              Text(
                '${_nicknameController.text.length} / 20',
                style: const TextStyle(fontSize: 12, color: Color(0xFF49454F)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNicknameField() {
    const borderColor = Color(0xFF79747E);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: borderColor),
    );
    return SizedBox(
      height: 56,
      child: TextField(
        controller: _nicknameController,
        maxLength: 20,
        enabled: !_isSaving,
        style: const TextStyle(fontSize: 16, color: Color(0xFF1D1B20)),
        decoration: InputDecoration(
          hintText: '您的昵称',
          hintStyle: const TextStyle(fontSize: 16, color: Color(0xFF49454F)),
          prefixIcon: const Icon(
            Icons.face_outlined,
            size: 20,
            color: Color(0xFF49454F),
          ),
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(horizontal: 11),
          border: border,
          enabledBorder: border,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFF6750A4), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      height: 40,
      child: FilledButton(
        onPressed: _canProceed && !_isSaving ? _next : null,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF6750A4),
          disabledBackgroundColor: const Color(0x1F1C1B1F),
          foregroundColor: Colors.white,
          disabledForegroundColor: const Color(0x611C1B1F),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        child: _isSaving
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
    );
  }
}

/// A short segment of the step indicator (active → primary, else outline).
class _StepBar extends StatelessWidget {
  final bool active;

  const _StepBar({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 24 : 16,
      height: 4,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF6750A4) : const Color(0xFFCAC4D0),
        borderRadius: BorderRadius.circular(100),
      ),
    );
  }
}
