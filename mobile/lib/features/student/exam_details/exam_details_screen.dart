import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/exam.dart';
import '../../../models/purchase.dart';
import '../../../providers/purchase_provider.dart';
import '../../../repositories/catalogue_repository.dart';
import '../../../repositories/payment_repository.dart';
import '../../../widgets/loading_list.dart';

const _coverGradients = {
  'g1': LinearGradient(colors: [Color(0xFF3B5BDB), Color(0xFF7048E8)]),
  'g2': LinearGradient(colors: [Color(0xFF0CA678), Color(0xFF20C997)]),
  'g3': LinearGradient(colors: [Color(0xFFE8590C), Color(0xFFF59F00)]),
  'g4': LinearGradient(colors: [Color(0xFF0B7285), Color(0xFF15AABF)]),
};

class ExamDetailsScreen extends StatefulWidget {
  final int examId;
  const ExamDetailsScreen({super.key, required this.examId});

  @override
  State<ExamDetailsScreen> createState() => _ExamDetailsScreenState();
}

class _ExamDetailsScreenState extends State<ExamDetailsScreen> {
  final _catalogueRepo = CatalogueRepository();
  final _paymentRepo = PaymentRepository();

  Exam? _exam;
  Map<String, dynamic>? _paymentStatus;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final exam = await _catalogueRepo.fetchExamDetail(widget.examId);
      final paymentStatus = await _paymentRepo.fetchPaymentStatus(widget.examId);

      if (mounted) {
        setState(() {
          _exam = exam;
          _paymentStatus = paymentStatus;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final purchaseProvider = context.watch<PurchaseProvider>();
    Purchase? existingPurchase;
    for (final p in purchaseProvider.purchases) {
      if (p.epreuveId == widget.examId) {
        existingPurchase = p;
        break;
      }
    }

    final isPaid = existingPurchase != null || _paymentStatus?['statut'] == 'PAID';
    final isPending = _paymentStatus?['statut'] == 'PENDING_VERIFICATION' ||
        _paymentStatus?['statut'] == 'PAYMENT_SUBMITTED';
    final isRejected = _paymentStatus?['statut'] == 'REJECTED';
    final motifRefus = _paymentStatus?['motif_refus'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Détails du document',
          style: TextStyle(fontSize: 15),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Padding(padding: EdgeInsets.all(16), child: LoadingList())
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 160,
                            width: double.infinity,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              gradient: _coverGradients['g1'],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (_exam?.fullCouvertureUrl != null && _exam!.fullCouvertureUrl!.isNotEmpty)
                                  Image.network(
                                    _exam!.fullCouvertureUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(
                                        Icons.description_outlined,
                                        color: Colors.white,
                                        size: 44,
                                      ),
                                    ),
                                  )
                                else
                                  const Center(
                                    child: Icon(
                                      Icons.description_outlined,
                                      color: Colors.white,
                                      size: 44,
                                    ),
                                  ),
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: .45,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.lock_outlined,
                                          size: 11,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'SÉCURISÉ',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _exam!.titre,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _Chip(label: _exam!.filiereNom, selected: true),
                              if (_exam!.matieresNoms.isNotEmpty)
                                ..._exam!.matieresNoms.map((nom) => _Chip(label: nom))
                              else if (_exam!.matiereNom.isNotEmpty)
                                _Chip(label: _exam!.matiereNom),
                              _Chip(label: '${_exam!.nombrePages} pages'),
                              _Chip(label: _exam!.typeContenu),
                            ],
                          ),
                          const SizedBox(height: 14),

                          if (isRejected) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.dangerSoft,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.danger.withValues(alpha: .3)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Paiement refusé par l\'administration',
                                          style: TextStyle(
                                            color: AppColors.danger,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          motifRefus.isNotEmpty ? 'Motif : $motifRefus' : 'Reçu invalide ou non reconnu.',
                                          style: const TextStyle(color: Color(0xFF7F1D1D), fontSize: 11.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _exam!.description.isNotEmpty
                                ? _exam!.description
                                : 'Document officiel certifié par l\'université.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Garanties de sécurité',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 8),
                                _InclRow(
                                  icon: Icons.shield_outlined,
                                  label: 'Chiffrement AES local',
                                ),
                                _InclRow(
                                  icon: Icons.phonelink_lock_outlined,
                                  label: 'Liaison appareil unique',
                                ),
                                _InclRow(
                                  icon: Icons.person_outline,
                                  label: 'Filigrane personnel intégré',
                                  isLast: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Formatters.currency(
                                    _exam!.prix,
                                    devise: _exam!.devise,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  isPaid
                                      ? 'Achat validé · Accès complet'
                                      : isPending
                                          ? 'Paiement soumis · En cours de vérification'
                                          : 'Paiement manuel Mobile Money',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: isPaid
                                        ? AppColors.success
                                        : isPending
                                            ? const Color(0xFFD97706)
                                            : AppColors.faint,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            StatusPill(
                              label: isPaid
                                  ? 'DÉBLOQUÉ'
                                  : isPending
                                      ? 'EN ATTENTE'
                                      : 'PRIX FINAL',
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        if (isPaid) ...[
                          ElevatedButton.icon(
                            onPressed: () {
                              final int achatId = existingPurchase?.id ??
                                  (_paymentStatus?['achat_id'] is int
                                      ? _paymentStatus!['achat_id'] as int
                                      : int.tryParse('${_paymentStatus?['achat_id']}') ?? 0);
                              final p = existingPurchase ??
                                  Purchase(
                                    id: achatId,
                                    documentId: widget.examId,
                                    documentTitre: _exam!.titre,
                                    documentPrix: _exam!.prix,
                                    statut: 'VALID',
                                    nombreTelechargements: 0,
                                    createdAt: DateTime.now(),
                                  );
                              context.push('/student/reader', extra: p);
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                            icon: const Icon(Icons.lock_open_rounded, size: 18),
                            label: const Text('Accéder au document'),
                          ),
                        ] else if (isPending) ...[
                          ElevatedButton.icon(
                            onPressed: () async {
                              await context.push('/student/payment', extra: _exam);
                              _load();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              foregroundColor: Colors.black,
                            ),
                            icon: const Icon(Icons.hourglass_top_rounded, size: 18),
                            label: const Text('Paiement en attente de vérification'),
                          ),
                        ] else if (isRejected) ...[
                          ElevatedButton.icon(
                            onPressed: () async {
                              await context.push('/student/payment', extra: _exam);
                              _load();
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                            icon: const Icon(Icons.replay_rounded, size: 18),
                            label: const Text('Soumettre un nouveau reçu'),
                          ),
                        ] else ...[
                          ElevatedButton.icon(
                            onPressed: () async {
                              await context.push('/student/payment', extra: _exam);
                              _load();
                            },
                            icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 18),
                            label: const Text('Acheter le document'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class StatusPill extends StatelessWidget {
  final String label;
  const StatusPill({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  const _Chip({required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : AppColors.muted,
        ),
      ),
    );
  }
}

class _InclRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isLast;
  const _InclRow({
    required this.icon,
    required this.label,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF0F3F9))),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: AppColors.primary),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF33415E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
