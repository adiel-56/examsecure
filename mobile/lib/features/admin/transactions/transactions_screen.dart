import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/transaction.dart';
import '../../../repositories/admin_repository.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/loading_list.dart';
import '../../../widgets/status_badge.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _repo = AdminRepository();
  List<AppTransaction> _transactions = [];
  bool _loading = true;
  String _selectedFilter = ''; // '' = Tous, 'PENDING_VERIFICATION', 'PAID', 'REJECTED'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _repo.fetchTransactions(
        statut: _selectedFilter.isNotEmpty ? _selectedFilter : null,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      if (mounted) {
        setState(() {
          _transactions = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  StatusBadge _badge(String statut) {
    switch (statut) {
      case 'PAID':
      case 'SUCCESS':
        return const StatusBadge(label: 'Validé', variant: BadgeVariant.green);
      case 'REJECTED':
      case 'FAILED':
        return const StatusBadge(label: 'Refusé', variant: BadgeVariant.red);
      case 'PENDING_VERIFICATION':
      case 'PAYMENT_SUBMITTED':
      case 'PENDING':
        return const StatusBadge(label: 'En attente', variant: BadgeVariant.amber);
      default:
        return const StatusBadge(label: 'Non payé', variant: BadgeVariant.gray);
    }
  }

  void _showTransactionDetail(AppTransaction t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TransactionDetailSheet(
        transaction: t,
        onValidate: () async {
          Navigator.pop(ctx);
          _confirmValidate(t);
        },
        onReject: () async {
          Navigator.pop(ctx);
          _promptReject(t);
        },
      ),
    );
  }

  Future<void> _confirmValidate(AppTransaction t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Valider ce paiement ?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        content: Text(
          'Confirmez-vous la réception du paiement de ${Formatters.currency(t.montant, devise: t.devise)} '
          'pour l\'étudiant ${t.etudiantNom.isNotEmpty ? t.etudiantNom : t.etudiantEmail} ?\n\n'
          'Cette action débloquera immédiatement l\'accès au document « ${t.documentTitre} ».',
          style: const TextStyle(fontSize: 12, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Confirmer la validation'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repo.validateTransaction(t.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Paiement validé avec succès ! L\'accès étudiant est débloqué.'),
              backgroundColor: AppColors.success,
            ),
          );
          _load();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.danger),
          );
        }
      }
    }
  }

  Future<void> _promptReject(AppTransaction t) async {
    final reasonController = TextEditingController();
    String selectedPredefined = 'Reçu illisible';
    final predefinedReasons = [
      'Reçu illisible',
      'Paiement non retrouvé',
      'Montant incorrect',
      'Référence invalide',
      'Reçu déjà utilisé',
      'Autre motif',
    ];

    final rejected = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Text('Refuser le paiement', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.danger)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sélectionnez ou précisez le motif du refus (obligatoire) :',
                  style: TextStyle(fontSize: 11.5, color: AppColors.muted),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedPredefined,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                  items: predefinedReasons
                      .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 12))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() {
                        selectedPredefined = val;
                        if (val != 'Autre motif') {
                          reasonController.text = val;
                        } else {
                          reasonController.clear();
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: reasonController..text = (reasonController.text.isEmpty ? selectedPredefined : reasonController.text),
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Précisions supplémentaires sur le motif...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = reasonController.text.trim();
                if (text.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Le motif de refus est obligatoire.')),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('Refuser'),
            ),
          ],
        ),
      ),
    );

    if (rejected == true) {
      try {
        final reason = reasonController.text.trim();
        await _repo.rejectTransaction(t.id, motif: reason);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Demande de paiement refusée.'),
              backgroundColor: AppColors.primaryDark,
            ),
          );
          _load();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.danger),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Demandes & Transactions', style: TextStyle(fontSize: 15)),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _load,
              tooltip: 'Actualiser',
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Rechercher un étudiant, un document...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _searchQuery = '';
                                  _load();
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      ),
                      onSubmitted: (val) {
                        _searchQuery = val.trim();
                        _load();
                      },
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterChip('Tous', ''),
                          const SizedBox(width: 6),
                          _filterChip('En attente (MoMo)', 'PENDING_VERIFICATION'),
                          const SizedBox(width: 6),
                          _filterChip('Validés', 'PAID'),
                          const SizedBox(width: 6),
                          _filterChip('Refusés', 'REJECTED'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 16),

              Expanded(
                child: _loading
                    ? const Padding(padding: EdgeInsets.all(16), child: LoadingList())
                    : _transactions.isEmpty
                        ? const EmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: 'Aucune demande trouvée',
                            subtitle: 'Les paiements Mobile Money soumis apparaîtront ici.',
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: _transactions.length,
                              itemBuilder: (context, i) {
                                final t = _transactions[i];
                                return InkWell(
                                  onTap: () => _showTransactionDetail(t),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 9),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: t.isPending
                                            ? const Color(0xFFF59E0B).withValues(alpha: .5)
                                            : AppColors.border,
                                        width: t.isPending ? 1.2 : 1.0,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                t.epreuveTitre,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                              ),
                                            ),
                                            Text(
                                              Formatters.currency(t.montant, devise: t.devise),
                                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.person_outline, size: 13, color: AppColors.muted),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                t.etudiantNom.isNotEmpty ? t.etudiantNom : t.etudiantEmail,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 11, color: AppColors.muted),
                                              ),
                                            ),
                                            _badge(t.statut),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              t.numeroTelephone.isNotEmpty
                                                  ? 'MoMo : ${t.numeroTelephone}'
                                                  : (t.referenceRecu.isNotEmpty ? 'Réf : ${t.referenceRecu}' : 'Mobile Money'),
                                              style: const TextStyle(fontSize: 10, color: AppColors.faint),
                                            ),
                                            Text(
                                              Formatters.dateTime(t.createdAt),
                                              style: const TextStyle(fontSize: 10, color: AppColors.faint),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
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
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
      selected: selected,
      onSelected: (val) {
        setState(() {
          _selectedFilter = val ? value : '';
        });
        _load();
      },
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(color: selected ? Colors.white : AppColors.navy),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      ),
    );
  }
}

class _TransactionDetailSheet extends StatelessWidget {
  final AppTransaction transaction;
  final VoidCallback onValidate;
  final VoidCallback onReject;

  const _TransactionDetailSheet({
    required this.transaction,
    required this.onValidate,
    required this.onReject,
  });

  void _openProof(BuildContext context, String url) {
    final t = transaction;
    final isPdf = url.toLowerCase().endsWith('.pdf') || url.toLowerCase().contains('.pdf');
    if (isPdf) {
      showDialog(
        context: context,
        useSafeArea: false,
        builder: (_) => _PdfReceiptViewerDialog(
          pdfUrl: url,
          title: 'Reçu PDF · ${t.etudiantNom.isNotEmpty ? t.etudiantNom : t.etudiantEmail}',
        ),
      );
    } else {
      showDialog(
        context: context,
        useSafeArea: false,
        builder: (_) => _ImageReceiptViewerDialog(
          imageUrl: url,
          title: 'Reçu · ${t.etudiantNom.isNotEmpty ? t.etudiantNom : t.etudiantEmail}',
          amount: Formatters.currency(t.montant, devise: t.devise),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final proofUrl = t.fullRecuUrl;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(99)),
                ),
              ),
              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Détail du paiement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  Text(
                    Formatters.currency(t.montant, devise: t.devise),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _item('Étudiant', '${t.etudiantNom.isNotEmpty ? t.etudiantNom : t.etudiantEmail} (${t.etudiantEmail})'),
              _item('Document', t.documentTitre),
              if (t.epreuvePrix > 0) _item('Prix officiel', Formatters.currency(t.epreuvePrix, devise: t.devise)),
              _item('Numéro MoMo utilisé', t.numeroTelephone.isNotEmpty ? t.numeroTelephone : 'Non renseigné'),
              if (t.referenceRecu.isNotEmpty) _item('Référence transaction', t.referenceRecu),
              if (t.commentaireEtudiant.isNotEmpty) _item('Commentaire étudiant', t.commentaireEtudiant),
              _item('Date de soumission', Formatters.dateTime(t.createdAt)),
              _item('Statut actuel', t.statut),

              if (t.motifRefus.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(10)),
                  child: Text('Motif de refus : ${t.motifRefus}', style: const TextStyle(color: AppColors.danger, fontSize: 11.5)),
                ),
              ],

              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Preuve de paiement (Reçu)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  if (proofUrl != null)
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.touch_app_outlined, size: 13, color: AppColors.primary),
                        SizedBox(width: 3),
                        Text('Appuyez pour ouvrir', style: TextStyle(fontSize: 10.5, color: AppColors.primary, fontWeight: FontWeight.w700)),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),

              if (proofUrl != null && proofUrl.isNotEmpty) ...[
                InkWell(
                  onTap: () => _openProof(context, proofUrl),
                  borderRadius: BorderRadius.circular(14),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary.withValues(alpha: .3), width: 1.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: proofUrl.toLowerCase().endsWith('.pdf') || proofUrl.toLowerCase().contains('.pdf')
                          ? Container(
                              padding: const EdgeInsets.all(16),
                              color: const Color(0xFFF8FAFC),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.dangerSoft,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.danger, size: 30),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Document PDF joint', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                        SizedBox(height: 2),
                                        Text('Appuyez pour ouvrir et lire le document', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.open_in_new_rounded, color: AppColors.primary, size: 18),
                                ],
                              ),
                            )
                          : Stack(
                              children: [
                                Image.network(
                                  proofUrl,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return Container(
                                      height: 180,
                                      color: const Color(0xFFF1F5F9),
                                      child: const Center(child: CircularProgressIndicator()),
                                    );
                                  },
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 100,
                                    color: const Color(0xFFF1F5F9),
                                    padding: const EdgeInsets.all(12),
                                    child: const Center(
                                      child: Text(
                                        'Reçu disponible · Appuyez pour afficher',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.75),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white),
                                        SizedBox(width: 4),
                                        Text('Agrandir / Zoomer', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                  child: const Center(child: Text('Aucun fichier joint', style: TextStyle(fontSize: 11.5, color: AppColors.faint))),
                ),
              ],

              const SizedBox(height: 20),

              if (t.isPending || t.isRejected) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onValidate,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                        icon: const Icon(Icons.check_circle_outline, size: 17),
                        label: const Text('Valider'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onReject,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                        icon: const Icon(Icons.cancel_outlined, size: 17),
                        label: const Text('Refuser'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.navy)),
          ),
        ],
      ),
    );
  }
}

class _ImageReceiptViewerDialog extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String amount;

  const _ImageReceiptViewerDialog({
    required this.imageUrl,
    required this.title,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: const Color(0xFF090D16),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.black54,
          foregroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
              Text('Montant : $amount', style: const TextStyle(fontSize: 10.5, color: Colors.white70)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        body: Center(
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 6.0,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 12),
                      Text('Chargement de l\'image…', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                );
              },
              errorBuilder: (_, __, ___) => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
                      SizedBox(height: 12),
                      Text(
                        'Impossible de charger l\'image du reçu.\nVérifiez la connexion avec le serveur.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PdfReceiptViewerDialog extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const _PdfReceiptViewerDialog({
    required this.pdfUrl,
    required this.title,
  });

  @override
  State<_PdfReceiptViewerDialog> createState() => _PdfReceiptViewerDialogState();
}

class _PdfReceiptViewerDialogState extends State<_PdfReceiptViewerDialog> {
  bool _loading = true;
  String? _error;
  PdfController? _controller;
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadPdf() async {
    try {
      final response = await ApiClient.instance.dio.get<List<int>>(
        widget.pdfUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.data != null) {
        final bytes = Uint8List.fromList(response.data!);
        _controller = PdfController(document: PdfDocument.openData(bytes));
        if (mounted) {
          setState(() => _loading = false);
        }
      } else {
        throw Exception('Données PDF vides.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger le document PDF : $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: const Color(0xFF090D16),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.black54,
          foregroundColor: Colors.white,
          title: Text(widget.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
          actions: [
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        body: _loading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 12),
                    Text('Chargement du reçu PDF…', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.danger, size: 40),
                          const SizedBox(height: 12),
                          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 14),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _loading = true;
                                _error = null;
                              });
                              _loadPdf();
                            },
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: PdfView(
                            controller: _controller!,
                            onPageChanged: (p) => setState(() => _currentPage = p),
                            onDocumentLoaded: (doc) => setState(() {
                              _totalPages = doc.pagesCount;
                              _currentPage = 1;
                            }),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        color: Colors.black45,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Page $_currentPage sur $_totalPages',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
