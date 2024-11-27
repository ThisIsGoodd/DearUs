// lib/utils/date_utils.dart
// DateUtils: 날짜 관련 유틸리티 함수들
class DateUtils {
  // 특정 날짜로부터 며칠 후 날짜 계산
  static DateTime addDays(DateTime date, int days) {
    return date.add(Duration(days: days));
  }

  // 날짜 형식 변환
  static String formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}