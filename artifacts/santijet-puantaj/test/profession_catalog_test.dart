import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_puantaj/domain/catalogs/professions.dart';

void main() {
  group('ProfessionCatalog', () {
    test('varsayılan meslekler SGK grup sırasındadır', () {
      final flat = ProfessionCatalog.defaultProfessions;
      expect(flat, isNotEmpty);
      expect(flat.first, 'Proje Koordinatörü');
      expect(flat.contains('Betonarme Demircisi'), isTrue);
      expect(flat.contains('Seramik / Fayans Döşeyicisi'), isTrue);
      expect(flat.contains('İnşaat İşçisi'), isTrue);
      expect(flat.toSet().length, flat.length);
    });

    test('groupItems SGK grupları ve Diğer bölümünü üretir', () {
      final sections = ProfessionCatalog.groupItems([
        'Kalıpçı',
        'Özel Meslek',
        'Elektrikçi',
        'Şantiye Şefi',
      ]);
      expect(sections.map((s) => s.groupName).toList(), [
        'Yönetim ve Teknik',
        'Kaba İnşaat',
        'Elektrik ve Mekanik',
        'Diğer',
      ]);
      expect(sections.first.items, ['Şantiye Şefi']);
      expect(sections.last.items, ['Özel Meslek']);
    });

    test('legacy meslek adları SGK adına çözülür', () {
      expect(
        ProfessionCatalog.resolveLegacyName('Demirci Usta'),
        'Betonarme Demircisi',
      );
      expect(
        ProfessionCatalog.resolveLegacyName('Elektrik Usta'),
        'Elektrikçi',
      );
      expect(
        ProfessionCatalog.resolveLegacyName('Kalıpçı'),
        'Kalıpçı',
      );
    });
  });
}
