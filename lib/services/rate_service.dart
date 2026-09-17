import 'dart:convert';

import 'package:http/http.dart' as http;

class RateService {
  static const String _currencyUrl =
      'https://myanmar-currency-api.github.io/api/latest.json';

  static const String _goldUrl =
      'https://xaus.com/api/v1/spot?currency=USD&unit=gram&compact=1';

  Future<RateData> fetchRates() async {
    final responses = await Future.wait([
      http
          .get(Uri.parse(_currencyUrl))
          .timeout(const Duration(seconds: 10)),
      http
          .get(Uri.parse(_goldUrl))
          .timeout(const Duration(seconds: 10)),
    ]);

    final currencyResponse = responses[0];
    final goldResponse = responses[1];

    if (currencyResponse.statusCode != 200) {
      throw Exception('Failed to load currency rates');
    }

    if (goldResponse.statusCode != 200) {
      throw Exception('Failed to load gold rate');
    }

    final currencyDecoded = jsonDecode(currencyResponse.body);
    final goldDecoded = jsonDecode(goldResponse.body);

    if (currencyDecoded is! Map<String, dynamic>) {
      throw Exception('Invalid currency API response');
    }

    if (goldDecoded is! Map<String, dynamic>) {
      throw Exception('Invalid gold API response');
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

    final gold = goldDecoded['xau'];

    if (gold is! Map<String, dynamic>) {
      throw Exception('Gold data not found');
    }

    final goldUsdGram = _toDouble(gold['price']);

    if (goldUsdGram == null) {
      throw Exception('Invalid gold rate');
    }

    final goldBuy = goldUsdGram * usdBuy;
    final goldSell = goldUsdGram * usdSell;

    final updatedAt = DateTime.tryParse(
      goldDecoded['updated_at']?.toString() ?? '',
    );

    return RateData(
      usd: UsdRate(
        buy: usdBuy,
        sell: usdSell,
        updatedAt: updatedAt ?? DateTime.now(),
      ),
      gold: GoldRate(
        usdPerGram: goldUsdGram,
        buy: goldBuy,
        sell: goldSell,
      ),
      updatedAt: updatedAt ?? DateTime.now(),
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
  final GoldRate gold;
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