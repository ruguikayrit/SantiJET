part of 'dashboard_screen.dart';

/// Pro modül kapağı. Mini uygulama kabuğu kopyalanmaz;
/// her sayfa o modülün kendi kaydını ve sınırını anlatır.
class _ModulKapak {
  const _ModulKapak({
    required this.id,
    required this.title,
    required this.rol,
    required this.sinir,
    required this.icon,
    required this.color,
    required this.kpiEtiket,
    required this.demoDeger,
    required this.bolumler,
  });

  final String id;
  final String title;
  final String rol;
  final String sinir;
  final IconData icon;
  final Color color;
  final List<String> kpiEtiket;
  final List<String>? demoDeger;
  final List<_ModulBolum> bolumler;

  static const katalog = <_ModulKapak>[
    _ModulKapak(
      id: 'genel-imalatlar',
      title: 'Genel İmalatlar',
      rol: 'İş kalemi plan miktarı ve gerçekleşen miktarı tutar. Birim ve ekip buradadır; fiyat yoktur.',
      sinir: 'Beton dökümü ve demir tonajı ayrı kayıttır. Bu sayfa onların yerine geçmez.',
      icon: Icons.construction_outlined,
      color: Color(0xFFEA580C),
      kpiEtiket: ['Plan', 'Gerçekleşen', 'Kalan'],
      demoDeger: null,
      bolumler: [
        _ModulBolum('İş kalemleri', 'Ad, birim, kat', Icons.view_list_outlined, 'Her kalemin plan miktarı ve birimi.'),
        _ModulBolum('Gerçekleşen', 'Günlük miktar', Icons.trending_up, 'Günlük tamamlanan miktar. Stok hareketi yazmaz.'),
        _ModulBolum('Ekipler', 'Kim yaptı', Icons.groups_outlined, 'Kalemi yapan ekip. Puantaj kişi kartı değildir.'),
      ],
    ),
    _ModulKapak(
      id: 'beton',
      title: 'Beton',
      rol: 'Keşif metrajı, sipariş, döküm ve numune aynı projede ayrı kayıtlardır.',
      sinir: 'Dökülen hacim saha imalat satırı değildir. Sipariş tutarı kasa hareketi değildir.',
      icon: _ModulDeskMark.betonIcon,
      color: _ModulDeskMark.betonColor,
      kpiEtiket: ['Planlanan döküm', 'Gerçekleşen döküm', 'Keşif ilerlemesi'],
      demoDeger: _Demo.beton,
      bolumler: [
        _ModulBolum('Keşif', 'Sınıf ve metraj', Icons.square_foot_outlined, 'Beton sınıfına göre keşif miktarı ve kalan.'),
        _ModulBolum('Sipariş', 'Plan m³', Icons.local_shipping_outlined, 'Planlanan hacim, tarih, tedarikçi ve pompa.'),
        _ModulBolum('Döküm', 'Gerçekleşen hacim', Icons.water_drop_outlined, 'Dökülen hacim ve mikser. Siparişle aynı kayıt değildir.'),
        _ModulBolum('Test', 'Numune', Icons.science_outlined, 'Numune ve basınç sonucu. Döküm miktarını değiştirmez.'),
      ],
    ),
    _ModulKapak(
      id: 'demir',
      title: 'Demir',
      rol: 'Sipariş, irsaliye teslimi ve saha sayımı ayrıdır. Kullanılan, teslimden sayılanı düşer.',
      sinir: 'Teslim tonajı gerçekleşen imalat sayılmaz. Tahvil hesabı bu modülde değildir.',
      icon: _ModulDeskMark.demirIcon,
      color: _ModulDeskMark.demirColor,
      kpiEtiket: ['Planlanan tonaj', 'Beklenen kullanım', 'İlerleme'],
      demoDeger: _Demo.demir,
      bolumler: [
        _ModulBolum('Sipariş', 'Çap ve tonaj', Icons.assignment_outlined, 'Donatı siparişi. İrsaliye bu kayda bağlanır.'),
        _ModulBolum('Gelen Demir', 'İrsaliye', Icons.move_to_inbox_outlined, 'Sahaya gelen çap ve tonaj. Teslim, kullanım değildir.'),
        _ModulBolum('Saha Sayım', 'Kalan demir', Icons.fact_check_outlined, 'Sayılan stok. Kullanılan = teslim − sayılan.'),
        _ModulBolum('Analiz', 'Fire', Icons.analytics_outlined, 'Plan, teslim ve sayım sapması. Ayrı bir hesap motoru değildir.'),
      ],
    ),
    _ModulKapak(
      id: 'celik',
      title: 'Çelik',
      rol: 'İmalat modülü: atölye üretimi, sevkiyat ve montaj. Hesap motoru değildir.',
      sinir: 'Birleşim hesabı bu modüle girmez. Kayıt henüz tutulmuyor.',
      icon: Icons.precision_manufacturing_outlined,
      color: Color(0xFF7C3AED),
      kpiEtiket: ['Atölye', 'Sevkiyat', 'Montaj'],
      demoDeger: null,
      bolumler: [
        _ModulBolum('Atölye', 'Üretim', Icons.precision_manufacturing_outlined, 'Atölyede üretilen eleman.'),
        _ModulBolum('Sevkiyat', 'Şantiyeye çıkış', Icons.local_shipping_outlined, 'Sevk edilen eleman. Montaj kaydı değildir.'),
        _ModulBolum('Montaj', 'Yerine konan', Icons.construction_outlined, 'Sahada yerine konan eleman.'),
      ],
    ),
    _ModulKapak(
      id: 'malzeme',
      title: 'Malzeme',
      rol: 'Birim sarfiyat, keşif ihtiyacı, talep, teklif ve teslim.',
      sinir: 'Teslim, stok bakiyesi üretmez. Sahadaki tüketim Saha modülündedir.',
      icon: _ModulDeskMark.malzemeIcon,
      color: _ModulDeskMark.malzemeColor,
      kpiEtiket: ['Onay bekleyen', 'Onaylandı', 'Teslim edildi'],
      demoDeger: _Demo.malzeme,
      bolumler: [
        _ModulBolum('Keşif', 'İhtiyaç', Icons.calculate_outlined, 'Birim sarfiyat çarpı metraj. Stok kartı değildir.'),
        _ModulBolum('Talep', 'Onay', Icons.playlist_add_check_outlined, 'Talep satırı ve onay durumu.'),
        _ModulBolum('Teslim', 'İrsaliye', Icons.inventory_outlined, 'Teslim edilen miktar. Tüketim hareketi yazmaz.'),
        _ModulBolum('Kütüphane', 'Malzeme kartı', Icons.menu_book_outlined, 'Ad, birim ve kategori. Bakiye alanı yoktur.'),
      ],
    ),
    _ModulKapak(
      id: 'satin-alma',
      title: 'Satın Alma',
      rol: 'Tedarikçiden sipariş ve irsaliye. Malzeme talebinin ticari yüzüdür.',
      sinir: 'Birim fiyat analizi ve kasa ödemesi burada tutulmaz.',
      icon: Icons.shopping_cart_outlined,
      color: Color(0xFF16A34A),
      kpiEtiket: ['Tedarikçi', 'Sipariş', 'İrsaliye'],
      demoDeger: null,
      bolumler: [
        _ModulBolum('Tedarikçi', 'Firma', Icons.storefront_outlined, 'Siparişin gittiği firma.'),
        _ModulBolum('Sipariş', 'Verilen', Icons.shopping_bag_outlined, 'Talep satırından türeyen ticari sipariş.'),
        _ModulBolum('İrsaliye', 'Gelen belge', Icons.receipt_long_outlined, 'Teslim belgesi. Kasa çıkışı değildir.'),
      ],
    ),
    _ModulKapak(
      id: 'is-programi',
      title: 'İş Programı',
      rol: 'İş kırılımı, tarihler ve ilerleme. Miktar ve birim bu kayıtta yoktur.',
      sinir: 'Çizelge puantaj kişi kartı değildir. İlerleme, imalat miktarından otomatik yazılmaz.',
      icon: _ModulDeskMark.isProgramiIcon,
      color: _ModulDeskMark.isProgramiColor,
      kpiEtiket: ['Ortalama ilerleme', 'Kalan adam-gün', 'Geciken'],
      demoDeger: _Demo.program,
      bolumler: [
        _ModulBolum('Program', 'İş listesi', Icons.account_tree_outlined, 'Kırılım, süre, ekip sayısı ve öncül.'),
        _ModulBolum('Gantt', 'Çubuk', Icons.bar_chart_outlined, 'Yalnız zaman çizelgesi. Liste bu görünümde yoktur.'),
        _ModulBolum('Özet', 'İlerleme', Icons.pie_chart_outline, 'Ortalama ilerleme ve geciken işler.'),
      ],
    ),
    _ModulKapak(
      id: 'butce',
      title: 'Bütçe',
      rol: 'Planlanan harcama ve sapma. Kasa bakiyesi ve birim fiyat cetveli değildir.',
      sinir: 'Kasadan çıkan para bütçe satırı olmaz. Yaklaşık maliyet sapmayı tek başına doldurmaz.',
      icon: Icons.pie_chart_outline,
      color: Color(0xFFDB2777),
      kpiEtiket: ['Plan', 'Gerçekleşen', 'Sapma'],
      demoDeger: [_Demo.butce, '—', '—'],
      bolumler: [
        _ModulBolum('Plan', 'Ayrılan', Icons.pie_chart_outline, 'Kalem bazında planlanan tutar.'),
        _ModulBolum('Gerçekleşen', 'İşlenen', Icons.show_chart, 'Bütçeye işlenen tutar. Kasa satırı değildir.'),
        _ModulBolum('Sapma', 'Fark', Icons.compare_arrows, 'Plan ile gerçekleşenin farkı.'),
      ],
    ),
    _ModulKapak(
      id: 'maliyet',
      title: 'Maliyet',
      rol: 'Birim fiyat analizi, metraj, keşif ve yaklaşık maliyet. Bu plan fiyattır.',
      sinir: 'Gerçekleşen maliyet defteri, kasa ve bütçe sapması değildir.',
      icon: _ModulDeskMark.maliyetIcon,
      color: _ModulDeskMark.maliyetColor,
      kpiEtiket: ['Birim fiyat', 'Metraj', 'Yaklaşık maliyet'],
      demoDeger: ['—', '—', _Demo.maliyet],
      bolumler: [
        _ModulBolum('Analiz', 'Birim fiyat', Icons.functions, 'Pozun işçilik, malzeme ve ekipman kırılımı.'),
        _ModulBolum('Metraj', 'Miktar', Icons.square_foot_outlined, 'Keşif satırına giren miktar.'),
        _ModulBolum('Keşif', 'Poz cetveli', Icons.list_alt_outlined, 'Poz, birim, miktar ve tutar.'),
        _ModulBolum('Yaklaşık maliyet', 'Plan tutar', Icons.payments_outlined, 'Keşif tutarlarının toplamı. Ödeme değildir.'),
      ],
    ),
    _ModulKapak(
      id: 'kasa',
      title: 'Kasa',
      rol: 'İş avansı gelir ve gider. Güncel kasa, gelirden giderin düşülmesidir.',
      sinir: 'Maliyet tahakkuku ve bütçe sapması değildir. Bir satır ya gelirdir ya gider.',
      icon: _ModulDeskMark.kasaIcon,
      color: _ModulDeskMark.kasaColor,
      kpiEtiket: ['Toplam gelir', 'Toplam gider', 'Güncel kasa'],
      demoDeger: ['—', '—', _Demo.kasa],
      bolumler: [
        _ModulBolum('Kasa', 'Bakiye', Icons.account_balance_wallet_outlined, 'Seçili şantiyenin gelir, gider ve kalanı.'),
        _ModulBolum('Hareketler', 'Satır', Icons.swap_vert, 'Tarih, tedarikçi, açıklama, gelir veya gider.'),
        _ModulBolum('Rapor', 'Dönem', Icons.summarize_outlined, 'Dönem dökümü. Bütçe sapma raporu değildir.'),
      ],
    ),
    _ModulKapak(
      id: 'hakedis',
      title: 'Hakediş',
      rol: 'İşveren hakedişi ve taşeron hakedişi ayrıdır.',
      sinir: 'Kasa tahsilatı ve saha miktarı bu kayda otomatik yazılmaz.',
      icon: Icons.description_outlined,
      color: Color(0xFFDC2626),
      kpiEtiket: ['Hakediş', 'Taşeron', 'Ödeme'],
      demoDeger: [_Demo.hakedis, '—', '—'],
      bolumler: [
        _ModulBolum('İşveren', 'Hak ediş', Icons.apartment_outlined, 'İşverene kesilen hakediş.'),
        _ModulBolum('Taşeron', 'Alt yüklenici', Icons.engineering_outlined, 'Taşerona düzenlenen hakediş.'),
        _ModulBolum('Durum', 'Taslak, onay, ödeme', Icons.flag_outlined, 'Belgenin durumu. Kasa satırı ayrı açılır.'),
      ],
    ),
  ];

  static _ModulKapak byId(String id) => katalog.firstWhere((kapak) => kapak.id == id);
}

class _ModulBolum {
  const _ModulBolum(this.title, this.alt, this.icon, this.kayit);

  final String title;
  final String alt;
  final IconData icon;
  final String kayit;
}

class _ModulHost extends StatelessWidget {
  const _ModulHost({
    required this.id,
    required this.bolum,
    required this.onOpenBolum,
    required this.onBackToKapak,
  });

  final String id;
  final String? bolum;
  final ValueChanged<String> onOpenBolum;
  final VoidCallback onBackToKapak;

  @override
  Widget build(BuildContext context) {
    final kapak = _ModulKapak.byId(id);
    if (bolum == null) {
      return _ModulKapakView(kapak: kapak, onOpenBolum: onOpenBolum);
    }
    final secili = kapak.bolumler.firstWhere((b) => b.title == bolum);
    return _ModulBolumView(kapak: kapak, bolum: secili, onBack: onBackToKapak);
  }
}

class _ModulKapakView extends StatelessWidget {
  const _ModulKapakView({
    required this.kapak,
    required this.onOpenBolum,
  });

  final _ModulKapak kapak;
  final ValueChanged<String> onOpenBolum;

  @override
  Widget build(BuildContext context) {
    final demo = _DemoScope.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _ModulDeskUst(
          title: kapak.title,
          moduleIcon: kapak.icon,
          moduleColor: kapak.color,
        ),
        const SizedBox(height: 10),
        Text(
          kapak.rol,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, height: 1.35, color: ProColors.text),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            for (var i = 0; i < kapak.kpiEtiket.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _ModulKpi(
                  label: kapak.kpiEtiket[i],
                  value: demo && kapak.demoDeger != null ? kapak.demoDeger![i] : '—',
                  color: kapak.color,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: kapak.bolumler.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: 92,
          ),
          itemBuilder: (context, index) {
            final bolum = kapak.bolumler[index];
            return _ModulBolumTile(
              bolum: bolum,
              color: kapak.color,
              onTap: () => onOpenBolum(bolum.title),
            );
          },
        ),
        const SizedBox(height: 14),
        Text(
          kapak.sinir,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 12, height: 1.35, color: ProColors.textMuted),
        ),
      ],
    );
  }
}

class _ModulKpi extends StatelessWidget {
  const _ModulKpi({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 18, color: ProColors.text),
          ),
        ],
      ),
    );
  }
}

class _ModulBolumTile extends StatelessWidget {
  const _ModulBolumTile({required this.bolum, required this.color, required this.onTap});

  final _ModulBolum bolum;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: Key('modul-bolum-${bolum.title}'),
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(bolum.icon, color: color, size: 22),
              const Spacer(),
              Text(
                bolum.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 15, color: ProColors.text),
              ),
              Text(
                bolum.alt,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: ProColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModulBolumView extends StatelessWidget {
  const _ModulBolumView({required this.kapak, required this.bolum, required this.onBack});

  final _ModulKapak kapak;
  final _ModulBolum bolum;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _ModulDeskUst(
          title: bolum.title,
          moduleIcon: kapak.icon,
          moduleColor: kapak.color,
          backKey: const Key('modul-bolum-back'),
          onBack: onBack,
          backLabel: kapak.title,
        ),
        const SizedBox(height: 12),
        Text(
          bolum.kayit,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 14, height: 1.4, color: ProColors.text),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
          decoration: BoxDecoration(
            color: const Color(0xFF121826),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF243044)),
          ),
          child: const Text(
            'Bu kayıt Pro içinde henüz tutulmuyor.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: ProColors.textMuted),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('modul-kayit'),
          style: FilledButton.styleFrom(
            backgroundColor: kapak.color,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => _keepInPro(context),
          child: const Text('Kayıt ekle', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
