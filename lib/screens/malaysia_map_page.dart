import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/state_population_data.dart';
import '../services/api_service.dart';

class MalaysiaMapPage extends StatefulWidget {
  const MalaysiaMapPage({super.key});

  @override
  State<MalaysiaMapPage> createState() => _MalaysiaMapPageState();
}

class _MalaysiaMapPageState extends State<MalaysiaMapPage> {
  final ApiService _apiService = ApiService();

  final LayerHitNotifier<String> _polygonHitNotifier =
  ValueNotifier(null);

  bool _isLoading = true;
  String? _errorMessage;

  List<StatePopulationData> _allPopulationData = [];
  List<StatePopulationData> _latestStates = [];

  List<_StatePolygon> _statePolygons = [];

  String? _selectedState;

  double _currentZoom = 4.8;

  final Map<String, LatLng> _stateLabelPositions = {
    'Perlis': const LatLng(6.45, 100.20),
    'Kedah': const LatLng(5.95, 100.55),
    'Pulau Pinang': const LatLng(5.40, 100.25),
    'Perak': const LatLng(4.75, 101.00),
    'Kelantan': const LatLng(5.35, 102.05),
    'Terengganu': const LatLng(5.00, 103.00),
    'Pahang': const LatLng(3.85, 102.30),
    'Selangor': const LatLng(3.25, 101.45),
    'Negeri Sembilan': const LatLng(2.75, 102.10),
    'Melaka': const LatLng(2.25, 102.25),
    'Johor': const LatLng(2.00, 103.50),

    'W.P. Kuala Lumpur': const LatLng(3.15, 101.70),
    'W.P. Putrajaya': const LatLng(2.93, 101.69),

    'Sabah': const LatLng(5.40, 117.00),
    'Sarawak': const LatLng(2.80, 113.10),
    'W.P. Labuan': const LatLng(5.30, 115.23),
  };

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  @override
  void dispose() {
    _polygonHitNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadMapData() async {
    try {
      final populationData =
      await _apiService.getStatePopulation();

      final Map<String, StatePopulationData> latestByState = {};

      for (final record in populationData) {
        final current = latestByState[record.state];

        if (current == null ||
            record.date.isAfter(current.date)) {
          latestByState[record.state] = record;
        }
      }

      final latestStates = latestByState.values.toList()
        ..sort(
              (a, b) => b.population.compareTo(a.population),
        );

      final geoJsonString = await rootBundle.loadString(
        'assets/data/malaysia_state.geojson',
      );

      final Map<String, dynamic> geoJson =
      jsonDecode(geoJsonString);

      final List<dynamic> features =
      geoJson['features'] as List<dynamic>;

      final statePolygons = <_StatePolygon>[];

      for (final feature in features) {
        final properties =
        feature['properties'] as Map<String, dynamic>;

        final geometry =
        feature['geometry'] as Map<String, dynamic>;

        final geometryType = geometry['type'] as String;
        final coordinates = geometry['coordinates'];

        final stateName = _extractStateName(properties);

        if (stateName == null) {
          continue;
        }

        if (geometryType == 'Polygon') {
          final polygonCoordinates =
          coordinates as List<dynamic>;

          if (polygonCoordinates.isNotEmpty) {
            statePolygons.add(
              _StatePolygon(
                stateName: stateName,
                points: _convertPoints(
                  polygonCoordinates[0],
                ),
              ),
            );
          }
        }

        if (geometryType == 'MultiPolygon') {
          final multiPolygonCoordinates =
          coordinates as List<dynamic>;

          for (final polygon
          in multiPolygonCoordinates) {
            final polygonCoordinates =
            polygon as List<dynamic>;

            if (polygonCoordinates.isNotEmpty) {
              statePolygons.add(
                _StatePolygon(
                  stateName: stateName,
                  points: _convertPoints(
                    polygonCoordinates[0],
                  ),
                ),
              );
            }
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _allPopulationData = populationData;
        _latestStates = latestStates;
        _statePolygons = statePolygons;

        if (latestStates.isNotEmpty) {
          _selectedState = latestStates.first.state;
        }

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<LatLng> _convertPoints(
      dynamic rawCoordinates,
      ) {
    final points = <LatLng>[];

    for (final coordinate in rawCoordinates) {
      final values = coordinate as List<dynamic>;

      final longitude =
      (values[0] as num).toDouble();

      final latitude =
      (values[1] as num).toDouble();

      points.add(
        LatLng(
          latitude,
          longitude,
        ),
      );
    }

    return points;
  }

  String? _extractStateName(
      Map<String, dynamic> properties,
      ) {
    final possibleKeys = [
      'name',
      'NAME_1',
      'state',
      'State',
      'shapeName',
    ];

    for (final key in possibleKeys) {
      final value = properties[key];

      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return _normaliseStateName(
          value.toString(),
        );
      }
    }

    return null;
  }

  String _normaliseStateName(String value) {
    final name = value.trim();

    final replacements = {
      'Penang': 'Pulau Pinang',
      'Malacca': 'Melaka',

      'Kuala Lumpur': 'W.P. Kuala Lumpur',
      'WP Kuala Lumpur': 'W.P. Kuala Lumpur',
      'W.P Kuala Lumpur': 'W.P. Kuala Lumpur',

      'Putrajaya': 'W.P. Putrajaya',
      'WP Putrajaya': 'W.P. Putrajaya',

      'Labuan': 'W.P. Labuan',
      'WP Labuan': 'W.P. Labuan',
    };

    return replacements[name] ?? name;
  }

  List<Polygon<String>> _buildMapPolygons() {
    return _statePolygons.map(
          (statePolygon) {
        final isSelected =
            statePolygon.stateName == _selectedState;

        return Polygon<String>(
          points: statePolygon.points,

          color: isSelected
              ? const Color(0xFF168AAD)
              .withValues(alpha: 0.90)
              : const Color(0xFFB7D9E8)
              .withValues(alpha: 0.90),

          borderColor: isSelected
              ? const Color(0xFF075985)
              : const Color(0xFF5B8799),

          borderStrokeWidth:
          isSelected ? 2.8 : 1.2,

          hitValue: statePolygon.stateName,
        );
      },
    ).toList();
  }

  List<Marker> _buildStateLabels() {
    final markers = <Marker>[];

    final majorStates = {
      'Johor',
      'Pahang',
      'Perak',
      'Selangor',
      'Sabah',
      'Sarawak',
    };

    final mediumStates = {
      ...majorStates,
      'Kedah',
      'Kelantan',
      'Terengganu',
      'Negeri Sembilan',
      'Melaka',
    };

    for (final entry in _stateLabelPositions.entries) {
      final state = entry.key;
      final position = entry.value;
      final isSelected = state == _selectedState;

      bool shouldShow = false;

      if (_currentZoom < 5.3) {
        shouldShow =
            majorStates.contains(state) || isSelected;
      } else if (_currentZoom < 6.3) {
        shouldShow =
            mediumStates.contains(state) || isSelected;
      } else {
        shouldShow = true;
      }

      if (!shouldShow) {
        continue;
      }

      markers.add(
        Marker(
          point: position,
          width: isSelected ? 125 : 105,
          height: 30,
          child: GestureDetector(
            onTap: () {
              _selectState(state);
            },
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 2,
                ),
                decoration: isSelected
                    ? BoxDecoration(
                  color: const Color(0xFF075985),
                  borderRadius:
                  BorderRadius.circular(6),
                )
                    : null,
                child: Text(
                  _shortStateName(state),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSelected ? 10 : 9,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF20333D),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  String _shortStateName(String state) {
    switch (state) {
      case 'W.P. Kuala Lumpur':
        return 'Kuala Lumpur';

      case 'W.P. Putrajaya':
        return 'Putrajaya';

      case 'W.P. Labuan':
        return 'Labuan';

      default:
        return state;
    }
  }

  StatePopulationData? _getLatestRecord(
      String state,
      ) {
    final records = _allPopulationData
        .where(
          (record) => record.state == state,
    )
        .toList();

    if (records.isEmpty) {
      return null;
    }

    records.sort(
          (a, b) => b.date.compareTo(a.date),
    );

    return records.first;
  }

  StatePopulationData? _getPreviousYearRecord(
      String state,
      StatePopulationData latest,
      ) {
    final previousYear =
        latest.date.year - 1;

    final records =
    _allPopulationData.where(
          (record) =>
      record.state == state &&
          record.date.year == previousYear,
    );

    if (records.isEmpty) {
      return null;
    }

    return records.first;
  }

  int _getStateRanking(String state) {
    final index = _latestStates.indexWhere(
          (record) => record.state == state,
    );

    if (index == -1) {
      return 0;
    }

    return index + 1;
  }

  double? _calculateGrowth(
      StatePopulationData latest,
      StatePopulationData? previous,
      ) {
    if (previous == null ||
        previous.population == 0) {
      return null;
    }

    return ((latest.population -
        previous.population) /
        previous.population) *
        100;
  }

  String _formatPopulation(double population) {
    if (population >= 1000) {
      return '${(population / 1000).toStringAsFixed(2)}M';
    }

    return '${population.toStringAsFixed(1)}K';
  }

  void _selectState(String state) {
    setState(() {
      _selectedState = state;
    });
  }

  void _handlePolygonTap() {
    final hitResult = _polygonHitNotifier.value;

    if (hitResult == null) {
      return;
    }

    final hitValues = hitResult.hitValues.toList();

    if (hitValues.isEmpty) {
      return;
    }

    final state = hitValues.first;

    _selectState(state);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Interactive Malaysia Map',
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Interactive Malaysia Map',
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final selectedState = _selectedState;

    final latest = selectedState == null
        ? null
        : _getLatestRecord(selectedState);

    final previous = latest == null
        ? null
        : _getPreviousYearRecord(
      selectedState!,
      latest,
    );

    final growth = latest == null
        ? null
        : _calculateGrowth(
      latest,
      previous,
    );

    final ranking = selectedState == null
        ? 0
        : _getStateRanking(selectedState);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Interactive Malaysia Map',
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Explore Malaysia by State',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Tap anywhere inside a state or use the selector to explore its latest population intelligence.',
            style: TextStyle(
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 18),

          DropdownButtonFormField<String>(
            initialValue: _selectedState,
            decoration: InputDecoration(
              labelText: 'Select State',
              prefixIcon: const Icon(
                Icons.location_on_outlined,
              ),
              filled: true,
              fillColor:
              Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(16),
              ),
            ),
            items: _latestStates
                .map(
                  (state) =>
                  DropdownMenuItem(
                    value: state.state,
                    child: Text(
                      state.state,
                    ),
                  ),
            )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                _selectState(value);
              }
            },
          ),

          const SizedBox(height: 18),

          Container(
            height: 440,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFEAF7FC),
                  Color(0xFFD9EFF7),
                ],
              ),
              borderRadius:
              BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFFB6D5E1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),

            clipBehavior: Clip.antiAlias,

            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: const LatLng(
                      4.2105,
                      109.5,
                    ),
                    initialZoom: 4.8,
                    minZoom: 4.2,
                    maxZoom: 9.0,

                    onPositionChanged:
                        (position, hasGesture) {
                      final zoom = position.zoom;

                      if (zoom != _currentZoom) {
                        setState(() {
                          _currentZoom = zoom;
                        });
                      }
                    },
                  ),

                  children: [
                    GestureDetector(
                      behavior:
                      HitTestBehavior.deferToChild,
                      onTap: _handlePolygonTap,

                      child: PolygonLayer<String>(
                        hitNotifier:
                        _polygonHitNotifier,

                        simplificationTolerance: 0,

                        polygons:
                        _buildMapPolygons(),
                      ),
                    ),

                    MarkerLayer(
                      markers:
                      _buildStateLabels(),
                    ),
                  ],
                ),

                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white
                          .withValues(alpha: 0.92),
                      borderRadius:
                      BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize:
                      MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app_outlined,
                          size: 16,
                          color:
                          Color(0xFF168AAD),
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Tap a state',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white
                          .withValues(alpha: 0.92),
                      borderRadius:
                      BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize:
                      MainAxisSize.min,
                      children: [
                        _LegendBox(
                          color:
                          Color(0xFF168AAD),
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Selected',
                          style: TextStyle(
                            fontSize: 11,
                          ),
                        ),

                        SizedBox(width: 10),

                        _LegendBox(
                          color:
                          Color(0xFFB7D9E8),
                        ),
                        SizedBox(width: 5),

                        Text(
                          'State',
                          style: TextStyle(
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (latest != null)
            _StateInformationCard(
              state: latest.state,

              population:
              _formatPopulation(
                latest.population,
              ),

              year:
              latest.date.year.toString(),

              ranking: ranking == 0
                  ? 'N/A'
                  : '#$ranking',

              growth: growth == null
                  ? 'N/A'
                  : '${growth >= 0 ? '+' : ''}'
                  '${growth.toStringAsFixed(2)}%',

              growthPositive:
              growth != null &&
                  growth >= 0,
            ),
        ],
      ),
    );
  }
}

class _StatePolygon {
  final String stateName;
  final List<LatLng> points;

  const _StatePolygon({
    required this.stateName,
    required this.points,
  });
}

class _LegendBox extends StatelessWidget {
  final Color color;

  const _LegendBox({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius:
        BorderRadius.circular(3),
      ),
    );
  }
}

class _StateInformationCard
    extends StatelessWidget {
  final String state;
  final String population;
  final String ranking;
  final String year;
  final String growth;
  final bool growthPositive;

  const _StateInformationCard({
    required this.state,
    required this.population,
    required this.ranking,
    required this.year,
    required this.growth,
    required this.growthPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF075985),
            Color(0xFF168AAD),
          ],
        ),
        borderRadius:
        BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF075985)
                .withValues(alpha: 0.20),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white
                      .withValues(alpha: 0.15),
                  borderRadius:
                  BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'State Intelligence',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      state,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _InfoBox(
                  label: 'Population',
                  value: population,
                  icon:
                  Icons.people_alt_outlined,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _InfoBox(
                  label: 'Ranking',
                  value: ranking,
                  icon:
                  Icons.leaderboard_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _InfoBox(
                  label: 'Latest Year',
                  value: year,
                  icon:
                  Icons.calendar_today_outlined,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _InfoBox(
                  label: 'YoY Growth',
                  value: growth,
                  icon: growthPositive
                      ? Icons
                      .trending_up_rounded
                      : Icons
                      .trending_down_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white
            .withValues(alpha: 0.11),
        borderRadius:
        BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white
              .withValues(alpha: 0.12),
        ),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.white70,
            size: 18,
          ),

          const SizedBox(height: 8),

          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}