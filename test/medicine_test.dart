import 'package:flutter_test/flutter_test.dart';
import 'package:medbox/data/medicine.dart';

void main() {
  test('status follows the reminder window', () {
    final s = MedStore();
    final crocin = s.meds.firstWhere((m) => m.id == 'crocin');
    final antacid = s.meds.firstWhere((m) => m.id == 'antacid');
    final dolo = s.meds.firstWhere((m) => m.id == 'dolo');

    expect(crocin.daysLeft(), 6);
    expect(s.statusOf(crocin), MedStatus.soon);
    expect(s.statusOf(antacid), MedStatus.expired);
    expect(s.statusOf(dolo), MedStatus.safe);

    s.setReminderDays(7);
    expect(s.statusOf(s.meds.firstWhere((m) => m.id == 'cough')), MedStatus.safe);
  });

  test('duplicate pack is suggested', () {
    final s = MedStore();
    final crocin = s.meds.firstWhere((m) => m.id == 'crocin');
    expect(s.sameGeneric(crocin)?.name, 'Dolo 650');
  });
}
