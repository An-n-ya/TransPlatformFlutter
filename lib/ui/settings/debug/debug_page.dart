import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/services/global_config_provider.dart';
import 'server_page.dart';

/// Debug page — toggle debug mode and switch backend server.
class DebugPage extends StatelessWidget {
  const DebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('调试')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        children: [
          Consumer<GlobalConfigProvider>(
            builder: (context, config, _) => SwitchListTile(
              value: config.debugMode,
              onChanged: (value) => config.setDebugMode(value),
              title: const Text('调试模式'),
              subtitle: const Text('开启调试模式可以显示更多调试信息'),
            ),
          ),

          const Divider(height: 1),

          // ── Server selection ──
          Consumer<GlobalConfigProvider>(
            builder: (context, config, _) => ListTile(
              leading: const Icon(Icons.dns_outlined),
              title: const Text('服务器'),
              subtitle: Text(config.apiBaseUrl),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ServerPage()),
              ),
            ),
          ),

          const Divider(height: 1),
        ],
      ),
    );
  }
}
