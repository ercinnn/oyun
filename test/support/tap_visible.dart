import 'package:flutter_test/flutter_test.dart';

/// Önce hedefi görünür alana kaydırır, sonra dokunur. Bilim insanı
/// panelleri (adım listesi, büyük düğmeler) test ekranından uzun olabilir;
/// `tester.tap` görünmeyen bir widget'a dokunursa yalnızca uyarı verir ve
/// test sonra yanlış yerde düşer.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}
