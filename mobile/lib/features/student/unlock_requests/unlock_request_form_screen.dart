import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/purchase.dart';
import '../../../models/unlock_request.dart';
import '../../../repositories/unlock_repository.dart';
import '../../../widgets/status_badge.dart';

/// Reproduit l'écran « Demande de déblocage » de la maquette : bandeau
/// d'information ambre, champs en lecture (épreuve / appareil actuel),
/// motif, bouton d'envoi, puis un historique des demandes précédentes
/// sur le même écran.
class UnlockRequestFormScreen extends StatefulWidget {
  final Purchase purchase;
  const UnlockRequestFormScreen({super.key, required this.purchase});

  @override
  State<UnlockRequestFormScreen> createState() => _UnlockRequestFormScreenState();
}

class _UnlockRequestFormScreenState extends State<UnlockRequestFormScreen> {
  final _repo = UnlockRepository();
  final _motifCtrl = TextEditingController();
  bool _sending = false;
  List<UnlockRequest> _history = [];
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    try {
      _history = await _repo.fetchMyRequests();
    } catch (_) {}
    if (mounted) setState(() => _loadingHistory = false);
  }

  Future<void> _submit() async {
    if (_motifCtrl.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await _repo.createRequest(achatId: widget.purchase.id, motif: _motifCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Demande envoyée à l\'administration.')));
      _motifCtrl.clear();
      _loadHistory();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  StatusBadge _badge(String statut) {
    switch (statut) {
      case 'APPROVED':
        return const StatusBadge(label: 'Approuvée', variant: BadgeVariant.green);
      case 'REJECTED':
        return const StatusBadge(label: 'Refusée', variant: BadgeVariant.red);
      default:
        return const StatusBadge(label: 'En attente', variant: BadgeVariant.amber);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demande de déblocage', style: TextStyle(fontSize: 14)), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.warningSoft, borderRadius: BorderRadius.circular(12)),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.phone_iphone_outlined, color: AppColors.warning, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(fontSize: 10.5, color: Color(0xFF7A3A00), height: 1.5),
                        children: [
                          TextSpan(text: 'Nouveau téléphone ou réinstallation ? Demandez le transfert de votre achat sur '),
                          TextSpan(text: 'cet appareil', style: TextStyle(fontWeight: FontWeight.w800)),
                          TextSpan(text: '. Un administrateur examine chaque demande.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _ReadonlyField(icon: Icons.description_outlined, label: 'Document concerné', value: widget.purchase.documentTitre),
            const SizedBox(height: 8),
            const _ReadonlyField(icon: Icons.phone_iphone_outlined, label: 'Appareil actuel', value: 'Cet appareil'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Motif de la demande',
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.faint, letterSpacing: .3)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _motifCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Nouvel appareil acquis en septembre, l\'ancien est perdu…',
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _sending ? null : _submit,
              icon: const Icon(Icons.send_outlined, size: 16),
              label: Text(_sending ? 'Envoi…' : 'Envoyer la demande'),
            ),
            const SizedBox(height: 22),
            const Text('Historique des demandes', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
            const SizedBox(height: 10),
            if (_loadingHistory)
              const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
            else if (_history.isEmpty)
              const Text('Aucune demande précédente.', style: TextStyle(color: AppColors.faint, fontSize: 11.5))
            else
              ..._history.map((r) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.description_outlined, color: AppColors.primary, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.documentTitre, maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5)),
                              const SizedBox(height: 2),
                              Text('Envoyée le ${Formatters.date(r.createdAt)}',
                                  style: const TextStyle(color: AppColors.faint, fontSize: 10)),
                            ],
                          ),
                        ),
                        _badge(r.statut),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _ReadonlyField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ReadonlyField({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 9.5, color: AppColors.faint, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
