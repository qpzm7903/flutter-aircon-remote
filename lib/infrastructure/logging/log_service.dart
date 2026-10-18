import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

abstract final class LogService {
  static Directory? _directory;
  static final List<String> _logs = [];
  static Future<void> _writes = Future.value();
  static String _day(DateTime date) =>
      '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  static Future<void> init() async {
    try {
      _directory = await Directory(
        path.join((await getApplicationSupportDirectory()).path, 'logs'),
      ).create(recursive: true);
      final cutoff = _day(DateTime.now().subtract(const Duration(days: 7)));
      await for (final file in _directory!.list()) {
        final match = RegExp(r'^app_(\d{8})\.log$')
            .firstMatch(path.basename(file.path));
        if (match != null && match[1]!.compareTo(cutoff) < 0) {
          await file.delete();
        }
      }
    } catch (_) {
      /* Logging must never prevent startup. */
    }
  }

  static void info(String msg, [Object? err, StackTrace? stack]) =>
      _write('INFO', msg, err, stack);
  static void warning(String msg, [Object? err, StackTrace? stack]) =>
      _write('WARN', msg, err, stack);
  static void error(String msg, [Object? err, StackTrace? stack]) =>
      _write('ERROR', msg, err, stack);
  static void _write(String level, String msg, Object? err, StackTrace? stack) {
    if (_directory == null) {
      return;
    }
    final line =
        '${DateTime.now().toIso8601String()} $level $msg${err == null ? '' : ' | $err'}${stack == null ? '' : '\n$stack'}';
    _logs.add(line);
    if (_logs.length > 1000) {
      _logs.removeAt(0);
    }
    final file = File(getLogFilePath());
    _writes = _writes.then((_) async {
      try {
        await file.writeAsString('$line\n', mode: FileMode.append);
      } catch (_) {}
    });
  }

  static List<String> getRecentLogs([int n = 200]) => List.unmodifiable(
    _logs.skip((_logs.length - n.clamp(0, 1000)).clamp(0, _logs.length)),
  );
  static String getLogFilePath() => _directory == null
      ? ''
      : path.join(_directory!.path, 'app_${_day(DateTime.now())}.log');
}
