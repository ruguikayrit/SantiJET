import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_pro/app.dart';
import 'package:santijet_pro/modules/pro_module.dart';

void main() {
  test('modül listesi Pro kararlarıyla uyumlu', () {
    final ids = ProModule.catalog.map((module) => module.id).toList();
    expect(ids, [
      'saha',
      'beton',
      'demir',
      'tahvil',
      'malzeme',
      'is-programi',
      'maliyet',
      'kasa',
    ]);
    expect(ids, isNot(contains('muhendis')));
    expect(ids, isNot(contains('celik')));
  });

  testWidgets('dashboard modülleri gösterir', (tester) async {
    tester.view.physicalSize = const Size(800, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SantijetProApp());
    expect(find.text('Metraj'), findsWidgets);
    expect(find.text('Süre'), findsOneWidget);
    expect(find.text('Adam-gün'), findsOneWidget);
    expect(find.text('Planlanan döküm'), findsOneWidget);
    expect(find.text('Onay bekleyen'), findsOneWidget);
    expect(find.text('Güncel kasa'), findsOneWidget);
    expect(find.text('Ortalama ilerleme'), findsOneWidget);
    expect(find.text('Verim özeti'), findsOneWidget);
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
    expect(find.text('MODÜLLER'), findsOneWidget);
    expect(find.text('Saha'), findsOneWidget);
    expect(find.text('Tahvil'), findsOneWidget);
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
    expect(find.text('Yeni Günlük İmalat'), findsOneWidget);
    await tester.tap(find.byKey(const Key('imalat-back')));
    await tester.pumpAndSettle();
    expect(find.text('Saha operasyonlarını kolayca yönetin'), findsOneWidget);

    await tester.tap(find.byKey(const Key('quick-add')));
    await tester.pumpAndSettle();
    expect(find.text('MODÜLLER'), findsOneWidget);

    await tester.tap(find.byKey(const Key('quick-add')));
    await tester.pumpAndSettle();
    expect(find.text('MODÜLLER'), findsNothing);
    expect(find.text('Planlanan döküm'), findsOneWidget);
  });

  testWidgets('saha masası puantaj ekranını açar', (tester) async {
    tester.view.physicalSize = const Size(800, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SantijetProApp());
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
    expect(find.text('Ekiplerin aylık puantaj özeti.'), findsOneWidget);
    expect(find.text('Aylık Dağılım'), findsOneWidget);
    final today = DateTime.now();
    final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
    expect(find.text('${5 * daysInMonth}'), findsOneWidget);
    expect(find.text('İstanbul Residence'), findsNothing);
    expect(find.text('A Blok'), findsNothing);

    await tester.tap(find.text('Personel'));
    await tester.pumpAndSettle();
    expect(find.text('Personel bazlı aylık puantaj.'), findsOneWidget);
    expect(find.text('Ay Özeti (Tüm Personel)'), findsOneWidget);
    expect(find.text('Mehmet Arslan'), findsOneWidget);
    expect(find.textContaining('30 kişi'), findsOneWidget);

    await tester.tap(find.byKey(const Key('puantaj-back')));
    await tester.pumpAndSettle();
    expect(find.text('Saha operasyonlarını kolayca yönetin'), findsOneWidget);
    expect(find.text('Bugünkü Durum'), findsNothing);
    expect(find.text('Saha Genel'), findsNothing);
    expect(find.text('Günlük İmalatlar'), findsNothing);
  });

  testWidgets('saha masası personel ekranını açar', (tester) async {
    tester.view.physicalSize = const Size(800, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SantijetProApp());
    await tester.tap(find.byKey(const Key('quick-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('module-saha')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saha-open-personel')));
    await tester.pumpAndSettle();

    expect(find.text('Tüm Personel'), findsOneWidget);
    expect(find.text('Toplam Personel'), findsOneWidget);
    expect(find.text('Mevcut'), findsWidgets);
    expect(find.text('Ekipleri ve saha personelini yönetin'), findsOneWidget);
    expect(find.text('İstanbul Residence'), findsNothing);
    expect(find.text('Ahmet Yılmaz'), findsNothing);

    await tester.tap(find.text('Görevler'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Personel görevleri'), findsOneWidget);

    await tester.tap(find.byKey(const Key('personel-open-app')));
    await tester.pump();
    expect(find.text('Kayıt bu uygulamada henüz tutulmuyor.'), findsOneWidget);
    expect(find.textContaining('github.io'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('Tüm Personel'), findsOneWidget);

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

    await tester.pumpWidget(const SantijetProApp());
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

    await tester.pumpWidget(const SantijetProApp());
    await tester.tap(find.byKey(const Key('quick-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('module-saha')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saha-open-imalat')));
    await tester.pumpAndSettle();

    expect(find.text('Toplam İmalat'), findsOneWidget);
    expect(find.text('Devam eden'), findsOneWidget);
    expect(find.text('Hızlı Kayıt'), findsOneWidget);

    await tester.tap(find.text('Haftalık'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ELEKTRİK'));
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

    await tester.pumpWidget(const SantijetProApp());
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

    await tester.pumpWidget(const SantijetProApp());
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
    expect(find.text('İstanbul Residence'), findsNothing);

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

    await tester.pumpWidget(const SantijetProApp());
    await tester.tap(find.byKey(const Key('quick-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('module-demir')));
    await tester.pump();

    expect(find.text('Kayıt bu uygulamada henüz tutulmuyor.'), findsOneWidget);
    expect(find.byKey(const Key('pro-return')), findsNothing);
    expect(find.textContaining('github.io'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('module-saha')), findsOneWidget);
  });
}
