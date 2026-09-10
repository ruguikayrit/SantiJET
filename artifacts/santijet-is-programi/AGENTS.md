# ŞantiJET İş Programı

Bu klasör bağımsız **ŞantiJET İş Programı** ürünüdür.

## Kimlik
- Paket: `santijet_is_programi`
- Uygulama kimliği: `com.santijet.santijet_is_programi`
- Pages yolu: `/is-programi/`
- Commit önekleri: `feat(is-programi):`, `fix(is-programi):`, `docs(is-programi):`

## Sert sınırlar
- Ürün sıfırdan geliştirilir. Başka ŞantiJET ürünlerindeki schedule, gantt,
  iş programı, plan, entity, provider veya ekran akışı okunmaz, taşınmaz,
  kopyalanmaz ve referans alınmaz.
- Ürünün kodu başka `artifacts/santijet-*` ağacına taşınmaz.
- Login, hesap, bulut, abonelik, senkron ve başka ürüne bağlantı eklenmez.
- Yerel Hive kutularının tamamı `isprog_` önekini kullanır; çıplak
  `settings` kutusu açılmaz.
- Alt navigasyon yalnız Program, Takvim ve Özet'tir. Ayarlar sağ üst
  dişlidedir; zil ve avatar yoktur.
- Turuncu staging şeridi ve `flutter-view { top:28px }` kullanılmaz.

## V1 sınırı
CPM, kritik yol, faaliyet bağımlılığı, kaynak dengeleme, çoklu kullanıcı,
içe aktarım köprüsü ve PDF dışa aktarımı kapsam dışıdır.
