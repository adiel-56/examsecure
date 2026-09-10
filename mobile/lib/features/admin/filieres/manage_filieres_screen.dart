import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../repositories/admin_repository.dart';
import '../../../widgets/app_row_card.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/loading_list.dart';

class ManageFilieresScreen extends StatefulWidget {
  const ManageFilieresScreen({super.key});

  @override
  State<ManageFilieresScreen> createState() => _ManageFilieresScreenState();
}

class _ManageFilieresScreenState extends State<ManageFilieresScreen> {
  final _repo = AdminRepository();
  List<dynamic> _filieres = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _filieres = await _repo.fetchFilieres();
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _delete(int id) async {
    await _repo.deleteFiliere(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Filières')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.navy,
        onPressed: () async {
          await context.push('/admin/filiere-form');
          _load();
        },
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _loading
              ? const LoadingList()
              : _filieres.isEmpty
                  ? const EmptyState(icon: Icons.school_outlined, title: 'Aucune filière',
                      subtitle: 'Créez votre première filière avec le bouton +.')
                  : ListView.builder(
                      itemCount: _filieres.length,
                      itemBuilder: (context, i) {
                        final f = _filieres[i];
                        return AppRowCard(
                          leading: const ThumbBox(icon: Icons.school_outlined),
                          title: f['nom'],
                          subtitle: '${f['matieres_count'] ?? 0} matière(s)',
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) async {
                              if (v == 'edit') {
                                await context.push('/admin/filiere-form', extra: f);
                                _load();
                              } else if (v == 'delete') {
                                _delete(f['id']);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Modifier')),
                              PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}
