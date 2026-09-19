/// Pure display formatters (no locale dependency; the design is English-only).
abstract final class Formatters {
  static const List<String> _weekdays = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const List<String> _months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// `Tue, Oct 24`
  static String shortDate(DateTime date) =>
      '${_weekdays[date.weekday - 1]}, ${_months[date.month - 1]} ${date.day}';

  /// `2:00 PM`
  static String clockTime(DateTime time) {
    final hour12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour12:$minute ${time.hour < 12 ? 'AM' : 'PM'}';
  }

  /// `09:14 AM` (zero-padded, used in the approval timeline)
  static String timelineTime(DateTime time) {
    final hour12 = (time.hour % 12 == 0 ? 12 : time.hour % 12).toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour12:$minute ${time.hour < 12 ? 'AM' : 'PM'}';
  }

  /// `just now`, `45m ago`, `2h ago`, `3d ago`
  static String relativeAgo(DateTime past, DateTime now) {
    final diff = now.difference(past);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  /// `Expiring in 2h` / `Expiring in 40m` / `Expired`. Rounds up so a deadline
  /// that is 1h59m away reads as 2h rather than 1h.
  static String expiresIn(DateTime deadline, DateTime now) {
    final remaining = deadline.difference(now);
    if (remaining.inSeconds <= 0) return 'Expired';
    final minutes = (remaining.inSeconds / 60).ceil();
    if (minutes >= 60) return 'Expiring in ${(minutes / 60).ceil()}h';
    return 'Expiring in ${minutes}m';
  }

  /// `$4,850.00` (or `$4,850` with [withCents] false). Amounts are integer
  /// cents end-to-end to avoid floating point drift.
  static String usd(int cents, {bool withCents = true}) {
    final negative = cents < 0;
    final abs = cents.abs();
    final whole = (abs ~/ 100).toString();
    final grouped = whole.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    final fraction = (abs % 100).toString().padLeft(2, '0');
    final body = withCents ? '$grouped.$fraction' : grouped;
    return '${negative ? '-' : ''}\$$body';
  }

  /// `2.4 MB`
  static String fileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// First letters of the first two words, upper-cased (`Marcus Vance` -> `MV`).
  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = String.fromCharCode(parts.first.runes.first);
    if (parts.length == 1) return first.toUpperCase();
    return (first + String.fromCharCode(parts[1].runes.first)).toUpperCase();
  }
}
