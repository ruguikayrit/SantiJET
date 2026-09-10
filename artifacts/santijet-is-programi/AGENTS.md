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
  Ayarlar’daki Hesap yalnız cihazdaki ad/unvandır. İş kodu yereldir;
  kod varsa o şantiye açılır, yoksa boş şantiye yazılır.
- Şantiye seçimi Ayarlar → Projelerim’dedir. Program ana sayfasında
  açılır liste yoktur; aktif proje çubuğu Projelerim’e gider.
- Yerel Hive kutularının tamamı `isprog_` önekini kullanır; çıplak
  `settings` kutusu açılmaz. Projeler `isprog_projects` kutusundadır.
- Alt navigasyon yalnız Program, Takvim ve Özet'tir. Ayarlar sağ üst
  dişlidedir; zil ve avatar yoktur.
- Turuncu staging şeridi ve `flutter-view { top:28px }` kullanılmaz.

## MS Project alışverişi
Ürün MS Project ile dosya üzerinden çalışır; canlı bağlantı ya da senkron
yoktur.

- Dışa aktarım: MS Project XML (`.xml`), Excel (`.xlsx`), PDF.
- İçe aktarım: MS Project XML ve Excel. PDF yalnız dışa aktarımdır.
- `.mpp` yazılmaz ve okunmaz. Kullanıcı Project içinde
  "Farklı Kaydet → MS Project XML" ile dosya üretir.
- MSPDI yazımında eleman sırası şemaya uyar; alan eklerken sıra bozulmaz.
- Yazılan takvim yedi günü de çalışma günü sayar. Böylece Project'in
  hesapladığı bitiş tarihleri uygulamadakiyle örtüşür. Bu kural
  değiştirilirse süre alanı da iş gününe göre yeniden hesaplanmalıdır.
- Faaliyetler `ConstraintType 4` (en erken şu tarihte başla) ile yazılır;
  Project planı bozmadan yeniden hesaplar.
- Şantiye, MSPDI'de özet görev adı, Excel'de `Text2` sütunudur.
- Öncül bağı (`predecessors`) yalnız taşınır; uygulama hesaplamaz.
- PDF Türkçe karakterler için Inter'i gömer; yazı tipi yüklenemezse
  bozuk dosya üretmek yerine hata verilir.

## Adam-gün kurgusu
İş programı süredir. Bir imalatın birimi adam-gündür: süre × ekip.

- Plan: imalat adı, başlangıç, süre (gün), ekip (adam). Bitiş süreye göre
  hesaplanır. Form Project sütunlarının kopyası değildir.
- Gerçekleşen: günlük çalışan adam sayısı `isprog_daily_crew` kutusuna
  yazılır. İlerleme yüzdesi bu kayıtlardan doğar.
- Özet: plan AG / gerçek AG / kalan AG. Kalan, işçilik hakedişi ve
  malzeme nakit ihtiyacına işarettir; ödeme veya satınalma tutulmaz.
- MS Project dosyasında süre Duration, ekip atanan kaynak sayısı / Number1
  olarak taşınır. Günlük saha kaydı Project'e yazılmaz.

## V1 sınırı
CPM, kritik yol hesabı, faaliyet bağımlılığı çözümleme, kaynak dengeleme,
çoklu kullanıcı, satınalma, hakediş bordrosu ve başka ŞantiJET ürünüyle
içe aktarım köprüsü kapsam dışıdır.
