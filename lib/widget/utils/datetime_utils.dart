// lib/utils/date_utils.dart
import 'package:intl/intl.dart';

class DateTimeUtils {
  // Konversi UTC ke WIB saat menerima data dari Supabase
  static DateTime utcToLocal(String utcTime) {
    DateTime utcDate = DateTime.parse(utcTime);
    return utcDate.add(const Duration(hours: 7)); // WIB = UTC+7
  }

  // Konversi WIB ke UTC saat mengirim ke Supabase
  static String localToUtc(DateTime localTime) {
    DateTime utcTime = localTime.subtract(const Duration(hours: 7));
    return utcTime.toIso8601String();
  }

  // Format tanggal dan waktu ke format Indonesia
  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(date);
  }

  // Format hanya tanggal ke format Indonesia
  static String formatDate(DateTime date) {
    return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
  }

  // Format hanya waktu
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm', 'id_ID').format(date);
  }

  // Mendapatkan timestamp sekarang dalam WIB
  static DateTime nowWIB() {
    return DateTime.now().toUtc().add(const Duration(hours: 7));
  }
}