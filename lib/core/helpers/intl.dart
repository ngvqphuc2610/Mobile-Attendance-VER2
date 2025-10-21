import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final _fmtDisplay = DateFormat('yyyy-MM-dd HH:mm');      // để show trên UI
final _fmtSql     = DateFormat('yyyy-MM-dd HH:mm:ss');   // để gửi về API/DB

String dtToDisplay(DateTime? dt) =>
    dt == null ? '' : _fmtDisplay.format(dt);

String dtToSql(DateTime? dt) =>
    dt == null ? '' : _fmtSql.format(dt); // gửi local time dạng SQL

Future<DateTime?> pickDateTime(BuildContext context, {DateTime? initial}) async {
  final now = DateTime.now();
  final date = await showDatePicker(
    context: context,
    initialDate: initial ?? now,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );
  if (date == null) return null;

  final time = await showTimePicker(
    context: context,
    initialTime: initial != null
        ? TimeOfDay(hour: initial.hour, minute: initial.minute)
        : const TimeOfDay(hour: 7, minute: 0),
  );
  if (time == null) return null;

  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}
