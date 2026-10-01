import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_pro/app.dart';
import 'package:santijet_pro/modules/pro_module.dart';

Future<void> _ac(WidgetTester tester) async {
  await tester.pumpWidget(const SantijetProApp());
  await tester.pump(const Duration(milliseconds: 1700));
  await tester.pumpAndSettle();
}

void main() {
  test('modül listesi Pro kararlarıyla uyumlu', () {
    final ids = ProModule.catalog.map((module) => module.id).toList();
    expect(ids, [
      'saha',
      'beton',
      'demir',
      'malzeme',
      'is-programi',
      'maliyet',
      'kasa',
    ]);
    expect(ids, isNot(contains('muhendis')));
    expect(ids, isNot(contains('celik')));
    expect(ids, isNot(contains('tahvil')));
  });

  testWidgets('açılış ekranı PRO markasını gösterir', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SantijetProApp());
    expect(find.text('PRO'), findsOneWidget);
    expect(find.text('Metraj'), findsNothing);
    expect(find.byType(Image), findsWidgets);

    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle();
    expect(find.text('Metraj'), findsWidgets);
  });

  testWidgets('dashboard modülleri gösterir', (tester) async {
    tester.view.physicalSize = const Size(800, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _ac(tester);
    expect(find.text('Metraj'), findsWidgets);
    expect(find.text('Süre'), findsOneWidget);
    expect(find.text('Adam-gün'), findsOneWidget);
    expect(find.text('Planlanan döküm'), findsOneWidget);
    expect(find.text('Bugünkü döküm'), findsNothing);
    expect(find.text('Onay bekleyen'), findsOneWidget);
    expect(find.text('Güncel kasa'), findsNothing);
    expect(find.text('Planlanan maliyet'), findsNothing);
    expect(find.text('Toplam gelir'), findsNothing);
    expect(find.text('Ortalama ilerleme'), findsOneWidget);
    expect(find.text('Genel proje ilerleme'), findsOneWidget);
    expect(find.text('Verim özeti'), findsOneWidget);
    expect(find.text('Finansal özet'), findsOneWidget);
    expect(find.text('Teknik özet'), findsOneWidget);
    expect(find.text('İNŞAAT'), findsOneWidget);
    expect(find.text('ELEKTRİK'), findsOneWidget);
    expect(find.text('MEKANİK'), findsOneWidget);
    expect(find.text('Kasa'), findsOneWidget);
    expect(find.text('MODÜLLER'), findsNothing);
    expect(find.text('Saha'), findsNothing);
    expect(find.text('MÜHENDİS'), findsNothing);
    expect(find.text('Birim'), findsNothing);

    await tester.tap(find.text('Raporlar'));
    await tester.pumpAndSettle();
    expect(find.text('Maliyet Dağılımı'), findsOneWidget);
    expect(find.text('Günlük Rapor'), findsOneWidget);
    await tester.tap(find.byKey(const Key('report-open-gunluk')));
    await tester.pumpAndSettle();
    expect(find.text('Şantiye durumunu tek ekranda takip edin.'), findsOneWidget);
    expect(find.text('Raporu Kaydet'), findsOneWidget);
    expect(find.text('Yapılan İmalatlar'), findsOneWidget);
    await tester.tap(find.byKey(const Key('gunluk-rapor-back')));
    await tester.pumpAndSettle();
    expect(find.text('Demir Raporu'), findsOneWidget);
    await tester.tap(find.text('Saha'));
    await tester.pumpAndSettle();
    expect(find.text('Günlük Rapor'), findsOneWidget);
    expect(find.text('Demir Raporu'), findsNothing);
    await tester.tap(find.text('Ana Sayfa'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Menü'));
    await tester.pumpAndSettle();
    expect(find.text('Proje Yönetimi'), findsOneWidget);
    expect(find.text('Uğur Tiryaki'), findsOneWidget);
    expect(find.text('Çıkış Yap'), findsOneWidget);
    expect(find.text('Birim'), findsNothing);

    await tester.tap(find.byKey(const Key('quick-add')));
    await tester.pumpAndSettle();
    expect(find.text('Modüller'), findsNWidgets(2));
    expect(find.text('Saha'), findsOneWidget);
    expect(find.text('Tahvil'), findsNothing);
    expect(find.text('Planlanan döküm'), findsNothing);

    await tester.tap(find.byKey(const Key('module-saha')));
    await tester.pumpAndSettle();
    expect(find.text('Saha operasyonlarını kolayca yönetin'), findsOneWidget);
    expect(find.text('Bugünkü Durum'), findsNothing);
    expect(find.text('Saha Genel'), findsNothing);
    expect(find.text('Günlük İmalatlar'), findsNothing);
    expect(find.text('Görevler'), findsWidgets);
    expect(find.text('Saha Turu'), findsOneWidget);
    expect(find.text('Fotoğraf'), findsNothing);
    expect(find.text('Malzeme'), findsWidgets);
    expect(find.text('Günlük Rapor'), findsWidgets);
    expect(find.text('İmalat'), findsWidgets);
    await tester.tap(find.byKey(const Key('saha-open-daily-report')));
    await tester.pump();
    expect(find.text('Günlük Rapor daha sonra eklenecek.'), findsOneWidget);
    expect(find.textContaining('github.io'), findsNothing);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saha-open-imalat')));
    await tester.pumpAndSettle();
    expect(find.text('İmalat Kaydı Ekle'), findsOneWidget);
    await tester.tap(find.byKey(const Key('imalat-back')));
    await tester.pumpAndSettle();
    expect(find.text('Saha operasyonlarını kolayca yönetin'), findsOneWidget);

    await tester.tap(find.byKey(const Key('quick-add')));
    await tester.pumpAndSettle();
    expect(find.text('Modüller'), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('quick-add')));
    await tester.pumpAndSettle();
    expect(find.text('Modüller'), findsOneWidget);
    expect(find.text('Planlanan döküm'), findsOneWidget);
    expect(find.text('Bugünkü döküm'), findsNothing);
  });

  testWidgets('saha masası puantaj ekranını açar', (tester) async {
    tester.view.physicalSize = const Size(800, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _ac(tester);
    await tester.tap(find.byKey(const Key('quick-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('module-saha')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saha-open-puantaj')));
    await tester.pumpAndSettle();

    expect(find.text('Ekip ekip günlük puantaj özeti.'), findsOneWidget);
    expect(find.text('Günlük'), findsOneWidget);
    expect(find.text('Pzt'), findsOneWidget);
    expect(find.text('Paz'), findsOneWidget);
    expect(find.text('Ekip Bazlı Puantaj (Tümü)'), findsOneWidget);
    expect(find.text('Alçıpan Ekibi'), findsOneWidget);
    expect(find.text('Puantajı Kaydet'), findsNothing);
    expect(find.text('Ahmet Yılmaz'), findsNothing);

    await tester.tap(find.text('Haftalık'));
    await tester.pumpAndSettle();
    expect(find.text('Ekiplerin haftalık puantaj özeti.'), findsOneWidget);
    expect(find.text('Haftalık Toplam'), findsOneWidget);
    expect(find.text('Detaylı Raporu Görüntüle'), findsOneWidget);
    expect(find.text('İstanbul Residence'), findsNothing);
    expect(find.text('A Blok'), findsNothing);
    expect(find.text('Alçıpan'), findsWidgets);

    await tester.tap(find.text('Personel'));
    await tester.pumpAndSettle();
    expect(find.text('Personel bazlı haftalık puantaj.'), findsOneWidget);
    expect(find.text('Hafta Özeti (Tüm Personel)'), findsOneWidget);
    expect(find.text('Mehmet Arslan'), findsOneWidget);
    expect(find.text('Personel ara...'), findsOneWidget);

    await tester.tap(find.text('Günlük'));
    await tester.pumpAndSettle();
    expect(find.text('Ekip Bazlı Puantaj (Tümü)'), findsOneWidget);

    expect(find.textContaining('github.io'), findsNothing);

    await tester.tap(find.text('Alçıpan (5)'));
    await tester.pumpAndSettle();
    expect(find.text('Personel bazlı günlük puantaj.'), findsOneWidget);
    expect(find.text('Mehmet Arslan'), findsOneWidget);
    expect(find.text('Personel Ekle'), findsOneWidget);
    expect(find.textContaining('Puantaj otomatik olarak kaydedildi.'), findsOneWidget);
    expect(find.text('Pzt'), findsOneWidget);
    expect(find.text('Boya Ekibi'), findsNothing);

    await tester.tap(find.text('Boya (4)'));
    await tester.pumpAndSettle();
    expect(find.text('Boya Ekibi'), findsOneWidget);
    expect(find.text('Kemal Aydın'), findsOneWidget);
    expect(find.text('Mehmet Arslan'), findsNothing);

    await tester.tap(find.text('Tümü (30)'));
    await tester.pumpAndSettle();
    expect(find.text('Ekip Bazlı Puantaj (Tümü)'), findsOneWidget);
    expect(find.text('Pzt'), findsOneWidget);

    await tester.tap(find.text('Aylık'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('puantaj-ay-sec')), findsOneWidget);
    await tester.tap(find.byKey(const Key('puantaj-ay-sec')));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Ekiplerin aylık puantaj özeti.'), findsOneWidget);
    expect(find.text('Aylık Dağılım'), findsOneWidget);
    final today = DateTime.now();
    final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
    expect(find.text('${5 * daysInMonth}'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
    expect(find.text('İstanbul Residence'), findsNothing);
    expect(find.text('A Blok'), findsNothing);

    await tester.tap(find.text('Personel'));
    await tester.pumpAndSettle();
    expect(find.text('Personel bazlı aylık puantaj.'), findsOneWidget);
    expect(find.text('Ay Özeti (Tüm Personel)'), findsOneWidget);
    expect(find.text('Mehmet Arslan'), findsOneWidget);
    expect(find.textContaining('30 kişi'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);

    await tester.tap(find.byKey(const Key('puantaj-back')));
    await tester.pumpAndSettle();
    expect(find.text('Saha operasyonlarını kolayca yönetin'), findsOneWidget);
    expect(find.text('Bugünkü Durum'), findsNothing);
    expect(find.text('Saha Genel'), findsNothing);
    expect(find.text('Günlük İmalatlar'), findsNothing);
  });

  testWidgets('saha turu ekranı görseli gösterir', (tester) async {
    tester.view.physicalSize = const Size(800, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _ac(tester);
    await tester.tap(find.byKey(const Key('quick-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('module-saha')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saha-open-saha-turu')));
    await tester.pumpAndSettle();

    expect(find.text('Sahadaki durumu gözlemle, tespit et, kaydet.'), findsOneWidget);
    expect(find.text('26 Eylül 2026'), findsOneWidget);
    expect(find.text('Cuma'), findsOneWidget);
    expect(find.text('Tur Geçmişi'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Toplam Tespit'), findsOneWidget);
    expect(find.text('Açık'), findsOneWidget);
    expect(find.text('Devam Ediyor'), findsOneWidget);
    expect(find.text('Tamamlandı'), findsWidgets);
    expect(find.text('Yeni Saha Turu Başlat'), findsOneWidget);
    expect(find.text('Son Turlar'), findsOneWidget);
    expect(find.text('A Blok Genel Saha Turu'), findsOneWidget);
    expect(find.text('B Blok İç Mekan Turu'), findsOneWidget);
    expect(find.text('Şantiye Geneli Güvenlik Turu'), findsOneWidget);
    expect(find.text('A Blok - 3. Kat Mekanik Kontrol'), findsOneWidget);
    expect(find.text('8 tespit'), findsOneWidget);
    expect(find.textContaining('github.io'), findsNothing);

    await tester.tap(find.byKey(const Key('saha-turu-yeni')));
    await tester.pumpAndSettle();
    expect(find.text('Gözlem'), findsOneWidget);
    expect(find.text('Tespit'), findsOneWidget);
    expect(find.text('İstanbul Residence'), findsOneWidget);
    expect(find.text('A Blok > 3. Kat > Daire 12'), findsOneWidget);
    expect(find.text('Alçıpan'), findsOneWidget);
    expect(find.text('Alçıpan imalatları devam ediyor. Genel durum uygun.'), findsOneWidget);
    expect(find.text('47/500'), findsOneWidget);
    expect(find.text('3/10'), findsOneWidget);
    expect(find.text('Fotoğraf\nEkle'), findsOneWidget);
    expect(find.text('Gözlemi Kaydet'), findsOneWidget);
    expect(find.text('Ana Sayfa'), findsNothing);
    expect(find.text('Göreve Dönüştür'), findsNothing);

    await tester.tap(find.byKey(const Key('saha-turu-tespit')));
    await tester.pumpAndSettle();
    expect(find.text('Alçıpan derz uygulaması eksik.\n2 bölgede tespit edildi.'), findsOneWidget);
    expect(find.text('48/500'), findsOneWidget);
    expect(find.text('Göreve Dönüştür'), findsOneWidget);
    expect(find.text('Göreve Dönüştürme'), findsNothing);
    expect(find.text('Tespiti Kaydet'), findsOneWidget);
    expect(find.text('Gözlemi Kaydet'), findsNothing);

    await tester.tap(find.byKey(const Key('saha-turu-goreve-donustur')));
    await tester.pumpAndSettle();
    expect(find.text('Görev Oluştur - Özet'), findsOneWidget);
    expect(find.text('Alçıpan derz eksiklerini tamamla'), findsOneWidget);
    expect(find.text('Alçıpan Ekibi'), findsOneWidget);
    expect(find.text('28 Eylül 2026'), findsOneWidget);
    expect(find.text('Yüksek'), findsOneWidget);
    expect(find.text('68/500'), findsOneWidget);
    expect(find.text('Görevi Oluştur ve Kaydet'), findsOneWidget);

    await tester.tap(find.byKey(const Key('gorev-ozet-geri')));
    await tester.pumpAndSettle();
    expect(find.text('Tespiti Kaydet'), findsOneWidget);

    await tester.tap(find.byKey(const Key('yeni-saha-turu-back')));
    await tester.pumpAndSettle();
    expect(find.text('Yeni Saha Turu Başlat'), findsOneWidget);

    await tester.tap(find.byKey(const Key('saha-turu-back')));
    await tester.pumpAndSettle();
    expect(find.text('Saha operasyonlarını kolayca yönetin'), findsOneWidget);
  });

  testWidgets('yeni saha turu telefon genişliğinde taşmaz', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _ac(tester);
    await tester.tap(find.byKey(const Key('quick-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('module-saha')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saha-open-saha-turu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saha-turu-yeni')));
    await tester.pumpAndSettle();
    expect(find.text('Gözlemi Kaydet'), findsOneWidget);
    await tester.tap(find.byKey(const Key('saha-turu-tespit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saha-turu-goreve-donustur')));
    await tester.pumpAndSettle();
    expect(find.text('Görev Oluştur - Özet'), findsOneWidget);
  });

  testWidgets('demo yükle ana sayfayı doldurur', (tester) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _ac(tester);
    expect(find.text('Henüz proje yok'), findsNothing);
    expect(find.text('İstanbul Residence'), findsWidgets);
    expect(find.text('%62'), findsWidgets);

    await tester.tap(find.text('Menü'));
    await tester.pumpAndSettle();
    expect(find.text('Demo yüklü'), findsOneWidget);

    await tester.tap(find.byKey(const Key('menu-demo-load')));
    await tester.pump();
    expect(find.text('Demo veriler yüklendi. Aktif proje: İstanbul Residence.'), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('İstanbul Residence'), findsWidgets);
    expect(find.text('Henüz proje yok'), findsNothing);
    expect(find.text('%62'), findsWidgets);
    expect(find.textContaining('gün'), findsWidgets);
    expect(find.text('4.180'), findsOneWidget);
    expect(find.text('%71'), findsOneWidget);
    expect(find.text('%54'), findsOneWidget);
    expect(find.text('%38'), findsOneWidget);
    expect(find.text('128 M₺'), findsOneWidget);
    expect(find.text('4.800 m³'), findsOneWidget);
    expect(find.text('2.960 m³'), findsOneWidget);
    expect(find.text('Bugünkü döküm'), findsNothing);
    expect(find.text('42 m³'), findsNothing);
    expect(find.text('6'), findsWidgets);

    await tester.tap(find.text('Menü'));
    await tester.pumpAndSettle();
    expect(find.text('Demo yüklü'), findsOneWidget);
    expect(find.text('İstanbul Residence'), findsWidgets);

    await tester.tap(find.text('Proje Seç'));
    await tester.pumpAndSettle();
    expect(find.text('Tüm projeleri görüntüleyin ve yönetin.'), findsOneWidget);
    expect(find.text('İstanbul Residence'), findsOneWidget);
    expect(find.text('Ankara Plaza'), findsOneWidget);
    expect(find.byKey(const Key('project-add')), findsOneWidget);

    await tester.tap(find.byKey(const Key('quick-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('module-saha')));
    await tester.pumpAndSettle();
    expect(find.text('İstanbul Residence'), findsWidgets);
    await tester.tap(find.byKey(const Key('saha-open-saha-turu')));
    await tester.pumpAndSettle();
    expect(find.text('12'), findsOneWidget);
    expect(find.text('A Blok Genel Saha Turu'), findsOneWidget);
    await tester.tap(find.byKey(const Key('saha-turu-yeni')));
    await tester.pumpAndSettle();
    expect(find.text('İstanbul Residence'), findsOneWidget);
    expect(find.text('A Blok > 3. Kat > Daire 12'), findsOneWidget);
  });

  testWidgets('saha masası personel ekranını açar', (tester) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _ac(tester);
    await tester.tap(find.byKey(const Key('quick-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('module-saha')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saha-open-personel')));
    await tester.pumpAndSettle();

    expect(find.text('Personel'), findsOneWidget);
    expect(find.text('Ekip yönetimi ve personel bilgileri.'), findsOneWidget);
    expect(find.text('Çalışan (8)'), findsNothing);
    expect(find.text('Ayrılan (4)'), findsNothing);
    expect(find.text('Personel Ekle'), findsNothing);
    expect(find.byKey(const Key('personel-open-app')), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz), findsNothing);
    expect(find.text('İstanbul Residence'), findsNothing);
    expect(find.text('28 Personel'), findsNothing);
    expect(find.text('Mehmet Arslan'), findsOneWidget);
    expect(find.text('Kemal Aydın'), findsOneWidget);
    expect(find.text('Alçıpan Ekibi'), findsWidgets);
    expect(find.text('ABC Yapı Ltd. Şti.'), findsWidgets);
    expect(find.text('03.01.2026'), findsNothing);
    expect(find.text('Ahmet Yılmaz'), findsNothing);
    expect(find.text('Tüm Personel'), findsNothing);

    await tester.tap(find.byKey(const Key('personel-row-Mehmet Arslan')));
    await tester.pumpAndSettle();
    expect(find.text('Görev'), findsOneWidget);
    expect(find.text('İşe giriş'), findsOneWidget);
    expect(find.text('İşten ayrılış'), findsOneWidget);
    expect(find.text('03.01.2026'), findsOneWidget);
    expect(find.text('Alçıpan Ekibi'), findsOneWidget);
    expect(find.text('ABC Yapı Ltd. Şti.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('personel-bilgi-back')));
    await tester.pumpAndSettle();
    expect(find.text('03.01.2026'), findsNothing);
    expect(find.text('Kemal Aydın'), findsOneWidget);

    await tester.tap(find.byKey(const Key('personel-open-app')));
    await tester.pumpAndSettle();
    expect(find.text('Kayıt bu uygulamada henüz tutulmuyor.'), findsNothing);
    expect(find.text('Yeni personel bilgilerini girin.'), findsOneWidget);
    expect(find.text('Temel Bilgiler'), findsOneWidget);
    expect(find.text('Çalışma Bilgileri'), findsOneWidget);
    expect(find.textContaining('Kimlik Bilgileri'), findsOneWidget);
    expect(find.text('Vazgeç'), findsOneWidget);
    expect(find.text('Kayıt çalışan listesine eklenir.'), findsNothing);
    await tester.tap(find.byKey(const Key('personel-ekle-kaydet')));
    await tester.pumpAndSettle();
    expect(find.text('Ad Soyad gerekli.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('personel-ekle-ad')), 'Ayşe Demir');
    await tester.tap(find.byKey(const Key('personel-ekle-meslek')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('İşçi').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('personel-ekle-ekip')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alçıpan Ekibi').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('personel-ekle-firma')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ABC Yapı Ltd. Şti.').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('personel-ekle-kaydet')));
    await tester.pumpAndSettle();
    expect(find.text('Ayşe Demir'), findsOneWidget);
    expect(find.text('Mehmet Arslan'), findsOneWidget);
    expect(find.textContaining('github.io'), findsNothing);

    await tester.tap(find.byKey(const Key('personel-row-Ayşe Demir')));
    await tester.pumpAndSettle();
    expect(find.text('Alçıpan Ekibi'), findsOneWidget);
    expect(find.text('ABC Yapı Ltd. Şti.'), findsOneWidget);
    expect(find.text('İşe giriş'), findsOneWidget);
    await tester.tap(find.byKey(const Key('personel-bilgi-back')));
    await tester.pumpAndSettle();
    expect(find.text('Ayşe Demir'), findsOneWidget);

    await tester.tap(find.byKey(const Key('personel-back')));
    await tester.pumpAndSettle();
    expect(find.text('Saha operasyonlarını kolayca yönetin'), findsOneWidget);
    expect(find.text('Bugünkü Durum'), findsNothing);
    expect(find.text('Saha Genel'), findsNothing);
    expect(find.text('Günlük İmalatlar'), findsNothing);
  });

  testWidgets('saha masası görevler ekranını açar', (tester) async {
    tester.view.physicalSize = const Size(800, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _ac(tester);
    await tester.tap(find.byKey(const Key('quick-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('module-saha')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saha-open-gorevler')));
    await tester.pumpAndSettle();

    expect(find.text('Görev Listesi'), findsOneWidget);
    expect(find.text('Toplam Görev'), findsOneWidget);
    expect(find.text('Devam ediyor'), findsOneWidget);
    expect(find.textContaining('Yapılacak → Başladı'), findsOneWidget);
    expect(find.text('Beton Dökümü'), findsNothing);

    await tester.tap(find.text('Kanban'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Yapılacak, Başladı'), findsOneWidget);

    await tester.tap(find.byKey(const Key('gorevler-open-app')));
    await tester.pump();
    expect(find.text('Kayıt bu uygulamada henüz tutulmuyor.'), findsOneWidget);
    expect(find.textContaining('github.io'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('Görev Listesi'), findsOneWidget);

    await tester.tap(find.byKey(const Key('gorevler-back')));
    await tester.pumpAndSettle();
    expect(find.text('Saha operasyonlarını kolayca yönetin'), findsOneWidget);
    expect(find.text('Bugünkü Durum'), findsNothing);
    expect(find.text('Saha Genel'), findsNothing);
    expect(find.text('Günlük İmalatlar'), findsNothing);
  });

  testWidgets('saha masası günlük imalat ekranını açar', (tester) async {
    tester.view.physicalSize = const Size(800, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _ac(tester);
    await tester.tap(find.byKey(const Key('quick-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('module-saha')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saha-open-imalat')));
    await tester.pumpAndSettle();

    expect(find.text('İmalat kaydı'), findsOneWidget);
    expect(find.text('Devam Ediyor'), findsWidgets);
    expect(find.text('Geçmiş Kayıtlar'), findsOneWidget);

    await tester.tap(find.text('Bu hafta'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Demir'));
    await tester.pumpAndSettle();
    expect(find.text('Bu kategoride kayıt yok.'), findsOneWidget);
    await tester.tap(find.text('Tümü'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('imalat-open-app')));
    await tester.pump();
    expect(find.text('Kayıt bu uygulamada henüz tutulmuyor.'), findsOneWidget);
    expect(find.textContaining('github.io'), findsNothing);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('imalat-back')));
    await tester.pumpAndSettle();
    expect(find.text('Saha operasyonlarını kolayca yönetin'), findsOneWidget);
    expect(find.text('Bugünkü Durum'), findsNothing);
    expect(find.text('Saha Genel'), findsNothing);
    expect(find.text('Günlük İmalatlar'), findsNothing);
  });

  testWidgets('saha masası iş makineleri ekranını açar', (tester) async {
    tester.view.physicalSize = const Size(800, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _ac(tester);
    await tester.tap(find.byKey(const Key('quick-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('module-saha')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saha-open-makine')));
    await tester.pumpAndSettle();

    expect(find.text('Makine Listesi'), findsOneWidget);
    expect(find.text('Toplam Kayıt'), findsOneWidget);
    expect(find.text('İş makinesi'), findsWidgets);
    expect(find.text('Vasıta'), findsWidgets);
    expect(find.textContaining('Günlük raporda İş makinesi'), findsOneWidget);

    await tester.tap(find.text('Operatörler'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Operatör atamaları'), findsOneWidget);

    await tester.tap(find.byKey(const Key('makine-open-app')));
    await tester.pump();
    expect(find.text('Kayıt bu uygulamada henüz tutulmuyor.'), findsOneWidget);
    expect(find.textContaining('github.io'), findsNothing);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('makine-back')));
    await tester.pumpAndSettle();
    expect(find.text('Saha operasyonlarını kolayca yönetin'), findsOneWidget);
    expect(find.text('Bugünkü Durum'), findsNothing);
    expect(find.text('Saha Genel'), findsNothing);
    expect(find.text('Günlük İmalatlar'), findsNothing);
  });

  testWidgets('saha masası malzeme ekranını açar', (tester) async {
    tester.view.physicalSize = const Size(800, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _ac(tester);
    await tester.tap(find.byKey(const Key('quick-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('module-saha')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saha-open-malzeme')));
    await tester.pumpAndSettle();

    expect(find.text('Gelen Malzeme'), findsWidgets);
    expect(find.text('Stoktaki Toplam'), findsOneWidget);
    expect(find.text('Son Gelen Malzemeler'), findsOneWidget);
    expect(find.text('Çimento'), findsNothing);
    expect(find.text('İstanbul Residence'), findsOneWidget);

    await tester.tap(find.text('Stok Durumu'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Onay bekleyen'), findsOneWidget);

    await tester.tap(find.byKey(const Key('malzeme-open-gelen')));
    await tester.pump();
    expect(find.text('Kayıt bu uygulamada henüz tutulmuyor.'), findsOneWidget);
    expect(find.textContaining('github.io'), findsNothing);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('malzeme-back')));
    await tester.pumpAndSettle();
    expect(find.text('Saha operasyonlarını kolayca yönetin'), findsOneWidget);
    expect(find.text('Bugünkü Durum'), findsNothing);
    expect(find.text('Saha Genel'), findsNothing);
    expect(find.text('Günlük İmalatlar'), findsNothing);
  });

  testWidgets('modül kutusu eski uygulamayı açmaz', (tester) async {
    tester.view.physicalSize = const Size(800, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _ac(tester);
    await tester.tap(find.byKey(const Key('quick-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('module-demir')));
    await tester.pumpAndSettle();

    expect(find.text('Gelen Demir'), findsOneWidget);
    expect(find.text('Saha Sayım'), findsOneWidget);
    expect(find.text('Teslim tonajı gerçekleşen imalat sayılmaz. Tahvil hesabı bu modülde değildir.'), findsOneWidget);
    expect(find.byKey(const Key('pro-return')), findsNothing);
    expect(find.textContaining('github.io'), findsNothing);

    await tester.tap(find.byKey(const Key('modul-bolum-Gelen Demir')));
    await tester.pumpAndSettle();
    expect(find.text('Sahaya gelen çap ve tonaj. Teslim, kullanım değildir.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('modul-kayit')));
    await tester.pump();
    expect(find.text('Kayıt bu uygulamada henüz tutulmuyor.'), findsOneWidget);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('modul-bolum-back')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quick-add')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('module-saha')), findsOneWidget);

    await tester.tap(find.byKey(const Key('module-beton')));
    await tester.pumpAndSettle();
    expect(find.text('Döküm'), findsOneWidget);
    expect(find.text('Test'), findsOneWidget);
    expect(find.text('Dökülen hacim saha imalat satırı değildir. Sipariş tutarı kasa hareketi değildir.'), findsOneWidget);
  });
}
