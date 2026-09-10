import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../repositories/admin_repository.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/loading_list.dart';
import '../../../widgets/status_badge.dart';

/// Reproduit l'écran « Gestion des épreuves (PDF privés) » : recherche,
/// chips de filtre par statut, puis pour chaque épreuve une carte avec
/// couverture dégradée, badge de statut, nombre de téléchargements, et
/// actions Modifier / Archiver / Supprimer.
class ManageExamsScreen extends StatefulWidget {
  const ManageExamsScreen({super.key});

  @override
  State<ManageExamsScreen> createState() => _ManageExamsScreenState();
}

class _ManageExamsScreenState extends State<ManageExamsScreen> {
  final _repo = AdminRepository();
  List<dynamic> _exams = [];
  bool _loading = true;
  String? _statutFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _exams = await _repo.fetchExams(statut: _statutFilter);
    } catch (_) {}
    setState(() => _loading = false);
  }

  StatusBadge _badge(String statut) {
    switch (statut) {
      case 'PUBLISHED':
        return const StatusBadge(label: 'Publié', variant: BadgeVariant.green);
      case 'ARCHIVED':
        return const StatusBadge(label: 'Archivé', variant: BadgeVariant.gray);
      default:
        return const StatusBadge(label: 'Brouillon', variant: BadgeVariant.amber);
    }
  }

  Future<void> _delete(int id) async {
    await _repo.deleteExam(id);
    _load();
  }

  Future<void> _archive(Map exam) async {
    await _repo.updateExam(exam['id'], {'statut': 'ARCHIVED'});
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Documents', style: TextStyle(fontSize: 15)),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.navy,
          onPressed: () async {
            await context.push('/admin/exam-form');
            _load();
          },
          child: const Icon(Icons.add),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  onChanged: (v) {}, // recherche côté serveur branchable via AdminRepository._list(search: v)
                  decoration: const InputDecoration(hintText: 'Rechercher un document…', prefixIcon: Icon(Icons.search)),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _Chip(label: 'Tous', selected: _statutFilter == null, onTap: () { setState(() => _statutFilter = null); _load(); }),
                      _Chip(label: 'Publiés', selected: _statutFilter == 'PUBLISHED', onTap: () { setState(() => _statutFilter = 'PUBLISHED'); _load(); }),
                      _Chip(label: 'Brouillons', selected: _statutFilter == 'DRAFT', onTap: () { setState(() => _statutFilter = 'DRAFT'); _load(); }),
                      _Chip(label: 'Archivés', selected: _statutFilter == 'ARCHIVED', onTap: () { setState(() => _statutFilter = 'ARCHIVED'); _load(); }),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _loading
                      ? const LoadingList()
                      : _exams.isEmpty
                          ? const EmptyState(icon: Icons.description_outlined, title: 'Aucun document',
                              subtitle: 'Ajoutez votre premier document avec le bouton +.')
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.builder(
                                itemCount: _exams.length,
                                itemBuilder: (context, i) {
                                  final e = _exams[i];
                                  final String? rawCover = e['couverture_url'] ?? e['couverture'];
                                  final String? coverUrl = () {
                                    if (rawCover == null || rawCover.trim().isEmpty) return null;
                                    final url = rawCover.trim();
                                    if (url.startsWith('http://') || url.startsWith('https://')) return url;
                                    const base = ApiConstants.baseUrl;
                                    final origin = base.endsWith('/api')
                                        ? base.substring(0, base.length - 4)
                                        : (base.endsWith('/api/') ? base.substring(0, base.length - 5) : base);
                                    return '$origin${url.startsWith('/') ? '' : '/'}$url';
                                  }();

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
                                          width: 44, height: 44,
                                          clipBehavior: Clip.antiAlias,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF7048E8)]),
                                            borderRadius: BorderRadius.circular(11),
                                          ),
                                          child: coverUrl != null
                                              ? Image.network(
                                                  coverUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => const Icon(
                                                    Icons.picture_as_pdf_outlined,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                )
                                              : const Icon(Icons.picture_as_pdf_outlined, color: Colors.white, size: 18),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(e['titre'], maxLines: 1, overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                              const SizedBox(height: 2),
                                              Builder(
                                                builder: (_) {
                                                  final rawNoms = e['matieres_noms'];
                                                  final String matieresStr = (rawNoms is List && rawNoms.isNotEmpty)
                                                      ? rawNoms.join(' · ')
                                                      : (e['matiere_nom'] ?? '');
                                                  if (matieresStr.isEmpty) return const SizedBox.shrink();
                                                  return Padding(
                                                    padding: const EdgeInsets.only(bottom: 2),
                                                    child: Text(
                                                      matieresStr,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        color: AppColors.primary,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                              Text(
                                                '${Formatters.currency(double.tryParse('${e['prix']}') ?? 0)} · '
                                                '${e['achats_count'] ?? 0} téléchargement(s)',
                                                style: const TextStyle(fontSize: 10, color: AppColors.faint),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            _badge(e['statut']),
                                            PopupMenuButton<String>(
                                              padding: EdgeInsets.zero,
                                              icon: const Icon(Icons.more_horiz, size: 18, color: AppColors.faint),
                                              onSelected: (v) async {
                                                if (v == 'edit') {
                                                  await context.push('/admin/exam-form', extra: e);
                                                  _load();
                                                } else if (v == 'archive') {
                                                  _archive(e);
                                                } else if (v == 'delete') {
                                                  _delete(e['id']);
                                                }
                                              },
                                              itemBuilder: (_) => const [
                                                PopupMenuItem(value: 'edit', child: Text('Modifier')),
                                                PopupMenuItem(value: 'archive', child: Text('Archiver')),
                                                PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                                              ],
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

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.navy,
        labelStyle: TextStyle(color: selected ? Colors.white : AppColors.muted),
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}
