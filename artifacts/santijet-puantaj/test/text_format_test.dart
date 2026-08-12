import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_puantaj/core/utils/text_format.dart';
import 'package:santijet_puantaj/domain/entities/daily_report.dart';
import 'package:santijet_puantaj/domain/entities/person.dart';

void main() {
  test('titleCaseTr: Türkçe büyük harfleri başlık biçimine çevirir', () {
    expect(titleCaseTr('İSA ALKAN'), 'İsa Alkan');
    expect(titleCaseTr('DÜZ İŞÇİ'), 'Düz İşçi');
    expect(titleCaseTr('İNŞAAT İŞÇİSİ'), 'İnşaat İşçisi');
    expect(titleCaseTr('ALÇI LEVHA UYG. - USTA'), 'Alçı Levha Uyg. - Usta');
    expect(titleCaseTr('Seramik/Fayans'), 'Seramik/Fayans');
    expect(titleCaseTr('  mehmet fatih  '), 'Mehmet Fatih');
  });

  test('Person.name: kayıtta daima başlık biçimi', () {
    final p = Person(id: '1', projectId: 'p', name: 'İSA ALKAN');
    expect(p.name, 'İsa Alkan');
    expect(
      Person.fromJson({
        'id': '1',
        'projectId': 'p',
        'name': 'mehmet FATİH yılmaz',
      }).name,
      'Mehmet Fatih Yılmaz',
    );
  });

  test('Person meslek/ekip/firma başlık biçimi', () {
    final p = Person(
      id: '1',
      projectId: 'p',
      name: 'Ali',
      profession: 'İNŞAAT İŞÇİSİ',
      team: 'DEMİR',
      company: 'BSD İNŞAAT',
    );
    expect(p.profession, 'İnşaat İşçisi');
    expect(p.team, 'Demir');
    expect(p.company, 'Bsd İnşaat');
  });

  test('sentenceCaseTr: yalnızca ilk harfi büyütür', () {
    expect(sentenceCaseTr('CEPHE AKSESUAR'), 'Cephe aksesuar');
    expect(
      sentenceCaseTr('HAVALANDIRMA VE ISI YALITIMI'),
      'Havalandırma ve ısı yalıtımı',
    );
    expect(sentenceCaseTr('Trapez Sac'), 'Trapez sac');
    expect(sentenceCaseTr('çatıda yalıtım tamamlandı'), 'Çatıda yalıtım tamamlandı');
    expect(sentenceCaseTr('i'), 'İ');
    expect(sentenceCaseTr('• çatıda yalıtım'), '• Çatıda yalıtım');
  });

  test('DailyReportPhoto.caption: kayıtta cümle biçimi', () {
    final photo = DailyReportPhoto(
      id: 'ph1',
      dataBase64: 'YWJj',
      caption: 'çatıda yalıtım işleri tamamlandı',
    );
    expect(photo.caption, 'Çatıda yalıtım işleri tamamlandı');
    expect(
      photo.copyWith(caption: 'BOYA KAPORTA GİRİŞİ').caption,
      'Boya kaporta girişi',
    );
    expect(
      DailyReportPhoto.fromJson({
        'id': 'ph2',
        'dataBase64': 'YWJj',
        'caption': '  elektrik pano montajı  ',
      }).caption,
      'Elektrik pano montajı',
    );
  });
}
