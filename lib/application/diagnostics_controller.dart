import '../infrastructure/logging/log_service.dart';

class DiagnosticsController {
  List<String> logSnapshot([int n = 200]) => LogService.getRecentLogs(n);
  String logFilePath() => LogService.getLogFilePath();
}
