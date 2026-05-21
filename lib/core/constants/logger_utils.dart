
/// NOTES : Refer utils class and extension functions for common resource uses

class Logger {
  static var tag = '';
  static var cloud = '☁️';
  static var success = '✅️';
  static var info = '💡';
  static var warning = '🃏️';
  static var error = '💔';

  static var logIcon = '✏️';

  static void printLog({var tag = 'indicator', var printLog = '', var logIcon = 'ℹ️️'}) {
    if (true) {
      Logger.logIcon = logIcon;
      Logger.tag = tag;
    }

  }
}

