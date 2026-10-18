import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../core/theme.dart';
import 'storage.dart';

enum MedStatus { safe, soon, expired }

Color statusColor(MedStatus s) => switch (s) {
      MedStatus.safe => AppColors.mint,
      MedStatus.soon => AppColors.amber,
      MedStatus.expired => AppColors.coral,
    };

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

class Medicine {
  Medicine({
    required this.id,
    required this.name,
    required this.generic,
    required this.form,
    required this.use,
    required this.owner,
    required this.place,
    required this.unit,
    required this.qty,
    required this.expiry,
    required this.bought,
  });

  final String id;
  final String name;
  final String generic;

  /// Translation keys: form_*, use_*, owner_*, place_*, unit_*.
  final String form;
  final String use;
  final String owner;
  final String place;
  final String unit;

  int qty;
  final DateTime expiry;
  final DateTime bought;

  int daysLeft([DateTime? now]) =>
      _day(expiry).difference(_day(now ?? DateTime.now())).inDays;

  /// 0 = just bought, 1 = at (or past) expiry.
  double lifeUsed([DateTime? now]) {
    final total = expiry.difference(bought).inDays;
    if (total <= 0) return 1;
    final used = _day(now ?? DateTime.now()).difference(_day(bought)).inDays;
    return (used / total).clamp(0.0, 1.0);
  }

  bool get isLiquid => form == 'form_syrup' || form == 'form_gel';

  IconData get icon =>
      isLiquid ? Icons.medication_liquid_rounded : Icons.medication_rounded;

  String meta(BuildContext context) =>
      '${context.tr(form)} · ${context.tr(use)}';

  Map<String, Object> toJson() => {
        'id': id, 'name': name, 'generic': generic, 'form': form, 'use': use,
        'owner': owner, 'place': place, 'unit': unit, 'qty': qty,
        'expiry': expiry.toIso8601String(), 'bought': bought.toIso8601String(),
      };

  static Medicine fromJson(Map<String, dynamic> j) => Medicine(
        id: j['id'] as String,
        name: j['name'] as String,
        generic: j['generic'] as String,
        form: j['form'] as String,
        use: j['use'] as String,
        owner: j['owner'] as String,
        place: j['place'] as String,
        unit: j['unit'] as String,
        qty: (j['qty'] as num).toInt(),
        expiry: DateTime.parse(j['expiry'] as String),
        bought: DateTime.parse(j['bought'] as String),
      );
}

class MedStore extends ChangeNotifier {
  MedStore() : meds = _sample();

  final List<Medicine> meds;
  int reminderDays = 30;
  bool notifications = true;

  /// Load saved data (call once after Storage.init). First launch keeps the
  /// sample medicines so the app isn't empty.
  void load() {
    final saved = Storage.getJson('meds');
    if (saved is List) {
      meds
        ..clear()
        ..addAll(saved.whereType<Map<String, dynamic>>().map(Medicine.fromJson));
    }
    final settings = Storage.getJson('settings');
    if (settings is Map) {
      reminderDays = (settings['reminderDays'] as num?)?.toInt() ?? reminderDays;
      notifications = settings['notifications'] as bool? ?? notifications;
    }
    notifyListeners();
  }

  void _changed() {
    Storage.setJson('meds', [for (final m in meds) m.toJson()]);
    Storage.setJson('settings', {'reminderDays': reminderDays, 'notifications': notifications});
    notifyListeners();
  }

  MedStatus statusOf(Medicine m) {
    final d = m.daysLeft();
    if (d < 0) return MedStatus.expired;
    if (d <= reminderDays) return MedStatus.soon;
    return MedStatus.safe;
  }

  List<Medicine> get sorted =>
      [...meds]..sort((a, b) => a.expiry.compareTo(b.expiry));

  List<Medicine> byStatus(MedStatus s) =>
      sorted.where((m) => statusOf(m) == s).toList();

  List<Medicine> get lowStock => sorted
      .where((m) => statusOf(m) != MedStatus.expired && m.qty <= 4)
      .toList();

  double get health => meds.isEmpty
      ? 1
      : meds.where((m) => statusOf(m) != MedStatus.expired).length /
          meds.length;

  /// Another usable pack of the same medicine, if any.
  Medicine? sameGeneric(Medicine m) => meds
      .where((o) =>
          o.id != m.id &&
          o.generic == m.generic &&
          statusOf(o) != MedStatus.expired)
      .firstOrNull;

  void add(Medicine m) {
    meds.add(m);
    _changed();
  }

  void remove(String id) {
    meds.removeWhere((m) => m.id == id);
    _changed();
  }

  void useOne(Medicine m) {
    if (m.qty > 0) m.qty--;
    _changed();
  }

  void setReminderDays(int days) {
    reminderDays = days;
    _changed();
  }

  void setNotifications(bool on) {
    notifications = on;
    _changed();
  }
}

/// App-wide store. Swap for a database (Hive / sqflite) to persist data.
final store = MedStore();

List<Medicine> _sample() {
  final today = _day(DateTime.now());
  DateTime d(int days) => today.add(Duration(days: days));
  return [
    Medicine(
        id: 'crocin', name: 'Crocin 650', generic: 'Paracetamol 650 mg',
        form: 'form_tablet', use: 'use_fever', owner: 'owner_everyone',
        place: 'place_kitchen', unit: 'unit_tablets', qty: 8,
        expiry: d(6), bought: d(-700)),
    Medicine(
        id: 'cough', name: 'Cough Syrup', generic: 'Dextromethorphan 100 ml',
        form: 'form_syrup', use: 'use_cough', owner: 'owner_everyone',
        place: 'place_bedroom', unit: 'unit_ml', qty: 60,
        expiry: d(12), bought: d(-400)),
    Medicine(
        id: 'vitd', name: 'Vitamin D3', generic: 'Cholecalciferol 60K',
        form: 'form_capsule', use: 'use_vitamin', owner: 'owner_papa',
        place: 'place_bedroom', unit: 'unit_capsules', qty: 4,
        expiry: d(24), bought: d(-500)),
    Medicine(
        id: 'antacid', name: 'Antacid Gel', generic: 'Antacid suspension',
        form: 'form_gel', use: 'use_acidity', owner: 'owner_everyone',
        place: 'place_kitchen', unit: 'unit_ml', qty: 90,
        expiry: d(-16), bought: d(-720)),
    Medicine(
        id: 'dolo', name: 'Dolo 650', generic: 'Paracetamol 650 mg',
        form: 'form_tablet', use: 'use_fever', owner: 'owner_everyone',
        place: 'place_kitchen', unit: 'unit_tablets', qty: 15,
        expiry: d(160), bought: d(-200)),
    Medicine(
        id: 'cetirizine', name: 'Cetirizine 10', generic: 'Cetirizine 10 mg',
        form: 'form_tablet', use: 'use_allergy', owner: 'owner_maa',
        place: 'place_bedroom', unit: 'unit_tablets', qty: 10,
        expiry: d(300), bought: d(-90)),
  ];
}
