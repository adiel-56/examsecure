import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/admin_provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AdminProvider>().loadStatistics());
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final stats = admin.statistics;

    return Container(
      color: AppColors.bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Statistiques')),
        body: SafeArea(
          child: admin.isLoading || stats == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text('Revenus (30 derniers jours)',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(Formatters.currency(stats['revenus_30_jours'] ?? 0),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: AppColors.navy)),
                    const SizedBox(height: 20),
                    const Text('Documents les plus vendus', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    const SizedBox(height: 8),
                    ...List.from(stats['documents_plus_vendus'] ?? stats['epreuves_plus_vendues'] ?? []).map(
                      (e) => _RankRow(label: e['document__titre'] ?? e['epreuve__titre'] ?? '', value: '${e['total']} vente(s)'),
                    ),
                    const SizedBox(height: 20),
                    const Text('Filières les plus actives', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    const SizedBox(height: 8),
                    ...List.from(stats['filieres_plus_actives'] ?? []).map(
                      (f) => _RankRow(label: f['document__filiere__nom'] ?? f['epreuve__filiere__nom'] ?? '', value: '${f['total']} achat(s)'),
                    ),
                    const SizedBox(height: 20),
                    const Text('Ventes récentes', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    const SizedBox(height: 8),
                    ...List.from(stats['ventes_recentes'] ?? []).map(
                      (v) => _RankRow(label: '${v['etudiant']} · ${v['document'] ?? v['epreuve']}', value: ''),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final String label;
  final String value;
  const _RankRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
          if (value.isNotEmpty)
            Text(value, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.navy)),
        ],
      ),
    );
  }
}
