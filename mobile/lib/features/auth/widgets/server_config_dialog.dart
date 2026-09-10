import 'package:flutter/material.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_theme.dart';

class ServerConfigDialog extends StatefulWidget {
  const ServerConfigDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const ServerConfigDialog(),
    );
  }

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late final TextEditingController _urlCtrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController();
    _loadUrl();
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUrl() async {
    final custom = await SecureStorage.instance.baseUrl;
    if (mounted) {
      setState(() {
        _urlCtrl.text = custom ?? ApiConstants.baseUrl;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final newUrl = _urlCtrl.text.trim();
    if (newUrl.isEmpty) return;

    await SecureStorage.instance.saveBaseUrl(newUrl);
    ApiClient.instance.updateBaseUrl(newUrl);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Adresse serveur mise à jour : $newUrl'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _reset() async {
    await SecureStorage.instance.clearBaseUrl();
    ApiClient.instance.updateBaseUrl(ApiConstants.baseUrl);
    setState(() {
      _urlCtrl.text = ApiConstants.baseUrl;
    });

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adresse serveur réinitialisée par défaut.'),
          backgroundColor: AppColors.navy,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.dns_outlined, color: AppColors.primary, size: 22),
          SizedBox(width: 8),
          Text(
            'Configuration Serveur',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ],
      ),
      content: _loading
          ? const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Adresse URL de l\'API backend :',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _urlCtrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    hintText: 'http://192.168.1.XX:8000/api',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Conseils de connexion :\n'
                  '• Câble USB (ADB) : http://127.0.0.1:8000/api\n'
                  '• Même réseau Wi-Fi : http://192.168.100.154:8000/api\n'
                  '• Émulateur Android : http://10.0.2.2:8000/api',
                  style: TextStyle(fontSize: 10.5, color: AppColors.faint, height: 1.4),
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: _reset,
          child: const Text('Par défaut'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
