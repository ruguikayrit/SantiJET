import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_malzeme/domain/entities/delivery.dart';
import 'package:santijet_malzeme/domain/entities/material_request.dart';
import 'package:santijet_malzeme/domain/entities/request_approvals.dart';
import 'package:santijet_malzeme/domain/entities/kesif_line.dart';
import 'package:santijet_malzeme/domain/entities/kesif_snapshot.dart';
import 'package:santijet_malzeme/domain/entities/unit_consumption.dart';
import 'package:santijet_malzeme/domain/enums/main_discipline.dart';
import 'package:santijet_malzeme/domain/enums/request_status.dart';
import 'package:santijet_malzeme/domain/kesif/material_need_calculator.dart';

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

  test('RequestStatus RN labels and legacy parse', () {
    expect(RequestStatus.pending.label, 'Beklemede');
    expect(RequestStatus.approved.label, 'Onaylandı');
    expect(RequestStatus.delivered.label, 'Teslim Edildi');
    expect(RequestStatus.rejected.label, 'Reddedildi');
    expect(RequestStatus.tryParse('taslak'), RequestStatus.pending);
    expect(RequestStatus.tryParse('kismi'), RequestStatus.approved);
    expect(RequestStatus.tryParse('kapandi'), RequestStatus.delivered);
  });

  test('3 approvals allApproved — Pro RN zinciri', () {
    expect(const RequestApprovals().allApproved, isFalse);
    expect(const RequestApprovals(sef: true, mudur: true).allApproved, isFalse);
    expect(
      const RequestApprovals(sef: true, mudur: true, satinAlma: true)
          .allApproved,
      isTrue,
    );
  });

  test('MaterialRequest single-item JSON roundtrip + legacy lines', () {
    final req = MaterialRequest(
      id: 'r1',
      projectId: 'p1',
      name: 'İç cephe boyası',
      category: 'Boyalar',
      unit: 'm²',
      quantity: 1800,
      status: RequestStatus.pending,
      approvals: const RequestApprovals(sef: true),
      pozCode: 'Y.18.045',
    );
    final back = MaterialRequest.fromJson(req.toJson());
    expect(back.displayName, 'İç cephe boyası');
    expect(back.approvals.sef, isTrue);
    expect(back.quantity, 1800);

    final legacy = MaterialRequest.fromJson({
      'id': 'r2',
      'projectId': 'p1',
      'title': 'TLP-OLD',
      'status': 'teklifte',
      'lines': [
        {
          'id': 'l1',
          'materialName': 'XPS 5cm',
          'birim': 'm²',
          'miktar': 650,
          'pozNo': 'Y.25.012',
        },
      ],
    });
    expect(legacy.displayName, 'TLP-OLD');
    expect(legacy.status, RequestStatus.pending);
    expect(legacy.unit, 'm²');
    expect(legacy.quantity, 650);
  });

  test('Delivery fromRequest + legacy irsaliye JSON', () {
    final d = Delivery(
      id: 'd1',
      projectId: 'p1',
      name: 'Boyası',
      unit: 'm²',
      quantity: 1000,
      date: DateTime(2026, 3, 1),
      materialRequestId: 'r1',
      irsaliyeQty: 900,
      waybillNo: 'IRS-1',
    );
    expect(d.fromRequest, isTrue);
    final back = Delivery.fromJson(d.toJson());
    expect(back.materialRequestId, 'r1');
    expect(back.irsaliyeQty, 900);

    final legacy = Delivery.fromJson({
      'id': 'd2',
      'projectId': 'p1',
      'date': '2026-03-01T00:00:00.000',
      'irsaliyeNo': 'IRS-OLD',
      'supplierName': 'Firma',
      'lines': [
        {
          'materialName': 'Çimento',
          'birim': 'ton',
          'quantity': 24,
        },
      ],
    });
    expect(legacy.name, 'Çimento');
    expect(legacy.waybillNo, 'IRS-OLD');
    expect(legacy.supplier, 'Firma');
    expect(legacy.fromRequest, isFalse);
  });

  test('metraj × birim sarfiyat = malzeme miktarı', () {
    final lines = [
      const KesifLine(
        id: 'a',
        pozNo: 'Y.19.001',
        tanim: 'Seramik',
        birim: 'm²',
        miktar: 420,
        anaGrup: MainDiscipline.insaat,
      ),
    ];
    final consumptions = [
      const UnitConsumption(
        id: 'u1',
        projectId: 'p1',
        materialName: 'Yapıştırıcı C2TE',
        materialUnit: 'KG',
        rate: 5,
        pozNo: 'Y.19.001',
        kesifUnit: 'm²',
      ),
      const UnitConsumption(
        id: 'u2',
        projectId: 'p1',
        materialName: 'Derz',
        materialUnit: 'KG',
        rate: 0.4,
        pozNo: 'Y.19.001',
        kesifUnit: 'm²',
      ),
    ];
    final needs = computeMaterialNeeds(
      lines: lines,
      consumptions: consumptions,
    );
    expect(needs.length, 2);
    expect(needs[0].quantity, 2100);
    expect(needs[1].quantity, closeTo(168, 0.001));
  });
}
