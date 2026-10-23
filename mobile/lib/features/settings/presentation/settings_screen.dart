import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _language = 'en';

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('PREFERENCES', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Language'),
                  trailing: DropdownButton<String>(
                    value: _language,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'hi', child: Text('हिंदी (Hindi)')),
                      DropdownMenuItem(value: 'mr', child: Text('मराठी (Marathi)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _language = val);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text('SYSTEM & BACKEND', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.dns_outlined),
                  title: const Text('API Base URL'),
                  subtitle: Text(config.apiBaseUrl, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_queue),
                  title: const Text('Supabase Project'),
                  subtitle: Text(config.supabaseUrl, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('App Version'),
                  subtitle: const Text('${AppConstants.appName} v${AppConstants.appVersion}'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
