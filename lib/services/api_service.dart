import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;

import '../models/domain_data.dart';
import '../models/population_data.dart';
import '../models/internet_penetration_data.dart';
import '../models/state_population_data.dart';

class ApiService {
  // sort=-date : without this, the API was returning records in an
  // undefined/oldest-first order. With limit=100 and no sort, we were
  // getting the OLDEST 100 records instead of the newest - which is why
  // "Recent Dataset Updates" was showing dates that were decades stale.
  // (Confirmed against data.gov.my's official Request Query docs:
  // https://developer.data.gov.my/request-query)
  static const String domainsUrl =
      'https://api.data.gov.my/data-catalogue?id=domains&limit=100&sort=-date';

  static const String populationUrl =
      'https://api.data.gov.my/data-catalogue?id=population_malaysia&limit=100&sort=-date';

  // ============================================================
  // GET .MY DOMAIN DATA
  // ============================================================

  Future<List<DomainData>> getDomains() async {
    final response = await http.get(Uri.parse(domainsUrl));

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load domain data: ${response.statusCode}',
      );
    }

    final jsonData = _decodeAsList(response.body, 'domain data');
    return _parseList(jsonData, DomainData.fromJson, 'domain');
  }

  // ============================================================
  // GET MALAYSIA POPULATION DATA (national level)
  // ============================================================

  Future<List<PopulationData>> getPopulation() async {
    final response = await http.get(Uri.parse(populationUrl));

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load population data: ${response.statusCode}',
      );
    }

    final jsonData = _decodeAsList(response.body, 'population data');
    return _parseList(jsonData, PopulationData.fromJson, 'population');
  }

  // ============================================================
  // GET INTERNET PENETRATION DATA (bundled asset)
  // ============================================================

  Future<List<InternetPenetrationData>> getInternetPenetration() async {
    final String jsonString =
    await rootBundle.loadString('assets/data/internet_penetration.json');

    final jsonData = _decodeAsList(jsonString, 'internet penetration data');
    return _parseList(
      jsonData,
      InternetPenetrationData.fromJson,
      'internet penetration',
    );
  }

  // ============================================================
  // GET STATE-LEVEL POPULATION DATA (bundled asset)
  // ============================================================

  Future<List<StatePopulationData>> getStatePopulation() async {
    final String jsonString =
    await rootBundle.loadString('assets/data/population_state.json');

    final jsonData = _decodeAsList(jsonString, 'state population data');
    return _parseList(
      jsonData,
      StatePopulationData.fromJson,
      'state population',
    );
  }

  // ============================================================
  // INPUT VALIDATION HELPERS
  // ------------------------------------------------------------
  // Government open-data endpoints can return an error object,
  // a wrapped {"data": [...]} response, or the occasional
  // malformed record. Rather than let one bad row crash the
  // whole dataset (and therefore the whole dashboard), we:
  //   1. Confirm the decoded JSON is actually a List.
  //   2. Parse each row individually, skipping (and logging) any
  //      row that fails to parse instead of throwing.
  // ============================================================

  List<dynamic> _decodeAsList(String body, String label) {
    final decoded = jsonDecode(body);

    if (decoded is List) {
      return decoded;
    }

    // Some endpoints can return {"data": [...], "meta": {...}} -
    // handle that shape defensively too, in case ?meta=true is
    // ever added or the API changes its default response shape.
    if (decoded is Map && decoded['data'] is List) {
      return decoded['data'] as List;
    }

    throw Exception(
      'Unexpected response format for $label: expected a list of '
          'records but got ${decoded.runtimeType}.',
    );
  }

  List<T> _parseList<T>(
      List<dynamic> jsonData,
      T Function(Map<String, dynamic>) fromJson,
      String label,
      ) {
    final List<T> results = [];

    for (final item in jsonData) {
      if (item is! Map<String, dynamic>) {
        debugPrint('Skipping malformed $label record (not an object): $item');
        continue;
      }

      try {
        results.add(fromJson(item));
      } catch (e) {
        debugPrint('Skipping malformed $label record: $e');
      }
    }

    return results;
  }
}
