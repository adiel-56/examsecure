import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/app_notification.dart';
import '../../../providers/notification_provider.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/loading_list.dart';
import '../../../widgets/status_badge.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<NotificationProvider>().load(),
    );
  }

  void _showDetail(AppNotification n) {
    context.read<NotificationProvider>().markRead(n.id);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NotificationDetailSheet(notification: n),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontSize: 15)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.load(),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => provider.load(),
          child: provider.isLoading
              ? const Padding(padding: EdgeInsets.all(16), child: LoadingList())
              : provider.notifications.isEmpty
                  ? const EmptyState(
                      icon: Icons.notifications_none_outlined,
                      title: 'Aucune notification',
                      subtitle: 'Vous serez informé ici de vos paiements, achats et déblocages de documents.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      itemCount: provider.notifications.length,
                      itemBuilder: (context, i) {
                        final n = provider.notifications[i];
                        return _NotificationCard(
                          notification: n,
                          onTap: () => _showDetail(n),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  IconData _iconForType(String type) {
    switch (type.toUpperCase()) {
      case 'PAYMENT':
        return Icons.payments_outlined;
      case 'PURCHASE':
        return Icons.verified_outlined;
      case 'UNLOCK':
        return Icons.lock_open_rounded;
      case 'WARNING':
        return Icons.warning_amber_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _iconColorForType(String type) {
    switch (type.toUpperCase()) {
      case 'PAYMENT':
        return const Color(0xFFD97706);
      case 'PURCHASE':
        return AppColors.success;
      case 'UNLOCK':
        return AppColors.primary;
      case 'WARNING':
        return AppColors.danger;
      default:
        return AppColors.navy;
    }
  }

  Color _bgColorForType(String type) {
    switch (type.toUpperCase()) {
      case 'PAYMENT':
        return const Color(0xFFFEF3C7);
      case 'PURCHASE':
        return AppColors.successSoft;
      case 'UNLOCK':
        return AppColors.primarySoft;
      case 'WARNING':
        return AppColors.dangerSoft;
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  String _labelForType(String type) {
    switch (type.toUpperCase()) {
      case 'PAYMENT':
        return 'Paiement';
      case 'PURCHASE':
        return 'Achat validé';
      case 'UNLOCK':
        return 'Déblocage';
      case 'WARNING':
        return 'Alerte';
      default:
        return 'Information';
    }
  }

  BadgeVariant _badgeVariant(String type) {
    switch (type.toUpperCase()) {
      case 'PAYMENT':
        return BadgeVariant.amber;
      case 'PURCHASE':
        return BadgeVariant.green;
      case 'UNLOCK':
        return BadgeVariant.blue;
      case 'WARNING':
        return BadgeVariant.red;
      default:
        return BadgeVariant.gray;
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final isUnread = !n.lu;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: isUnread ? Colors.white : const Color(0xFFFAFCFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUnread ? AppColors.primary.withValues(alpha: .35) : AppColors.border,
            width: isUnread ? 1.2 : 1.0,
          ),
          boxShadow: isUnread
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: .06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _bgColorForType(n.type),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_iconForType(n.type), color: _iconColorForType(n.type), size: 19),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.titre,
                          style: TextStyle(
                            fontWeight: isUnread ? FontWeight.w800 : FontWeight.w700,
                            fontSize: 12.5,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    n.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.muted,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StatusBadge(label: _labelForType(n.type), variant: _badgeVariant(n.type)),
                      Text(
                        Formatters.dateTime(n.createdAt),
                        style: const TextStyle(fontSize: 10, color: AppColors.faint),
                      ),
                    ],
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

class _NotificationDetailSheet extends StatelessWidget {
  final AppNotification notification;
  const _NotificationDetailSheet({required this.notification});

  @override
  Widget build(BuildContext context) {
    final n = notification;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
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
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.notifications_active_outlined, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.titre,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Formatters.dateTime(n.createdAt),
                        style: const TextStyle(fontSize: 11, color: AppColors.faint),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                n.message.isNotEmpty ? n.message : 'Aucun détail supplémentaire.',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.navy,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (n.type.toUpperCase() == 'PURCHASE' || n.type.toUpperCase() == 'PAYMENT') ...[
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/student/purchases');
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                icon: const Icon(Icons.folder_open_outlined, size: 18),
                label: const Text('Accéder à mes achats'),
              ),
              const SizedBox(height: 8),
            ] else if (n.type.toUpperCase() == 'UNLOCK') ...[
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/student/unlock-requests');
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                icon: const Icon(Icons.lock_open_rounded, size: 18),
                label: const Text('Voir mes demandes de déblocage'),
              ),
              const SizedBox(height: 8),
            ],

            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        ),
      ),
    );
  }
}
