import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static String currency(num amount, {String devise = 'XOF'}) {
    try {
      final formatted = NumberFormat.decimalPattern('fr_FR').format(amount);
      return '$formatted F${devise != 'XOF' ? ' $devise' : ''}';
    } catch (_) {
      try {
        final formatted = NumberFormat.decimalPattern().format(amount);
        return '$formatted F${devise != 'XOF' ? ' $devise' : ''}';
      } catch (_) {
        return '$amount F${devise != 'XOF' ? ' $devise' : ''}';
      }
    }
  }

  static String date(DateTime dt) {
    try {
      return DateFormat('dd/MM/yyyy', 'fr_FR').format(dt);
    } catch (_) {
      try {
        return DateFormat('dd/MM/yyyy').format(dt);
      } catch (_) {
        final day = dt.day.toString().padLeft(2, '0');
        final month = dt.month.toString().padLeft(2, '0');
        return '$day/$month/${dt.year}';
      }
    }
  }

  static String dateTime(DateTime dt) {
    try {
      return DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(dt);
    } catch (_) {
      try {
        return '${DateFormat('dd/MM/yyyy').format(dt)} à ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        final day = dt.day.toString().padLeft(2, '0');
        final month = dt.month.toString().padLeft(2, '0');
        final hour = dt.hour.toString().padLeft(2, '0');
        final minute = dt.minute.toString().padLeft(2, '0');
        return '$day/$month/${dt.year} à $hour:$minute';
      }
    }
  }
}

