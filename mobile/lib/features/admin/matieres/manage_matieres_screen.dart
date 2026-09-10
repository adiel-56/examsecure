import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../repositories/admin_repository.dart';
import '../../../widgets/app_row_card.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/loading_list.dart';

class ManageMatieresScreen extends StatefulWidget {
  const ManageMatieresScreen({super.key});

  @override
  State<ManageMatieresScreen> createState() => _ManageMatieresScreenState();
}

class _ManageMatieresScreenState extends State<ManageMatieresScreen> {
  final _repo = AdminRepository();
  List<dynamic> _matieres = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _matieres = await _repo.fetchMatieres();
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _delete(int id) async {
    await _repo.deleteMatiere(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matières')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.navy,
        onPressed: () async {
          await context.push('/admin/matiere-form');
          _load();
        },
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _loading
              ? const LoadingList()
              : _matieres.isEmpty
                  ? const EmptyState(icon: Icons.menu_book_outlined, title: 'Aucune matière',
                      subtitle: 'Créez votre première matière avec le bouton +.')
                  : ListView.builder(
                      itemCount: _matieres.length,
                      itemBuilder: (context, i) {
                        final m = _matieres[i];
                        return AppRowCard(
                          leading: const ThumbBox(icon: Icons.menu_book_outlined),
                          title: m['nom'],
                          subtitle: m['filiere_nom'],
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) async {
                              if (v == 'edit') {
                                await context.push('/admin/matiere-form', extra: m);
                                _load();
                              } else if (v == 'delete') {
                                _delete(m['id']);
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
