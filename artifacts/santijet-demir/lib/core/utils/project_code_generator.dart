import 'dart:math';

abstract final class ProjectCodeGenerator {
  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static String generate() {
    final random = Random.secure();
    return List.generate(
      10,
      (_) => _chars[random.nextInt(_chars.length)],
    ).join();
  }
}
