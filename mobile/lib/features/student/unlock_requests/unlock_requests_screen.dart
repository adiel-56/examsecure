import 'package:flutter/material.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/unlock_request.dart';
import '../../../repositories/unlock_repository.dart';
import '../../../widgets/app_row_card.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/loading_list.dart';
import '../../../widgets/status_badge.dart';

class UnlockRequestsScreen extends StatefulWidget {
  const UnlockRequestsScreen({super.key});

  @override
  State<UnlockRequestsScreen> createState() => _UnlockRequestsScreenState();
}

class _UnlockRequestsScreenState extends State<UnlockRequestsScreen> {
  final _repo = UnlockRepository();
  List<UnlockRequest> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _requests = await _repo.fetchMyRequests();
    } catch (_) {}
    setState(() => _loading = false);
  }

  StatusBadge _badge(String statut) {
    switch (statut) {
      case 'APPROVED':
        return const StatusBadge(label: 'Approuvée', variant: BadgeVariant.green);
      case 'REJECTED':
        return const StatusBadge(label: 'Refusée', variant: BadgeVariant.red);
      default:
        return const StatusBadge(label: 'En attente', variant: BadgeVariant.amber);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes demandes de déblocage')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: _loading
              ? const LoadingList()
              : _requests.isEmpty
                  ? const EmptyState(
                      icon: Icons.lock_open,
                      title: 'Aucune demande',
                      subtitle: 'Vos demandes de déblocage apparaîtront ici.')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        itemCount: _requests.length,
                        itemBuilder: (context, i) {
                          final r = _requests[i];
                          return AppRowCard(
                            leading: const ThumbBox(icon: Icons.phonelink_lock_outlined),
                            title: r.documentTitre,
                            subtitle: Formatters.dateTime(r.createdAt),
                            trailing: _badge(r.statut),
                          );
                        },
                      ),
                    ),
        ),
      ),
    );
  }
}
