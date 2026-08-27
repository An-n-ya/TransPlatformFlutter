import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/env.dart';
import '../../../data/services/api/api_client.dart';
import '../../../data/services/global_config_provider.dart';
import '../settings_page.dart';

/// Server selection page.
///
/// Lets the user switch between a local (custom) and the production backend
/// at runtime. Only shown in dev mode — the production build renders a
/// placeholder instead.
class ServerPage extends StatefulWidget {
  const ServerPage({super.key});

  @override
  State<ServerPage> createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage> {
  /// 本地地址默认值，可在输入框中自行修改。
  static const _defaultLocalUrl = 'http://localhost:8081';

  /// 生产服务器地址（固定，不可修改）。
  static const _serverUrl = 'https://yx.annya.work';

  late final TextEditingController _localUrlController;

  @override
  void initState() {
    super.initState();
    final current = context.read<GlobalConfigProvider>().apiBaseUrl;
    // 若当前已是本地地址，回填到输入框方便查看/修改；否则用默认值。
    final isCurrentLocal = current.isNotEmpty && current != _serverUrl;
    _localUrlController = TextEditingController(
      text: isCurrentLocal ? current : _defaultLocalUrl,
    );
  }

  @override
  void dispose() {
    _localUrlController.dispose();
    super.dispose();
  }

  void _selectServer(BuildContext context, String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的服务器地址')),
      );
      return;
    }

    // Update the source of truth
    context.read<GlobalConfigProvider>().setApiBaseUrl(trimmed);
    // Update the active HTTP client for subsequent requests
    context.read<ApiClient>().setBaseUrl(trimmed);

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
    // 只在 dev flavor 显示服务器选择页，生产环境直接屏蔽。
    if (isProduction) {
      return Scaffold(
        appBar: AppBar(title: const Text('服务器')),
        body: const Center(child: Text('仅开发模式可用')),
      );
    }

    final currentUrl = context.watch<GlobalConfigProvider>().apiBaseUrl;

    return Scaffold(
      appBar: AppBar(title: const Text('服务器')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // ── 本地（地址可编辑）──
          ListTile(
            leading: Icon(
              currentUrl != _serverUrl
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: currentUrl != _serverUrl
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            title: const Text('本地'),
            subtitle: TextField(
              controller: _localUrlController,
              decoration: const InputDecoration(
                hintText: _defaultLocalUrl,
                isDense: true,
                border: InputBorder.none,
              ),
              keyboardType: TextInputType.url,
              onSubmitted: (_) =>
                  _selectServer(context, _localUrlController.text),
            ),
            onTap: () => _selectServer(context, _localUrlController.text),
          ),

          const Divider(height: 1),

          // ── 服务器（固定）──
          ListTile(
            leading: Icon(
              currentUrl == _serverUrl
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: currentUrl == _serverUrl
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            title: const Text('服务器'),
            subtitle: const Text(_serverUrl),
            onTap: () => _selectServer(context, _serverUrl),
          ),
        ],
      ),
    );
  }
}
