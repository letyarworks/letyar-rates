import 'dart:convert';

import 'package:http/http.dart' as http;

class RateService {
  static const String _currencyUrl =
      'https://myanmar-currency-api.github.io/api/latest.json';

  static const String _goldUrl =
      'https://xaus.com/api/v1/spot?currency=USD&unit=gram&compact=1';

  Future<RateData> fetchRates() async {
    final currencyResponse = await http
        .get(Uri.parse(_currencyUrl))
        .timeout(const Duration(seconds: 10));

    if (currencyResponse.statusCode != 200) {
      throw Exception('Failed to load currency rates');
    }

    final currencyDecoded = jsonDecode(currencyResponse.body);

    if (currencyDecoded is! Map<String, dynamic>) {
      throw Exception('Invalid currency API response');
    }

    final data = currencyDecoded['data'];

    if (data is! List) {
      throw Exception('Currency data not found');
    }

    Map<String, dynamic>? usd;

    for (final item in data) {
      if (item is Map<String, dynamic> &&
          item['currency']?.toString().toUpperCase() == 'USD') {
        usd = item;
        break;
      }
    }

    if (usd == null) {
      throw Exception('USD rate not found');
    }

    final usdBuy = _toDouble(usd['buy']);
    final usdSell = _toDouble(usd['sell']);

    if (usdBuy == null || usdSell == null) {
      throw Exception('Invalid USD rate');
    }

    final now = DateTime.now();
    GoldRate? goldRate;

    try {
      final goldResponse = await http
          .get(Uri.parse(_goldUrl))
          .timeout(const Duration(seconds: 10));

      if (goldResponse.statusCode == 200) {
        final goldDecoded = jsonDecode(goldResponse.body);

        if (goldDecoded is Map<String, dynamic>) {
          final gold = goldDecoded['xau'];
          final goldUsdGram = gold is Map<String, dynamic>
              ? _toDouble(gold['price'])
              : null;

          if (goldUsdGram != null) {
            goldRate = GoldRate(
              usdPerGram: goldUsdGram,
              buy: goldUsdGram * usdBuy,
              sell: goldUsdGram * usdSell,
            );
          }
        }
      }
    } catch (_) {
      // USD must remain available even if the gold service is unavailable.
    }

    return RateData(
      usd: UsdRate(
        buy: usdBuy,
        sell: usdSell,
        updatedAt: now,
      ),
      gold: goldRate,
      updatedAt: now,
    );
  }

  Future<UsdRate> fetchUsdRate() async {
    final rates = await fetchRates();
    return rates.usd;
  }

  double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString().replaceAll(',', '').trim(),
    );
  }
}

class RateData {
  final UsdRate usd;
  final GoldRate? gold;
  final DateTime updatedAt;

  const RateData({
    required this.usd,
    required this.gold,
    required this.updatedAt,
  });
}

class UsdRate {
  final double buy;
  final double sell;
  final DateTime? updatedAt;

  const UsdRate({
    required this.buy,
    required this.sell,
    this.updatedAt,
  });
}

class GoldRate {
  final double usdPerGram;
  final double buy;
  final double sell;

  const GoldRate({
    required this.usdPerGram,
    required this.buy,
    required this.sell,
  });
}