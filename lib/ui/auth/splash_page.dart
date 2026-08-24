import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/user/user_repository.dart';
import '../../data/services/api/api_client.dart';
import '../../data/services/current_user_provider.dart';
import '../../data/services/token_storage_service.dart';
import '../../domain/models/user.dart';
import '../../utils/result.dart';
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
    // Capture all context dependencies up-front so no `context.read` is used
    // across async gaps (the widget may be disposed mid-flight).
    final storage = context.read<TokenStorageService>();
    final userRepository = context.read<UserRepository>();
    final currentUser = context.read<CurrentUserProvider>();
    final apiClient = context.read<ApiClient?>();
    final navigator = Navigator.of(context);

    final hasToken = await storage.hasTokens();

    if (!mounted) return;

    if (hasToken) {
      // Restore session: read tokens and set on ApiClient (if available)
      final accessToken = await storage.getAccessToken();
      final refreshToken = await storage.getRefreshToken();
      if (accessToken != null) {
        apiClient?.setTokens(
          access: accessToken,
          refresh: refreshToken ?? '',
        );

        // Validate the saved token by fetching the current user's profile.
        // On success, restore CurrentUserProvider so the app works as if the
        // user had just logged in. On failure the token is stale/expired, so
        // clear the session and fall back to the login page.
        final result = await userRepository.getCurrentUser();
        if (!mounted) return;

        switch (result) {
          case Ok<User>(:final value):
            currentUser.setCurrentUser(value);
            navigator.pushReplacement(
              MaterialPageRoute(builder: (_) => const AppShell()),
            );
          case Error<User>(): // invalid/expired token
            await storage.clearTokens();
            apiClient?.clearTokens();
            currentUser.clear();
            if (!mounted) return;
            navigator.pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
        }
      } else {
        // Token missing from secure storage (shouldn't happen) → show login
        if (!mounted) return;
        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } else {
      // No saved session → show login
      if (!mounted) return;
      navigator.pushReplacement(
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
            Image.asset('assets/images/logoTP_Transparent.png', width: 72, height: 72),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
