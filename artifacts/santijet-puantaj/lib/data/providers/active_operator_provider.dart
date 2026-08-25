import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/puantaj_date.dart';
import '../../core/utils/text_format.dart';
import '../../domain/entities/person.dart';
import '../../domain/permissions/role_degree.dart';
import 'app_data_provider.dart';
import 'auth_provider.dart';
import 'collaboration_provider.dart';

String _foldName(String raw) {
  final t = titleCaseTr(raw);
  final b = StringBuffer();
  for (final unit in t.runes) {
    final c = String.fromCharCode(unit);
    switch (c) {
      case 'I':
        b.write('ı');
      case 'İ':
        b.write('i');
      case 'Ğ':
        b.write('ğ');
      case 'Ü':
        b.write('ü');
      case 'Ş':
        b.write('ş');
      case 'Ö':
        b.write('ö');
      case 'Ç':
        b.write('ç');
      default:
        b.write(c.toLowerCase());
    }
  }
  return b.toString();
}

/// Oturum açmış kullanıcı = aktif operatör.
///
/// Önce aktif projedeki personelde Ad Soyad eşleşmesi aranır; yoksa üyelik
/// yetkisine göre sentetik personel kaydı üretilir (görev görünürlüğü / atama).
/// Oturum yoksa (yerel demo) projedeki 1. derece personel kullanılır.
final activeOperatorProvider = Provider<Person?>((ref) {
  final user = ref.watch(authProvider).user;
  final project = ref.watch(activeProjectProvider);
  if (project == null) return null;

  final today = PuantajDate.today();
  final people = ref.watch(personnelProvider);

  if (user == null) {
    for (final p in people) {
      if (p.projectId != project.id) continue;
      if (!p.isActiveOn(today)) continue;
      if (RoleDegree.isFirstDegree(p)) return p;
    }
    for (final p in people) {
      if (p.projectId == project.id && p.isActiveOn(today)) return p;
    }
    return null;
  }

  final nameKey = _foldName(user.displayName);

  if (nameKey.isNotEmpty) {
    for (final p in people) {
      if (p.projectId != project.id) continue;
      if (!p.isActiveOn(today)) continue;
      if (_foldName(p.name) == nameKey) return p;
    }
  }

  final canEdit = ref.watch(canEditActiveProjectProvider);
  return Person(
    id: user.id,
    projectId: project.id,
    name: user.displayName,
    // Düzenleme yetkisi → 1. derece (görev atayabilir); aksi halde saha.
    profession: canEdit ? 'Şantiye Şefi' : 'Saha Düz İşçi',
  );
});
