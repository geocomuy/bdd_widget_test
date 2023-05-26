part of 'cli.dart';

class Dart {
  static Future<bool> installed({
    required Logger logger,
  }) async {
    try {
      await _Cmd.runProccess('dart', ['--version'], logger: logger);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> applyFixes({
    required Logger logger,
    required String filePath,
    bool recursive = false,
  }) async {
    await _Cmd.runProccess(
      'dart',
      [
        'fix',
        '--apply',
        filePath,
      ],
      logger: logger,
    );
  }

  static Future<void> format({
    required Logger logger,
    required String filePath,
  }) async {
    await _Cmd.runProccess(
      'dart',
      [
        'format',
        filePath,
      ],
      logger: logger,
    );
  }
}
