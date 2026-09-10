import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';
import '../audit/audit_logs_screen.dart';
import '../filieres/manage_filieres_screen.dart';
import '../matieres/manage_matieres_screen.dart';
import '../transactions/transactions_screen.dart';
import '../purchases/admin_purchases_screen.dart';
import '../unlock_requests/admin_unlock_requests_screen.dart';
import '../payments/manage_payment_config_screen.dart';

class AdminHomeTab extends StatefulWidget {
  const AdminHomeTab({super.key});

  @override
  State<AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends State<AdminHomeTab> {
  int _pendingUnlockCount = 0;
  int _pendingPaymentsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final admin = context.read<AdminProvider>();
    await admin.loadStatistics();
    final pendingUnlocks = await admin.repository.fetchUnlockRequests(statut: 'PENDING');
    final pendingPayments = await admin.repository.fetchTransactions(statut: 'PENDING_VERIFICATION');
    if (mounted) {
      setState(() {
        _pendingUnlockCount = pendingUnlocks.length;
        _pendingPaymentsCount = pendingPayments.length;
      });
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final auth = context.watch<AuthProvider>();
    final stats = admin.statistics;

    return Container(
      color: AppColors.navy,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tableau de bord',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Espace administrateur',
                          style: TextStyle(
                            color: Color(0xFF8FA3C8),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white),
                    tooltip: 'Configuration Mobile Money',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ManagePaymentConfigScreen()),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.receipt_long_outlined, color: Colors.white),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AuditLogsScreen()),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () async {
                      await auth.logout();
                      if (context.mounted) context.go('/login');
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: admin.isLoading || stats == null
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadAll,
                        child: ListView(
                          children: [
                            // Grille des statistiques
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 1.45,
                              children: [
                                _StatCard(
                                  label: 'Chiffre d\'affaires',
                                  value: Formatters.currency(
                                    double.tryParse('${stats['chiffre_affaires']}') ?? 0,
                                  ),
                                  icon: Icons.account_balance_wallet_outlined,
                                ),
                                _StatCard(
                                  label: 'Paiements en attente',
                                  value: '${stats['paiements_en_attente'] ?? _pendingPaymentsCount}',
                                  icon: Icons.hourglass_top_rounded,
                                  highlightColor: const Color(0xFFD97706),
                                ),
                                _StatCard(
                                  label: 'Étudiants inscrits',
                                  value: '${stats['nombre_etudiants'] ?? 0}',
                                  icon: Icons.people_outline,
                                ),
                                _StatCard(
                                  label: 'Documents au catalogue',
                                  value: '${stats['nombre_documents'] ?? stats['nombre_epreuves'] ?? 0}',
                                  icon: Icons.description_outlined,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Liens rapides
                            const _QuickLinks(),

                            // Bannière alerte paiements MoMo
                            if (_pendingPaymentsCount > 0) ...[
                              const SizedBox(height: 12),
                              _PaymentAlertBanner(
                                count: _pendingPaymentsCount,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const TransactionsScreen()),
                                ),
                              ),
                            ],

                            // Bannière alerte déblocages
                            if (_pendingUnlockCount > 0) ...[
                              const SizedBox(height: 10),
                              _AlertBanner(
                                count: _pendingUnlockCount,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const AdminUnlockRequestsScreen(),
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 18),
                            Row(
                              children: [
                                const Text(
                                  'Activité récente',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const TransactionsScreen(),
                                    ),
                                  ),
                                  child: const Text('Tout voir'),
                                ),
                              ],
                            ),

                            ...List.from(stats['activite_recente'] ?? stats['ventes_recentes'] ?? []).map(
                              (v) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: const Color(0xFFE0F5FE),
                                      child: Text(
                                        _initials(v['etudiant'] ?? ''),
                                        style: const TextStyle(
                                          color: Color(0xFF0B7285),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            v['etudiant'] ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 11.5,
                                            ),
                                          ),
                                          Text(
                                            v['epreuve'] ?? '',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: AppColors.faint,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (v['montant'] != null)
                                      Text(
                                        Formatters.currency(double.tryParse('${v['montant']}') ?? 0),
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentAlertBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _PaymentAlertBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_rounded, color: Color(0xFFD97706), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count paiement(s) MoMo en attente',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF92400E)),
                ),
                const Text(
                  'Reçus à vérifier et valider',
                  style: TextStyle(color: Color(0xFFB45309), fontSize: 10.5),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: const Text('Vérifier', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _AlertBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE0B2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count demande(s) de déblocage',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const Text(
                  'Changement d\'appareil',
                  style: TextStyle(color: AppColors.faint, fontSize: 10.5),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: const Text('Gérer', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

class _QuickLinks extends StatelessWidget {
  const _QuickLinks();

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.receipt_long_outlined, 'Paiements MoMo', const TransactionsScreen()),
      (Icons.phone_android_outlined, 'Config MoMo', const ManagePaymentConfigScreen()),
      (Icons.school_outlined, 'Filières', const ManageFilieresScreen()),
      (Icons.menu_book_outlined, 'Matières', const ManageMatieresScreen()),
      (Icons.shopping_bag_outlined, 'Achats', const AdminPurchasesScreen()),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (item) => ActionChip(
              avatar: Icon(item.$1, size: 16, color: AppColors.navy),
              label: Text(
                item.$2,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.border),
              onPressed: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => item.$3)),
            ),
          )
          .toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? highlightColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: highlightColor != null ? highlightColor!.withValues(alpha: .3) : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: highlightColor ?? AppColors.navy, size: 20),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14.5,
              color: highlightColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.faint, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
