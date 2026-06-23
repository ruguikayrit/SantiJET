import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

/// Uygulama başlatma — Demir `bootstrap()` deseniyle hizalı.
///
/// NOT (Faz 9/12): Yerel kalıcılık Hive ile sağlanacaktır (özel analizler,
/// favoriler, son görüntülenenler, keşif, tema). Hive kutu açılışları burada
/// ilgili fazlarda eklenecektir.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SantijetBfaApp()));
}
