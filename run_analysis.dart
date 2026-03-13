import 'dart:io';

void main() async {
  var result = await Process.run('dart', [
    'analyze',
    '--format=json',
    'lib/screens/admin/admin_analytics_screen.dart',
  ]);
  await File(
    'analysis.json',
  ).writeAsString('${result.stdout}\n${result.stderr}');
}
