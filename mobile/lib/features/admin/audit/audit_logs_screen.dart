import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../repositories/admin_repository.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/loading_list.dart';

/// Reproduit l'écran « Journal d'audit » : chaque ligne a une icône et
/// une couleur selon le type d'action (paiement = vert, déblocage =
/// bleu, modification = orange, suspension = rouge, connexion = gris).
class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final _repo = AdminRepository();
  List<dynamic> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _logs = await _repo.fetchAuditLogs();
    } catch (_) {}
    setState(() => _loading = false);
  }

  ({IconData icon, Color color}) _styleFor(String action) {
    if (action.contains('PAYMENT')) {
      return (icon: Icons.payments_outlined, color: AppColors.success);
    }
    if (action.contains('UNLOCK')) {
      return (icon: Icons.lock_open_outlined, color: AppColors.primary);
    }
    if (action.contains('DOWNLOAD') || action.contains('FILE')) {
      return (icon: Icons.download_outlined, color: AppColors.primary);
    }
    if (action.contains('DELETE') || action.contains('SUSPEND')) {
      return (icon: Icons.warning_amber_rounded, color: AppColors.danger);
    }
    if (action.contains('UPDATE') ||
        action.contains('CREATE') ||
        action.contains('EDIT')) {
      return (icon: Icons.edit_outlined, color: AppColors.warning);
    }
    if (action.contains('LOGIN') || action.contains('LOGOUT')) {
      return (icon: Icons.login, color: AppColors.muted);
    }
    return (icon: Icons.history, color: AppColors.muted);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Journal d\'audit', style: TextStyle(fontSize: 15)),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _loading
                ? const LoadingList()
                : _logs.isEmpty
                ? const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Aucune action journalisée',
                    subtitle: 'Les actions sensibles apparaîtront ici.',
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, i) {
                        final l = _logs[i];
                        final style = _styleFor(l['action'] ?? '');
                        return Container(
                          margin: const EdgeInsets.only(bottom: 9),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: style.color.withValues(alpha: .12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  style.icon,
                                  size: 16,
                                  color: style.color,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l['action'] ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${l['utilisateur_nom']} · ${Formatters.dateTime(DateTime.tryParse(l['created_at'] ?? '') ?? DateTime.now())}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.faint,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
