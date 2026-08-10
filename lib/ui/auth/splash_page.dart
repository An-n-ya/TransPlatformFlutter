import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/api/api_client.dart';
import '../../data/services/token_storage_service.dart';
import '../home/app_shell.dart';
import 'login_page.dart';

/// Shown on app startup while checking for a saved login session.
///
/// - Token found → auto-navigate to [AppShell] (restore session)
/// - No token   → navigate to [LoginPage]
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final storage = context.read<TokenStorageService>();
    final hasToken = await storage.hasTokens();

    if (!mounted) return;

    if (hasToken) {
      // Restore session: read tokens and set on ApiClient (if available)
      final accessToken = await storage.getAccessToken();
      final refreshToken = await storage.getRefreshToken();
      if (accessToken != null) {
        // ApiClient is only available in remote mode; ignore in local mode
        final apiClient = context.read<ApiClient?>();
        apiClient?.setTokens(
          access: accessToken,
          refresh: refreshToken ?? '',
        );
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
    } else {
      // No saved session → show login
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logoTP.png', width: 72, height: 72),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
