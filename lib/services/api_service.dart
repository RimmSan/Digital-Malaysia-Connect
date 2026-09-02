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

  // Full-history variant used by the Growth Tracker page, which needs
  // the complete multi-year trend (2007-present) rather than just the
  // most recent 100 records. Kept separate from `domainsUrl` above so
  // other modules relying on "most recent" data are unaffected.
  static const String domainsFullHistoryUrl =
      'https://api.data.gov.my/data-catalogue?id=domains&limit=5000';

  static const String populationUrl =
      'https://api.data.gov.my/data-catalogue?id=population_malaysia&limit=100&sort=-date';

  // ============================================================
  // GET .MY DOMAIN DATA (most recent — used for dashboard/updates)
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
  // GET .MY DOMAIN DATA (full history — used for Growth Tracker chart)
  // ============================================================

  Future<List<DomainData>> getDomainsFullHistory() async {
    final List<DomainData> allRecords = [];
    final Set<String> seenKeys = {}; // detects duplicate/non-advancing pages
    const int pageSize = 100;
    const int maxPages = 30;

    for (int page = 1; page <= maxPages; page++) {
      final url =
          'https://api.data.gov.my/data-catalogue?id=domains&limit=$pageSize&sort=-date&page=$page';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        debugPrint('getDomainsFullHistory: request failed at page $page (${response.statusCode})');
        break;
      }

      final jsonData = _decodeAsList(response.body, 'domain history data');
      final pageRecords = _parseList(jsonData, DomainData.fromJson, 'domain');

      if (pageRecords.isEmpty) {
        debugPrint('getDomainsFullHistory: stopped at page $page — empty page');
        break;
      }

      // Build a unique key per record to detect if this "page" is actually
      // new data, or just the same records the API already gave us before
      // (which would mean pagination isn't working).
      int newRecordsThisPage = 0;
      for (final record in pageRecords) {
        final key = '${record.date.toIso8601String()}_${record.domain}_${record.series}';
        if (seenKeys.add(key)) {
          allRecords.add(record);
          newRecordsThisPage++;
        }
      }

      debugPrint('getDomainsFullHistory: page $page — ${pageRecords.length} fetched, $newRecordsThisPage new');

      if (newRecordsThisPage == 0) {
        debugPrint('getDomainsFullHistory: stopped at page $page — no new records, pagination not advancing');
        break;
      }

      if (pageRecords.length < pageSize) {
        debugPrint('getDomainsFullHistory: stopped at page $page — reached last page');
        break;
      }
    }

    if (allRecords.isNotEmpty) {
      final dates = allRecords.map((d) => d.date).toList()..sort();
      debugPrint('getDomainsFullHistory: TOTAL fetched ${allRecords.length} unique records');
      debugPrint('getDomainsFullHistory: earliest = ${dates.first}, latest = ${dates.last}');
    } else {
      debugPrint('getDomainsFullHistory: no records fetched at all');
    }

    return allRecords;
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
  // ============================================================

  List<dynamic> _decodeAsList(String body, String label) {
    final decoded = jsonDecode(body);

    if (decoded is List) {
      return decoded;
    }

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