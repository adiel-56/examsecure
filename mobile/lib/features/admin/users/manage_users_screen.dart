import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../repositories/admin_repository.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/loading_list.dart';
import '../../../widgets/status_badge.dart';

/// Reproduit l'écran « Gestion des utilisateurs » : recherche, et pour
/// chaque étudiant un avatar à initiales, filière · nombre d'achats ·
/// date d'inscription, badge ACTIF/SUSPENDU, action de suspension.
class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final _repo = AdminRepository();
  List<dynamic> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({String? search}) async {
    setState(() => _loading = true);
    try {
      _users = await _repo.fetchUsers(search: search);
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _toggle(int id) async {
    await _repo.toggleUserActive(id);
    _load();
  }

  String _initials(String first, String last) {
    final a = first.isNotEmpty ? first[0] : '';
    final b = last.isNotEmpty ? last[0] : '';
    final r = (a + b).toUpperCase();
    return r.isEmpty ? '?' : r;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Utilisateurs', style: TextStyle(fontSize: 15))),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_users.length} étudiant(s) inscrit(s)', style: const TextStyle(color: AppColors.faint, fontSize: 11)),
                const SizedBox(height: 10),
                TextField(
                  onSubmitted: (v) => _load(search: v),
                  decoration: const InputDecoration(hintText: 'Rechercher un étudiant…', prefixIcon: Icon(Icons.search)),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _loading
                      ? const LoadingList()
                      : _users.isEmpty
                          ? const EmptyState(icon: Icons.people_outline, title: 'Aucun étudiant',
                              subtitle: 'La liste des étudiants inscrits apparaîtra ici.')
                          : RefreshIndicator(
                              onRefresh: () => _load(),
                              child: ListView.builder(
                                itemCount: _users.length,
                                itemBuilder: (context, i) {
                                  final u = _users[i];
                                  final suspended = u['is_suspended'] == true;
                                  final filiere = (u['filiere_nom'] ?? '').toString();
                                  final achats = u['achats_count'] ?? 0;
                                  final createdAt = DateTime.tryParse(u['created_at'] ?? '');
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
                                        CircleAvatar(
                                          radius: 21,
                                          backgroundColor: AppColors.primarySoft,
                                          child: Text(_initials(u['first_name'] ?? '', u['last_name'] ?? ''),
                                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 12)),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('${u['first_name']} ${u['last_name']}', maxLines: 1, overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                                              const SizedBox(height: 3),
                                              Text(
                                                [
                                                  if (filiere.isNotEmpty) filiere,
                                                  '$achats achat(s)',
                                                  if (createdAt != null) 'inscrit le ${Formatters.date(createdAt)}',
                                                ].join(' · '),
                                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 10, color: AppColors.faint),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            suspended
                                                ? const StatusBadge(label: 'Suspendu', variant: BadgeVariant.red)
                                                : const StatusBadge(label: 'Actif', variant: BadgeVariant.green),
                                            IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              icon: Icon(suspended ? Icons.lock_open : Icons.block, size: 16,
                                                  color: suspended ? AppColors.success : AppColors.danger),
                                              onPressed: () => _toggle(u['id']),
                                            ),
                                          ],
                                        ),
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
