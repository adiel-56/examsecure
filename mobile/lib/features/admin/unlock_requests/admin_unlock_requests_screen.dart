import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../repositories/admin_repository.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/loading_list.dart';
import '../../../widgets/status_badge.dart';

/// Reproduit l'écran « Traitement des déblocages » : chaque demande en
/// attente est présentée sous forme de carte détaillée (épreuve, motif,
/// appareil) avec les boutons Refuser / Approuver directement accessibles
/// — sans passer par une boîte de dialogue intermédiaire.
class AdminUnlockRequestsScreen extends StatefulWidget {
  const AdminUnlockRequestsScreen({super.key});

  @override
  State<AdminUnlockRequestsScreen> createState() => _AdminUnlockRequestsScreenState();
}

class _AdminUnlockRequestsScreenState extends State<AdminUnlockRequestsScreen> {
  final _repo = AdminRepository();
  List<dynamic> _requests = [];
  bool _loading = true;
  final Map<int, TextEditingController> _responseCtrls = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _requests = await _repo.fetchUnlockRequests();
    } catch (_) {}
    setState(() => _loading = false);
  }

  TextEditingController _ctrlFor(int id) => _responseCtrls.putIfAbsent(id, () => TextEditingController());

  Future<void> _resolve(int id, String statut) async {
    await _repo.resolveUnlockRequest(id, statut: statut, reponseAdmin: _ctrlFor(id).text.trim());
    _load();
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
    final pendingCount = _requests.where((r) => r['statut'] == 'PENDING').length;

    return Container(
      color: AppColors.bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Demandes de déblocage', style: TextStyle(fontSize: 14))),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$pendingCount en attente sur ${_requests.length} demande(s)',
                    style: const TextStyle(color: AppColors.faint, fontSize: 11)),
                const SizedBox(height: 10),
                Expanded(
                  child: _loading
                      ? const LoadingList()
                      : _requests.isEmpty
                          ? const EmptyState(icon: Icons.lock_open, title: 'Aucune demande',
                              subtitle: 'Les demandes de déblocage des étudiants apparaîtront ici.')
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.builder(
                                itemCount: _requests.length,
                                itemBuilder: (context, i) {
                                  final r = _requests[i];
                                  final pending = r['statut'] == 'PENDING';
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: pending ? const Color(0xFFFFD8A8) : AppColors.border, width: pending ? 1.5 : 1),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(child: Text(r['document_titre'] ?? r['epreuve_titre'] ?? '',
                                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5))),
                                            _badge(r['statut']),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(Formatters.dateTime(DateTime.tryParse(r['created_at'] ?? '') ?? DateTime.now()),
                                            style: const TextStyle(color: AppColors.faint, fontSize: 9.5)),
                                        const SizedBox(height: 8),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(9),
                                          decoration: BoxDecoration(
                                            color: AppColors.bg,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('MOTIF', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: AppColors.faint, letterSpacing: .4)),
                                              const SizedBox(height: 3),
                                              Text(r['motif'] ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF33415E))),
                                            ],
                                          ),
                                        ),
                                        if (pending) ...[
                                          const SizedBox(height: 9),
                                          TextField(
                                            controller: _ctrlFor(r['id']),
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              hintText: 'Réponse (optionnelle)',
                                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                            ),
                                          ),
                                          const SizedBox(height: 9),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton(
                                                  onPressed: () => _resolve(r['id'], 'REJECTED'),
                                                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger,
                                                      side: const BorderSide(color: AppColors.dangerSoft, width: 1.5)),
                                                  child: const Text('Refuser', style: TextStyle(fontSize: 11.5)),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () => _resolve(r['id'], 'APPROVED'),
                                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                                                  child: const Text('Approuver', style: TextStyle(fontSize: 11.5)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ] else if ((r['reponse_admin'] ?? '').toString().isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text('Réponse : ${r['reponse_admin']}',
                                              style: const TextStyle(fontSize: 10.5, color: AppColors.faint, fontStyle: FontStyle.italic)),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
