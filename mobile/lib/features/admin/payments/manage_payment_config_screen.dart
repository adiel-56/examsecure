import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../repositories/admin_repository.dart';

class ManagePaymentConfigScreen extends StatefulWidget {
  const ManagePaymentConfigScreen({super.key});

  @override
  State<ManagePaymentConfigScreen> createState() => _ManagePaymentConfigScreenState();
}

class _ManagePaymentConfigScreenState extends State<ManagePaymentConfigScreen> {
  final _adminRepo = AdminRepository();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _numberController;
  late TextEditingController _beneficiaryController;
  late TextEditingController _instructionsController;

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _numberController = TextEditingController();
    _beneficiaryController = TextEditingController();
    _instructionsController = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _numberController.dispose();
    _beneficiaryController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final config = await _adminRepo.fetchPaymentConfig();
      if (mounted) {
        setState(() {
          _numberController.text = config.momoNumber;
          _beneficiaryController.text = config.beneficiaryName;
          _instructionsController.text = config.instructions;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _adminRepo.updatePaymentConfig({
        'momo_number': _numberController.text.trim(),
        'beneficiary_name': _beneficiaryController.text.trim(),
        'instructions': _instructionsController.text.trim(),
      });

      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration Mobile Money enregistrée avec succès !'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'enregistrement : $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Configuration Mobile Money', style: TextStyle(fontSize: 15)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ces coordonnées sont directement présentées aux étudiants lors de l\'achat d\'un document.',
                                style: TextStyle(color: AppColors.primaryDark, fontSize: 11.5, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      const Text(
                        'Numéro Mobile Money de réception *',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _numberController,
                        decoration: const InputDecoration(
                          hintText: 'Ex: +229 97 00 00 00',
                          prefixIcon: Icon(Icons.phone_android_outlined, size: 18),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Numéro requis' : null,
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Nom du compte / Bénéficiaire *',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _beneficiaryController,
                        decoration: const InputDecoration(
                          hintText: 'Ex: Administration ExamSecure',
                          prefixIcon: Icon(Icons.badge_outlined, size: 18),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Bénéficiaire requis' : null,
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Instructions de paiement pour les étudiants *',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _instructionsController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Rédigez les consignes de transfert et de soumission du reçu...',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Instructions requises' : null,
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined, size: 18),
                        label: Text(_saving ? 'Enregistrement...' : 'Enregistrer la configuration'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
