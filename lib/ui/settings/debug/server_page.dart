import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/services/api/api_client.dart';
import '../../../data/services/global_config_provider.dart';
import '../settings_page.dart';

/// Server selection page.
///
/// Lets the user switch between local and remote backend at runtime.
class ServerPage extends StatelessWidget {
  const ServerPage({super.key});

  static const _servers = [
    ('本地 (模拟器)', 'http://10.0.2.2:8081'),
    ('Tailscale 远程', 'http://100.122.220.40:8081'),
    ('服务器', 'https://trans.annya.work'),
  ];

  void _selectServer(BuildContext context, String url) {
    // Update the source of truth
    context.read<GlobalConfigProvider>().setApiBaseUrl(url);
    // Update the active HTTP client for subsequent requests
    context.read<ApiClient>().setBaseUrl(url);

    // Switching server invalidates the current session — require re-login
    handleLogout(
      context,
      title: '切换服务器',
      message: '已切换服务器，需要重新登录',
      confirmLabel: '重新登录',
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUrl = context.watch<GlobalConfigProvider>().apiBaseUrl;

    return Scaffold(
      appBar: AppBar(title: const Text('服务器')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          for (final (name, url) in _servers)
            ListTile(
              leading: Icon(
                currentUrl == url
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: currentUrl == url
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: Text(name),
              subtitle: Text(url),
              onTap: () => _selectServer(context, url),
            ),
        ],
      ),
    );
  }
}
