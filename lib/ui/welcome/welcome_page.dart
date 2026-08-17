import 'package:flutter/material.dart';

import '../home/app_shell.dart';

/// Final welcome screen shown after the onboarding steps.
///
/// Summarizes the community and enters the app on "开始使用".
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF7FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo in a primary-container circle
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEADDFF),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Image.asset(
                      'assets/images/logoTP.png',
                      width: 56,
                      height: 56,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Center(
                  child: Text(
                    '欢迎加入!',
                    style: TextStyle(
                      fontSize: 36,
                      height: 44 / 36,
                      color: Color(0xFF1C1B1F),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    '您的账号已设置完成。\n开始探索属于您的空间吧。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 24 / 16,
                      letterSpacing: 0.15,
                      color: Color(0xFF49454F),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const _FeatureRow(
                  symbol: '✦',
                  title: '跨性别社群',
                  subtitle: '专属跨性别人群自己的社群',
                ),
                const SizedBox(height: 12),
                const _FeatureRow(
                  symbol: '◎',
                  title: '私密安全',
                  subtitle: '仅限受邀成员的专属空间',
                ),
                const SizedBox(height: 12),
                const _FeatureRow(
                  symbol: '◈',
                  title: '实时互动',
                  subtitle: '与志同道合的伙伴交流',
                ),
                const SizedBox(height: 32),
                // Start button
                SizedBox(
                  height: 40,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const AppShell()),
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
                      '开始使用',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A highlight row describing a community benefit.
class _FeatureRow extends StatelessWidget {
  final String symbol;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.symbol,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE7E0EC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            symbol,
            style: const TextStyle(
              fontSize: 20,
              height: 30 / 20,
              letterSpacing: -0.45,
              color: Color(0xFF6750A4),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1C1B1F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    letterSpacing: 0.4,
                    color: Color(0xFF49454F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
