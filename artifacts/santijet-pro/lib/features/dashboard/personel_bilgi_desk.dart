part of 'dashboard_screen.dart';

/// Personel kaydının okuma sayfası. Liste ile aynı masanın içindedir;
/// kayıt bellekteki satırdan gelir, ayrı depo açılmaz.
class _PersonelBilgiDesk extends StatelessWidget {
  const _PersonelBilgiDesk({required this.kayit, required this.onBack});

  final _PersonelKayit kayit;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _ModulDeskUst(
          title: 'Personel',
          moduleIcon: _ModulDeskMark.sahaIcon,
          moduleColor: _ModulDeskMark.sahaColor,
          backKey: const Key('personel-bilgi-back'),
          onBack: onBack,
          backLabel: 'Personel',
        ),
        const SizedBox(height: 16),
        _PersonelBilgiBaslik(kayit: kayit),
        const SizedBox(height: 14),
        _PersonelBilgiKarti(
          title: 'Görev',
          rows: [
            _PersonelBilgiSatir(icon: Icons.groups_outlined, label: 'Ekip', value: kayit.ekip),
            _PersonelBilgiSatir(icon: Icons.apartment_outlined, label: 'Firma', value: kayit.firma),
            _PersonelBilgiSatir(icon: Icons.badge_outlined, label: 'Ünvan', value: kayit.unvan),
          ],
        ),
        const SizedBox(height: 10),
        _PersonelBilgiKarti(
          title: 'Tarihler',
          rows: [
            _PersonelBilgiSatir(icon: Icons.login, label: 'İşe giriş', value: kayit.giris),
            _PersonelBilgiSatir(icon: Icons.logout, label: 'İşten ayrılış', value: kayit.cikis ?? '—'),
            if (kayit.dogum != null) _PersonelBilgiSatir(icon: Icons.cake_outlined, label: 'Doğum', value: kayit.dogum!),
          ],
        ),
        if (kayit.telefon != null) ...[
          const SizedBox(height: 10),
          _PersonelBilgiKarti(
            title: 'İletişim',
            rows: [
              _PersonelBilgiSatir(icon: Icons.phone_outlined, label: 'Telefon', value: kayit.telefon!),
            ],
          ),
        ],
        if (kayit.iban != null) ...[
          const SizedBox(height: 10),
          _PersonelBilgiKarti(
            title: 'Ödeme',
            rows: [
              _PersonelBilgiSatir(icon: Icons.credit_card_outlined, label: 'IBAN', value: kayit.iban!),
            ],
          ),
        ],
        if (kayit.tc != null) ...[
          const SizedBox(height: 10),
          _PersonelBilgiKarti(
            title: 'Kimlik',
            rows: [
              _PersonelBilgiSatir(icon: Icons.badge_outlined, label: 'T.C. kimlik', value: kayit.tc!),
            ],
          ),
        ],
        if (kayit.adres != null || kayit.notlar != null) ...[
          const SizedBox(height: 10),
          _PersonelBilgiKarti(
            title: 'Adres ve notlar',
            rows: [
              if (kayit.adres != null) _PersonelBilgiSatir(icon: Icons.location_on_outlined, label: 'Adres', value: kayit.adres!),
              if (kayit.notlar != null) _PersonelBilgiSatir(icon: Icons.notes_outlined, label: 'Notlar', value: kayit.notlar!),
            ],
          ),
        ],
      ],
    );
  }
}

class _PersonelBilgiBaslik extends StatelessWidget {
  const _PersonelBilgiBaslik({required this.kayit});

  final _PersonelKayit kayit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: kayit.color, shape: BoxShape.circle),
          child: Text(
            kayit.initials,
            style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kayit.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 26, color: ProColors.text),
              ),
              Text(
                kayit.calisan ? 'Çalışan' : 'Ayrılan',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: ProColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PersonelBilgiKarti extends StatelessWidget {
  const _PersonelBilgiKarti({required this.title, required this.rows});

  final String title;
  final List<_PersonelBilgiSatir> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 16, color: ProColors.text),
          ),
          const SizedBox(height: 6),
          for (final row in rows) row,
        ],
      ),
    );
  }
}

class _PersonelBilgiSatir extends StatelessWidget {
  const _PersonelBilgiSatir({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          SizedBox(
            width: 108,
            child: Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: ProColors.textMuted)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: ProColors.text)),
          ),
        ],
      ),
    );
  }
}
