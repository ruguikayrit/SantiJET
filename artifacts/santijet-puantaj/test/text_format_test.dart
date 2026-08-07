import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_puantaj/core/utils/text_format.dart';

void main() {
  test('titleCaseTr: Türkçe büyük harfleri başlık biçimine çevirir', () {
    expect(titleCaseTr('İSA ALKAN'), 'İsa Alkan');
    expect(titleCaseTr('DÜZ İŞÇİ'), 'Düz İşçi');
    expect(titleCaseTr('İNŞAAT İŞÇİSİ'), 'İnşaat İşçisi');
    expect(titleCaseTr('ALÇI LEVHA UYG. - USTA'), 'Alçı Levha Uyg. - Usta');
    expect(titleCaseTr('Seramik/Fayans'), 'Seramik/Fayans');
    expect(titleCaseTr('  mehmet fatih  '), 'Mehmet Fatih');
  });

  test('sentenceCaseTr: yalnızca ilk harfi büyütür', () {
    expect(sentenceCaseTr('CEPHE AKSESUAR'), 'Cephe aksesuar');
    expect(
      sentenceCaseTr('HAVALANDIRMA VE ISI YALITIMI'),
      'Havalandırma ve ısı yalıtımı',
    );
    expect(sentenceCaseTr('Trapez Sac'), 'Trapez sac');
  });
}
