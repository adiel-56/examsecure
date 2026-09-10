import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/catalogue_provider.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/loading_list.dart';
import '../../../widgets/status_badge.dart';

/// Reproduit l'écran « Catalogue — recherche & filtres » : en-tête avec
/// compteur de résultats, bouton filtre plein (bleu), chips de filtre, et
/// pour chaque ligne le prix + un badge contextuel (ACHETÉ / NOUVEAU / PDF)
/// empilés à droite avec affichage de la photo de couverture si présente.
class CatalogueScreen extends StatefulWidget {
  const CatalogueScreen({super.key});

  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<CatalogueProvider>();
      p.loadFilieres();
      p.loadExams();
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalogue = context.watch<CatalogueProvider>();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Catalogue', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      Text('${catalogue.exams.length} documents publiés',
                          style: const TextStyle(fontSize: 10.5, color: AppColors.faint, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.tune, color: Colors.white, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: catalogue.setSearch,
              decoration: const InputDecoration(
                hintText: 'Rechercher un document, une matière…',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(label: 'Tous', selected: catalogue.selectedFiliereId == null,
                      onTap: () => catalogue.setFiliereFilter(null)),
                  ...catalogue.filieres.map((f) => _FilterChip(
                        label: f.nom,
                        selected: catalogue.selectedFiliereId == f.id,
                        onTap: () => catalogue.setFiliereFilter(f.id),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: catalogue.isLoading
                  ? const LoadingList(itemCount: 8)
                  : catalogue.exams.isEmpty
                      ? const EmptyState(
                          icon: Icons.search_off,
                          title: 'Aucun document trouvé',
                          subtitle: 'Essayez une autre recherche ou filière.')
                      : ListView.builder(
                          itemCount: catalogue.exams.length,
                          itemBuilder: (context, i) {
                            final exam = catalogue.exams[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 9),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: InkWell(
                                onTap: () => context.push('/student/exam/${exam.id}'),
                                child: Row(
                                  children: [
                                    exam.fullCouvertureUrl != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(11),
                                            child: Image.network(
                                              exam.fullCouvertureUrl!,
                                              width: 46,
                                              height: 46,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                width: 46,
                                                height: 46,
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF7048E8)]),
                                                  borderRadius: BorderRadius.circular(11),
                                                ),
                                                child: const Icon(Icons.description_outlined, color: Colors.white, size: 20),
                                              ),
                                            ),
                                          )
                                        : Container(
                                            width: 46,
                                            height: 46,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF7048E8)]),
                                              borderRadius: BorderRadius.circular(11),
                                            ),
                                            child: const Icon(Icons.description_outlined, color: Colors.white, size: 20),
                                          ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(exam.titre, maxLines: 1, overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                                          if (exam.matieresDisplay.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(exam.matieresDisplay, maxLines: 1, overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 10.5, color: AppColors.primary, fontWeight: FontWeight.w600)),
                                          ],
                                          const SizedBox(height: 2),
                                          Text('${exam.typeContenu} · ${exam.nombrePages} pages · ${exam.anneeAcademique}',
                                              maxLines: 1, overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 10.5, color: AppColors.faint)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(Formatters.currency(exam.prix, devise: exam.devise),
                                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                                        const SizedBox(height: 4),
                                        const StatusBadge(label: 'PDF', variant: BadgeVariant.gray),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(color: selected ? Colors.white : AppColors.muted),
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}
