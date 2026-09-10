import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../models/device.dart';
import '../../../repositories/device_repository.dart';
import '../../../widgets/app_row_card.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/loading_list.dart';
import '../../../widgets/status_badge.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final _repo = DeviceRepository();
  List<AppDevice> _devices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _devices = await _repo.fetchMyDevices();
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes appareils')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _loading
              ? const LoadingList()
              : _devices.isEmpty
              ? const EmptyState(
                  icon: Icons.phone_iphone,
                  title: 'Aucun appareil',
                  subtitle:
                      'Votre appareil sera enregistré à la première connexion.',
                )
              : ListView.builder(
                  itemCount: _devices.length,
                  itemBuilder: (context, i) {
                    final d = _devices[i];
                    return AppRowCard(
                      leading: ThumbBox(
                        icon: d.platform == 'IOS'
                            ? Icons.phone_iphone
                            : Icons.android,
                      ),
                      title: d.deviceName.isEmpty
                          ? d.deviceIdentifier
                          : d.deviceName,
                      subtitle: 'Vu ${Formatters.dateTime(d.lastSeen)}',
                      trailing: d.isActive
                          ? const StatusBadge(
                              label: 'Actif',
                              variant: BadgeVariant.green,
                            )
                          : const StatusBadge(
                              label: 'Inactif',
                              variant: BadgeVariant.gray,
                            ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
