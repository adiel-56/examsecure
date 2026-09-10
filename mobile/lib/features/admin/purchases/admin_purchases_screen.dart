import 'package:flutter/material.dart';

import '../../../repositories/admin_repository.dart';
import '../../../widgets/app_row_card.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/loading_list.dart';
import '../../../widgets/status_badge.dart';

class AdminPurchasesScreen extends StatefulWidget {
  const AdminPurchasesScreen({super.key});

  @override
  State<AdminPurchasesScreen> createState() => _AdminPurchasesScreenState();
}

class _AdminPurchasesScreenState extends State<AdminPurchasesScreen> {
  final _repo = AdminRepository();
  List<dynamic> _purchases = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _purchases = await _repo.fetchPurchases();
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Achats')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _loading
              ? const LoadingList()
              : _purchases.isEmpty
              ? const EmptyState(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Aucun achat',
                  subtitle: 'Les achats validés apparaîtront ici.',
                )
              : ListView.builder(
                  itemCount: _purchases.length,
                  itemBuilder: (context, i) {
                    final a = _purchases[i];
                    return AppRowCard(
                      leading: const ThumbBox(
                        icon: Icons.shopping_bag_outlined,
                      ),
                      title: a['document_titre'] ?? a['epreuve_titre'] ?? '',
                      subtitle:
                          '${a['etudiant_nom']} · ${a['nombre_telechargements']} téléch.',
                      trailing: StatusBadge(
                        label: a['statut'] == 'VALID'
                            ? 'Validé'
                            : (a['statut'] == 'BLOCKED' ? 'Bloqué' : 'Révoqué'),
                        variant: a['statut'] == 'VALID'
                            ? BadgeVariant.green
                            : (a['statut'] == 'BLOCKED'
                                  ? BadgeVariant.amber
                                  : BadgeVariant.red),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
