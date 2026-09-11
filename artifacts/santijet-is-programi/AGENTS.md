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
- Alt navigasyon yalnız Program, Gantt ve Özet'tir. Ayarlar sağ üst
  dişlidedir; zil ve avatar yoktur. Gantt sayfasında yalnız Gantt
  grafiği vardır; liste, filtre ve giriş tablosu yoktur.
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

## Giriş ve izleme
Veri girişi ve takip MS Project Giriş / İzleme tablosuyla aynı kurgudadır.
Program ana sayfası bu iki tablodur; hücreye dokunup yazılır.

- Giriş: Ad, Süre, Başlangıç, Bitiş, Öncüller, Kaynak Adları, WBS,
  kilometre taşı. Bitiş = başlangıç + süre − 1. İş = süre × birim.
- İzleme: % Tamamlanma, Fiili Başlangıç/Bitiş, Fiili/Kalan Süre,
  Fiili/Kalan İş. % yazılınca fiili ve kalan birlikte güncellenir.
  Fiili süre planı aşarsa süre uzar. Kalan süre yazılınca
  süre = fiili + kalan olur.
- Görev tipi sabit birimdir. CPM / öncül hesabı yoktur; öncül metni
  yalnız taşınır.
- MS Project dosyasında Duration, Start, Finish, % Complete, Actual*
  ve Work alanları gider gelir.

## V1 sınırı
CPM, kritik yol hesabı, faaliyet bağımlılığı çözümleme, kaynak dengeleme,
çoklu kullanıcı, satınalma, hakediş bordrosu ve başka ŞantiJET ürünüyle
içe aktarım köprüsü kapsam dışıdır.
