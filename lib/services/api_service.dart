import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;

import '../models/domain_data.dart';
import '../models/population_data.dart';
import '../models/internet_penetration_data.dart';
import '../models/state_population_data.dart';

class ApiService {
  static const String domainsUrl =
      'https://api.data.gov.my/data-catalogue?id=domains&limit=100&sort=-date';

  static const String populationUrl =
      'https://api.data.gov.my/data-catalogue?id=population_malaysia&limit=100&sort=-date';

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

  Future<List<DomainData>> getDomainsFullHistory() async {
    final url = Uri.parse(
      'https://api.data.gov.my/data-catalogue?id=domains'
          '&date_start=2007-01-01@date&limit=10000&sort=date',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to load domain history: ${response.statusCode}');
    }

    final jsonData = _decodeAsList(response.body, 'domain history data');
    final records = _parseList(jsonData, DomainData.fromJson, 'domain');

    debugPrint('getDomainsFullHistory: fetched ${records.length} records');

    if (records.isNotEmpty) {
      final dates = records.map((d) => d.date).toList()..sort();
      debugPrint(
        'getDomainsFullHistory: earliest = ${dates.first}, latest = ${dates.last}',
      );
    }

    return records;
  }

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