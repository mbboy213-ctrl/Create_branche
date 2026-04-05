import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/providers/settings_provider.dart';
import '../../domain/providers/websocket_provider.dart';
import '../../domain/providers/analytics_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlController;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _urlController = TextEditingController(text: settings.wsUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionHeader('Connection'),
              _WsUrlCard(
                controller: _urlController,
                editing: _editing,
                onEdit: () => setState(() => _editing = true),
                onSave: () async {
                  await settings.setWsUrl(_urlController.text.trim());
                  setState(() => _editing = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('WebSocket URL updated')),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              _SwitchTile(
                title: 'Auto-Connect on Start',
                subtitle: 'Automatically connect to WebSocket on app launch',
                value: settings.autoConnect,
                onChanged: settings.setAutoConnect,
              ),
              const SizedBox(height: 16),
              _SectionHeader('Appearance'),
              _ThemeSelector(settings: settings),
              const SizedBox(height: 16),
              _SectionHeader('Data Management'),
              _RetentionSelector(settings: settings),
              _SwitchTile(
                title: 'Push Notifications',
                subtitle: 'Receive alerts for anomalies and critical states',
                value: settings.notificationsEnabled,
                onChanged: settings.setNotificationsEnabled,
              ),
              const SizedBox(height: 16),
              _SectionHeader('Actions'),
              _DangerZone(),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _WsUrlCard extends StatelessWidget {
  final TextEditingController controller;
  final bool editing;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  const _WsUrlCard({
    required this.controller,
    required this.editing,
    required this.onEdit,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('WebSocket URL', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (editing)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        hintText: 'wss://your-server.com/ws',
                      ),
                      keyboardType: TextInputType.url,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: onSave, child: const Text('Save')),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Text(
                      controller.text,
                      style: const TextStyle(color: Colors.grey, fontFamily: 'monospace'),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.edit_rounded), onPressed: onEdit),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final Future<void> Function(bool) onChanged;
  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  final SettingsProvider settings;
  const _ThemeSelector({required this.settings});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Theme', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded), label: Text('Light')),
                ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded), label: Text('Dark')),
                ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.contrast_rounded), label: Text('System')),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (s) => settings.setThemeMode(s.first),
            ),
          ],
        ),
      ),
    );
  }
}

class _RetentionSelector extends StatelessWidget {
  final SettingsProvider settings;
  const _RetentionSelector({required this.settings});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Data Retention', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: settings.dataRetentionDays,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 30, child: Text('30 days')),
                DropdownMenuItem(value: 90, child: Text('90 days')),
                DropdownMenuItem(value: 180, child: Text('6 months')),
                DropdownMenuItem(value: 365, child: Text('1 year')),
                DropdownMenuItem(value: 730, child: Text('2 years')),
              ],
              onChanged: (v) => settings.setDataRetentionDays(v!),
            ),
          ],
        ),
      ),
    );
  }
}

class _DangerZone extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.statusCritical.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.statusCritical.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_rounded, color: AppColors.statusCritical, size: 18),
                SizedBox(width: 8),
                Text('Danger Zone', style: TextStyle(color: AppColors.statusCritical, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.statusCritical,
                  side: const BorderSide(color: AppColors.statusCritical),
                ),
                icon: const Icon(Icons.delete_forever_rounded),
                label: const Text('Clear All Historical Data'),
                onPressed: () => _confirmClear(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all historical sensor data and analytics. '
          'AI predictions will be reset. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusCritical),
            onPressed: () async {
              await context.read<AnalyticsProvider>().clearAllData();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data cleared')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
