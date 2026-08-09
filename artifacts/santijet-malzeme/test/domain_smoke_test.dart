import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_malzeme/domain/entities/kesif_line.dart';
import 'package:santijet_malzeme/domain/entities/kesif_snapshot.dart';
import 'package:santijet_malzeme/domain/enums/main_discipline.dart';
import 'package:santijet_malzeme/domain/enums/request_status.dart';

void main() {
  test('KesifSnapshot groups by discipline and subgroup', () {
    final snap = KesifSnapshot(
      id: 'k1',
      projectId: 'p1',
      name: 'Demo',
      lines: const [
        KesifLine(
          id: 'a',
          pozNo: '1',
          tanim: 'Seramik',
          birim: 'm²',
          miktar: 10,
          anaGrup: MainDiscipline.insaat,
          altGrup: 'Kaplama / seramik',
        ),
        KesifLine(
          id: 'b',
          pozNo: '2',
          tanim: 'Kablo',
          birim: 'm',
          miktar: 20,
          anaGrup: MainDiscipline.elektrik,
          altGrup: 'Pano / kablo',
        ),
      ],
    );

    final tree = snap.groupedTree();
    expect(tree[MainDiscipline.insaat]!['Kaplama / seramik']!.length, 1);
    expect(tree[MainDiscipline.elektrik]!['Pano / kablo']!.first.pozNo, '2');
  });

  test('RequestStatus labels', () {
    expect(RequestStatus.teklifte.label, 'Teklifte');
    expect(RequestStatus.tryParse('kismi'), RequestStatus.kismi);
  });
}
