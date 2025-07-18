import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

DateTime nowInBrazil() {
  return DateTime.now().toUtc().subtract(Duration(hours: 3)); // GMT-3 (BRT)
}

DateTime convertToBrazilTime(Timestamp timestamp) {
  return timestamp.toDate().subtract(Duration(hours: 3)); // UTC -> BRT
}

String formatBrazilianDate(DateTime date) {
  return DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(date);
}
