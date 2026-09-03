import '../models/domain_data.dart';
import '../models/population_data.dart';
import '../models/internet_penetration_data.dart';
import '../models/state_population_data.dart';

// ============================================================
// DASHBOARD STATS
// ------------------------------------------------------------
// Turns the raw lists returned by ApiService into the numbers
// shown on the dashboard. Previously the dashboard just showed
// hard-coded numbers even though the data was already being
// fetched - these helpers actually use it.
//
// NOTE: data.gov.my's live endpoints can add/rename fields over
// time, so every helper fails gracefully (returns a fallback
// string) instead of crashing the UI if a field is missing or
// a list is empty.
// ============================================================

class DashboardStats {
  // ------------------------------------------------------------
  // Internet penetration: latest mobile broadband rate (%).
  // ------------------------------------------------------------
  static String internetPenetration(List<InternetPenetrationData> data) {
    if (data.isEmpty) return '--';
    final latest = _latestByDate(data, (d) => d.date);
    final rate = latest.mbbRate;
    return '${rate.toStringAsFixed(1)}%';
  }

  // ------------------------------------------------------------
  // .MY domain registrations: total registrations on the most
  // recent date present in the dataset.
  //
  // The domains dataset carries multiple rows per date: split by
  // series ('cumulative' vs 'new_net') AND by domain ('overall'
  // plus each individual TLD like .com.my, .net.my, etc). Summing
  // every row at a date massively overcounts (~2x from double
  // series, further inflated by TLD breakdown rows on top of the
  // 'overall' row that already totals them). Must filter to
  // series == 'cumulative' && domain == 'overall' - the single
  // row that already represents the true running total.
  // ------------------------------------------------------------
  static String domainRegistrations(List<DomainData> data) {
    final filtered = _overallCumulativeDomains(data);
    if (filtered.isEmpty) return '--';

    final latest = _latestByDate(filtered, (d) => d.date);
    return formatCompact(latest.registrations.toDouble());
  }

  // ------------------------------------------------------------
  // National population: prefers the aggregated
  // "overall / both / overall" row for the most recent date;
  // falls back to the single largest value on that date (which
  // is normally the same aggregated row) if the filter matches
  // nothing.
  // ------------------------------------------------------------
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

    // data.gov.my reports population in thousands.
    return formatCompact(value * 1000);
  }

  // ------------------------------------------------------------
  // Top state by population. State data can arrive as a full
  // historical time series (multiple rows per state across
  // years) - always resolve to the latest-year snapshot first,
  // otherwise a fast-growing state's older-but-still-large rows
  // can outrank other states' current values.
  // ------------------------------------------------------------
  static StatePopulationData? topState(List<StatePopulationData> data) {
    final snapshot = latestStateSnapshot(data);
    if (snapshot.isEmpty) return null;
    return snapshot.reduce((a, b) => a.population > b.population ? a : b);
  }

  // ------------------------------------------------------------
  // A simple "Digital Connectivity Score" (0-100) blended from
  // internet penetration and mobile cellular rate. This is a
  // heuristic for the dashboard headline card, not an official
  // metric.
  // ------------------------------------------------------------
  static int connectivityScore(List<InternetPenetrationData> data) {
    if (data.isEmpty) return 0;
    final latest = _latestByDate(data, (d) => d.date);
    final blended = (latest.mbbRate + latest.mcRate) / 2;
    return blended.clamp(0, 100).round();
  }

  // ------------------------------------------------------------
  // Formats a number compactly, e.g. 1820000 -> "1.82M".
  // ------------------------------------------------------------
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

  // ------------------------------------------------------------
  // Mobile broadband penetration rate over time, oldest to
  // newest - feeds the dashboard's trend sparkline.
  // ------------------------------------------------------------
  static List<double> internetPenetrationTrend(
      List<InternetPenetrationData> data,
      ) {
    if (data.isEmpty) return [];
    final sorted = [...data]..sort((a, b) => a.date.compareTo(b.date));
    return sorted.map((d) => d.mbbRate).toList();
  }

  // ------------------------------------------------------------
  // Total .MY domain registrations per date, oldest to newest -
  // feeds the dashboard's trend sparkline. Same series/domain
  // filter as domainRegistrations() above - each date should
  // contribute exactly one (already-cumulative) value, not a sum
  // of every series/TLD row at that date.
  // ------------------------------------------------------------
  static List<double> domainRegistrationsTrend(List<DomainData> data) {
    final filtered = _overallCumulativeDomains(data);
    if (filtered.isEmpty) return [];

    final sorted = [...filtered]..sort((a, b) => a.date.compareTo(b.date));
    return sorted.map((d) => d.registrations.toDouble()).toList();
  }

  // ------------------------------------------------------------
  // Filters the raw domains dataset down to the single row per
  // date that represents the true running total: the cumulative
  // series' "overall" domain row (as opposed to new_net series or
  // individual TLD breakdown rows like .com.my, .gov.my, etc).
  // ------------------------------------------------------------
  static List<DomainData> _overallCumulativeDomains(List<DomainData> data) {
    return data
        .where((d) => d.series == 'cumulative' && d.domain == 'overall')
        .toList();
  }

  static const List<String> _monthAbbr = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  // ------------------------------------------------------------
  // Formats a date as "MMM yyyy", e.g. "Jun 2026" - used for the
  // "Last Updated" stat and the Recent Dataset Updates list.
  // ------------------------------------------------------------
  static String formatMonthYear(DateTime date) {
    return '${_monthAbbr[date.month - 1]} ${date.year}';
  }

  // ------------------------------------------------------------
  // Latest date found across a set of dataset "latest" dates -
  // used for the dashboard's "Last Updated" stat card.
  // ------------------------------------------------------------
  static DateTime? overallLastUpdated(List<DateTime?> latestDates) {
    final valid = latestDates.whereType<DateTime>().toList();
    if (valid.isEmpty) return null;
    return valid.reduce((a, b) => a.isAfter(b) ? a : b);
  }

  static DateTime? latestDate<T>(List<T> items, DateTime Function(T) getDate) {
    if (items.isEmpty) return null;
    return items.map(getDate).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  // ------------------------------------------------------------
  // Collapses a full historical state-population time series
  // down to just the most recent year, one row per state. Fixes
  // duplicate/dominated rankings when the source data spans
  // multiple decades instead of a single snapshot.
  // ------------------------------------------------------------
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

  // ------------------------------------------------------------
  // data.gov.my reports state population in thousands, same
  // convention as the national population dataset - multiply
  // before formatting so displayed values are actual people.
  // ------------------------------------------------------------
  static String formatStatePopulation(double populationInThousands) {
    return formatCompact(populationInThousands * 1000);
  }
}
