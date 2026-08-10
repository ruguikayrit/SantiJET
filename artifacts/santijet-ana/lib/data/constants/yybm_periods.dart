/// YYBM dönem özeti — RN `constants/yybm.ts` bilgisinden (salt okuma portu).
class YybmPeriod {
  const YybmPeriod({
    required this.id,
    required this.year,
    required this.label,
    required this.gazeteNo,
    required this.gazeteDate,
    this.subPeriod,
    this.url,
  });

  final String id;
  final int year;
  final String label;
  final String gazeteNo;
  final String gazeteDate;
  final int? subPeriod;

  /// Açılabilir dış URL (varsa).
  final String? url;
}

const List<YybmPeriod> yybmPeriods = [
  YybmPeriod(
    id: '2020',
    year: 2020,
    label: '2020',
    gazeteNo: '31044',
    gazeteDate: '15 Şubat 2020',
    url: 'https://www.resmigazete.gov.tr/',
  ),
  YybmPeriod(
    id: '2021',
    year: 2021,
    label: '2021',
    gazeteNo: '31389',
    gazeteDate: '27 Şubat 2021',
    url: 'https://www.resmigazete.gov.tr/',
  ),
  YybmPeriod(
    id: '2022/1',
    year: 2022,
    subPeriod: 1,
    label: '2022/1',
    gazeteNo: '31755',
    gazeteDate: '18 Şubat 2022',
    url: 'https://www.resmigazete.gov.tr/',
  ),
  YybmPeriod(
    id: '2022/2',
    year: 2022,
    subPeriod: 2,
    label: '2022/2',
    gazeteNo: '31874',
    gazeteDate: '21 Haziran 2022',
    url: 'https://www.resmigazete.gov.tr/',
  ),
  YybmPeriod(
    id: '2022/3',
    year: 2022,
    subPeriod: 3,
    label: '2022/3',
    gazeteNo: '31952',
    gazeteDate: '13 Eylül 2022',
    url: 'https://www.resmigazete.gov.tr/',
  ),
  YybmPeriod(
    id: '2023/1',
    year: 2023,
    subPeriod: 1,
    label: '2023/1',
    gazeteNo: '32106',
    gazeteDate: '11 Şubat 2023',
    url: 'https://www.resmigazete.gov.tr/',
  ),
  YybmPeriod(
    id: '2023/2',
    year: 2023,
    subPeriod: 2,
    label: '2023/2',
    gazeteNo: '32277',
    gazeteDate: '12 Ağustos 2023',
    url: 'https://www.resmigazete.gov.tr/',
  ),
  YybmPeriod(
    id: '2024',
    year: 2024,
    label: '2024',
    gazeteNo: '32465',
    gazeteDate: '20 Şubat 2024',
    url: 'https://www.resmigazete.gov.tr/',
  ),
  YybmPeriod(
    id: '2025',
    year: 2025,
    label: '2025',
    gazeteNo: '32799',
    gazeteDate: '31 Ocak 2025',
    url: 'https://www.resmigazete.gov.tr/',
  ),
  YybmPeriod(
    id: '2026',
    year: 2026,
    label: '2026',
    gazeteNo: '33157',
    gazeteDate: '3 Şubat 2026',
    url: 'https://www.resmigazete.gov.tr/',
  ),
];
