// ============================================================
// DASHBOARD PREFERENCES MODEL
// ------------------------------------------------------------
// Backs the "Customize Dashboard" personalization feature - lets
// the user show/hide individual dashboard stat cards & sections.
// Persisted locally, separate from DashboardNote (My Insights).
// ============================================================

class DashboardPreferences {
  bool showInternetCard;
  bool showDomainsCard;
  bool showPopulationCard;
  bool showDigitalScoreCard;
  bool showTopStateCard;
  bool showLastUpdatedCard;
  bool showTrends;
  bool showRecentUpdates;

  DashboardPreferences({
    this.showInternetCard = true,
    this.showDomainsCard = true,
    this.showPopulationCard = true,
    this.showDigitalScoreCard = true,
    this.showTopStateCard = true,
    this.showLastUpdatedCard = true,
    this.showTrends = true,
    this.showRecentUpdates = true,
  });

  DashboardPreferences copyWith({
    bool? showInternetCard,
    bool? showDomainsCard,
    bool? showPopulationCard,
    bool? showDigitalScoreCard,
    bool? showTopStateCard,
    bool? showLastUpdatedCard,
    bool? showTrends,
    bool? showRecentUpdates,
  }) {
    return DashboardPreferences(
      showInternetCard: showInternetCard ?? this.showInternetCard,
      showDomainsCard: showDomainsCard ?? this.showDomainsCard,
      showPopulationCard: showPopulationCard ?? this.showPopulationCard,
      showDigitalScoreCard: showDigitalScoreCard ?? this.showDigitalScoreCard,
      showTopStateCard: showTopStateCard ?? this.showTopStateCard,
      showLastUpdatedCard: showLastUpdatedCard ?? this.showLastUpdatedCard,
      showTrends: showTrends ?? this.showTrends,
      showRecentUpdates: showRecentUpdates ?? this.showRecentUpdates,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'showInternetCard': showInternetCard,
      'showDomainsCard': showDomainsCard,
      'showPopulationCard': showPopulationCard,
      'showDigitalScoreCard': showDigitalScoreCard,
      'showTopStateCard': showTopStateCard,
      'showLastUpdatedCard': showLastUpdatedCard,
      'showTrends': showTrends,
      'showRecentUpdates': showRecentUpdates,
    };
  }

  factory DashboardPreferences.fromJson(Map<String, dynamic> json) {
    return DashboardPreferences(
      showInternetCard: json['showInternetCard'] as bool? ?? true,
      showDomainsCard: json['showDomainsCard'] as bool? ?? true,
      showPopulationCard: json['showPopulationCard'] as bool? ?? true,
      showDigitalScoreCard: json['showDigitalScoreCard'] as bool? ?? true,
      showTopStateCard: json['showTopStateCard'] as bool? ?? true,
      showLastUpdatedCard: json['showLastUpdatedCard'] as bool? ?? true,
      showTrends: json['showTrends'] as bool? ?? true,
      showRecentUpdates: json['showRecentUpdates'] as bool? ?? true,
    );
  }
}
