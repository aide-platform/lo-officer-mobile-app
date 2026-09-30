/// Display formats for LO screens. API payloads stay 24-hour / `yyyy-MM-dd`.
class LoDisplayFormat {
  LoDisplayFormat._();

  /// `2026-09-30`. Returns [raw] when it is not a date.
  static String date(String? raw) {
    final parsed = tryParseDate(raw);
    if (parsed == null) return raw?.trim() ?? '';
    return _ymd(parsed);
  }

  /// `11:25:00 AM` or `11:25:00 PM`. Returns [raw] when it is not a time.
  static String time(String? raw) {
    final parsed = tryParseTime(raw);
    if (parsed == null) return raw?.trim() ?? '';
    return _ampmFromParts(parsed.hour, parsed.minute, parsed.second);
  }

  /// Date and time together, skipping empty parts.
  static String dateAndTime(String? dateRaw, String? timeRaw) {
    final d = date(dateRaw);
    final t = time(timeRaw);
    if (d.isEmpty) return t;
    if (t.isEmpty) return d;
    return '$d $t';
  }

  /// Local date and time, for example `2026-09-30 11:25:00 AM`.
  static String dateTime(DateTime value) {
    final local = value.toLocal();
    return '${_ymd(local)} ${_ampm(_Clock(local.hour, local.minute, local.second))}';
  }

  /// A date, a time, or a combined timestamp, whichever [raw] contains.
  static String when(String? raw) {
    final t = raw?.trim() ?? '';
    if (t.isEmpty) return '';
    final hasDate = t.contains('-') || t.contains('T');
    final clock = tryParseTime(t);
    final day = tryParseDate(t);
    if (hasDate && day != null && clock != null && _hasClock(t)) {
      return '${_ymd(day)} ${_ampmFromParts(clock.hour, clock.minute, clock.second)}';
    }
    if (!hasDate && clock != null) {
      return _ampmFromParts(clock.hour, clock.minute, clock.second);
    }
    if (day != null && hasDate) return _ymd(day);
    return t;
  }

  /// 24-hour value safe to send back to CAP. Seconds omitted when they are 0.
  static String toApiTime(String raw) {
    final parsed = tryParseTime(raw);
    if (parsed == null) return raw.trim();
    final h = parsed.hour.toString().padLeft(2, '0');
    final m = parsed.minute.toString().padLeft(2, '0');
    if (parsed.second == 0) return '$h:$m';
    final s = parsed.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  static String _ampmFromParts(int hour, int minute, int second) =>
      _ampm(_Clock(hour, minute, second));

  static DateTime? tryParseDate(String? raw) {
    final t = raw?.trim() ?? '';
    if (t.isEmpty) return null;
    final dmy = RegExp(r'^(\d{2})-(\d{2})-(\d{4})').firstMatch(t);
    if (dmy != null) {
      return _calendar(
        int.parse(dmy.group(3)!),
        int.parse(dmy.group(2)!),
        int.parse(dmy.group(1)!),
      );
    }
    final ymd = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(t);
    if (ymd != null) {
      return _calendar(
        int.parse(ymd.group(1)!),
        int.parse(ymd.group(2)!),
        int.parse(ymd.group(3)!),
      );
    }
    final parsed = DateTime.tryParse(t);
    if (parsed == null) return null;
    final local = parsed.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static ({int hour, int minute, int second})? tryParseTime(String? raw) {
    final t = raw?.trim() ?? '';
    if (t.isEmpty) return null;

    final ampm = RegExp(
      r'(\d{1,2}):(\d{2})(?::(\d{2}))?\s*([AaPp][Mm])',
    ).firstMatch(t);
    if (ampm != null) {
      var hour = int.parse(ampm.group(1)!);
      final minute = int.parse(ampm.group(2)!);
      final second = int.parse(ampm.group(3) ?? '0');
      final pm = ampm.group(4)!.toUpperCase() == 'PM';
      if (hour == 12) hour = 0;
      if (pm) hour += 12;
      if (hour > 23 || minute > 59 || second > 59) return null;
      return (hour: hour, minute: minute, second: second);
    }

    final iso = DateTime.tryParse(t);
    if (iso != null && (t.contains('T') || RegExp(r'\d{2}:\d{2}').hasMatch(t))) {
      final local = iso.toLocal();
      if (t.contains(':')) {
        return (hour: local.hour, minute: local.minute, second: local.second);
      }
    }

    final clock = RegExp(r'(?:^|\s)(\d{1,2}):(\d{2})(?::(\d{2}))?').firstMatch(t);
    if (clock == null) return null;
    final hour = int.parse(clock.group(1)!);
    final minute = int.parse(clock.group(2)!);
    final second = int.parse(clock.group(3) ?? '0');
    if (hour > 23 || minute > 59 || second > 59) return null;
    return (hour: hour, minute: minute, second: second);
  }

  static bool _hasClock(String raw) => RegExp(r'\d{1,2}:\d{2}').hasMatch(raw);

  static DateTime? _calendar(int year, int month, int day) {
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  static String _ymd(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _ampm(_Clock clock) {
    final pm = clock.hour >= 12;
    var hour = clock.hour % 12;
    if (hour == 0) hour = 12;
    final m = clock.minute.toString().padLeft(2, '0');
    final s = clock.second.toString().padLeft(2, '0');
    return '$hour:$m:$s ${pm ? 'PM' : 'AM'}';
  }
}

class _Clock {
  const _Clock(this.hour, this.minute, this.second);
  final int hour;
  final int minute;
  final int second;
}
