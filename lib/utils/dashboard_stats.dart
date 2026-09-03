import '../models/domain_data.dart';
import '../models/population_data.dart';
import '../models/internet_penetration_data.dart';
import '../models/state_population_data.dart';

class DashboardStats {
  static String internetPenetration(List<InternetPenetrationData> data) {
    if (data.isEmpty) return '--';
    final latest = _latestByDate(data, (d) => d.date);
    final rate = latest.mbbRate;
    return '${rate.toStringAsFixed(1)}%';
  }

  static String domainRegistrations(List<DomainData> data) {
    final filtered = _overallCumulativeDomains(data);
    if (filtered.isEmpty) return '--';

    final latest = _latestByDate(filtered, (d) => d.date);
    return formatCompact(latest.registrations.toDouble());
  }

  static String population(List<PopulationData> data) {
    if (data.isEmpty) return '--';

    final latestDate = data
        .map((d) => d.date)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    final sameDate = data.where((d) => d.date == latestDate).toList();

    final overallRows = sameDate.where(
          (d) =>
      d.age.toLowerCase() == 'overall' &&
          d.sex.toLowerCase() == 'both' &&
          d.ethnicity.toLowerCase() == 'overall',
    );

    final value = overallRows.isNotEmpty
        ? overallRows.first.population
        : sameDate.map((d) => d.population).reduce((a, b) => a > b ? a : b);

    return formatCompact(value * 1000);
  }

  static StatePopulationData? topState(List<StatePopulationData> data) {
    final snapshot = latestStateSnapshot(data);
    if (snapshot.isEmpty) return null;
    return snapshot.reduce((a, b) => a.population > b.population ? a : b);
  }

  static int connectivityScore(List<InternetPenetrationData> data) {
    if (data.isEmpty) return 0;
    final latest = _latestByDate(data, (d) => d.date);
    final blended = (latest.mbbRate + latest.mcRate) / 2;
    return blended.clamp(0, 100).round();
  }

  static String formatCompact(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(2)}B';
    }
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  static T _latestByDate<T>(List<T> items, DateTime Function(T) getDate) {
    return items.reduce(
          (a, b) => getDate(a).isAfter(getDate(b)) ? a : b,
    );
  }

  static List<double> internetPenetrationTrend(
      List<InternetPenetrationData> data,
      ) {
    if (data.isEmpty) return [];
    final sorted = [...data]..sort((a, b) => a.date.compareTo(b.date));
    return sorted.map((d) => d.mbbRate).toList();
  }

  static List<double> domainRegistrationsTrend(List<DomainData> data) {
    final filtered = _overallCumulativeDomains(data);
    if (filtered.isEmpty) return [];

    final sorted = [...filtered]..sort((a, b) => a.date.compareTo(b.date));
    return sorted.map((d) => d.registrations.toDouble()).toList();
  }

  static List<DomainData> _overallCumulativeDomains(List<DomainData> data) {
    return data
        .where((d) => d.series == 'cumulative' && d.domain == 'overall')
        .toList();
  }

  static const List<String> _monthAbbr = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String formatMonthYear(DateTime date) {
    return '${_monthAbbr[date.month - 1]} ${date.year}';
  }

  static DateTime? overallLastUpdated(List<DateTime?> latestDates) {
    final valid = latestDates.whereType<DateTime>().toList();
    if (valid.isEmpty) return null;
    return valid.reduce((a, b) => a.isAfter(b) ? a : b);
  }

  static DateTime? latestDate<T>(List<T> items, DateTime Function(T) getDate) {
    if (items.isEmpty) return null;
    return items.map(getDate).reduce((a, b) => a.isAfter(b) ? a : b);
  }
  static List<StatePopulationData> latestStateSnapshot(
      List<StatePopulationData> data,
      ) {
    if (data.isEmpty) return [];

    final maxDate = data
        .map((d) => d.date)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    final Map<String, StatePopulationData> byState = {};
    for (final d in data) {
      if (d.date == maxDate) {
        byState[d.state] = d;
      }
    }
    return byState.values.toList();
  }

  static String formatStatePopulation(double populationInThousands) {
    return formatCompact(populationInThousands * 1000);
  }
}
