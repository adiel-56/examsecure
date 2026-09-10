import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/exam.dart';
import '../../../models/payment_config.dart';
import '../../../models/transaction.dart';
import '../../../providers/auth_provider.dart';
import '../../../repositories/payment_repository.dart';
import '../../../widgets/status_badge.dart';

class PaymentScreen extends StatefulWidget {
  final Exam exam;
  const PaymentScreen({super.key, required this.exam});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _paymentRepo = PaymentRepository();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _phoneController;
  late TextEditingController _amountController;
  late TextEditingController _refController;
  late TextEditingController _commentController;

  PaymentConfig? _config;
  AppTransaction? _existingTransaction;
  bool _loading = true;
  bool _submitting = false;
  int _currentStep = 1; // 1: Instructions, 2: Formulaire Reçu, 3: Statut en attente

  PlatformFile? _selectedFile;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _amountController = TextEditingController(
      text: widget.exam.prix.toStringAsFixed(0),
    );
    _refController = TextEditingController();
    _commentController = TextEditingController();

    _init();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    _refController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    try {
      final config = await _paymentRepo.fetchConfig();
      final statusData = await _paymentRepo.fetchPaymentStatus(widget.exam.id);

      if (mounted) {
        setState(() {
          _config = config;
          if (statusData['statut'] != null && statusData['statut'] != 'UNPAID') {
            _existingTransaction = AppTransaction.fromJson(statusData);
            if (_existingTransaction!.isPending) {
              _currentStep = 3;
            } else if (_existingTransaction!.isRejected) {
              _currentStep = 2; // Permet de soumettre un nouveau reçu
            }
          }
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickReceiptFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de sélectionner le fichier : $e')),
        );
      }
    }
  }

  Future<void> _submitReceipt() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null || _selectedFile!.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner votre reçu de paiement (Image ou PDF).'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final amount = double.tryParse(_amountController.text.trim()) ?? widget.exam.prix;
      final txn = await _paymentRepo.submitReceipt(
        examId: widget.exam.id,
        amount: amount,
        phoneNumber: _phoneController.text.trim(),
        referenceRecu: _refController.text.trim(),
        commentaire: _commentController.text.trim(),
        filePath: _selectedFile!.path!,
        fileName: _selectedFile!.name,
      );

      if (mounted) {
        setState(() {
          _existingTransaction = txn;
          _currentStep = 3;
          _submitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reçu envoyé avec succès ! En attente de validation.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _copyMomoNumber() {
    final number = _config?.momoNumber ?? '+229 97 00 00 00';
    Clipboard.setData(ClipboardData(text: number));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Numéro copié : $number'),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primaryDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Paiement Mobile Money', style: TextStyle(fontSize: 15)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildExamHeader(),
                    const SizedBox(height: 16),
                    if (_currentStep == 1) ...[
                      _buildInstructionsStep(),
                    ] else if (_currentStep == 2) ...[
                      _buildFormStep(),
                    ] else ...[
                      _buildPendingStep(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildExamHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.menu_book_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.exam.titre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                ),
                const SizedBox(height: 3),
                Text(
                  '${widget.exam.filiereNom} · ${widget.exam.matiereNom}',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            Formatters.currency(widget.exam.prix, devise: widget.exam.devise),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsStep() {
    final momoNumber = _config?.momoNumber ?? '+229 97 00 00 00';
    final beneficiary = _config?.beneficiaryName ?? 'Administration ExamSecure';
    final instructions = _config?.instructions ??
        'Pour accéder à ce document, veuillez envoyer le montant exact au numéro Mobile Money ci-dessus.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '1. Coordonnées de paiement',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.navy),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'MOBILE MONEY',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 9.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _copyMomoNumber,
                    icon: const Icon(Icons.copy, color: Colors.white70, size: 18),
                    tooltip: 'Copier le numéro',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'NUMÉRO DE RÉCEPTION',
                style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                momoNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const Divider(color: Colors.white12, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BÉNÉFICIAIRE',
                        style: TextStyle(color: Colors.white54, fontSize: 9.5, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        beneficiary,
                        style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'MONTANT EXACT',
                        style: TextStyle(color: Colors.white54, fontSize: 9.5, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        Formatters.currency(widget.exam.prix, devise: widget.exam.devise),
                        style: const TextStyle(color: Color(0xFF34D399), fontSize: 14, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: .2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  instructions,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.primaryDark,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _copyMomoNumber,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.navy,
            side: const BorderSide(color: AppColors.border),
          ),
          icon: const Icon(Icons.copy_outlined, size: 18),
          label: const Text('Copier le numéro Mobile Money'),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () => setState(() => _currentStep = 2),
          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          label: const Text('J\'ai effectué le paiement'),
        ),
      ],
    );
  }

  Widget _buildFormStep() {
    final isRejected = _existingTransaction != null && _existingTransaction!.isRejected;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _currentStep = 1),
                icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              const Text(
                '2. Formulaire & Envoi du reçu',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.navy),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isRejected) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.danger.withValues(alpha: .3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Paiement précédent refusé',
                        style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Motif : ${_existingTransaction!.motifRefus.isNotEmpty ? _existingTransaction!.motifRefus : "Reçu non conforme"}',
                    style: const TextStyle(color: Color(0xFF991B1B), fontSize: 11.5),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Veuillez renseigner les informations correctes et joindre un nouveau reçu lisible.',
                    style: TextStyle(color: Color(0xFF7F1D1D), fontSize: 10.5, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          const Text('Montant payé (FCFA) *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Ex: 1000',
              prefixIcon: Icon(Icons.payments_outlined, size: 18),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Montant requis' : null,
          ),
          const SizedBox(height: 14),
          const Text('Numéro Mobile Money utilisé *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: 'Ex: +229 97 00 00 00',
              prefixIcon: Icon(Icons.phone_android_outlined, size: 18),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Numéro de téléphone requis' : null,
          ),
          const SizedBox(height: 14),
          const Text('Référence de la transaction (facultatif)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _refController,
            decoration: const InputDecoration(
              hintText: 'Ex: ID de transaction MoMo ou référence SMS',
              prefixIcon: Icon(Icons.tag_outlined, size: 18),
            ),
          ),
          const SizedBox(height: 14),
          const Text('Commentaire (facultatif)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _commentController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Précisions supplémentaires pour l\'administration...',
            ),
          ),
          const SizedBox(height: 16),
          const Text('Reçu de paiement (Image ou PDF) *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          if (_selectedFile == null) ...[
            InkWell(
              onTap: _pickReceiptFile,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary, width: 1.2),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 36),
                    SizedBox(height: 8),
                    Text(
                      'Sélectionner le reçu',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Capture d\'écran (JPG, PNG) ou fichier PDF (max 10 Mo)',
                      style: TextStyle(color: AppColors.muted, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.success),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.successSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _selectedFile!.extension == 'pdf'
                          ? Icons.picture_as_pdf_outlined
                          : Icons.image_outlined,
                      color: AppColors.success,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedFile!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                        Text(
                          '${(_selectedFile!.size / 1024).toStringAsFixed(1)} Ko',
                          style: const TextStyle(color: AppColors.faint, fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _pickReceiptFile,
                    icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                    tooltip: 'Changer de fichier',
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _submitting ? null : _submitReceipt,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(_submitting ? 'Envoi en cours...' : 'Envoyer le reçu pour vérification'),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingStep() {
    final txn = _existingTransaction;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: .4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                ),
                child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 28),
              ),
              const SizedBox(height: 12),
              const Text(
                'Paiement en attente de vérification',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Votre reçu a été soumis à l\'administration. Une fois le virement validé, votre document sera automatiquement débloqué.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Détails de la demande',
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.navy),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _buildDetailRow('Statut', const StatusBadge(label: 'En attente', variant: BadgeVariant.amber)),
              const Divider(height: 16),
              _buildDetailRow(
                'Montant déclaré',
                Text(
                  txn != null ? Formatters.currency(txn.montant, devise: txn.devise) : '${widget.exam.prix} FCFA',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
              if (txn != null && txn.numeroTelephone.isNotEmpty) ...[
                const Divider(height: 16),
                _buildDetailRow(
                  'Numéro payeur',
                  Text(txn.numeroTelephone, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ],
              if (txn != null && txn.referenceRecu.isNotEmpty) ...[
                const Divider(height: 16),
                _buildDetailRow(
                  'Référence',
                  Text(txn.referenceRecu, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                ),
              ],
              if (txn != null) ...[
                const Divider(height: 16),
                _buildDetailRow(
                  'Date d\'envoi',
                  Text(Formatters.dateTime(txn.createdAt), style: const TextStyle(fontSize: 11.5, color: AppColors.faint)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _init,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Vérifier le statut'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => context.pop(),
          child: const Text('Retour au document'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, Widget valueWidget) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
        valueWidget,
      ],
    );
  }
}
