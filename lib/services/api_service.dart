import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;

import '../models/domain_data.dart';
import '../models/population_data.dart';
import '../models/internet_penetration_data.dart';
import '../models/state_population_data.dart';

class ApiService {
  static const String domainsUrl =
      'https://api.data.gov.my/data-catalogue?id=domains&limit=100';

  static const String populationUrl =
      'https://api.data.gov.my/data-catalogue?id=population_malaysia&limit=100';

  // ============================================================
  // GET .MY DOMAIN DATA
  // ============================================================

  Future<List<DomainData>> getDomains() async {
    final response = await http.get(
      Uri.parse(domainsUrl),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load domain data: ${response.statusCode}',
      );
    }

    final List<dynamic> jsonData = jsonDecode(response.body);

    return jsonData
        .map((json) => DomainData.fromJson(json))
        .toList();
  }

  // ============================================================
  // GET MALAYSIA POPULATION DATA (national level)
  // ============================================================

  Future<List<PopulationData>> getPopulation() async {
    final response = await http.get(
      Uri.parse(populationUrl),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load population data: ${response.statusCode}',
      );
    }

    final List<dynamic> jsonData = jsonDecode(response.body);

    return jsonData
        .map((json) => PopulationData.fromJson(json))
        .toList();
  }

  // ============================================================
  // GET INTERNET PENETRATION DATA
  // ============================================================

  Future<List<InternetPenetrationData>> getInternetPenetration() async {
    final String jsonString =
    await rootBundle.loadString('assets/data/internet_penetration.json');

    final List<dynamic> jsonData = jsonDecode(jsonString);

    return jsonData
        .map((json) => InternetPenetrationData.fromJson(json))
        .toList();
  }

  // ============================================================
  // GET STATE-LEVEL POPULATION DATA
  // ============================================================

  Future<List<StatePopulationData>> getStatePopulation() async {
    final String jsonString =
    await rootBundle.loadString('assets/data/population_state.json');

    final List<dynamic> jsonData = jsonDecode(jsonString);

    return jsonData
        .map((json) => StatePopulationData.fromJson(json))
        .toList();
  }
}