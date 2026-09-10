import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';
import '../repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository = NotificationRepository();

  List<AppNotification> notifications = [];
  bool isLoading = false;

  int get unreadCount => notifications.where((n) => !n.lu).length;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    try {
      notifications = await _repository.fetchAll();
    } catch (_) {
      // Silencieux : les notifications ne doivent jamais bloquer l'app.
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(int id) async {
    await _repository.markRead(id);
    await load();
  }
}
