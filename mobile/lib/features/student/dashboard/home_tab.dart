import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/purchase.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/catalogue_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/purchase_provider.dart';
import '../../../widgets/app_row_card.dart';
import '../../../widgets/status_badge.dart';
import '../notifications/notifications_screen.dart';

const _coverGradients = [
  LinearGradient(colors: [Color(0xFF3B5BDB), Color(0xFF7048E8)]), // g1
  LinearGradient(colors: [Color(0xFF0CA678), Color(0xFF20C997)]), // g2
  LinearGradient(colors: [Color(0xFFE8590C), Color(0xFFF59F00)]), // g3
  LinearGradient(colors: [Color(0xFF0B7285), Color(0xFF15AABF)]), // g4
];

/// Reproduit l'écran « Dashboard étudiant » de la maquette : en-tête avec
/// logo + salutation, recherche, chips de filières, carrousel « Nouveaux
/// documents » (cover / image de couverture), puis « Mes derniers achats ».
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogueProvider>()
        ..loadFilieres()
        ..loadExams();
      context.read<NotificationProvider>().load();
      context.read<PurchaseProvider>().loadPurchases();
    });
  }

  StatusBadge _purchaseBadge(Purchase p) {
    if (p.statut == 'VALID' && p.nombreTelechargements > 0) {
      return const StatusBadge(label: 'Consultable', variant: BadgeVariant.green);
    }
    if (p.statut == 'VALID') {
      return const StatusBadge(label: 'À télécharger', variant: BadgeVariant.blue);
    }
    if (p.statut == 'BLOCKED') {
      return const StatusBadge(label: 'Limite atteinte', variant: BadgeVariant.amber);
    }
    return const StatusBadge(label: 'Révoqué', variant: BadgeVariant.red);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final catalogue = context.watch<CatalogueProvider>();
    final notifications = context.watch<NotificationProvider>();
    final purchases = context.watch<PurchaseProvider>();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ExamSecure', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                    Text('Bonjour ${auth.currentUser?.firstName ?? ''}',
                        style: const TextStyle(fontSize: 10.5, color: AppColors.faint, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border)),
                  child: Stack(
                    children: [
                      const Center(child: Icon(Icons.notifications_outlined, size: 16, color: AppColors.muted)),
                      if (notifications.unreadCount > 0)
                        Positioned(
                          top: 5, right: 6,
                          child: Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: catalogue.setSearch,
            decoration: const InputDecoration(hintText: 'Rechercher un document, un cours…', prefixIcon: Icon(Icons.search)),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _Chip(label: 'Tous', selected: catalogue.selectedFiliereId == null,
                    onTap: () => catalogue.setFiliereFilter(null)),
                ...catalogue.filieres.map((f) => _Chip(
                      label: f.nom,
                      selected: catalogue.selectedFiliereId == f.id,
                      onTap: () => catalogue.setFiliereFilter(f.id),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Nouveaux documents', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
              const Spacer(),
              TextButton(onPressed: () => context.go('/student/catalogue'), child: const Text('Voir tout')),
            ],
          ),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: catalogue.exams.take(8).length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final exam = catalogue.exams[i];
                final gradient = _coverGradients[i % _coverGradients.length];
                return _ExamCoverCard(
                  gradient: gradient,
                  imageUrl: exam.fullCouvertureUrl,
                  title: exam.titre,
                  subtitle: '${exam.matieresDisplay} · ${exam.typeContenu}',
                  pages: '${exam.nombrePages} p',
                  price: Formatters.currency(exam.prix, devise: exam.devise),
                  onTap: () => context.push('/student/exam/${exam.id}'),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text('Mes derniers achats', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
              const Spacer(),
              TextButton(onPressed: () => context.go('/student/purchases'), child: const Text('Tous')),
            ],
          ),
          if (purchases.purchases.isEmpty && !purchases.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Aucun achat pour le moment.', style: TextStyle(color: AppColors.faint, fontSize: 12)),
            )
          else
            ...purchases.purchases.take(4).map(
              (p) => AppRowCard(
                leading: p.fullCouvertureUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          p.fullCouvertureUrl!,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const ThumbBox(
                            icon: Icons.picture_as_pdf_outlined,
                            gradient: LinearGradient(colors: [Color(0xFF0B7285), Color(0xFF15AABF)]),
                          ),
                        ),
                      )
                    : const ThumbBox(
                        icon: Icons.picture_as_pdf_outlined,
                        gradient: LinearGradient(colors: [Color(0xFF0B7285), Color(0xFF15AABF)]),
                      ),
                title: p.documentTitre,
                subtitle: '${Formatters.date(p.createdAt)} · ${Formatters.currency(p.documentPrix)}',
                trailing: _purchaseBadge(p),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExamCoverCard extends StatelessWidget {
  final Gradient gradient;
  final String? imageUrl;
  final String title;
  final String subtitle;
  final String pages;
  final String price;
  final VoidCallback onTap;

  const _ExamCoverCard({
    required this.gradient,
    this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.pages,
    required this.price,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 148,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 82,
              width: double.infinity,
              decoration: BoxDecoration(gradient: gradient),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.description_outlined, color: Colors.white, size: 22),
                          const SizedBox(height: 5),
                          Text('PDF • $pages', style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.description_outlined, color: Colors.white, size: 22),
                        const SizedBox(height: 5),
                        Text('PDF • $pages', style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w700)),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, height: 1.25)),
                  const SizedBox(height: 3),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 9.5, color: AppColors.faint)),
                  const SizedBox(height: 5),
                  Text(price, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});

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
