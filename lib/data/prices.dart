import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'storage.dart';

/// An online pharmacy. Shown with initials, not the company's logo.
class Pharmacy {
  const Pharmacy({
    required this.id,
    required this.name,
    required this.initials,
    required this.domain,
    required this.color,
    required this.searchBase,
  });

  final String id;
  final String name;
  final String initials;
  final String domain;
  final Color color;

  /// Search page; the medicine name is appended URL-encoded.
  /// Check each pattern on the live site before release — URL formats change.
  final String searchBase;

  Uri searchUri(String medicine) =>
      Uri.parse('$searchBase${Uri.encodeComponent(medicine)}');
}

const pharmacies = [
  Pharmacy(id: 'truemeds', name: 'Truemeds', initials: 'TM', domain: 'truemeds.in', color: AppColors.mint, searchBase: 'https://www.truemeds.in/search/'),
  Pharmacy(id: 'amazon', name: 'Amazon Pharmacy', initials: 'AZ', domain: 'amazon.in', color: Color(0xFFFF8A4C), searchBase: 'https://www.amazon.in/s?k='),
  Pharmacy(id: 'pharmeasy', name: 'PharmEasy', initials: 'PE', domain: 'pharmeasy.in', color: AppColors.violet, searchBase: 'https://pharmeasy.in/search/all?name='),
  Pharmacy(id: 'tata1mg', name: 'Tata 1mg', initials: '1mg', domain: '1mg.com', color: AppColors.coral, searchBase: 'https://www.1mg.com/search/all?name='),
  Pharmacy(id: 'netmeds', name: 'Netmeds', initials: 'NM', domain: 'netmeds.com', color: AppColors.sky, searchBase: 'https://www.netmeds.com/catalogsearch/result/'),
  Pharmacy(id: 'apollo', name: 'Apollo Pharmacy', initials: 'AP', domain: 'apollopharmacy.in', color: AppColors.amber, searchBase: 'https://www.apollopharmacy.in/search-medicines/'),
];

/// What the user saw on one site. [price] is per strip; null = not available.
class PriceEntry {
  const PriceEntry({required this.price, required this.at});

  final double? price;
  final DateTime at;

  bool get available => price != null;
}

/// Prices the user has collected, per medicine. No server involved: the user
/// opens each pharmacy inside the app, sees the live price and saves it.
/// Saved on the phone with shared_preferences.
class PriceBook extends ChangeNotifier {
  final Map<String, Map<String, PriceEntry>> _byMed = {};

  Map<String, PriceEntry> of(String medId) => _byMed[medId] ?? const {};

  void save(String medId, String pharmacyId, double? price) {
    (_byMed[medId] ??= {})[pharmacyId] = PriceEntry(price: price, at: DateTime.now());
    Storage.setJson('prices', {
      for (final m in _byMed.entries)
        m.key: {
          for (final e in m.value.entries)
            e.key: {'p': e.value.price, 'at': e.value.at.toIso8601String()},
        },
    });
    notifyListeners();
  }

  void load() {
    final saved = Storage.getJson('prices');
    if (saved is! Map) return;
    for (final m in saved.entries) {
      final inner = m.value;
      if (inner is! Map) continue;
      _byMed[m.key as String] = {
        for (final e in inner.entries)
          if (e.value is Map)
            e.key as String: PriceEntry(
              price: ((e.value as Map)['p'] as num?)?.toDouble(),
              at: DateTime.tryParse((e.value as Map)['at'] as String? ?? '') ?? DateTime.now(),
            ),
      };
    }
    notifyListeners();
  }

  /// Available entries, cheapest first.
  List<(Pharmacy, PriceEntry)> ranked(String medId) {
    final m = of(medId);
    return [
      for (final p in pharmacies)
        if (m[p.id]?.available ?? false) (p, m[p.id]!),
    ]..sort((a, b) => a.$2.price!.compareTo(b.$2.price!));
  }

  /// Next pharmacy not yet checked for this medicine, after [afterId].
  Pharmacy? nextUnchecked(String medId, {String? afterId}) {
    final m = of(medId);
    final start = afterId == null ? 0 : pharmacies.indexWhere((p) => p.id == afterId) + 1;
    for (var i = 0; i < pharmacies.length; i++) {
      final p = pharmacies[(start + i) % pharmacies.length];
      if (!m.containsKey(p.id)) return p;
    }
    return null;
  }
}

final priceBook = PriceBook();
