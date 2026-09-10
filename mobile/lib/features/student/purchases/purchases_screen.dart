import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/purchase.dart';
import '../../../providers/purchase_provider.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/loading_list.dart';
import '../../../widgets/status_badge.dart';

/// Reproduit l'écran « Mes achats » de la maquette : chips de filtre
/// (Tous / Téléchargés / À télécharger), et pour chaque achat une carte
/// avec badge d'état + les actions pertinentes pour cet état exact
/// (Consulter, Télécharger (chiffré), ou Demander un déblocage).
class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

enum _Filter { all, downloaded, toDownload }

class _PurchasesScreenState extends State<PurchasesScreen> {
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<PurchaseProvider>().loadPurchases(),
    );
  }

  List<Purchase> _apply(List<Purchase> all) {
    switch (_filter) {
      case _Filter.downloaded:
        return all
            .where((p) => p.nombreTelechargements > 0 && p.statut == 'VALID')
            .toList();
      case _Filter.toDownload:
        return all
            .where((p) => p.statut == 'VALID' && p.nombreTelechargements == 0)
            .toList();
      case _Filter.all:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PurchaseProvider>();
    final downloaded = provider.purchases
        .where((p) => p.nombreTelechargements > 0 && p.statut == 'VALID')
        .length;
    final toDownload = provider.purchases
        .where((p) => p.statut == 'VALID' && p.nombreTelechargements == 0)
        .length;
    final visible = _apply(provider.purchases);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Mes achats',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Text(
                  '${provider.purchases.length} documents',
                  style: const TextStyle(color: AppColors.faint, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(
                    label: 'Tous',
                    selected: _filter == _Filter.all,
                    onTap: () => setState(() => _filter = _Filter.all),
                  ),
                  _FilterChip(
                    label: 'Téléchargés ($downloaded)',
                    selected: _filter == _Filter.downloaded,
                    onTap: () => setState(() => _filter = _Filter.downloaded),
                  ),
                  _FilterChip(
                    label: 'À télécharger ($toDownload)',
                    selected: _filter == _Filter.toDownload,
                    onTap: () => setState(() => _filter = _Filter.toDownload),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: provider.isLoading
                  ? const LoadingList()
                  : provider.errorMessage != null
                  ? _PurchaseError(
                      message: provider.errorMessage!,
                      onRetry: provider.loadPurchases,
                    )
                  : visible.isEmpty
                  ? const EmptyState(
                      icon: Icons.folder_open,
                      title: 'Aucun achat pour le moment',
                      subtitle:
                          'Les documents que vous achetez apparaîtront ici.',
                    )
                  : ListView.builder(
                      itemCount: visible.length,
                      itemBuilder: (context, i) =>
                          _PurchaseCard(purchase: visible[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _PurchaseError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.dangerSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF5B8B8)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: AppColors.danger,
              size: 32,
            ),
            const SizedBox(height: 10),
            const Text(
              'Impossible de charger vos achats',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseCard extends StatelessWidget {
  final Purchase purchase;
  const _PurchaseCard({required this.purchase});

  @override
  Widget build(BuildContext context) {
    final consultable =
        purchase.statut == 'VALID' && purchase.nombreTelechargements > 0;
    final aTelecharger =
        purchase.statut == 'VALID' && purchase.nombreTelechargements == 0;
    final deblocageRequis = purchase.statut == 'BLOCKED';

    late final StatusBadge badge;
    if (consultable) {
      badge = const StatusBadge(
        label: 'Sur cet appareil',
        variant: BadgeVariant.green,
      );
    } else if (aTelecharger) {
      badge = const StatusBadge(
        label: 'Disponible',
        variant: BadgeVariant.blue,
      );
    } else if (deblocageRequis) {
      badge = const StatusBadge(
        label: 'Déblocage requis',
        variant: BadgeVariant.amber,
      );
    } else {
      badge = const StatusBadge(label: 'Révoqué', variant: BadgeVariant.red);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0CA678), Color(0xFF20C997)],
                  ),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: purchase.fullCouvertureUrl != null &&
                        purchase.fullCouvertureUrl!.isNotEmpty
                    ? Image.network(
                        purchase.fullCouvertureUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.picture_as_pdf_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      )
                    : const Icon(
                        Icons.picture_as_pdf_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      purchase.documentTitre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Acheté le ${Formatters.date(purchase.createdAt)} · ${Formatters.currency(purchase.documentPrix)}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.faint,
                      ),
                    ),
                  ],
                ),
              ),
              badge,
            ],
          ),
          const SizedBox(height: 10),
          if (consultable)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        context.push('/student/reader', extra: purchase),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text(
                      'Consulter',
                      style: TextStyle(fontSize: 11.5),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 14),
                  label: const Text(
                    'Détails',
                    style: TextStyle(fontSize: 11.5),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            )
          else if (aTelecharger)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    context.push('/student/reader', extra: purchase),
                icon: const Icon(Icons.download_outlined, size: 16),
                label: const Text(
                  'Télécharger (chiffré)',
                  style: TextStyle(fontSize: 11.5),
                ),
              ),
            )
          else if (deblocageRequis)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    context.push('/student/unlock-request', extra: purchase),
                icon: const Icon(Icons.send_outlined, size: 14),
                label: const Text(
                  'Demander un déblocage',
                  style: TextStyle(fontSize: 11.5),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warning,
                  side: const BorderSide(color: Color(0xFFFFD8A8), width: 1.5),
                  backgroundColor: AppColors.warningSoft,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: ChoiceChip(
        label: Text(
          label,
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
        ),
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
